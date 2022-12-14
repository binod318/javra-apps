-- =============================================
-- Author:		Binod Gurung
-- Create date: 2019/10/22
-- Description:	Pull Test Information for input period for LIMS
-- =============================================
/*
EXEC PR_GetTestInfoForLIMS 4791, 5, 2
*/
ALTER PROCEDURE [dbo].[PR_GetTestInfoForLIMS]
(
	@PeriodID INT,
	@WeekDiff INT,
	@WeekDiffLab INT
)
AS
BEGIN
	
	DECLARE @PlannedDateStart DATETIME, @PlannedDateEnd DATETIME, @ExpectedDateStart DATETIME, @ExpectedDateEnd DATETIME, @PlannedDate DATETIME, @ExpectedDate DATETIME;
	DECLARE @ExpectedDateStartLab DATETIME, @ExpectedDateEndLab DATETIME, @ExpectedDateLab DATETIME;

	SET NOCOUNT ON;

	SELECT 
		@PlannedDateStart = StartDate, 
		@PlannedDateEnd = EndDate 
	FROM [Period] WHERE PeriodID = @PeriodID;

	SELECT @ExpectedDateStart = DATEADD(WEEK, @WeekDiff, @PlannedDateStart);
	SELECT @ExpectedDateEnd = DATEADD(WEEK, @WeekDiff, @PlannedDateEnd);

	SELECT @ExpectedDateStartLab = DATEADD(WEEK, @WeekDiffLab, @PlannedDateStart);
	SELECT @ExpectedDateEndLab = DATEADD(WEEK, @WeekDiffLab, @PlannedDateEnd);

	-- Planned date is the monday of planned week
	WITH CTE
	AS
	(
		SELECT TOP 1 0 AS N, StartDate FROM [Period] P
			WHERE P.StartDate BETWEEN @PlannedDateStart AND @PlannedDateEnd ORDER BY P.StartDate
		UNION ALL
		SELECT n + 1, DATEADD(Day,1, Startdate) AS D1 
		FROM CTE
		  WHERE n < 6
	)
	SELECT @PlannedDate = CTE.StartDate FROM CTE
	WHERE DATENAME(WEEKDAY,CTE.StartDate) = 'Monday';

	-- Expected date is the friday of expected week
	WITH CTE
	AS
	(
		SELECT TOP 1 0 AS N, StartDate FROM [Period] P
			WHERE P.StartDate BETWEEN @ExpectedDateStart AND @ExpectedDateEnd ORDER BY P.StartDate
		UNION ALL
		SELECT n+1, DATEADD(Day,1, Startdate) AS D1 FROM CTE
			WHERE n<6
	)
	SELECT @ExpectedDate = CTE.StartDate FROM CTE
	WHERE DATENAME(WEEKDAY,CTE.StartDate) = 'Friday';

	WITH CTE
	AS
	(
		SELECT TOP 1 0 AS N, StartDate FROM [Period] P
			WHERE P.StartDate BETWEEN @ExpectedDateStartLab AND @ExpectedDateEndLab ORDER BY P.StartDate
		UNION ALL
		SELECT n+1, DATEADD(Day,1, Startdate) AS D1 FROM CTE
			WHERE n<6
	)
	SELECT @ExpectedDateLab = CTE.StartDate FROM CTE
	WHERE DATENAME(WEEKDAY,CTE.StartDate) = 'Friday';

	SELECT 
	   T1.ContainerType,
	   T1.CountryCode,
	   T1.CropCode,
	   ExpectedDate = FORMAT(T1.ExpectedDate, 'yyyy-MM-dd', 'en-US'),
	   ExpectedWeek = DATEPART(WEEK, T1.ExpectedDate),
	   ExpectedYear = YEAR(T1.ExpectedDate),
	   T1.Isolated,
	   T1.MaterialState,
	   T1.MaterialType,
	   PlannedDate = FORMAT(T1.PlannedDate, 'yyyy-MM-dd', 'en-US'),
	   T1.PlannedWeek,
	   T1.PlannedYear,
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
		    ExpectedDate = CASE WHEN ISNULL(MAX(L1.TestID),0) = 0 THEN @ExpectedDate ELSE @ExpectedDateLab END,
		    'N' AS Isolated,	
		    'FRS' AS MaterialState,
		    'SDS' AS MaterialType,
		    PlannedDate =  @PlannedDate,
		    PlannedWeek = DATEPART(WEEK, @PlannedDate),	
		    PlannedYear = YEAR(@PlannedDate),
		    'PAC' AS Remark, 
		    T.TestID	AS RequestID, 
		    'PAC' AS RequestingSystem,
		    'NL' AS SynchronisationCode,
			CAST(CEILING(SUM(ISNULL(V0.PlatesPerRow,0))) AS INT) AS TotalNrOfPlates,
			CAST(CEILING(SUM(ISNULL(TestsPerRow,0))) AS INT) AS TotalNrOfTests
		    
	    FROM
	    (	
		    SELECT 
			    TestID, DA.DetAssignmentID, 
			    (M.NrOfSeeds / 92.0) AS PlatesPerRow,
			    V1.MarkersPerDA,
			    ( (M.NrOfSeeds / 92.0) * V1.MarkersPerDA) + ISNULL(TM.TraitMarkerCount,0) AS TestsPerRow,
			    AC.CropCode
		    FROM TestDetAssignment TDA
		    JOIN DeterminationAssignment DA ON DA.DetAssignmentID = TDA.DetAssignmentID
		    JOIN Method M ON M.MethodCode = DA.MethodCode
		    JOIN CropMethod CM ON CM.MethodID = M.MethodID AND CM.ABSCropCode = DA.ABSCropCode
		    JOIN ABSCrop AC On AC.ABSCropCode = DA.ABSCropCode
		    LEFT JOIN 
		    (
			    SELECT DetAssignmentID, COUNT(DetAssignmentID) AS MarkersPerDA FROM MarkerToBeTested MTBT 
			    GROUP BY DetAssignmentID
		    ) V1 ON V1.DetAssignmentID = DA.DetAssignmentID
			--Add traitmarker count to total number of test
			LEFT JOIN
			(
				SELECT VarietyNr, COUNT(DISTINCT MarkerID) AS TraitMarkerCount FROM MarkerPerVariety MPV
				WHERE MPV.StatusCode = 100
				GROUP BY VarietyNr
			) TM ON TM.VarietyNr = DA.VarietyNr
	    ) V0 
	    JOIN Test T ON T.TestID = V0.TestID
		--Find IsLabPriority on Determination assignment level
		LEFT JOIN 
		(
			SELECT T.TestID FROM Test T
			JOIN Plate P On P.TestID = T.TestID
			JOIN Well W ON W.PlateID = W.PlateID
			JOIN DeterminationAssignment DA ON DA.DetAssignmentID = W.DetAssignmentID
			WHERE ISNULL(DA.IsLabPriority,0) = 1 
		) L1 ON L1.TestID = T.TestID
	    WHERE T.PeriodID = @PeriodID AND T.StatusCode = 150
	    GROUP BY T.TestID, T.IsLabPriority
	) T1;
