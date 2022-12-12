
/*
	DECLARE @DATA NVARCHAR(MAX) = '[{"id": 21520, "nr": 5}]';
	EXEC PR_SaveNrOfSamples 3075, @DATA
*/
ALTER PROCEDURE [dbo].[PR_SaveNrOfSamples]
(
	@FileID		INT,
	@DATA		NVARCHAR(MAX) 
) AS BEGIN
	SET NOCOUNT ON;
	BEGIN TRY
		BEGIN TRANSACTION;
			DECLARE @TestID INT,@ImportLevel NVARCHAR(MAX), @DeadWellType INT, @AllowUpdate BIT =1;

			SELECT @TestID = TestID,@ImportLevel = ImportLevel FROM Test  WHERE FileID = @FileID

			IF(@ImportLevel = 'LIST') BEGIN

				SELECT 
					@DeadWellType = WellTypeID 
				FROM WellType 
				WHERE WellTypeName = 'D';

				IF EXISTS (SELECT TOP 1 * FROM Test T JOIN Plate P ON P.TestID = T.TestID JOIN Well W ON W.PlateID = P.PlateID WHERE W.WellTypeID = @DeadWellType AND T.TestID = @TestID)
				BEGIN
					
					SET @AllowUpdate = 0;

				END

				IF(ISNULL(@AllowUpdate,0) = 0)
				BEGIN
					EXEC PR_ThrowError 'Updating Sample number is not possible when plate filling contains dead material(s).';
					RETURN;
				END
				ELSE
				BEGIN
					UPDATE R SET 
						NrOfSamples = D.NrOfSamples
					FROM [Row] R
					JOIN Material M ON M.MaterialKey = R.MaterialKey
					JOIN OPENJSON(@DATA) WITH 
					(   
						MaterialID	 INT   '$.id',  
						NrOfSamples  INT   '$.nr'
					) D ON D.MaterialID = M.MaterialID
					WHERE R.FileID = @FileID;

					--reorder plate filling screen for group testing from here.
					EXEC PR_PlateFillingForGroupTesting @TestID

					--set rearrange to true because some value can be unselected on later process
					UPDATE Test set RearrangePlateFilling = 1 WHERE TestID = @TestID;
				END
				
			END

	COMMIT;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
            ROLLBACK;
		THROW;
	END CATCH
END