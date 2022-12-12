/*
Author					Date				Description
Krishna Gautam								Sp Created.
KRIAHNA GAUTAM			2020-March-20		#11673: Allow lab user to delete test which have status In Lims (StatusCode = 500)

=================Example===============

EXEC PR_Delete_Test 4582
*/

ALTER PROCEDURE [dbo].[PR_Delete_Test]
(
	@TestID INT,
	@ForceDelete BIT = 0,
	@Status INT OUT,
	@PlatePlanName NVARCHAR(MAX) OUT
)
AS BEGIN
	DECLARE @FileID INT;
	DECLARE @TestType NVARCHAR(50),@RequiredPlates BIT,@DeterminationRequired BIT;
	IF NOT EXISTS(SELECT TestID FROM Test WHERE TestID = @TestID) BEGIN
		EXEC PR_ThrowError 'Invalid test.';
		RETURN;
	END

	SELECT 
		@Status = ISNULL(T.StatusCode,0),
		@PlatePlanName = ISNULL(T.LabPlatePlanName,''),
		@FileID = ISNULL(T.FileID,0),
		@TestType = TT.TestTypeCode,
		@RequiredPlates = CASE WHEN ISNULL(TT.PlateTypeID,0) = 0 THEN 0 ELSE 1 END,
		@DeterminationRequired = CASE WHEN ISNULL(TT.DeterminationRequired,0) = 0 THEN 0 ELSE 1 END
	FROM Test T 
	JOIN TestType TT ON TT.TestTypeID = T.TestTypeID
	WHERE T.TestID = @TestID;

	IF(ISNULL(@ForceDelete,0) = 0 AND @Status > 400) BEGIN
		EXEC PR_ThrowError 'Cannot delete test which is sent to LIMS.';
		RETURN;
	END

	IF(ISNULL(@ForceDelete,0) = 0 AND @Status > 100 AND @TestType = 'RDT') BEGIN
		EXEC PR_ThrowError 'Cannot delete test which is sent to LIMS.';
		RETURN;
	END

	IF(ISNULL(@ForceDelete,0) = 1 AND @Status > 500) BEGIN
		EXEC PR_ThrowError 'Cannot delete test having result from LIMS';
		RETURN;
	END
	
	SET NOCOUNT ON;
	BEGIN TRY
		BEGIN TRANSACTION;
		
		IF(@TestType = 'C&T') BEGIN

			WHILE 1 =1
			BEGIN
				DELETE TOP (15000) I
				FROM CnTInfo I
				JOIN [Row] R ON R.RowID = I.RowID
				JOIN [File] F ON F.FileID = R.FileID
				JOIN Test T ON T.FileID = F.FileID
				WHERE T.TestID = @TestID;

				IF @@ROWCOUNT < 15000
				BREAK;
			END
		END
		--RDT
		IF(@TestType = 'RDT') BEGIN

			WHILE 1 =1
			BEGIN
				DELETE TOP (15000) TM
				FROM TestMaterial TM
				WHERE TM.TestID = @TestID;
				IF @@ROWCOUNT < 15000
				BREAK;
			END
		END
		
		IF(@RequiredPlates = 1)
		BEGIN
			--delete from testmaterialdeterminationwell
			DELETE TMDW
			FROM TestMaterialDeterminationWell TMDW
			JOIN Well W ON W.WellID = TMDW.WellID
			JOIN Plate P ON P.PlateID = W.PlateID
			WHERE P.TestID = @TestID;

			--delete from well
			DELETE W
			FROM Well W 
			JOIN Plate P ON P.PlateID = W.PlateID
			WHERE P.TestID = @TestID;

			--delete from Plate
			DELETE Plate WHERE TestID = @TestID;
		END
		--delete from slottest
		DELETE SlotTest WHERE TestID = @TestID;

		--delete from testmaterialdetermination
		IF(@DeterminationRequired = 1)
		BEGIN
			
			WHILE 1=1
			BEGIN
				DELETE TOP (15000) TestMaterialDetermination WHERE TestID = @TestID				
				IF @@ROWCOUNT < 15000
				BREAK;
			END

			
		END
		
		IF(@TestType = 'S2S')
		BEGIN
			--delete Donor info for S2S 
			
			WHILE 1=1
			BEGIN
				DELETE TOP (15000) SD 
				FROM Test T 
				JOIN [Row] R ON R.FileID = T.FileID
				JOIN S2SDonorInfo SD ON SD.RowID = R.RowID
				WHERE T.TestID = @TestID

				IF @@ROWCOUNT < 15000
				BREAK;
			END
			
						
			WHILE 1=1
			BEGIN
				--delete marker score
				DELETE TOP(15000) FROM S2SDonorMarkerScore WHERE TestID = @TestID

				IF @@ROWCOUNT < 15000
				BREAK;
			END

			
		END

		IF(@TestType = 'LDISK')
		BEGIN
			

			--DELETE SampleTestDetermination
			DELETE  STD FROM Test T 
			JOIN LD_SampleTest ST ON ST.TestID = T.TestFlowType
			JOIN LD_SampleTestDetermination STD ON STD.SampleTestID = ST.SampleTestID				
			WHERE T.TestID = @TestID

				
			--DELETE sampletestmaterial
			DELETE  STM FROM Test T 
			JOIN LD_SampleTest ST ON ST.TestID = T.TestID
			JOIN LD_SampleTestMaterial STM ON STM.SampleTestID = ST.SampleTestID				
			WHERE T.TestID = @TestID

			DECLARE @Deleted TABLE(ID INT);
			--DELETE sampletest
			DELETE FROM LD_SampleTest 
			OUTPUT DELETED.SampleID INTO @Deleted
			WHERE TestID = @TestID

			--delete sample
			DELETE S FROM [LD_Sample] S
			JOIN @Deleted T ON S.SampleID = T.ID;

			--Delete materialPlant
			DELETE MP FROM LD_MaterialPlant MP
			JOIN TestMaterial TM ON TM.TestMaterialID = MP.TestMaterialID
			WHERE TM.TestID = @TestID;


			--delete testmaterial
			DELETE FROM TestMaterial WHERE TestID = @TestID;

		END
		--delete test
		DELETE Test WHERE TestID = @TestID


		WHILE 1= 1 
		BEGIN
			--delete cell
			DELETE TOP (15000) C FROM Cell C 
			JOIN [Row] R ON R.RowID = C.RowID
			WHERE R.FileID = @FileID
			
			IF @@ROWCOUNT < 15000
			BREAK;
		END
		--delete column
		DELETE [Column] WHERE FileID = @FileID

		--delete row
		DELETE [Row] WHERE FileID = @FileID

		--delete file
		DELETE [File] WHERE FileID = @FileID

		COMMIT;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
            ROLLBACK;
		THROW;
	END CATCH


	