END

GO


/*
Author					Date			Remarks
Binod Gurung			-				-
Krishna Gautam			2020-01-21		Where clause added.

=================EXAMPLE=============
-- PR_GetDeterminationAssigmentOverview 4792
*/
ALTER PROCEDURE [dbo].[PR_GetDeterminationAssigmentOverview]
(
    @PeriodID INT
) AS BEGIN
    SET NOCOUNT ON;
    DECLARE @PlatformID INT = (SELECT PlatformID FROM [Platform] WHERE PlatformCode = 'LS'); --light scanner  

	SELECT 
	   DA.DetAssignmentID,
	   DA.SampleNr,   
	   DA.BatchNr,
	   Article = V.Shortname,
	   'Status' = COALESCE(S.StatusName, CAST(DA.StatusCode AS NVARCHAR(10))),
	   'Exp Ready' = DA.ExpectedReadyDate, 
	   V2.Folder,
	   'Quality Class' = DA.QualityClass
    FROM DeterminationAssignment DA
    JOIN
    (
	   SELECT
		  AC.ABSCropCode,
		  PM.MethodCode
	   FROM CropMethod CM
	   JOIN ABSCrop AC ON AC.ABSCropCode = CM.ABSCropCode
	   JOIN Method PM ON PM.MethodID = CM.MethodID
	   WHERE CM.PlatformID = @PlatformID
    ) V1 ON V1.ABSCropCode = DA.ABSCropCode AND V1.MethodCode = DA.MethodCode
    JOIN Variety V ON V.VarietyNr = DA.VarietyNr
	JOIN
	(
		SELECT W.DetAssignmentID, MAX(T.TestName) AS Folder FROM Test T
		JOIN Plate P ON P.TestID = T.TestID
		JOIN Well W ON W.PlateID = P.PlateID
		--WHERE T.StatusCode >= 500
		GROUP BY W.DetAssignmentID
	) V2 On V2.DetAssignmentID = DA.DetAssignmentID
	join TestDetAssignment TDA ON TDA.DetAssignmentID = DA.DetAssignmentID
	JOIN Test T ON T.TestID = TDA.TestID
	JOIN [Status] S ON S.StatusCode = DA.StatusCode AND S.StatusTable = 'DeterminationAssignment'
	WHERE T.PeriodID = @PeriodID AND DA.StatusCode IN (600,999)

