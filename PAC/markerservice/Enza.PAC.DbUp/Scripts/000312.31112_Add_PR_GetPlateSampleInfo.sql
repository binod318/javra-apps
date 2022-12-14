DROP PROCEDURE IF EXISTS [dbo].[PR_GetPlateSampleInfo]
GO


/*
Author					Date			Remarks
Binod Gurung			2022/01/19		Get all sample information for given lab plateid
============ExAMPLE===================
EXEC PR_GetPlateSampleInfo 48
*/

CREATE PROCEDURE [dbo].[PR_GetPlateSampleInfo]
(
	@LabPlateID INT
)
AS
BEGIN

	SET NOCOUNT ON;

	SELECT 
		P.PlateName
		,DA.SampleNr
		,V.Shortname
		,Position =  CASE WHEN (T1.NrOfSeeds = 23 AND (T1.Position IN ('A-B', 'C-D', 'E-F', 'G-H'))) THEN REPLACE(T1.Position, '-', '+')
				     WHEN T1.NrOfSeeds >=92 THEN 'A-H'
				ELSE T1.Position
				END
	FROM Plate P
	JOIN Test T ON T.TestID = P.TestID
	JOIN TestDetAssignment TD ON TD.TestID = T.TestID
	JOIN DeterminationAssignment DA ON DA.DetAssignmentID = TD.DetAssignmentID
	LEFT JOIN Variety V ON V.VarietyNr = DA.VarietyNr
	JOIN ABSCrop C ON C.ABSCropCode = DA.ABSCropCode
	JOIN
	(
		SELECT 
			W.PlateID
			,W.DetAssignmentID
			,Position = CONCAT(LEFT(MIN(W.Position), 1), '-', LEFT(MAX(w.Position), 1))
			,NrOfSeeds = MAX(M.NrOfSeeds)
			,SampleNr = MAX(DA.SampleNr)
		FROM Test T
		JOIN Plate P ON T.TestID = P.TestID
		JOIN Well W on W.PlateID = P.PlateID	
		JOIN DeterminationAssignment DA ON DA.DetAssignmentID = W.DetAssignmentID   		
		JOIN Method M ON M.MethodCode = DA.MethodCode
		WHERE W.Position NOT IN ('B01','D01','F01','H01') AND P.LabPlateID = @LabPlateID
		GROUP BY W.DetAssignmentID, W.PlateID				
	) T1 ON T1.PlateID = P.PlateID AND T1.DetAssignmentID = DA.DetAssignmentID
	WHERE P.LabPlateID = @LabPlateID
	ORDER BY P.LabPlateID, Position 

END
GO


