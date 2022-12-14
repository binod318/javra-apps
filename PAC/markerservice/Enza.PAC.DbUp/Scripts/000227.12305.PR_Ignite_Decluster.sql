DROP PROCEDURE IF EXISTS [dbo].[PR_Ignite_Decluster]
GO

-- =============================================
-- Author:		Binod Gurung
-- Create date: 2019/10/18
-- Description:	Procedure to ignite decluster
-- =============================================
/*	
	EXEC [PR_Ignite_Decluster]
*/
CREATE PROCEDURE [dbo].[PR_Ignite_Decluster]
AS
BEGIN

	DECLARE @DetAssignmentID INT, @ReturnVarieties NVARCHAR(MAX), @TestID INT, @ID INT = 1, @Count INT;;
	DECLARE @tbl TABLE(ID INT IDENTITY(1, 1), TestID INT);
	
	SET NOCOUNT ON;
	
	BEGIN TRY
		BEGIN TRANSACTION;

		DECLARE Determination_Cursor CURSOR LOCAL FAST_FORWARD FOR
		SELECT DetAssignmentID FROM DeterminationAssignment DA WHERE DA.StatusCode = 200
		OPEN Determination_Cursor;
		FETCH NEXT FROM Determination_Cursor INTO @DetAssignmentID;
	
		WHILE @@FETCH_STATUS = 0
		BEGIN
			
			EXEC [PR_Decluster] @DetAssignmentID, @ReturnVarieties OUTPUT;

			--update status of determination assignment 
			UPDATE DeterminationAssignment
			SET StatusCode = 300
			WHERE DetAssignmentID = @DetAssignmentID;

			--for all test where this determination assignment is used update test status if all DA of that test is declustered
			INSERT @tbl(TestID)
			SELECT TestID FROM TestDetAssignment WHERE DetAssignmentID = @DetAssignmentID;

			SELECT @Count = COUNT(ID) FROM @tbl;
			WHILE(@ID <= @Count) BEGIN
				SELECT 
					@TestID = TestID 
				FROM @tbl
				WHERE ID = @ID;

				--if all determination assignments are declustered then update status of Test
				IF NOT EXISTS
				(
					SELECT TD.TestID FROM TestDetAssignment TD
					JOIN DeterminationAssignment DA ON DA.DetAssignmentID = TD.DetAssignmentID
					where DA.StatusCode < 300 AND TD.TestID = @TestID
				)
				BEGIN

					UPDATE Test
					SET StatusCode = 150 --Declustered
					WHERE TestID = @TestID

				END

				SET @ID = @ID + 1;
			END
						
			FETCH NEXT FROM Determination_Cursor INTO @DetAssignmentID;
		END
	
		CLOSE Determination_Cursor;
		DEALLOCATE Determination_Cursor;

		COMMIT;
	END TRY
	BEGIN CATCH
		IF(@@TRANCOUNT > 0)
			ROLLBACK;
		THROW;
	END CATCH
	
END
GO


