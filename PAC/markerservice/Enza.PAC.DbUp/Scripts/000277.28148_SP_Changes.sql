DROP PROCEDURE IF EXISTS [dbo].[PR_SaveCriteriaPerCrop]
GO



/*
Author					Date				Remarks
Binod Gurung			2021-10-29			Add,update,Delete criteria per crop record

=================EXAMPLE=============
 EXEC PR_SaveCriteriaPerCrop N'[{"CropCode":"ED","ThresholdA":6,"ThresholdB":12,"CalcExternalAppHybrid":1, "CalcExternalAppParent":0,"Action":"i"}]';
 EXEC PR_SaveCriteriaPerCrop N'[{"CropCode":"ED","Action":"d"}]'
 EXEC PR_SaveCriteriaPerCrop @DataAsJson=N'{"CropCode":"AF","ThresholdA":0.0,"ThresholdB":0.0,"CalcExternalAppHybrid":false,"CalcExternalAppParent":false,"Action":"d"}'

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
	   WHERE (ISNULL(ThresholdA,0) = 0 OR ISNULL(ThresholdB,0) = 0 ) AND ISNULL(CalcExternalAppHybrid,0) = 0 AND ISNULL(CalcExternalAppParent,0) = 0 AND [Action] IN ('i','u')
    ) BEGIN
	   EXEC PR_ThrowError N'Threshold value 0 not allowed to save.';
	   RETURN;
    END

    --duplicate validation while adding new and updating existing
    IF EXISTS
    (
	   SELECT T.CropCode FROM @Tbl T
	   JOIN CalcCriteriaPerCrop CC ON CC.CropCode = T.CropCode AND [Action] = 'i'
    ) BEGIN
	   EXEC PR_ThrowError N'Record already exists for selected crop.';
	   RETURN;
    END
    
	MERGE INTO CalcCriteriaPerCrop T
	USING @Tbl S ON T.CropCode = S.CropCode
	WHEN NOT MATCHED AND S.[Action] = 'i' THEN --Insert data
		INSERT (CropCode, ThresholdA, ThresholdB, CalcExternalAppHybrid, CalcExternalAppParent)
		VALUES (S.CropCode, S.ThresholdA, ThresholdB, S.CalcExternalAppHybrid, S.CalcExternalAppParent)
	WHEN MATCHED AND S.[Action] = 'u' THEN
		UPDATE SET
			ThresholdA = CASE WHEN ISNULL(S.ThresholdA,0) <> 0 THEN S.ThresholdA ELSE T.ThresholdA END,
			ThresholdB = CASE WHEN ISNULL(S.ThresholdB,0) <> 0 THEN S.ThresholdB ELSE T.ThresholdB END,
			CalcExternalAppHybrid = CASE WHEN ISNULL(S.CalcExternalAppHybrid,0) <> 0 THEN S.CalcExternalAppHybrid ELSE T.CalcExternalAppHybrid END,
			CalcExternalAppParent = CASE WHEN ISNULL(S.CalcExternalAppParent,0) <> 0 THEN S.CalcExternalAppParent ELSE T.CalcExternalAppParent END
	WHEN MATCHED AND S.[Action] = 'd' THEN
		DELETE;
END
GO


DROP PROCEDURE IF EXISTS [dbo].[PR_GetAllCriteriaPerCrop]
GO

/*
Author					Date				Remarks
Binod Gurung			2021-10-29			Get all data for criteria per crop

=================EXAMPLE=============
EXEC PR_GetAllCriteriaPerCrop 1,20 ,@CalcExternalAppHybrid='True'

*/
CREATE PROCEDURE [dbo].[PR_GetAllCriteriaPerCrop]
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
			ThresholdA = CAST ( ThresholdA AS NVARCHAR(10)),
			ThresholdB = CAST ( ThresholdB AS NVARCHAR(10)),
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

	SELECT CropCode FROM CropRD ORDER BY CropCode;

END
GO


