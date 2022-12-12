DROP PROCEDURE IF EXISTS [dbo].[PR_UndoReplaceLOT]
GO

/*
=========Changes====================

========Example=============
EXEC PR_UndoReplaceLOT 1547
*/
CREATE PROCEDURE [dbo].[PR_UndoReplaceLOT]
(
	@GID INT
)
AS BEGIN

	DECLARE @RelationGID INT, @CurrentLotID INT;

	--find Actively linked GID for Variety
	SELECT TOP 1 @RelationGID = GID FROM RelationPtoV
	WHERE VarietyNr IN (SELECT VarietyNr FROM RelationPtoV	WHERE GID = @GID) AND StatusCode = 100

	--if there is no old replace
	IF(ISNULL(@RelationGID,0) <> 0 AND @GID <> ISNULL(@RelationGID,0))
		SELECT @CurrentLotID = PhenomeLotID FROM LOT WHERE GID = @RelationGID

	--remove ReplacingLot from currently linked GID
	UPDATE Variety
	SET ReplacingLot = 0
	WHERE GID IN (SELECT LotGID FROM Variety WHERE GID = @GID)
	
	--reset existing replace link
	UPDATE Variety
	SET ReplacedLot = 0,
		ReplacedLotID = @CurrentLotID,
		LotGID = @RelationGID
	WHERE GID = @GID

END
GO


