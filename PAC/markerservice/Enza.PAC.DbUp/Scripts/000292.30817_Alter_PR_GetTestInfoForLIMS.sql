DROP PROCEDURE IF EXISTS [dbo].[PR_GetTestInfoForLIMS]
GO


/*
Author					Date			Description
Binod Gurung			2019/10/22		Pull Test Information for input period for LIMS
Binod Gurung			2020-jan-23		Transcation isolation level implemented to avoid record lock
Binod Gurung			2021-dec-17		Expected Week and Planned Week is used from Period table not from DATEPART(WEEK) function because it doesn't match
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
		    'SDS' AS MaterialType,
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


