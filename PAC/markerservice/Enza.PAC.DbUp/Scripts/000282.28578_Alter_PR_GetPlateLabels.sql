DROP PROCEDURE IF EXISTS [dbo].[PR_GetPlateLabels]
GO

/*
Author					Date			Remarks
Krishna Gautam			2020/01/10		Created folder structcture based on lab priority and excelude already sent test while preparing folder structure
Binod Gurung			2021/11/17		Added Position and SampleNr in Bartender print.
============ExAMPLE===================
EXEC PR_GetPlateLabels 4805,NULL
*/

CREATE PROCEDURE [dbo].[PR_GetPlateLabels]
(
	@PeriodID INT,
	@TestID INT
)
AS
BEGIN
	--SELECT 
	--	'NLSO' AS Country, 
	--	CropCode = MAX(C.CropCode), 
	--	PlateName = MAX(P.PlateName), 
	--	LabPlateID = MAX(P.LabPlateID)  
	--FROM Plate P
	--JOIN Test T ON T.TestID = P.TestID
	--JOIN TestDetAssignment TD ON TD.TestID = T.TestID
	--JOIN DeterminationAssignment DA ON DA.DetAssignmentID = TD.DetAssignmentID
	--JOIN ABSCrop C ON C.ABSCropCode = DA.ABSCropCode
	--WHERE (ISNULL(@TestID,0) = 0  OR T.TestID = @TestID) AND  T.PeriodID = @PeriodID
	--GROUP BY P.PlateID

	DECLARE @TempTBL TABLE (TestID INT, NrOfSeeds INT,PeriodName NVARCHAR(50));

    INSERT INTO @TempTBL(TestID, NrOfSeeds)
    SELECT T.TestID, M.NrOfSeeds FROM Test T 
    JOIN TestDetAssignment TDA ON T.TestID = TDA.TestID
    JOIN DeterminationAssignment DA ON DA.DetAssignmentID = TDA.DetAssignmentID
    JOIN Method M ON M.MethodCode = DA.MethodCode
    WHERE T.PeriodID = @PeriodID
    GROUP BY T.TestID, NrOfSeeds;

	SELECT 
		C.CropCode, 
		P.PlateName, 
		P.LabPlateID 
		,Position =  CASE WHEN (T1.NrOfSeeds = 23 AND (T1.Position IN ('A-B', 'C-D', 'E-F', 'G-H'))) THEN REPLACE(T1.Position, '-', '+')
				     WHEN T1.NrOfSeeds >=92 THEN ''
				ELSE T1.Position
				END
		,T1.SampleNr
	FROM Plate P
	JOIN Test T ON T.TestID = P.TestID
	JOIN TestDetAssignment TD ON TD.TestID = T.TestID
	JOIN DeterminationAssignment DA ON DA.DetAssignmentID = TD.DetAssignmentID
	JOIN ABSCrop C ON C.ABSCropCode = DA.ABSCropCode
	JOIN
	(
		SELECT 
			T.TestID
			,W.PlateID
			,W.DetAssignmentID
			,Position = CONCAT(LEFT(MIN(w.Position), 1), '-', LEFT(MAX(w.Position), 1))
			,NrOfSeeds = MAX(T1.NrOfSeeds)
			,SampleNr = MAX(DA.SampleNr)
		FROM Test T
		JOIN @TempTBL T1 ON T1.TestID = T.TestID
		JOIN Plate p ON T.TestID = P.TestID
		JOIN Well W on W.PlateID = P.PlateID	
		JOIN DeterminationAssignment DA ON DA.DetAssignmentID = W.DetAssignmentID    
		WHERE W.Position NOT IN ('B01','D01','F01','H01') AND T.PeriodID = @PeriodID
		GROUP BY T.TestID, W.DetAssignmentID, W.PlateID				
	) T1 ON T1.TestID = T.TestID AND T1.PlateID = P.PlateID AND T1.DetAssignmentID = DA.DetAssignmentID
	WHERE T.PeriodID = @PeriodID

END
GO


