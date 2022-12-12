DROP TABLE IF EXISTS [dbo].[LD_MaterialPlant]
GO

CREATE TABLE [dbo].[LD_MaterialPlant](
	[MaterialPlantID] [int] IDENTITY(1,1) NOT NULL,
	[TestMaterialID] [int] NULL,
	[Name] [nvarchar](150) NULL,
PRIMARY KEY CLUSTERED 
(
	[MaterialPlantID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[LD_MaterialPlant]  WITH CHECK ADD FOREIGN KEY([TestMaterialID])
REFERENCES [dbo].[TestMaterial] ([TestMaterialID])
GO

DROP PROCEDURE IF EXISTS [dbo].[PR_LFDISK_Calculate_Sample_Filling]
GO


/*
Author							Date				Description
Binod Gurung					2021/06/14			Automatic sample filling for selection/crosses
=================Example===============
EXEC [PR_LFDISK_Calculate_Sample_Filling] 12684, 20
*/
CREATE PROCEDURE [dbo].[PR_LFDISK_Calculate_Sample_Filling]
(
	@TestID INT,
	@TotalPlantsInSample INT
)
AS BEGIN
	SET NOCOUNT ON;
	DECLARE @ReCalculate BIT, @ImportLevel NVARCHAR(20), @TestTypeID INT, @TotalPlants INT, @Counter INT, @SampleCounter INT, @SampleName NVARCHAR(50);
	DECLARE @MatPlant TABLE (TestMaterialID INT, MaterialName NVARCHAR(30), NrOfPlants INT);
	DECLARE @Plants TABLE(ID INT, TestMaterialID INT, PlantName NVARCHAR(50));
	DECLARE @SampleTest TABLE(SampleTestID INT, TestID INT);
	DECLARE @DeleteSample TABLE(ID INT);
	DECLARE @TestMaterialID INT, @PlantName NVARCHAR(150), @ID INT = 1, @Count INT, @NewSample BIT = 1, @SampleCount INT = 1, @StatusCode INT;

	IF NOT EXISTS (SELECT TestID FROM Test WHERE TestID = @TestID)
	BEGIN
		EXEC PR_ThrowError 'Invalid test.'; 
		RETURN;
	END

	SELECT @ReCalculate = RearrangePlateFilling, @ImportLevel = ImportLevel, @TestTypeID = TestTypeID, @StatusCode = StatusCode FROM Test WHERE TestID = @TestID

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

		---------------

		INSERT @MatPlant (TestMaterialID, MaterialName, NrOfPlants)
		SELECT 
			TM.TestMaterialID, 
			MaterialName = COALESCE(T3.Plantnumber, T3.Femalecode), 
			NrOfPlants 
		FROM TestMaterial TM
		JOIN 
		(
			SELECT T2.TestMaterialID, T2.Plantnumber, T2.[Female code] AS Femalecode
					FROM
					(
						SELECT 
							T.TestID,
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
						WHERE C.ColumLabel IN('Plantnumbr', 'Female code') AND T.TestID = @TestID
					) T1
					PIVOT
					(
						Max(CellValue)
						FOR [ColumLabel] IN ([Plantnumber], [Female code])
					) T2
		) T3 On T3.TestMaterialID = TM.TestMaterialID
		WHERE  testid = @TestID;


		WITH CTE AS
		(
			SELECT TestMaterialID, MaterialName, NrOfPlants FROM @MatPlant
			UNION ALL
			SELECT TestMaterialID, MaterialName, NrOfPlants - 1 FROM CTE WHERE NrOfPlants > 1
		)

		INSERT @Plants(ID, TestMaterialID, PlantName)
		SELECT	
			ROW_NUMBER() OVER (ORDER BY TestMaterialID, NrOfPlants),
			TestMaterialID,
			PlantName = MaterialName + '-' + CAST( NrOfPlants AS NVARCHAR(10))
		FROM CTE
		ORDER BY
			TestMaterialID, NrOfPlants

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
					VALUES('Sample_' + CAST(@TestID AS NVARCHAR(50)) + '_' + CAST(@SampleCount AS NVARCHAR(10)));

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
GO




DROP PROCEDURE IF EXISTS [dbo].[PR_LFDISK_SaveSampleMaterial]
GO


/*
Author					Date			Description
Binod Gurung			2021/06/08		Save Plots to sample
===================================Example================================
EXEC [PR_LFDISK_SaveSampleMaterial] 4556, ''
*/
CREATE PROCEDURE [dbo].[PR_LFDISK_SaveSampleMaterial]
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
				JOIN TestMaterial TM ON TM.MaterialID = M.MaterialID AND TM.TestID = @TestID

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
				JOIN LD_MaterialPlant MP ON MP.TestMaterialID = TM.MaterialID
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
				JOIN LD_MaterialPlant MP ON MP.TestMaterialID = TM.MaterialID
				JOIN LD_SampleTest ST ON ST.SampleID = M.SampleID


			) S ON T.MaterialPlantID = S.MaterialPlantID AND T.SampleTestID = S.SampleTestID
			WHEN MATCHED THEN
			DELETE;
		
		END
	END
END
GO



DROP PROCEDURE IF EXISTS [dbo].[PR_LFDISK_GetSampleMaterial]
GO


/*
Author					Date			Description
Binod Gurung			2021/06/08		Get sample plot information for selected test
===================================Example================================
EXEC [PR_LFDISK_GetSampleMaterial] 12684,1,100,'',20
*/
CREATE PROCEDURE [dbo].[PR_LFDISK_GetSampleMaterial]
(
	@TestID INT,
	@Page INT,
	@PageSize INT,
	@FilterQuery NVARCHAR(MAX),
	@TotalPlantsInSample INT = NULL
)
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @ReCalculate BIT, @ImportLevel NVARCHAR(20), @Offset INT;
	DECLARE @ColumnTable TABLE(ColumnID NVARCHAR(MAX), Label NVARCHAR(MAX),[Order] INT, IsVisible BIT);
	DECLARE @RequiredColumns NVARCHAR(MAX), @RequiredColumns1 NVARCHAR(MAX)

	DECLARE @Query NVARCHAR(MAX);

	IF NOT EXISTS (SELECT TestID FROM Test WHERE TestID = @TestID AND TestTypeID = 9)
	BEGIN
		EXEC PR_ThrowError N'Invalid Test.';
		RETURN;
	END

	IF(ISNULL(@FilterQuery,'') <> '')
	BEGIN
		SET @FilterQuery = ' AND '+ @FilterQuery ;
	END
	ELSE
	BEGIN
		SET @FilterQuery = ''; 
	END

	SET @Offset = @PageSize * (@Page -1);

	SELECT @ReCalculate = RearrangePlateFilling, @ImportLevel = ImportLevel FROM Test WHERE TestID = @TestID

	--Automatic calculate platefilling for Selection/Crosses
	IF(@ImportLevel = 'CROSSES/SELECTION' AND ISNULL(@ReCalculate,1) = 1 )
		EXEC PR_LFDISK_Calculate_Sample_Filling @TestID, @TotalPlantsInSample;

	INSERT @ColumnTable(ColumnID, Label, [Order], IsVisible)
	VALUES  ('SampleID', 'SampleID', 0, 0),
			('SampleName', 'Sample', 1, 1);

	IF(@ImportLevel = 'PLOT')
	BEGIN
		INSERT @ColumnTable(ColumnID, Label, [Order], IsVisible)
		VALUES  
		('FEID', 'FEID', 2, 1),
		('Plot name', 'Plot name', 3, 1);
	END
	ELSE
	BEGIN
		INSERT @ColumnTable(ColumnID, Label, [Order], IsVisible)
		VALUES  
		('GID', 'GID', 2, 1),
		('Origin', 'Origin', 3, 1),
		('Female code', 'Female code', 4, 1);
		
	END

	SELECT 
		@RequiredColumns = COALESCE(@RequiredColumns + ',', '') + QUOTENAME(ColumnID),
		@RequiredColumns1 = COALESCE(@RequiredColumns1 + ',', '') + QUOTENAME(ColumnID,'''')
	FROM @ColumnTable WHERE [Order] >= 2;

	SET @Query = ';WITH CTE AS
	(

		
	SELECT 
		S.SampleID,
		S.SampleName,
		'+@RequiredColumns+'
	FROM [LD_Sample] S
	JOIN [LD_SampleTest] ST ON ST.SampleID = S.SampleID
	JOIN Test T ON T.TestID = ST.TestID
	JOIN [File] F ON F.FileID = T.FileID
	LEFT JOIN [LD_SampleTestMaterial] STM ON STM.SampleTestID = ST.SampleTestID
	LEFT JOIN [LD_MaterialPlant] MP On MP.MaterialPlantID = STM.MaterialPlantID
	LEFT JOIN [TestMaterial] TM ON TM.TestMaterialID = MP.TestmaterialID
	LEFT JOIN [Material] M ON M.MaterialID = TM.MaterialID
	LEFT JOIN [Row] R ON R.MaterialKey = M.MaterialKey AND R.FileID = F.FileID
	LEFT JOIN
	(
		SELECT T2.MaterialKey,  '+@RequiredColumns+', T2.TestID
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
				WHERE T.TestID = @TestID --AND C.ColumLabel IN('+@RequiredColumns1+')
			) T1
			PIVOT
			(
				Max(CellValue)
				FOR [ColumLabel] IN ('+@RequiredColumns+')
			) T2
	) T3 ON T3.MaterialKey = M.MaterialKey AND T3.TestID = ST.TestID
	WHERE ST.TestID = @TestID '+@FilterQuery+' ), Count_CTE AS (SELECT COUNT([SampleID]) AS [TotalRows] FROM CTE) 

	SELECT CTE.*, Count_CTE.[TotalRows] FROM CTE, COUNT_CTE
	ORDER BY CTE.[SampleID]
	OFFSET ' + CAST(@Offset AS NVARCHAR) + ' ROWS
	FETCH NEXT ' + CAST (@PageSize AS NVARCHAR) + ' ROWS ONLY'

	
	EXEC sp_executesql @Query, N'@TestID INT', @TestID;	

	PRINT @Query;

	SELECT * FROM @ColumnTable ORDER BY [Order]


END
GO


DROP PROCEDURE IF EXISTS [dbo].[PR_LFDISK_ImportMaterials]
GO

/*
=========Changes====================
Changed By			DATE				Description
Binod Gurung		2021/06/07			#22628 : Import screen for Leaf Disk

========Example=============

*/

CREATE PROCEDURE [dbo].[PR_LFDISK_ImportMaterials]
(
	@TestID						INT OUTPUT,
	@CropCode					NVARCHAR(10),
	@BrStationCode				NVARCHAR(10),
	@SyncCode					NVARCHAR(10),
	@CountryCode				NVARCHAR(10),
	@UserID						NVARCHAR(100),
	@TestProtocolID				INT,
	@TestName					NVARCHAR(200),
	@Source						NVARCHAR(50) = 'Phenome',
	@ObjectID					NVARCHAR(100),
	@ImportLevel				NVARCHAR(20),
	@TVPColumns TVP_Column		READONLY,
	@TVPRow TVP_Row				READONLY,
	@TVPCell TVP_Cell			READONLY,
	@FileID						INT,
	@PlannedDate				DATETIME,
	@MaterialTypeID				INT
)
AS BEGIN
    SET NOCOUNT ON;

    --DECLARE @FileID INT;
    DECLARE @SQL NVARCHAR(MAX);
    DECLARE @TblInsertedMaterial TABLE(MaterialID INT, TestID INT);
	DECLARE @TestTypeID INT = 9;

    BEGIN TRY
	   BEGIN TRANSACTION;

	   --import data as new test/file
	   IF(ISNULL(@FileID, 0) = 0) 
	   BEGIN
		  DECLARE @RowData TABLE([RowID] int, [RowNr] int);
		  DECLARE @ColumnData TABLE([ColumnID] int,[ColumnNr] int);

		  INSERT INTO [FILE] ([CropCode],[FileTitle],[UserID],[ImportDateTime])
		  VALUES(@CropCode, @TestName, @UserID, GETUTCDATE());
		  --Get Last inserted fileid
		  SELECT @FileID = SCOPE_IDENTITY();

		  INSERT INTO [Row] ([RowNr], [MaterialKey], [FileID], NrOfSamples)
		  OUTPUT INSERTED.[RowID],INSERTED.[RowNr] INTO @RowData
		  SELECT T.RowNr,T.MaterialKey,@FileID, 1 
		  FROM @TVPRow T
		  ORDER BY T.RowNr;

		  INSERT INTO [Column] ([ColumnNr], [TraitID], [ColumLabel], [FileID], [DataType])
		  OUTPUT INSERTED.[ColumnID], INSERTED.[ColumnNr] INTO @ColumnData
		  SELECT T.[ColumnNr], T1.[TraitID], T.[ColumLabel], @FileID, T.[DataType] 
		  FROM @TVPColumns T
		  LEFT JOIN 
		  (
			 SELECT CT.TraitID,T.TraitName, T.ColumnLabel
			 FROM Trait T 
			 JOIN CropTrait CT ON CT.TraitID = T.TraitID
			 WHERE CT.CropCode = @CropCode AND T.Property = 0
		  )
		  T1 ON T1.ColumnLabel = T.ColumLabel

		  INSERT INTO [Cell] ( [RowID], [ColumnID], [Value])
		  SELECT [RowID], [ColumnID], [Value] 
		  FROM @TVPCell T1
		  JOIN @RowData T2 ON T2.RowNr = T1.RowNr
		  JOIN @ColumnData T3 ON T3.ColumnNr = T1.ColumnNr
		  WHERE ISNULL(T1.[Value],'')<>'';	

		  --CREATE TEST
		  INSERT INTO [Test]([TestTypeID],[FileID],[RequestingSystem],[RequestingUser],[TestName],[CreationDate],[StatusCode],[BreedingStationCode],
		  [SyncCode], [ImportLevel], CountryCode, TestProtocolID, PlannedDate, MaterialTypeID)
		  VALUES(@TestTypeID, @FileID, @Source, @UserID, @TestName, GETUTCDATE(), 100, @BrStationCode, 
		  @SyncCode, CASE WHEN ISNULL(@ImportLevel,'') ='Plot' THEN 'Plot' ELSE 'CROSSES/SELECTION' END, @CountryCode, @TestProtocolID,@PlannedDate, @MaterialTypeID);
		  --Get Last inserted testid
		  SELECT @TestID = SCOPE_IDENTITY();

		  --CREATE Materials if not already created

		  MERGE INTO Material T 
			 USING
			 (
				    SELECT R.MaterialKey
				    FROM @TVPRow R
				    --JOIN @TVPList L ON R.GID = L.GID --AND R.EntryCode = L.EntryCode
				    GROUP BY R.MaterialKey
			 ) S	ON S.MaterialKey = T.MaterialKey
		  WHEN NOT MATCHED THEN 
				    INSERT(MaterialType, MaterialKey, [Source], CropCode,Originrowid,RefExternal,BreedingStationCode)
				    VALUES (@ImportLevel, S.MaterialKey, @Source, @CropCode,S.MaterialKey,@ObjectID,@BrStationCode)
		  WHEN MATCHED AND ISNULL(S.MaterialKey,0) <> ISNULL(T.OriginrowID,0) THEN 
				    UPDATE  SET T.OriginrowID = S.MaterialKey,T.RefExternal = @ObjectID ,BreedingStationCode = @BrStationCode
		OUTPUT INSERTED.MaterialID, @TestID INTO @TblInsertedMaterial(MaterialID, TestID);

		--Merge data in testmaterial table
		MERGE INTO TestMaterial T
		USING 
		(
			SELECT * FROM @TblInsertedMaterial
		) S ON S.MaterialID = T.MaterialID AND S.TestID = T.TestID
		WHEN NOT MATCHED THEN 
			INSERT(TestID,MaterialID,NrOfPlants)
			VALUES(@TestID,S.MaterialID,CASE WHEN ISNULL(@ImportLevel,'') ='Plot' THEN NULL ELSE 1 END);
		
		END
		--import data to existing test/file
		ELSE BEGIN
			DECLARE @importtype NVARCHAR(MAX)='';

			IF NOT EXISTS (SELECT * FROM [File] WHERE FileID = @FileID)
			BEGIN
				EXEC PR_ThrowError 'Invalid FileID.';
				RETURN;
			END
			
			
		  SELECT @importtype = T.ImportLevel FROM Test T
		  JOIN [File] F ON F.FileID = T.FileID
		  WHERE F.FileID = @FileID;

		  IF((@importtype = 'Plot' AND @ImportLevel <> 'Plot') OR (@importtype <> 'Plot' AND @ImportLevel = 'Plot'))
		  BEGIN
			EXEC PR_ThrowError 'Cannot import data from different level.';
				RETURN;
		  END

			--SELECT * FROM Test
			DECLARE @TempTVP_Cell TVP_Cell, @TempTVP_Column TVP_Column, @TempTVP_Row TVP_Row, @TVP_Material TVP_Material, @TVP_Well TVP_Material,
			@TVP_MaterialWithWell TVP_TMDW;
			DECLARE @LastRowNr INT =0, @LastColumnNr INT = 0,@PlatesCreated INT,@PlatesRequired INT,@WellsPerPlate INT,@LastPlateID INT,
			@PlateID INT,@TotalRows INT,@AssignedWellTypeID INT, @EmptyWellTypeID INT,@TotalMaterial INT;
			
			DECLARE @NewColumns TABLE([ColumnNr] INT,[TraitID] INT,[ColumLabel] NVARCHAR(100), [DataType] VARCHAR(15),[NewColumnNr] INT);
			DECLARE @TempRow TABLE (RowNr INT IDENTITY(1,1),MaterialKey NVARCHAR(MAX));
			DECLARE @BridgeColumnTable AS TABLE(OldColNr INT, NewColNr INT);
			DECLARE @RowData1 TABLE(RowNr INT,RowID INT,MaterialKey NVARCHAR(MAX));
			DECLARE @BridgeRowTable AS TABLE(OldRowNr INT, NewRowNr INT);
			DECLARE @StatusCode INT;
			DECLARE @CropCode1 NVARCHAR(10),@BreedingStationCode1 NVARCHAR(10),@SyncCode1 NVARCHAR(2);

			SELECT 
				@CropCode1 = F.CropCode,
				@BreedingStationCode1 = T.BreedingStationCode,
				@SyncCode1 = T.SyncCode,
				@TestTypeID = T.TestTypeID,
				@UserID = T.RequestingUser,
				@TestName = T.TestName,
				@Source = T.RequestingSystem,
				@TestID = T.TestID,
				@TestProtocolID = T.TestProtocolID,
				@PlannedDate = T.PlannedDate,
				@MaterialTypeID = T.MaterialTypeID
			FROM [File] F
			JOIN Test T ON T.FileID = F.FileID
			WHERE F.FileID = @FileID

			SELECT @StatusCode = Statuscode FROM Test WHERE TestID = @TestID;
			IF(@StatusCode >= 200) BEGIN
				EXEC PR_ThrowError 'Cannot import material to this test after plate is requested on LIMS.';
				RETURN;
			END
	
			IF(ISNULL(@CropCode1,'') <> ISNULL(@CropCode,'')) BEGIN
				EXEC PR_ThrowError 'Cannot import material with different crop  to this test.';
				RETURN;
			END

			INSERT INTO @TempTVP_Cell(RowNr,ColumnNr,[Value])
			SELECT RowNr,ColumnNr,[Value] FROM @TVPCell

			INSERT INTO @TempTVP_Column(ColumnNr,ColumLabel,DataType,TraitID)
			SELECT ColumnNr,ColumLabel,DataType,TraitID FROM @TVPColumns;

			INSERT INTO @TempTVP_Row(RowNr,MaterialKey)
			SELECT RowNr,Materialkey FROM @TVPRow;

			--get maximum column number inserted in column table.
			SELECT @LastColumnNr = ISNULL(MAX(ColumnNr), 0)
			FROM [Column] 
			WHERE FileID = @FileID;
			
			--get maximum row number inserted on row table.
			SELECT @LastRowNr = ISNULL(MAX(RowNr),0)
			FROM [Row] R 
			WHERE FileID = @FileID;

			SET @LastRowNr = @LastRowNr + 1;
			SET @LastColumnNr = @LastColumnNr + 1;
			--get only new columns which are not imported already
			INSERT INTO @NewColumns (ColumnNr, TraitID, ColumLabel, DataType, NewColumnNr)
			 SELECT 
				    ColumnNr,
				    TraitID, 
				    ColumLabel, 
				    DataType,
				    ROW_NUMBER() OVER(ORDER BY ColumnNr) + @LastColumnNr
			 FROM @TVPColumns T1
			 WHERE NOT EXISTS
			 (
				    SELECT ColumnID 
				    FROM [Column] C 
				    WHERE C.ColumLabel = T1.ColumLabel AND C.FileID = @FileID
			 )
			 ORDER BY T1.ColumnNr;

			 --insert into new temp row table
			 INSERT INTO @TempRow(MaterialKey)
			 SELECT T1.MaterialKey FROM @TempTVP_Row T1
			 WHERE NOT EXISTS
			 (
				    SELECT R1.MaterialKey FROM [Row] R1 
				    WHERE R1.FileID = @FileID AND T1.MaterialKey = R1.MaterialKey
			 )
			 ORDER BY T1.RowNr;

			 --now insert into row table if material is not availale 
			 INSERT INTO [Row] ( [RowNr], [MaterialKey], [FileID], NrOfSamples)
			 OUTPUT INSERTED.[RowID],INSERTED.[RowNr],INSERTED.MaterialKey INTO @RowData1(RowID, RowNr, MaterialKey)
			 SELECT T.RowNr+ @LastRowNr,T.MaterialKey,@FileID, 1 FROM @TempRow T
			 ORDER BY T.RowNr;

			 --now insert new columns if available which are not already available on table
			 INSERT INTO [Column] ([ColumnNr], [TraitID], [ColumLabel], [FileID], [DataType])
			 SELECT T1.[NewColumnNr], T.[TraitID], T1.[ColumLabel], @FileID, T1.[DataType] 
			 FROM @NewColumns T1
			 LEFT JOIN 
			 (
				    SELECT CT.TraitID,T.TraitName, T.ColumnLabel
				    FROM Trait T 
				    JOIN CropTrait CT ON CT.TraitID = T.TraitID
				    WHERE CT.CropCode = @CropCode AND T.Property = 0
			 )
			 T ON T.ColumnLabel = T1.ColumLabel;

			 INSERT INTO @BridgeColumnTable(OldColNr,NewColNr)
			 SELECT T.ColumnNr,C.ColumnNr FROM 
			 [Column] C
			 JOIN @TempTVP_Column T ON T.ColumLabel = C.ColumLabel
			 WHERE C.FileID = @FileID;

			 INSERT INTO @ColumnData(ColumnID,ColumnNr)
			 SELECT ColumnID, ColumnNr FROM [Column] 
			 WHERE FileID = @FileID;

			 --update this to match previous column with new one if column order changed or new columns inserted.
			 UPDATE T1 SET 
				    T1.ColumnNr = T2.NewColNr
			 FROM @TempTVP_Cell T1
			 JOIN @BridgeColumnTable T2 ON T1.ColumnNr = T2.OldColNr;

			 --update row number if new row added which are already present for that file or completely new row are available on  SP Parameter TVP_ROw
			 INSERT INTO @BridgeRowTable(NewRowNr,OldRowNr)
			 SELECT T1.RowNr,T2.RowNr FROM @RowData1 T1
			 JOIN @TVPRow T2 ON T1.MaterialKey = T2.MaterialKey;

			 UPDATE T1 SET
				    T1.RowNr = T2.NewRowNr
			 FROM @TempTVP_Cell T1
			 JOIN @BridgeRowTable T2 ON T1.RowNr = T2.OldRowNr;

			 INSERT INTO [Cell] ( [RowID], [ColumnID], [Value])
			 SELECT T2.[RowID], T3.[ColumnID], T1.[Value] 
			 FROM @TempTVP_Cell T1
			 JOIN @RowData1 T2 ON T2.RowNr = T1.RowNr
			 JOIN @ColumnData T3 ON T3.ColumnNr = T1.ColumnNr
			 WHERE ISNULL(T1.[Value], '') <> '';

			 --Merge into material
			 MERGE INTO Material T 
				USING
				(
					SELECT R.MaterialKey
					FROM @TVPRow R
					GROUP BY R.MaterialKey
				) S	ON S.MaterialKey = T.MaterialKey
				WHEN NOT MATCHED THEN 
					INSERT(MaterialType, MaterialKey, [Source], CropCode,Originrowid,RefExternal, BreedingStationCode)
					VALUES (@ImportLevel, S.MaterialKey, @Source, @CropCode,S.MaterialKey,@ObjectID, @BrStationCode)
				WHEN MATCHED AND ISNULL(S.MaterialKey,0) <> ISNULL(T.OriginrowID,0) THEN 
				    UPDATE  SET T.OriginrowID = S.MaterialKey,T.RefExternal = @ObjectID, BreedingStationCode= @BrStationCode
					OUTPUT INSERTED.MaterialID, @TestID INTO @TblInsertedMaterial(MaterialID, TestID);

			--Merge data in testmaterial table
			MERGE INTO TestMaterial T
			USING 
			(
				SELECT * FROM @TblInsertedMaterial
			) S ON S.MaterialID = T.MaterialID AND S.TestID = T.TestID
			WHEN NOT MATCHED THEN 
				INSERT(TestID,MaterialID,NrOfPlants)
				VALUES(@TestID,S.MaterialID,CASE WHEN ISNULL(@ImportLevel,'') ='Plot' THEN NULL ELSE 1 END);
			END

		COMMIT;
	END TRY
	BEGIN CATCH
	   IF @@TRANCOUNT > 0 
		ROLLBACK;
	   THROW;
	END CATCH
END
GO


