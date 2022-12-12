DROP PROCEDURE IF EXISTS [dbo].[PR_LFDISK_UpdateTestMaterial]
GO


/*
Author					Date			Description
Binod Gurung			2021/06/21		Save number of plants in TestMaterial
===================================Example================================
DECLARE @Json NVARCHAR(MAX) = N'[{
									"MaterialID": "70228",
									"NrOfPlants": "2"
								}, {
									"MaterialID": "70229",
									"NrOfPlants": "15"
								}]'
EXEC [PR_LFDISK_UpdateTestMaterial] 12679, @Json
*/
CREATE PROCEDURE [dbo].[PR_LFDISK_UpdateTestMaterial]
(
	@TestID INT,
	@Json NVARCHAR(MAX)
)
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @ImportLevel NVARCHAR(20), @TestTypeID INT, @StatusCode INT;
	DECLARE @Material TABLE(MaterialID INT, NrOfPlants INT);

	IF NOT EXISTS (SELECT TestID FROM Test WHERE TestID = @TestID)
	BEGIN
		EXEC PR_ThrowError 'Invalid test.'; 
		RETURN;
	END

	SELECT @ImportLevel = ImportLevel, @TestTypeID = TestTypeID, @StatusCode = StatusCode FROM Test WHERE TestID = @TestID

	IF (@TestTypeID <> 9)
	BEGIN
		EXEC PR_ThrowError 'Invalid test type.';
		RETURN;
	END

	IF (@ImportLevel <> 'CROSSES/SELECTION')
	BEGIN
		EXEC PR_ThrowError 'Number of Plants can be updated only for Selection/Crosses';
		RETURN;
	END
	
	IF (@StatusCode >= 500)
	BEGIN
		EXEC PR_ThrowError 'Material info can not be updated for test already sent to LIMS.';
		RETURN;
	END

	INSERT @Material(MaterialID, NrOfPlants)
	SELECT MaterialID, NrOfPlants
	FROM OPENJSON(@Json) WITH
	(
		MaterialID	INT '$.MaterialID',
		NrOfPlants	INT '$.NrOfPlants'
	);

	MERGE INTO TestMaterial T
	USING @Material S
	ON T.TestID = @TestID AND S.MaterialID = T.MaterialID
	WHEN MATCHED THEN
		UPDATE 
		SET T.NrOfPlants = S.NrOfPlants;

	--Update Flag to run recalculate platefilling
	UPDATE Test
	SET RearrangePlateFilling = 1
	WHERE TestID = @TestID

END
GO


