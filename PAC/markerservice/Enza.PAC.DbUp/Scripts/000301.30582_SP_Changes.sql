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
	@MaterialTypeCode		NVARCHAR(20) = NULL,
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
	('Material Type','MaterialTypeCode',2,1),
	('ThresholdA','ThresholdA',3,1),
	('ThresholdB','ThresholdB',4,1),
	('Calculate External Hybrid','CalcExternalAppHybrid',5,1),
	('Calculate External Parent','CalcExternalAppParent',6,1);

	IF (ISNULL(@SortBy,'') = '')
		SET @SortQuery = 'ORDER BY CropCode';
	ELSE
		SET @SortQuery = 'ORDER BY ' + QUOTENAME(@SortBy) + ' ' + ISNULL(@SortOrder,'');  

	SET @Query = N'
    ;WITH CTE AS
	(
		SELECT 
			CropCode,
			CC.MaterialTypeID,
			M.MaterialTypeCode,
			ThresholdA = CAST ( ISNULL(ThresholdA,0) AS NVARCHAR(10)),
			ThresholdB = CAST ( ISNULL(ThresholdB,0) AS NVARCHAR(10)),
			CalcExternalAppHybrid = CASE WHEN ISNULL(CalcExternalAppHybrid,''false'') = ''false'' THEN ''False'' ELSE ''True'' END,
			CalcExternalAppParent = CASE WHEN ISNULL(CalcExternalAppParent,''false'') = ''false'' THEN ''False'' ELSE ''True'' END
		FROM CalcCriteriaPerCrop CC
		LEFT JOIN MaterialType M On M.MaterialTypeID = CC.MaterialTypeID
		WHERE		
				(ISNULL(@CropCode,'''') = '''' OR CropCode like ''%''+ @CropCode +''%'') AND	
				(ISNULL(@MaterialTypeCode,'''') = '''' OR M.MaterialTypeCode like ''%''+ @MaterialTypeCode +''%'') AND	
				(ISNULL(@ThresholdA,'''') = '''' OR ISNULL(ThresholdA,0) like ''%''+ @ThresholdA +''%'') AND
				(ISNULL(@ThresholdB,'''') = '''' OR ISNULL(ThresholdB,0) like ''%''+ @ThresholdB +''%'') AND
				(ISNULL(@CalcExternalAppHybrid,'''') = '''' OR ISNULL(CalcExternalAppHybrid,0) like ''%''+ @CalcExternalAppHybrid +''%'') AND
				(ISNULL(@CalcExternalAppParent,'''') = '''' OR ISNULL(CalcExternalAppParent,0) like ''%''+ @CalcExternalAppParent	+''%'')
	
	), Count_CTE AS (SELECT COUNT(CropCode) AS [TotalRows] FROM CTE)
	SELECT 
		CropCode,
		MaterialTypeID,
		MaterialTypeCode,
		ThresholdA,
		ThresholdB,
		CalcExternalAppHybrid,
		CalcExternalAppParent,
		TotalRows
	FROM CTE,Count_CTE 
	' + @SortQuery + ' 
	OFFSET @Offset ROWS
    FETCH NEXT @PageSize ROWS ONLY';

	SET @Parameters = N'@CropCode NVARCHAR(10), @MaterialTypeCode NVARCHAR(20), @ThresholdA NVARCHAR(100), @ThresholdB NVARCHAR(100), @CalcExternalAppHybrid NVARCHAR(100), @CalcExternalAppParent NVARCHAR(100), @OffSet INT, @PageSize INT';

	EXEC sp_executesql @Query, @Parameters, @CropCode, @MaterialTypeCode, @ThresholdA, @ThresholdB, @CalcExternalAppHybrid, @CalcExternalAppParent, @OffSet, @PageSize;

	SELECT * FROM @TblColumn order by [Order];

	SELECT CropCode FROM CropRD ORDER BY CropCode;

	SELECT MaterialTypeID, MaterialTypeCode FROM MaterialType

END
GO


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
	DECLARE @Tbl TABLE(CropCode NVARCHAR(10), MaterialTypeID INT, ThresholdA DECIMAL(5,2), ThresholdB DECIMAL(5,2), CalcExternalAppHybrid BIT, CalcExternalAppParent BIT, [Action] CHAR(1));

	--Read JSON into temptable
	INSERT @Tbl (CropCode, MaterialTypeID, ThresholdA, ThresholdB, CalcExternalAppHybrid, CalcExternalAppParent, [Action])
	SELECT T1.CropCode, T1.MaterialTypeID, T1.ThresholdA,T1.ThresholdB,T1.CalcExternalAppHybrid,T1.CalcExternalAppParent,T1.[Action] 
	FROM OPENJSON(@DataAsJson) WITH
	(
		CropCode				NVARCHAR(10),
		MaterialTypeID			INT,
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
		INSERT (CropCode, MaterialTypeID, ThresholdA, ThresholdB, CalcExternalAppHybrid, CalcExternalAppParent)
		VALUES (S.CropCode, S.MaterialTypeID, S.ThresholdA, ThresholdB, S.CalcExternalAppHybrid, S.CalcExternalAppParent)
	WHEN MATCHED AND S.[Action] = 'u' THEN -- update data
		UPDATE SET
			MaterialTypeID = CASE WHEN S.MaterialTypeID = '' THEN NULL ELSE S.MaterialTypeID END,
			ThresholdA = S.ThresholdA,
			ThresholdB = S.ThresholdB,
			CalcExternalAppHybrid = S.CalcExternalAppHybrid,
			CalcExternalAppParent = S.CalcExternalAppParent
	WHEN MATCHED AND S.[Action] = 'd' THEN --delete data
		DELETE;
END
GO


DROP PROCEDURE IF EXISTS [dbo].[PR_GetTestInfoForLIMS]
GO


/*
Author					Date			Description
Binod Gurung			2019/10/22		Pull Test Information for input period for LIMS
Binod Gurung			2020-jan-23		Transcation isolation level implemented to avoid record lock
Binod Gurung			2021-dec-17		Expected Week and Planned Week is used from Period table not from DATEPART(WEEK) function because it doesn't match
Binod Gurung			2022-jan-03		Material type value now used from criteripercrop table, before it was hardcoded [#30582]
===================================Example================================

EXEC PR_GetTestInfoForLIMS 4805
*/
CREATE PROCEDURE [dbo].[PR_GetTestInfoForLIMS]
(
	@PeriodID INT
)
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

	DECLARE @TestPlates TABLE (TestID INT, NrOfPlates INT, NrOfMarkes INT, IsLabPrioity BIT);
	
	INSERT @TestPlates (TestID, NrOfPlates, NrOfMarkes, IsLabPrioity)
	EXEC PR_GetNrOFPlatesAndTests @PeriodID, 150;

	SELECT 
	   T1.ContainerType,
	   T1.CountryCode,
	   T1.CropCode,
	   ExpectedDate = FORMAT(T1.ExpectedDate, 'yyyy-MM-dd', 'en-US'),
	   ExpectedWeek = CAST (SUBSTRING(P1.PeriodName, CHARINDEX(' ', P1.PeriodName) + 1, 2) AS INT), --DATEPART(WEEK, T1.ExpectedDate),
	   ExpectedYear = YEAR(T1.ExpectedDate),
	   T1.Isolated,
	   T1.MaterialState,
	   T1.MaterialType,
	   PlannedDate = FORMAT(T1.PlannedDate, 'yyyy-MM-dd', 'en-US'),
	   PlannedWeek = CAST (SUBSTRING(P2.PeriodName, CHARINDEX(' ', P2.PeriodName) + 1, 2) AS INT), --DATEPART(WEEK, T1.PlannedDate),	
	   PlannedYear = YEAR(T1.PlannedDate),
	   T1.Remark,
	   T1.RequestID,
	   T1.RequestingSystem,
	   T1.SynchronisationCode,
	   T1.TotalNrOfPlates,
	   T1.TotalNrOfTests
	FROM
	(
	    SELECT 
		    'DPW' AS ContainerType,
		    'NL' AS CountryCode,
		    MAX(V0.CropCode) AS CropCode,
		    ExpectedDate = COALESCE ( MAX(V1.ExpectedReadyDateLab), MAX(V0.ExpectedReadyDate)),
		    'N' AS Isolated,	
		    'FRS' AS MaterialState,
		    MaterialType = MAX(V0.MaterialType),
		    PlannedDate =  MAX(V0.PlannedDate),
		    'PAC' AS Remark, 
		    T.TestID AS RequestID, 
		    'PAC' AS RequestingSystem,
		    'NL' AS SynchronisationCode,
			MAX(TP.NrOfPlates) AS TotalNrOfPlates,
			MAX(TP.NrOfMarkes) AS TotalNrOfTests		    
	    FROM
	    (	
		    SELECT 
			    TestID, 
			    DA.DetAssignmentID, 
			    AC.CropCode,
				MaterialType = CASE WHEN MT.MaterialTypeCode IS NULL THEN 'SDS' ELSE MT.MaterialTypeCode END, --default value SDS
			    DA.PlannedDate,
			    DA.ExpectedReadyDate,
				DA.StatusCode
		    FROM TestDetAssignment TDA
		    JOIN DeterminationAssignment DA ON DA.DetAssignmentID = TDA.DetAssignmentID
		    JOIN Method M ON M.MethodCode = DA.MethodCode
		    JOIN CropMethod CM ON CM.MethodID = M.MethodID AND CM.ABSCropCode = DA.ABSCropCode
			--handle if same method is used for hybrid and parent
			JOIN
			(
				SELECT 
					VarietyNr, 
					UsedFor = CASE WHEN HybOp = 1 AND [Type] <> 'P' THEN 'Hyb' ELSE 'Par' END
				FROM Variety
			) V ON V.VarietyNr = DA.VarietyNr AND V.UsedFor = CM.UsedFor
		    JOIN ABSCrop AC On AC.ABSCropCode = DA.ABSCropCode
			LEFT JOIN CalcCriteriaPerCrop CC ON CC.CropCode = AC.CropCode
			LEFT JOIN MaterialType MT ON MT.MaterialTypeID = CC.MaterialTypeID
	    ) V0 
		LEFT JOIN
		(
			SELECT 
				T.TestID,
				ExpectedReadyDateLab = MAX(DA.ExpectedReadyDate) 
			FROM DeterminationAssignment DA
			JOIN TestDetAssignment TDA ON TDA.DetAssignmentID = DA.DetAssignmentID
			JOIN Test T On T.TestID = TDA.TestID
			WHERE T.PeriodID = @PeriodID AND DA.IsLabPriority = 1
			GROUP BY T.TestID
		) V1 ON V1.TestID = V0.TestID
	    JOIN Test T ON T.TestID = V0.TestID		
	    JOIN @TestPlates TP ON TP.TestID = T.TestID
	    WHERE T.PeriodID = @PeriodID AND (T.StatusCode < 200 AND V0.StatusCode = 300) --sometimes test status remain on 100 even though all DA got status 300
	    GROUP BY T.TestID
	) T1
	JOIN [Period] P1 ON T1.ExpectedDate BETWEEN P1.StartDate AND P1.EndDate --Expected Week
	JOIN [Period] P2 ON T1.PlannedDate BETWEEN P2.StartDate AND P2.EndDate -- Planned Week

END

GO


