DROP PROCEDURE IF EXISTS [dbo].[PR_GetTestInfoForLIMS]
GO

-- =============================================
-- Author:		Binod Gurung
-- Create date: 2019/10/22
-- Description:	Pull Test Information for input period for LIMS
-- =============================================
/*
EXEC PR_GetTestInfoForLIMS 4791, 5, 2
*/
CREATE PROCEDURE [dbo].[PR_GetTestInfoForLIMS]
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
		SELECT n+1, DATEADD(Day,1, Startdate) AS D1 FROM CTE
			WHERE n<6
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
		'DPW'																													AS ContainerType,
		'NL'																													AS CountryCode,
		MAX(V0.CropCode)																										AS CropCode,
		CONVERT(VARCHAR(50), (CASE WHEN ISNULL(T.IsLabPriority,0) = 0 THEN @ExpectedDate ELSE @ExpectedDateLab END), 127)		AS ExpectedDate,
		ExpectedWeek = DATEPART(WEEK, (CASE WHEN ISNULL(T.IsLabPriority,0) = 0 THEN @ExpectedDate ELSE @ExpectedDateLab END)),	
		ExpectedYear = YEAR((CASE WHEN ISNULL(T.IsLabPriority,0) = 0 THEN @ExpectedDate ELSE @ExpectedDateLab END)),
		'N'																														AS Isolated,	
		'FRS'																													AS MaterialState,
		'SDS'																													AS MaterialType,
		CONVERT(varchar(50), @PlannedDate, 127)																					AS PlannedDate, 
		PlannedWeek = DATEPART(WEEK, @PlannedDate),	
		PlannedYear = YEAR(@PlannedDate),
		'TestRemarks'																											AS Remark, 
		T.TestID																												AS RequestID, 
		'PAC'																													AS RequestingSystem,
		'NL'																													AS SynchronisationCode,
		CAST(ROUND(SUM(ISNULL(V0.PlatesPerRow,0)),0) AS INT)																	AS TotalNrOfPlates , 
		CAST(ROUND(SUM(ISNULL(TestsPerRow,0)),0) AS INT)																		AS TotalNrOfTests  
	FROM
	(	
		SELECT 
			TestID, DA.DetAssignmentID, 
			(M.NrOfSeeds / 92.0) AS PlatesPerRow,
			V1.MarkersPerDA,
			( (M.NrOfSeeds / 92.0) * V1.MarkersPerDA) AS TestsPerRow,
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
	) V0 
	JOIN Test T ON T.TestID = V0.TestID
	WHERE T.PeriodID = @PeriodID AND T.StatusCode = 150
	GROUP BY T.TestID, T.IsLabPriority

END

GO


