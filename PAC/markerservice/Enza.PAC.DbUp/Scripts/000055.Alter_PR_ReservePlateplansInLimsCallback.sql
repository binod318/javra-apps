DROP PROCEDURE IF EXISTS [dbo].[PR_ReservePlateplansInLimsCallback]
GO

/*
=================EXAMPLE=============
DECLARE @T1 TVP_Plates
INSERT INTO @T1(LIMSPlateID,LIMSPlateName)
VALUES(336,'abc'),(337,'bcd')
EXEC PR_ReservePlateplansInLimsCallback 44,'Test',322,@T1
*/
CREATE PROCEDURE [dbo].[PR_ReservePlateplansInLimsCallback]
(
	@LIMSPlateplanID		INT,
	@TestName				NVARCHAR(100),
	@TestID					INT,
	@TVP_Plates TVP_Plates	READONLY
) AS BEGIN

	DECLARE @LabPlateTable TABLE
		(
			LabID INT,
			LabPlateName NVARCHAR(100)
		);

	SET NOCOUNT ON;
	BEGIN TRY
		
		BEGIN TRANSACTION;

			IF NOT EXISTS (SELECT * FROM TEST WHERE TestID = @TestID AND StatusCode = 200) BEGIN
				EXEC PR_ThrowError 'Invalid RequestID.';
				ROLLBACK;
				RETURN;
			END
		
			INSERT INTO @LabPlateTable (LabID, LabPlateName)
			SELECT LIMSPlateID, LIMSPlateName
			FROM @TVP_Plates;	

			--Insert plate info
			MERGE INTO Plate T
			USING
			(
				SELECT LabID, LabPlateName FROM @LabPlateTable

			) S ON S.LabID = T.LabPlateID
			WHEN NOT MATCHED THEN
			  INSERT(PlateName,LabPlateID,TestID)  
			  VALUES(S.LabPlateName,S.LabID, @TestID);
			
			--Update Test info
			UPDATE Test 
			SET LabPlatePlanID = @LIMSPlateplanID,
				TestName = @TestName,
				StatusCode = 300
			WHERE TestID = @TestID;

		COMMIT;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK;
		THROW;
	END CATCH
END
GO