END

GO


/*
Author					Date			Description
Binod Gurung			2021/06/08		Save Plots to sample
===================================Example================================
EXEC [PR_LFDISK_SaveSampleMaterial] 4556, ''
*/
ALTER PROCEDURE [dbo].[PR_LFDISK_SaveSampleMaterial]
(
	@TestID INT,
	@Json NVARCHAR(MAX),
	@Action NVARCHAR(MAX)
)
AS
BEGIN
	
	SET NOCOUNT ON;
	DECLARE @ImportLevel NVARCHAR(20);
	DECLARE @MaterialPlant TABLE(MaterialPlantID INT, MaterialID INT); 
	DECLARE @Material TABLE(SampleID INT, MaterialID INT);
	
	IF NOT EXISTS (SELECT TestID FROM Test WHERE TestID = @TestID AND TestTypeID = 9)
	BEGIN
		EXEC PR_ThrowError N'Invalid Test.';
		RETURN;
	END

	SELECT @ImportLevel = ImportLevel FROM Test WHERE TestID = @TestID;
	IF(ISNULL(@ImportLevel,'') = 'Plot')
	BEGIN
		--ADD material to sample
		IF(ISNULL(@Action,'') = 'Add')
		BEGIN
			INSERT @Material(SampleID, MaterialID)
			SELECT SampleID, MaterialID
					FROM OPENJSON(@Json) WITH
					(
						SampleID	INT '$.SampleID',
						MaterialID	NVARCHAR(MAX) '$.MaterialID'
					)

				
			--Insert to MaterialPlant and copy MaterialPlantID for SampleTestMaterial
		

			MERGE INTO LD_MaterialPlant T
			USING
			(
			
				SELECT 
					TM.TestMaterialID,
					PlantName = CASE WHEN @ImportLevel = 'Plot' THEN T3.Plotname ELSE COALESCE(T3.Plantnumbr, T3.Femalecode) END
				FROM @Material S
				JOIN Material M ON M.MaterialID = S.MaterialID
				JOIN TestMaterial TM ON TM.MaterialID = M.MaterialID AND TM.TestID = @TestID
				JOIN
				(
					SELECT T2.MaterialKey,  T2.[Plot name] AS Plotname, T2.Plantnumbr, T2.[Female code] AS Femalecode
						FROM
						(
							SELECT 
								T.TestID,
								R.MaterialKey,
								C.ColumLabel,
								CellValue = CL.[Value]
							FROM [File] F
							JOIN [Row] R ON R.FileID = F.FileID
							JOIN [Column] C ON C.FileID = F.FileID
							JOIN Test T ON T.FileID = F.FileID
							LEFT JOIN [Cell] CL ON CL.RowID = R.RowID AND CL.ColumnID = C.ColumnID
							WHERE C.ColumLabel IN('Plot name', 'Plantnumbr', 'Female code') AND T.TestID = @TestID
						) T1
						PIVOT
						(
							Max(CellValue)
							FOR [ColumLabel] IN ([Plot name], [Plantnumbr], [Female code])
						) T2
				) T3 ON T3.MaterialKey = M.MaterialKey
			) S ON S.TestMaterialID = T.TestMaterialID
			WHEN NOT MATCHED THEN
				INSERT (TestMaterialID, [Name])
				VALUES (TestMaterialID, PlantName);

			--Merge into SampleTestMaterial
			MERGE INTO LD_SampleTestMaterial T
			USING
			(
				SELECT 
					MP.MaterialPlantID, 
					M.MaterialID,
					ST.SampleTestID
				FROM @Material M
				JOIN TestMaterial TM ON TM.MaterialID = M.MaterialID AND TM.TestID = @TestID
				JOIN LD_MaterialPlant MP ON MP.TestMaterialID = TM.TestMaterialID
				JOIN LD_SampleTest ST ON ST.SampleID = M.SampleID

			) S ON T.MaterialPlantID = S.MaterialPlantID AND T.SampleTestID = S.SampleTestID
			WHEN NOT MATCHED THEN
			INSERT (SampleTestID,MaterialPlantID)
			VALUES(S.SampleTestID, S.MaterialPlantID);
		END
	

	ELSE IF(ISNULL(@Action,'') = 'Remove')
		BEGIN
			--here sampleID is SampleTestID
			INSERT @Material(SampleID, MaterialID)
			SELECT SampleID, MaterialID
					FROM OPENJSON(@Json) WITH
					(
						SampleID	INT '$.SampleID',
						MaterialID	NVARCHAR(MAX) '$.MaterialID'
					)

			--delete data
			MERGE INTO LD_SampleTestMaterial T
			USING
			(
				SELECT 
					MP.MaterialPlantID, 
					M.MaterialID,
					ST.SampleTestID
				FROM @Material M				
				JOIN TestMaterial TM ON TM.MaterialID = M.MaterialID AND TM.TestID = @TestID
				JOIN LD_MaterialPlant MP ON MP.TestMaterialID = TM.TestMaterialID
				JOIN LD_SampleTest ST ON ST.SampleID = M.SampleID


			) S ON T.MaterialPlantID = S.MaterialPlantID AND T.SampleTestID = S.SampleTestID
			WHEN MATCHED THEN
			DELETE;
		
		END
	END
END

GO
