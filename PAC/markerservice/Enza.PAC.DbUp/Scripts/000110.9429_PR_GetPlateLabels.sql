DROP PROCEDURE IF EXISTS PR_GetPlateLabels
GO

/*
Author					Date			Remarks
Krishna Gautam			2020/01/10		Created folder structcture based on lab priority and excelude already sent test while preparing folder structure

============ExAMPLE===================
--EXEC PR_GetPlateLabels 4792,NULL
*/

CREATE PROCEDURE [PR_GetPlateLabels]
(
	@PeriodID INT,
	@TestID INT
)
AS
BEGIN
	SELECT 'NLSO' AS Country, MAX(C.CropCode), MAX(P.PlateName), MAX(P.LabPlateID)  FROM Plate P
	JOIN Test T ON T.TestID = P.TestID
	JOIN TestDetAssignment TD ON TD.TestID = T.TestID
	JOIN DeterminationAssignment DA ON DA.DetAssignmentID = TD.DetAssignmentID
	JOIN ABSCrop C ON C.ABSCropCode = DA.ABSCropCode
	WHERE (ISNULL(@TestID,0) = 0  OR T.TestID = @TestID) AND  T.PeriodID = @PeriodID
	GROUP BY P.PlateID

END
GO