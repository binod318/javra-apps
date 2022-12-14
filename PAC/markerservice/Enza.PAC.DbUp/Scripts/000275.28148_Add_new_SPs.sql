
EXEC sp_rename 'CalcCriteriaPerCrop.CalcExternalAppl', 'CalcExternalAppHybrid';  
GO 

ALTER TABLE CalcCriteriaPerCrop
ADD CalcExternalAppParent BIT
GO

DROP PROCEDURE IF EXISTS [dbo].[PR_ProcessAllTestResultSummary]
GO




/*
Author					Date			Remarks
Binod Gurung			2020-jan-23		Trigger background summary calculation for all determination assignment whose result is determined(500)
Binod Gurung			2021-july-16	ThresholdA and ThresholdB is now considered per crop. Also calculation is only done for crops which is not marked
										to do calculation from external application

=================EXAMPLE=============

-- EXEC PR_ProcessAllTestResultSummary 43
-- All input values are in percentage (1 - 100)
*/

CREATE PROCEDURE [dbo].[PR_ProcessAllTestResultSummary]
(
	@MissingResultPercentage DECIMAL
)
AS 
BEGIN
    SET NOCOUNT ON;
	    
	DECLARE @tbl TABLE(ID INT IDENTITY(1, 1), DetAssignmentID INT, ThresholdA DECIMAL(5,2), ThresholdB DECIMAL(5,2));
	DECLARE @ThresholdA DECIMAL(5,2), @ThresholdB DECIMAL(5,2), @Crop NVARCHAR(10);

	DECLARE @Errors TABLE (DetAssignmentID INT, ErrorMessage NVARCHAR(MAX));
   
	INSERT @tbl(DetAssignmentID, ThresholdA, ThresholdB)
	SELECT 
		W.DetAssignmentID,
		MAX(ISNULL(CCPR.ThresholdA,0)),
		MAX(ISNULL(CCPR.ThresholdB,0))
	FROM TestResult TR
	JOIN Well W ON W.WellID = TR.WellID
	JOIN TestDetAssignment TDA ON TDA.DetAssignmentID = W.DetAssignmentID
	JOIN DeterminationAssignment DA ON DA.DetAssignmentID = TDA.DetAssignmentID
	JOIN ABSCrop AC ON AC.ABSCropCode = DA.ABSCropCode
	LEFT JOIN CalcCriteriaPerCrop CCPR On CCPR.CropCode = AC.CropCode
	WHERE ISNULL(W.DetAssignmentID, 0) <> 0
	AND DA.StatusCode = 500
	--AND ISNULL(CCPR.CalcExternalAppl,0) = 0 --Do not trigger calculation for crop that is done from external application
	GROUP BY W.DetAssignmentID;

	DECLARE @DetAssignmentID INT, @ID INT = 1, @Count INT;
	SELECT @Count = COUNT(ID) FROM @tbl;
	WHILE(@ID <= @Count) BEGIN
			
		SELECT 
			@DetAssignmentID = DetAssignmentID,
			@ThresholdA = ThresholdA,
			@ThresholdB = ThresholdB 
		FROM @tbl
		WHERE ID = @ID;

		SET @ID = @ID + 1;

		--threshold value not saved for crop
		IF (@ThresholdA = 0 AND @ThresholdB = 0)
		BEGIN

			SELECT @Crop = AC.CropCode FROM DeterminationAssignment DA 
			JOIN ABSCrop AC ON AC.ABSCropCode = DA.ABSCropCode
			WHERE DA.DetAssignmentID = @DetAssignmentID

			INSERT @Errors(DetAssignmentID, ErrorMessage)
			SELECT @DetAssignmentID, 'Threshold value not found for crop ' + @Crop; 
			
			CONTINUE;
		END

		BEGIN TRY
		BEGIN TRANSACTION;
			
			--Background task 1
			EXEC PR_ProcessTestResultSummary @DetAssignmentID;

			--Background task 2, 3, 4
			EXEC PR_BG_Task_2_3_4 @DetAssignmentID, @MissingResultPercentage, @ThresholdA, @ThresholdB;

		COMMIT;
		END TRY
		BEGIN CATCH

			--Store exceptions
			INSERT @Errors(DetAssignmentID, ErrorMessage)
			SELECT @DetAssignmentID, ERROR_MESSAGE(); 

			IF @@TRANCOUNT > 0
				ROLLBACK;

		END CATCH

	END   

	SELECT DetAssignmentID, ErrorMessage FROM @Errors;

END
GO




DROP PROCEDURE IF EXISTS [dbo].[PR_SaveCriteriaPerCrop]
GO

