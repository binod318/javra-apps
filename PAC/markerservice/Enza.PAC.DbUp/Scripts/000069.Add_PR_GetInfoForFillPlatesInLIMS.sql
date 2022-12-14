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
		ISNULL(M.MarkerID,0), --needs to be updated with MBD marker number
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
	JOIN MarkerValuePerVariety MVPV On MVPV.VarietyNr = DA.VarietyNr
	JOIN Marker M ON M.MarkerID = MVPV.MarkerID
	WHERE T.PeriodID = @PeriodID
	
END

GO


