DROP PROCEDURE IF EXISTS [dbo].[PR_GetInfoForFillPlatesInLIMS]
GO

/*
Author					Date			Description
Binod Gurung			2019/12/03		Get information for FillPlatesInLIMS
Binod Gurung			2020-jan-23		Transcation isolation level implemented to avoid record lock
Krishna Gautam			2020-Mar-01		Test with status code 350 is only selected to send to LIMS.
Krishna Gautam			2020-Mar-06		#11304 VarietyName in PlantNr and SampleNr in PlantName.
Binod Gurung			2022-Feb-08		#32219 PeriodID made optional. When no periodID then fetch all tests for all periods
===================================Example================================

EXEC PR_GetInfoForFillPlatesInLIMS 0
*/
CREATE PROCEDURE [dbo].[PR_GetInfoForFillPlatesInLIMS]
(
	@PeriodID INT = NULL
)
AS
BEGIN
	
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

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
		PlantNr = V.Shortname,-- ISNULL(DA.SampleNr,0),
		PlantName = CAST(DA.SampleNr as VARCHAR(200)),-- V.Shortname,
		BreedingStation = 'NLSO' --hard coded : comment in #7257
	FROM Test T
	JOIN Plate P ON P.TestID = T.TestID
	JOIN Well W ON W.PlateID = P.PlateID
	JOIN DeterminationAssignment DA ON DA.DetAssignmentID = W.DetAssignmentID
	JOIN Variety V ON V.VarietyNr = DA.VarietyNr
	JOIN ABSCrop AC ON AC.ABSCropCode = DA.ABSCropCode
	JOIN
	(
		SELECT MTB.MarkerID, DetAssignmentID FROM MarkerToBeTested MTB
		UNION
		SELECT MarkerID, DA.DetAssignmentID FROM MarkerPerVariety MPV
		JOIN DeterminationAssignment DA ON DA.VarietyNr = MPV.VarietyNr
		WHERE MPV.StatusCode = 100
	) MVPV ON MVPV.DetAssignmentID = DA.DetAssignmentID
	JOIN Marker M ON M.MarkerID = MVPV.MarkerID
	WHERE T.PeriodID = CASE WHEN ISNULL(@PeriodID,0) = 0 THEN T.PeriodID ELSE @PeriodID END
	AND T.StatusCode = 350
	ORDER BY T.PeriodID, T.TestID

END

GO


CREATE INDEX idx_DetAssignmentID
ON MarkerToBeTested (DetAssignmentID)

GO