/*
Author					Date				Remarks
Binod Gurung			2021-10-29			Add,update,Delete criteria per crop record

=================EXAMPLE=============
 EXEC PR_SaveCriteriaPerCrop N'[{"CropCode":"ED","ThresholdA":6,"ThresholdB":12,"CalcExternalAppHybrid":1, "CalcExternalAppParent":0,"Action":"I"}]';
 EXEC PR_SaveCriteriaPerCrop N'[{"CropCode":"ED","Action":"D"}]'

*/


CREATE PROCEDURE [dbo].[PR_SaveCriteriaPerCrop]
(
    @DataAsJson NVARCHAR(MAX)
)AS BEGIN
    SET NOCOUNT ON;
	DECLARE @Tbl TABLE(CropCode NVARCHAR(10), ThresholdA DECIMAL(5,2), ThresholdB DECIMAL(5,2), CalcExternalAppHybrid BIT, CalcExternalAppParent BIT, [Action] CHAR(1));

	--Read JSON into temptable
	INSERT @Tbl (CropCode, ThresholdA, ThresholdB, CalcExternalAppHybrid, CalcExternalAppParent, [Action])
	SELECT T1.CropCode,T1.ThresholdA,T1.ThresholdB,T1.CalcExternalAppHybrid,T1.CalcExternalAppParent,T1.[Action] 
	FROM OPENJSON(@DataAsJson) WITH
	(
		CropCode				NVARCHAR(10),
		ThresholdA				DECIMAL(5,2),
		ThresholdB				DECIMAL(5,2),
		CalcExternalAppHybrid	BIT,
		CalcExternalAppParent	BIT,
		[Action]				CHAR(1)
	) T1

	--Validation not to allow save for 0 Threshold value when Calcualte external is not checked
	IF EXISTS
    (
	   SELECT CropCode FROM @Tbl
	   WHERE (ISNULL(ThresholdA,0) = 0 OR ISNULL(ThresholdB,0) = 0 ) AND ISNULL(CalcExternalAppHybrid,0) = 0 AND ISNULL(CalcExternalAppParent,0) = 0 AND [Action] IN ('I','U')
    ) BEGIN
	   EXEC PR_ThrowError N'Threshold value 0 not allowed to save.';
	   RETURN;
    END

    --duplicate validation while adding new and updating existing
    IF EXISTS
    (
	   SELECT T.CropCode FROM @Tbl T
	   JOIN CalcCriteriaPerCrop CC ON CC.CropCode = T.CropCode AND [Action] = 'I'
    ) BEGIN
	   EXEC PR_ThrowError N'Record already exists for selected crop.';
	   RETURN;
    END
    
	MERGE INTO CalcCriteriaPerCrop T
	USING @Tbl S ON T.CropCode = S.CropCode
	WHEN NOT MATCHED AND S.[Action] = 'I' THEN --Insert data
		INSERT (CropCode, ThresholdA, ThresholdB, CalcExternalAppHybrid, CalcExternalAppParent)
		VALUES (S.CropCode, S.ThresholdA, ThresholdB, S.CalcExternalAppHybrid, S.CalcExternalAppParent)
	WHEN MATCHED AND S.[Action] = 'U' THEN
		UPDATE SET
			ThresholdA = CASE WHEN ISNULL(S.ThresholdA,0) <> 0 THEN S.ThresholdA ELSE T.ThresholdA END,
			ThresholdB = CASE WHEN ISNULL(S.ThresholdB,0) <> 0 THEN S.ThresholdB ELSE T.ThresholdB END,
			CalcExternalAppHybrid = CASE WHEN ISNULL(S.CalcExternalAppHybrid,0) <> 0 THEN S.CalcExternalAppHybrid ELSE T.CalcExternalAppHybrid END,
			CalcExternalAppParent = CASE WHEN ISNULL(S.CalcExternalAppParent,0) <> 0 THEN S.CalcExternalAppParent ELSE T.CalcExternalAppParent END
	WHEN MATCHED AND S.[Action] = 'D' THEN
		DELETE;
END
GO


DROP PROCEDURE IF EXISTS [dbo].[PR_GETAllCriteriaPerCrop]
GO


