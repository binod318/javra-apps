

ALTER PROCEDURE [dbo].[PR_RDT_GetUpdateTestInfo]
(	
	@TestID INT
)
AS BEGIN

	SELECT 
		TestID, 
		MaterialID, 
		DeterminationID, 
		InterfaceRefID,
		MaxSelect,
		StatusCode 
	FROM TestMaterialDetermination 
	WHERE
		TestID = @TestID 
		AND StatusCode IN (200, 300)
END