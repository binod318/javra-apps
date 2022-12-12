DROP PROCEDURE IF EXISTS [dbo].[PR_LFDISK_Calculate_Sample_Filling]
GO

/*
Author							Date				Description
Binod Gurung					2021/06/14			Automatic sample filling for selection/crosses
=================Example===============
EXEC [PR_LFDISK_Calculate_Sample_Filling] 12669, 20
*/
CREATE PROCEDURE [dbo].[PR_LFDISK_Calculate_Sample_Filling]
(
	@TestID INT,
	@TotalPlantsInSample INT
)
AS BEGIN
	SET NOCOUNT ON;
	DECLARE @ReCalculate BIT, @ImportLevel NVARCHAR(20), @TestTypeID INT, @TotalPlants INT, @Counter INT, @SampleCounter INT, @SampleName NVARCHAR(50);
	DECLARE @MatPlant TABLE (MaterialID INT, MaterialName NVARCHAR(30), NrOfPlants INT);
	DECLARE @Plants TABLE(ID INT, MaterialID INT, PlantName NVARCHAR(50));
	DECLARE @SampleTest TABLE(SampleTestID INT, TestID INT);
	DECLARE @MaterialID INT, @PlantName NVARCHAR(150), @ID INT = 1, @Count INT, @NewSample BIT = 1, @SampleCount INT = 1;

	IF NOT EXISTS (SELECT TestID FROM Test WHERE TestID = @TestID)
	BEGIN
		EXEC PR_ThrowError 'Invalid test.'; 
		RETURN;
	END

	SELECT @ReCalculate = RearrangePlateFilling, @ImportLevel = ImportLevel, @TestTypeID = TestTypeID FROM Test WHERE TestID = @TestID

	IF (@TestTypeID <> 9)
	BEGIN
		EXEC PR_ThrowError 'Calculation is performed only for Leafdisk.';
		RETURN;
	END

	IF (@ImportLevel = 'Plot')
	BEGIN
		EXEC PR_ThrowError 'Automatic sample calculation is only for selection/crosses';
		RETURN;
	END

	--Only perform recalculate if @ReCalculate flag is set 
	IF (ISNULL(@ReCalculate,1) = 1)
	BEGIN

		INSERT @MatPlant (MaterialID, MaterialName, NrOfPlants)
		SELECT 
			TM.MaterialID, 
			MaterialName = COALESCE(T3.Plantnumber, T3.Femalecode), 
			NrOfPlants 
		FROM TestMaterial TM
		JOIN 
		(
			SELECT T2.MaterialID, T2.Plantnumber, T2.[Female code] AS Femalecode
					FROM
					(
						SELECT 
							T.TestID,
							M.MaterialID,
							C.ColumLabel,
							CellValue = CL.[Value]
						FROM [File] F
						JOIN [Row] R ON R.FileID = F.FileID
						JOIN Material M ON M.MaterialKey = R.MaterialKey
						JOIN [Column] C ON C.FileID = F.FileID
						JOIN Test T ON T.FileID = F.FileID
						LEFT JOIN [Cell] CL ON CL.RowID = R.RowID AND CL.ColumnID = C.ColumnID
						WHERE C.ColumLabel IN('Plantnumber', 'Female code') AND T.TestID = @TestID
					) T1
					PIVOT
					(
						Max(CellValue)
						FOR [ColumLabel] IN ([Plantnumber], [Female code])
					) T2
		) T3 On T3.MaterialID = TM.MaterialID
		WHERE  testid = @TestID;


		WITH CTE AS
		(
			SELECT MaterialID, MaterialName, NrOfPlants FROM @MatPlant
			UNION ALL
			SELECT MaterialID, MaterialName, NrOfPlants - 1 FROM CTE WHERE NrOfPlants > 1
		)

		INSERT @Plants(ID, MaterialID, PlantName)
		SELECT	
			ROW_NUMBER() OVER (ORDER BY MaterialID, NrOfPlants),
			MaterialID,
			PlantName = MaterialName + '-' + CAST( NrOfPlants AS NVARCHAR(10))
		FROM CTE
		ORDER BY
			MaterialID, NrOfPlants

		--remove suffix -1 for from plantname for materials with only one plant
		UPDATE @Plants 		
		SET PlantName = REPLACE(PlantName, '-1', '')
		WHERE ID IN 
		(
			SELECT MIN(ID) FROM @Plants
			GROUP BY MaterialID
			HAVING COUNT(MaterialID) = 1
		)
		
		BEGIN TRY
		BEGIN TRANSACTION;

			SELECT @Count = COUNT(ID) FROM @Plants;
			WHILE(@ID <= @Count) BEGIN
			
				SELECT 
					@MaterialID = MaterialID,
					@PlantName = PlantName 
				FROM @Plants
				WHERE ID = @ID;

				--create Sample/SampleTest if @NewSample = 1
				IF(@NewSample = 1)
				BEGIN
					
					DELETE FROM @SampleTest;

					INSERT LD_Sample(SampleName)
					--OUTPUT INSERTED.SampleID INTO @Sample
					VALUES('Sample_' + CAST(@TestID AS NVARCHAR(50)) + '_' + CAST(@SampleCount AS NVARCHAR(10)));

					INSERT LD_SampleTest(SampleID, TestID)
					OUTPUT INSERTED.SampleTestID, INSERTED.TestID INTO @SampleTest
					--SELECT ID, @TestID FROM @Sample;
					VALUES(SCOPE_IDENTITY(), @TestID);

					SET @NewSample = 0;
				END

				--create MaterialPlant/SampleTestMaterial
				INSERT LD_MaterialPlant(MaterialID, [Name])
				VALUES(@MaterialID, @PlantName);

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

		SET @ReCalculate = 0;
	END

