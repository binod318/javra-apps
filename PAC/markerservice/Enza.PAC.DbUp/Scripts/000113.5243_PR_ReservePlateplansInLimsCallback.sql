
DROP PROCEDURE IF EXISTS [dbo].[PR_ReservePlateplansInLimsCallback]
GO

/*
Author					Date			Remarks
Binod Gurung			2019/12/13		Created service to create plate when callback sevice from lims is called to PAC.
Krishna Gautam			2020/01/10		Changed logic to solve issue of well assigning to multiple determination

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

	DECLARE @LabPlateTable TABLE(LabID INT, LabPlateName NVARCHAR(100));
	DECLARE @StartRow CHAR(1) = 'A', @EndRow CHAR(1) = 'H', @StartColumn INT = 1, @EndColumn INT = 12, @RowCounter INT = 0, @ColumnCounter INT, @PlateCount INT, @Offset INT = 0, @NextRows INT, @DACount INT, @DetAssignmentID INT;
	DECLARE @TempTbl TABLE (Position VARCHAR(5));
	DECLARE @TempPlateTable TABLE(PlateID INT);
	DECLARE @CreatedWell TABLE(ID INT IDENTITY(1,1), WellID INT, PlateID INT, Position NVARCHAR(10), DAID INT,Inserted BIT);
	DECLARE @TblDA TABLE(ID INT IDENTITY(1,1), DAID INT,NrOfSeeds INT);

	SET NOCOUNT ON;
	BEGIN TRY
		
		BEGIN TRANSACTION;

			IF NOT EXISTS (SELECT * FROM TEST WHERE TestID = @TestID AND StatusCode = 200) BEGIN
				EXEC PR_ThrowError 'Invalid RequestID.';
				ROLLBACK;
				RETURN;
			END
			
			DELETE W FROM Well W
			JOIN Plate P ON P.PlateID = W.PlateID
			WHERE P.TestID = @TestID;

			DELETE Plate WHERE TestID = @TestID


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


			INSERT INTO @TblDA(DAID, NrOfSeeds)
			SELECT 
				TDA.DetAssignmentID, 
				M.NrOfSeeds 
			FROM Method M
			JOIN DeterminationAssignment DA ON DA.MethodCode = M.MethodCode
			JOIN TestDetAssignment TDA ON TDA.DetAssignmentID = DA.DetAssignmentID
			WHERE TDA.TestID = @TestID
			ORDER BY ISNULL(DA.IsLabPriority, 0) DESC, DA.DetAssignmentID ASC

			
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
			  VALUES(S.LabPlateName,S.LabID, @TestID)
			  OUTPUT INSERTED.PlateID INTO @TempPlateTable(PlateID);


			 --Create empty well for created plates
			INSERT INTO Well(PlateID, Position)
			OUTPUT INSERTED.WellID, INSERTED.PlateID, INSERTED.Position INTO @CreatedWell(WellID,PlateID,Position)
			SELECT T2.PlateID, T1.Position FROM @TempTbl T1
			CROSS APPLY @TempPlateTable T2
			ORDER BY T2.PlateID;

			DELETE FROM @CreatedWell where Position IN ('B01', 'D01', 'F01', 'H01');

			SET @RowCounter =1;
			SELECT @DACount = COUNT(ID) FROM @TblDA;

			WHILE(@RowCounter <= @DACount)
			BEGIN
				SELECT 
					@NextRows = NrOfSeeds,
					@DetAssignmentID = DAID
				FROM @TblDA WHERE ID = @RowCounter;

				MERGE INTO @CreatedWell T
				USING
				(
					SELECT ID FROM @CreatedWell  ORDER BY ID OFFSET @Offset ROWS FETCH NEXT @NextRows ROWS ONLY
				) S
				ON S.ID = T.ID
				WHEN MATCHED THEN
				UPDATE SET T.DAID = @DetAssignmentID;

				SET @Offset = @Offset + @NextRows;

				SET @RowCounter = @RowCounter + 1;

			END

			MERGE INTO Well T
			USING @CreatedWell S
			ON S.WellID = T.WellID
			WHEN MATCHED
			THEN UPDATE SET T.DetAssignmentID = S.DAID;

			
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


