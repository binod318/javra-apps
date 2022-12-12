DROP PROCEDURE IF EXISTS [dbo].[PR_CheckPlateValidation]
GO


/*
Authror					Date				Description
KRIAHNA GAUTAM			2022-April-05		#33865: Sp created to check if plates are in set of 4.

==========================Example===============================

EXEC PR_CheckPlateValidation 3133

*/

CREATE PROCEDURE [dbo].[PR_CheckPlateValidation]
(
	@TestID INT
)
AS BEGIN

	DECLARE @TotalPlates INT =0;
	SELECT @TotalPlates = ISNULL(COUNT(PlateID),0) FROM Plate WHERE TestID = @TestID;
	IF(@TotalPlates % 4 = 0)
	BEGIN 
		SELECT CAST(1 AS BIT) AS Success, '' AS Message

	END
	ELSE
	BEGIN
		SELECT CAST(0 AS BIT) AS Success,'Plates are not in sets of 4. Do you wish to continue?' AS Message

	END

END
GO


