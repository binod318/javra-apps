DROP PROCEDURE IF EXISTS [dbo].[PR_PlateFilling]
GO

-- =============================================
-- Author:		Binod Gurung
-- Create date: 2019-12-02
-- Description:	Platefilling
-- EXEC PR_PlateFilling 331
-- =============================================
CREATE PROCEDURE [dbo].[PR_PlateFilling]
(
	@TestID INT
)
AS
BEGIN
	
	DECLARE @StartRow CHAR(1) = 'A', @EndRow CHAR(1) = 'H', @StartColumn INT = 1, @EndColumn INT = 12, @RowCounter INT = 0, @ColumnCounter INT;
	DECLARE @TempTbl TABLE (Position VARCHAR(5))

	SET NOCOUNT ON;

	BEGIN TRY
		
		BEGIN TRANSACTION;

			--delete existing well in case already exists for sme test/plate
			DELETE W FROM Well W
			JOIN Plate P ON P.PlateID = W.PlateID
			WHERE P.TestID = @TestID;

			SET @RowCounter=Ascii(@StartRow);

			WHILE @RowCounter<=Ascii(@EndRow)	BEGIN
				SET @ColumnCounter = @StartColumn;
				WHILE(@ColumnCounter <= @EndColumn) BEGIN							
					INSERT INTO @TempTbl(Position)
						VALUES(CHAR(@RowCounter) + RIGHT('00'+CAST(@ColumnCounter AS VARCHAR),2))
					SET @ColumnCounter = @ColumnCounter + 1;
				END
				SET @RowCounter=@RowCounter + 1;
			END

			INSERT INTO Well (Position, PlateID, DetAssignmentID)
			SELECT 
				Position,
				T1.PlateID, 		
				CASE WHEN CHARINDEX(Position, 'B01,D01,F01,H01') > 0 THEN NULL ELSE T1.DetAssignmentID END
			FROM @TempTbl
			CROSS JOIN 
			(
				SELECT P.PlateID, DA.DetAssignmentID FROM Plate P
				JOIN TestDetAssignment TD ON TD.TestID = P.TestID
				JOIN DeterminationAssignment DA ON DA.DetAssignmentID = TD.DetAssignmentID
				JOIN Method M ON M.MethodCode = DA.MethodCode WHERE TD.TestID = @TestID 
		
			) T1
			ORDER BY T1.PlateID

			--Update Test info 350
			UPDATE Test 
				SET StatusCode = 350
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