/*
Author					Date				Remarks
Binod Gurung			2021-10-29			Get all data for criteria per crop

=================EXAMPLE=============
EXEC PR_GETAllCriteriaPerCrop 1,20 ,@CalcExternalAppHybrid='True'

*/
CREATE PROCEDURE [dbo].[PR_GETAllCriteriaPerCrop]
(
	@PageNr					INT,
	@PageSize				INT,
	@SortBy					NVARCHAR(100) = NULL,
	@SortOrder				NVARCHAR(20) = NULL,
	@CropCode				NVARCHAR(10) = NULL,
	@ThresholdA				NVARCHAR(100) = NULL,
	@ThresholdB				NVARCHAR(100) = NULL,
	@CalcExternalAppHybrid	NVARCHAR(100) = NULL,
	@CalcExternalAppParent	NVARCHAR(100) = NULL
)
AS BEGIN
    SET NOCOUNT ON;

	DECLARE @TblColumn TABLE(ColumnLabel VARCHAR(100), ColumnID VARCHAR(100),[Order] INT,IsVisible BIT);
	DECLARE @Offset INT, @Query NVARCHAR(MAX), @SortQuery NVARCHAR(MAX), @Parameters NVARCHAR(MAX);

	SET @OffSet = @PageSize * (@pageNr -1);

	--Convert value fot BIT 
	IF (@CalcExternalAppHybrid = 'True' OR @CalcExternalAppHybrid = 'yes')
		SET @CalcExternalAppHybrid = '1';
	ELSE IF (@CalcExternalAppHybrid = 'False' OR @CalcExternalAppHybrid = 'no')
		SET @CalcExternalAppHybrid = '0';

	IF (@CalcExternalAppParent = 'True' OR @CalcExternalAppParent = 'yes')
		SET @CalcExternalAppParent = '1';
	ELSE IF (@CalcExternalAppParent = 'False' OR @CalcExternalAppParent = 'no')
		SET @CalcExternalAppParent = '0';

	INSERT INTO @TblColumn(ColumnLabel,ColumnID,[Order],IsVisible)
	VALUES
	('Crop','CropCode',1,1),
	('ThresholdA','ThresholdA',2,1),
	('ThresholdB','ThresholdB',3,1),
	('Calculate External Hybrid','CalcExternalAppHybrid',4,1),
	('Calculate External Parent','CalcExternalAppParent',5,1);

	IF (ISNULL(@SortBy,'') = '')
		SET @SortQuery = 'ORDER BY CropCode';
	ELSE
		SET @SortQuery = 'ORDER BY ' + QUOTENAME(@SortBy) + ' ' + ISNULL(@SortOrder,'');  

	SET @Query = N'
    ;WITH CTE AS
	(
		SELECT 
			CropCode,
			ThresholdA,
			ThresholdB,
			CalcExternalAppHybrid = CASE WHEN ISNULL(CalcExternalAppHybrid,''false'') = ''false'' THEN ''False'' ELSE ''True'' END,
			CalcExternalAppParent = CASE WHEN ISNULL(CalcExternalAppParent,''false'') = ''false'' THEN ''False'' ELSE ''True'' END
		FROM CalcCriteriaPerCrop
		WHERE		
				(ISNULL(@CropCode,'''') = '''' OR CropCode like ''%''+ @CropCode +''%'') AND	
				(ISNULL(@ThresholdA,'''') = '''' OR ThresholdA like ''%''+ @ThresholdA +''%'') AND
				(ISNULL(@ThresholdB,'''') = '''' OR ThresholdB like ''%''+ @ThresholdA +''%'') AND
				(ISNULL(@CalcExternalAppHybrid,'''') = '''' OR CalcExternalAppHybrid like ''%''+ @CalcExternalAppHybrid +''%'') AND
				(ISNULL(@CalcExternalAppParent,'''') = '''' OR CalcExternalAppParent like ''%''+ @CalcExternalAppParent	+''%'')
	
	), Count_CTE AS (SELECT COUNT(CropCode) AS [TotalRows] FROM CTE)
	SELECT 
		CropCode,
		ThresholdA,
		ThresholdB,
		CalcExternalAppHybrid,
		CalcExternalAppParent,
		TotalRows
	FROM CTE,Count_CTE 
	' + @SortQuery + ' 
	OFFSET @Offset ROWS
    FETCH NEXT @PageSize ROWS ONLY';

	SET @Parameters = N'@CropCode NVARCHAR(10), @ThresholdA NVARCHAR(100), @ThresholdB NVARCHAR(100), @CalcExternalAppHybrid NVARCHAR(100), @CalcExternalAppParent NVARCHAR(100), @OffSet INT, @PageSize INT';

	EXEC sp_executesql @Query, @Parameters, @CropCode, @ThresholdA, @ThresholdB, @CalcExternalAppHybrid, @CalcExternalAppParent, @OffSet, @PageSize;

	SELECT * FROM @TblColumn order by [Order];

END
GO


