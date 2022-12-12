
DROP PROCEDURE IF EXISTS [dbo].[PR_RDT_GetUpdateTestInfo]
GO


CREATE PROCEDURE [dbo].[PR_RDT_GetUpdateTestInfo]
(	
	@TestID INT
)
AS BEGIN

	SELECT TOP 7 
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
GO