END
GO


DROP PROCEDURE IF EXISTS [dbo].[PR_LFDISK_GetSampleMaterial]
GO


/*
Author					Date			Description
Binod Gurung			2021/06/08		Get sample plot information for selected test
===================================Example================================
EXEC [PR_LFDISK_GetSampleMaterial] 12655,20
*/
CREATE PROCEDURE [dbo].[PR_LFDISK_GetSampleMaterial]
(
	@TestID INT,
	@TotalPlantsInSample INT = NULL
)
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @ReCalculate BIT, @ImportLevel NVARCHAR(20);
	DECLARE @ColumnTable TABLE(ColumnID NVARCHAR(MAX), Label NVARCHAR(MAX),[Order] INT, IsVisible BIT);

	IF NOT EXISTS (SELECT TestID FROM Test WHERE TestID = @TestID AND TestTypeID = 9)
	BEGIN
		EXEC PR_ThrowError N'Invalid Test.';
		RETURN;
	END

	SELECT @ReCalculate = RearrangePlateFilling, @ImportLevel = ImportLevel FROM Test WHERE TestID = @TestID

	--Automatic calculate platefilling for Selection/Crosses
	IF(@ImportLevel = 'CROSSES/SELECTION' AND ISNULL(@ReCalculate,1) = 1 )
		EXEC PR_LFDISK_Calculate_Sample_Filling @TestID, @TotalPlantsInSample;

	INSERT @ColumnTable(ColumnID, Label, [Order], IsVisible)
	VALUES  ('SampleID', 'SampleID', 0, 0),
			('SampleName', 'SampleName', 1, 1),
			('GID', 'GID', 2, 1),
			('Plot name', 'Plot name', 3, 1);

	SELECT 
		S.SampleID,
		S.SampleName,
		GID = ISNULL(T3.GID,''),
		Plotname = ISNULL(T3.[Plot name],'')
	FROM [LD_Sample] S
	JOIN [LD_SampleTest] ST ON ST.SampleID = S.SampleID
	LEFT JOIN [LD_SampleTestMaterial] STM ON STM.SampleTestID = ST.SampleTestID
	LEFT JOIN [LD_MaterialPlant] MP On MP.MaterialPlantID = STM.MaterialPlantID
	LEFT JOIN [Material] M ON M.MaterialID = MP.MaterialID
	LEFT JOIN [Row] R ON R.MaterialKey = M.MaterialKey
	LEFT JOIN
	(
		SELECT T2.MaterialKey,  T2.[GID], T2.[Plot name], T2.TestID
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
				WHERE C.ColumLabel IN('GID', 'Plot name')
			) T1
			PIVOT
			(
				Max(CellValue)
				FOR [ColumLabel] IN ([GID], [Plot name])
			) T2
	) T3 ON T3.MaterialKey = M.MaterialKey AND T3.TestID = ST.TestID
	WHERE ST.TestID = @TestID

	SELECT * FROM @ColumnTable ORDER BY [Order]

END
GO


