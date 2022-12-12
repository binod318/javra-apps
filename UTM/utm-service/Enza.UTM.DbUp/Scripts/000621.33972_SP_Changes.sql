/*
Author							Date				Description
Binod Gurung					2021/06/14			Automatic sample filling for selection/crosses
=================Example===============
EXEC [PR_LFDISK_Calculate_Sample_Filling] 12684, 20
*/
ALTER PROCEDURE [dbo].[PR_LFDISK_Calculate_Sample_Filling]
(
	@TestID INT,
	@TotalPlantsInSample INT
)
AS BEGIN
	SET NOCOUNT ON;
	DECLARE @ReCalculate BIT, @ImportLevel NVARCHAR(20), @TestTypeID INT, @TotalPlants INT, @Counter INT, @SampleCounter INT, @SampleName NVARCHAR(50), @TestName NVARCHAR(MAX);
	DECLARE @MatPlant TABLE (MatPlantID INT IDENTITY(1,1), TestMaterialID INT, MaterialName NVARCHAR(30), NrOfPlants INT);
	DECLARE @Plants TABLE(ID INT, TestMaterialID INT, PlantName NVARCHAR(50));
	DECLARE @SampleTest TABLE(SampleTestID INT, TestID INT);
	DECLARE @DeleteSample TABLE(ID INT);
	DECLARE @TestMaterialID INT, @PlantName NVARCHAR(150), @ID INT = 1, @Count INT, @NewSample BIT = 1, @SampleCount INT = 1, @StatusCode INT;

	IF NOT EXISTS (SELECT TestID FROM Test WHERE TestID = @TestID)
	BEGIN
		EXEC PR_ThrowError 'Invalid test.'; 
		RETURN;
	END

	SELECT @TestName = TestName, @ReCalculate = RearrangePlateFilling, @ImportLevel = ImportLevel, @TestTypeID = TestTypeID, @StatusCode = StatusCode FROM Test WHERE TestID = @TestID

	IF (@TestTypeID <> 9)
	BEGIN
		EXEC PR_ThrowError 'Calculation is performed only for Leafdisk.';
		RETURN;
	END

	IF (@ImportLevel <> 'CROSSES/SELECTION')
	BEGIN
		EXEC PR_ThrowError 'Automatic sample calculation is only for selection/crosses';
		RETURN;
	END

	--Only perform recalculate if @ReCalculate flag is set  -- NULL for first time
	IF (ISNULL(@ReCalculate,1) = 1 AND @StatusCode < 500) --do not update once it is sent to LIMS
	BEGIN

		--delete all old records

		DELETE STD FROM LD_SampleTestDetermination STD
		JOIN LD_SampleTest ST ON ST.SampleTestID = STD.SampleTestID
		WHERE ST.TestID = @TestID;

		DELETE M FROM LD_MaterialPlant M
		JOIN LD_SampleTestMaterial STM ON STM.MaterialPlantID = M.MaterialPlantID
		JOIN LD_SampleTest ST ON ST.SampleTestID = STM.SampleTestID
		where ST.TestID = @TestID

		DELETE STM from LD_SampleTestMaterial STM
		JOIN LD_SampleTest ST on ST.SampleTestID = STM.SampleTestID
		where ST.testid = @TestID

		INSERT @DeleteSample(ID)
		SELECT ST.SampleID FROM LD_SampleTest ST
		JOIN LD_Sample S ON s.SampleID = ST.SampleID 
		WHERE st.testid = @TestID

		DELETE FROM LD_SampleTest
		WHERE SampleID In (SELECT ID FROM @DeleteSample);

		DELETE FROM LD_Sample
		WHERE SampleID In (SELECT ID FROM @DeleteSample);

		INSERT @MatPlant (TestMaterialID, MaterialName, NrOfPlants)
		SELECT 
			TM.TestMaterialID, 
			MaterialName = COALESCE(T3.Plantnumber, T3.Femalecode, ''), 
			NrOfPlants
		FROM TestMaterial TM
		JOIN 
		(
			SELECT T2.TestMaterialID, T2.RowID, T2.Plantnumber, T2.[Female code] AS Femalecode
					FROM
					(
						SELECT 
							T.TestID,
							R.RowID,
							TM.TestMaterialID,
							C.ColumLabel,
							CellValue = CL.[Value]
						FROM [File] F
						JOIN [Row] R ON R.FileID = F.FileID
						JOIN Material M ON M.MaterialKey = R.MaterialKey
						JOIN [Column] C ON C.FileID = F.FileID
						JOIN Test T ON T.FileID = F.FileID
						JOIN TestMaterial TM ON TM.TestID = T.TestID AND Tm.MaterialID = M.materialID
						LEFT JOIN [Cell] CL ON CL.RowID = R.RowID AND CL.ColumnID = C.ColumnID
						WHERE 
							C.ColumLabel IN('origin', 'Female code') AND 
							T.TestID = @TestID
						
					) T1
					PIVOT
					(
						Max(CellValue)
						FOR [ColumLabel] IN ([Plantnumber], [Female code], [GID], [FEID])
					) T2
		) T3 On T3.TestMaterialID = TM.TestMaterialID
		WHERE  testid = @TestID AND ISNULL(NrOfPlants,0) > 0
		order by T3.RowID;


		;WITH CTE AS
		(
			SELECT MatPlantID, TestMaterialID, MaterialName, NrOfPlants FROM @MatPlant
			UNION ALL
			SELECT MatPlantID, TestMaterialID, MaterialName, NrOfPlants - 1 FROM CTE WHERE NrOfPlants > 1
		)

		INSERT @Plants(ID, TestMaterialID, PlantName)
		SELECT	
			ROW_NUMBER() OVER (ORDER BY MatPlantID),
			TestMaterialID,
			PlantName = ISNULL(MaterialName,'') + '-' + CAST( NrOfPlants AS NVARCHAR(10))
		FROM CTE
		ORDER BY
			MatPlantID;

		--remove suffix -1 for from plantname for materials with only one plant
		UPDATE @Plants 		
		SET PlantName = REPLACE(PlantName, '-1', '')
		WHERE ID IN 
		(
			SELECT MIN(ID) FROM @Plants
			GROUP BY TestMaterialID
			HAVING COUNT(TestMaterialID) = 1
		)
		
		BEGIN TRY
		BEGIN TRANSACTION;

			SELECT @Count = COUNT(ID) FROM @Plants;
			WHILE(@ID <= @Count) BEGIN
			
				SELECT 
					@TestMaterialID = TestMaterialID,
					@PlantName = PlantName 
				FROM @Plants
				WHERE ID = @ID;

				--create Sample/SampleTest if @NewSample = 1
				IF(@NewSample = 1)
				BEGIN
					
					DELETE FROM @SampleTest;

					INSERT LD_Sample(SampleName)
					--OUTPUT INSERTED.SampleID INTO @Sample
					VALUES(@TestName + '-' + CAST(@SampleCount AS NVARCHAR(10)));

					INSERT LD_SampleTest(SampleID, TestID)
					OUTPUT INSERTED.SampleTestID, INSERTED.TestID INTO @SampleTest
					--SELECT ID, @TestID FROM @Sample;
					VALUES(SCOPE_IDENTITY(), @TestID);

					SET @NewSample = 0;
				END

				--create MaterialPlant/SampleTestMaterial
				INSERT LD_MaterialPlant(TestMaterialID, [Name])
				VALUES(@TestMaterialID, @PlantName);

				INSERT LD_SampleTestMaterial(MaterialPlantID, SampleTestID)
				SELECT SCOPE_IDENTITY(), SampleTestID FROM @SampleTest

				IF(@ID % @TotalPlantsInSample = 0) 
				BEGIN
					SET @NewSample = 1;
					SET @SampleCount = @SampleCount + 1;
				END

				SET @ID = @ID + 1;
			END   

		COMMIT;
		END TRY
		BEGIN CATCH

			IF @@TRANCOUNT > 0
				ROLLBACK;

		END CATCH

		--SET @ReCalculate = 0;
		UPDATE Test
		SET RearrangePlateFilling = 0
		WHERE TestID = @TestID
	END

END
