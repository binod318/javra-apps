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
		    'TestRemarks' AS Remark, 
		    T.TestID	AS RequestID, 
		    'PAC' AS RequestingSystem,
		    'NL' AS SynchronisationCode,
		    CAST(ROUND(SUM(ISNULL(V0.PlatesPerRow,0)),0) AS INT) AS TotalNrOfPlates , 
		    CAST(ROUND(SUM(ISNULL(TestsPerRow,0)),0) AS INT) AS TotalNrOfTests  
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


DROP PROCEDURE IF EXISTS [dbo].[PR_GetInfoForFillPlatesInLIMS]
GO

-- =============================================
-- Author:		Binod Gurung
-- Create date: 2019/12/03
-- Description:	Get information for FillPlatesInLIMS
-- =============================================
/*
EXEC PR_GetInfoForFillPlatesInLIMS 4792
*/
CREATE PROCEDURE [dbo].[PR_GetInfoForFillPlatesInLIMS]
(
	@PeriodID INT
)
AS
BEGIN
	
	SET NOCOUNT ON;

	SELECT 
		ISNULL(T.LabPlatePlanID,0),
		ISNULL(T.TestID,0),
		AC.CropCode,
		ISNULL(P.LabPlateID,0),
		ISNULL(P.PlateName,''),
		ISNULL(M.MarkerID,0), 
		M.MarkerFullName,
		PlateColumn = CAST(substring(W.Position,2,2) AS INT),
		PlateRow = substring(W.Position,1,1),
		PlantNr = ISNULL(DA.SampleNr,0),
		PlantName = V.Shortname,
		BreedingStation = 'NLSO' --hard coded : comment in #7257
	FROM Test T
	JOIN Plate P ON P.TestID = T.TestID
	JOIN Well W ON W.PlateID = P.PlateID
	JOIN DeterminationAssignment DA ON DA.DetAssignmentID = W.DetAssignmentID
	JOIN Variety V ON V.VarietyNr = DA.VarietyNr
	JOIN ABSCrop AC ON AC.ABSCropCode = DA.ABSCropCode
	JOIN
	(
		SELECT MarkerID, VarietyNr FROM MarkerValuePerVariety MVPV
		UNION ALL
		SELECT MarkerID, VarietyNr FROM MarkerPerVariety
	) MVPV ON MVPV.VarietyNr = DA.VarietyNr
	JOIN Marker M ON M.MarkerID = MVPV.MarkerID
	WHERE T.PeriodID = @PeriodID

	
END

GO