END

GO

/*
Author					Date			Remarks
Krishna Gautam			2020/01/16		Created Stored procedure to fetch data
Krishna Gautam			2020/01/21		Status description is sent instead of status code.

=================EXAMPLE=============

EXEC PR_GetBatch 
		@PageNr = 1,
		@PageSize = 10,
		@CropCode = NULL,
		@PlatformDesc = NULL,
		@MethodCode = NULL,
		@Plates = NULL,
		@TestName = NULL,
		@StatusCode = NULL,
		@ExpectedWeek = NULL,
		@SampleNr = NULL,
		@BatchNr = NULL,
		@DetAssignmentID = NULL,
		@VarietyNr = NULL
*/

ALTER PROCEDURE [dbo].[PR_GetBatch]
(
	@pageNr INT,
	@PageSize INT,
	@CropCode NVARCHAR(10) =NULL,
	@PlatformDesc NVARCHAR(100) = NULL,
	@MethodCode NVARCHAR(50) = NULL, 
	@Plates NVARCHAR(100) = NULL, 
	@TestName NVARCHAR(100) = NULL,
	@StatusCode NVARCHAR(100) = NULL, 
	@ExpectedWeek NVARCHAR(100) = NULL,
	@SampleNr NVARCHAR(100) = NULL, 
	@BatchNr NVARCHAR(100) = NULL, 
	@DetAssignmentID  NVARCHAR(100) = NULL,
	@VarietyNr NVARCHAR(100) = NULL
)
AS
BEGIN
	
	DECLARE @Offset INT;
	DECLARE @Columns TABLE(ColumnID NVARCHAR(100), ColumnName NVARCHAR(100));
	DECLARE @Status TABLE(StatusCode INT, StatusName NVARCHAR(100));

	INSERT INTO @Status(StatusCode, StatusName)
	SELECT StatusCode,StatusName FROM [Status] WHERE StatusTable = 'DeterminationAssignment';

	set @Offset = @PageSize * (@pageNr -1);
	;WITH CTE AS 
	(
		SELECT * FROM 
		(
			SELECT T.TestID, 
				C.CropCode,
				P.PlatformDesc,
				M.MethodCode, 
				Plates = CAST(CAST((M.NrOfSeeds/92.0) as decimal(4,2)) AS NVARCHAR(10)), 
				T.TestName ,
				StatusCode = S.StatusName,
				[ExpectedWeek] = CAST(DATEPART(Week, DA.ExpectedReadyDate) AS NVARCHAR(10)),
				SampleNr = CAST(DA.SampleNr AS NVARCHAR(50)), 
				BatchNr = CAST(DA.BatchNr AS NVARCHAR(50)), 
				DetAssignmentID = CAST(DA.DetAssignmentID AS NVARCHAR(50)) ,
				VarietyNr = CAST(V.VarietyNr  AS NVARCHAR(50))
			FROM  Test T 
			JOIN TestDetAssignment TDA ON TDA.TestID = T.TestID
			JOIN DeterminationAssignment DA ON DA.DetAssignmentID = TDA.DetAssignmentID
			JOIN @Status S ON S.StatusCode = DA.StatusCode
			JOIN Variety V ON V.VarietyNr = DA.VarietyNr
			JOIN Method M ON M.MethodCode = DA.MethodCode
			JOIN CropMethod CM ON CM.MethodID = M.MethodID AND CM.ABSCropCode = DA.ABSCropCode
			JOIN ABSCrop C ON C.ABSCropCode = CM.ABSCropCode
			JOIN [Platform] P ON P.PlatformID = CM.PlatformID
		) T
		WHERE 
		(ISNULL(@CropCode,'') = '' OR CropCode like '%'+ @CropCode +'%') AND
		(ISNULL(@PlatformDesc,'') = '' OR PlatformDesc like '%'+ @PlatformDesc +'%') AND
		(ISNULL(@MethodCode,'') = '' OR MethodCode like '%'+ @MethodCode +'%') AND
		(ISNULL(@Plates,'') = '' OR Plates like '%'+ @Plates +'%') AND
		(ISNULL(@TestName,'') = '' OR TestName like '%'+ @TestName +'%') AND
		(ISNULL(@StatusCode,'') = '' OR StatusCode like '%'+ @StatusCode +'%') AND
		(ISNULL(@ExpectedWeek,'') = '' OR ExpectedWeek like '%'+ @ExpectedWeek +'%') AND
		(ISNULL(@SampleNr,'') = '' OR SampleNr like '%'+ @SampleNr +'%') AND
		(ISNULL(@BatchNr,'') = '' OR BatchNr like '%'+ @BatchNr +'%') AND
		(ISNULL(@DetAssignmentID,'') = '' OR DetAssignmentID like '%'+ @DetAssignmentID +'%') AND
		(ISNULL(@VarietyNr,'') = '' OR VarietyNr like '%'+ @VarietyNr +'%')
	), Count_CTE AS (SELECT COUNT(TestID) AS [TotalRows] FROM CTE)
	SELECT 
	
		CropCode,
		PlatformDesc,
		MethodCode, 
		Plates , 
		TestName ,
		StatusCode, 
		ExpectedWeek,
		SampleNr, 
		BatchNr, 
		DetAssignmentID ,
		VarietyNr,
		TotalRows
	FROM CTE,Count_CTE 
	ORDER BY TestID DESC, DetAssignmentID ASC
	OFFSET @Offset ROWS
	FETCH NEXT @PageSize ROWS ONLY


	INSERT INTO @Columns(ColumnID,ColumnName)
	VALUES
	('CropCode','Crop'),
	('PlatformDesc','Platform'),
	('MethodCode','Method'),
	('Plates','#Plates'),
	('TestName','Folder no'),
	('StatusCode','Status'),
	('ExpectedWeek','Expected Week'),
	('SampleNr','SampleNr'),
	('BatchNr','BatchNr'),
	('DetAssignmentID','Det. Assignment'),
	('VarietyNr','Var. Name')

	SELECT * FROM @Columns;
END
GO
