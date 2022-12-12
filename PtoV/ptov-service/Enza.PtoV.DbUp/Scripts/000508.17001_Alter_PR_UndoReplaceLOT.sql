DROP PROCEDURE IF EXISTS [dbo].[PR_UndoReplaceLOT]
GO


/*
=========Changes====================

========Example=============
EXEC PR_UndoReplaceLOT 3754364
*/
CREATE PROCEDURE [dbo].[PR_UndoReplaceLOT]
(
	@GID INT
)
AS BEGIN

	DECLARE @RelationGID INT, @CurrentLotID INT, @ReplacingGID INT;

	SELECT @ReplacingGID = LotGID FROM Variety WHERE GID = @GID

	--find Actively linked GID for Variety
	SELECT TOP 1 @RelationGID = GID FROM RelationPtoV
	WHERE VarietyNr IN (SELECT VarietyNr FROM RelationPtoV	WHERE GID = @GID) AND StatusCode = 100

	--if there is no old replace
	IF(ISNULL(@RelationGID,0) <> 0 AND @GID <> ISNULL(@RelationGID,0))
		SELECT @CurrentLotID = PhenomeLotID FROM LOT WHERE GID = @RelationGID

	--if replacing variety is only imported and not used on other germplasm then delete all germplasm information
	IF NOT EXISTS 
	( 
		SELECT GID FROM Variety WHERE MalePar = @ReplacingGID OR FemalePar = @ReplacingGID OR Maintainer = @ReplacingGID OR (GID = @ReplacingGID AND StatusCode > 100) 
	)
	BEGIN

		--delete Cell
		DELETE C FROM [Cell] C
		JOIN [Row] R ON R.RowID = C.RowID
		WHERE R.MaterialKey = @ReplacingGID

		--delete Row
		DELETE FROM [Row]
		WHERE MaterialKey = @ReplacingGID

		--delete Lot
		DELETE FROM LOT
		WHERE GID = @ReplacingGID

		--delete germplasm
		DELETE FROM Variety
		WHERE GID = @ReplacingGID

	END
	ELSE

		--remove ReplacingLot from currently linked GID
		UPDATE Variety
		SET ReplacingLot = 0
		WHERE GID = @ReplacingGID

	END
	
	--reset existing replace link
	UPDATE Variety
	SET ReplacedLot		= 0,
		ReplacedLotID	= @CurrentLotID,
		LotGID			= @RelationGID
	WHERE GID = @GID

GO


