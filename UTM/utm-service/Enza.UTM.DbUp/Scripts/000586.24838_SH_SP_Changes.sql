DROP PROCEDURE IF EXISTS PR_SH_ImportMaterials
GO
/*
=========Changes====================
Changed By			DATE				Description
Krishna Gautam		2021/11/01			#22628 : Import screen for Seed health

========Example=============

*/

CREATE PROCEDURE [dbo].[PR_SH_ImportMaterials]
(
	@TestID						INT OUTPUT,
	@CropCode					NVARCHAR(10),
	@BrStationCode				NVARCHAR(10),
	@SyncCode					NVARCHAR(10),
	@CountryCode				NVARCHAR(10),
	@UserID						NVARCHAR(100),
	--@TestProtocolID				INT,
	@TestName					NVARCHAR(200),
	@Source						NVARCHAR(50) = 'Phenome',
	@ObjectID					NVARCHAR(100),
	@ImportLevel				NVARCHAR(20),
	@TVPColumns TVP_Column		READONLY,
	@TVPRow TVP_Row				READONLY,
	@TVPCell TVP_Cell			READONLY,
	@FileID						INT,
	@PlannedDate				DATETIME,
	@MaterialTypeID				INT,
	@SiteID						INT = NULL,
	@SampleType					NVARCHAR(MAX)
)
AS BEGIN
    SET NOCOUNT ON;

    DECLARE @SQL NVARCHAR(MAX);
    --DECLARE @TblInsertedMaterial TABLE(MaterialID INT, TestID INT);
	DECLARE @TestTypeID INT = 10;

    BEGIN TRY
	   BEGIN TRANSACTION;
	   DECLARE @TblInsertedMaterial TABLE(ID INT IDENTITY(1,1), MaterialLotID INT, TestID INT);
	   DECLARE @CreatedSample TABLE (ID INT IDENTITY(1,1), SampleID INT);
	   DECLARE @CreatedSampleTest TABLE(ID INT IDENTITY(1,1), SampleTestID INT);
	   DECLARE @SampleTestID INT;

	   --import data as new test/file
	   IF(ISNULL(@FileID, 0) = 0) 
	   BEGIN

			IF EXISTS(SELECT FileTitle FROM [File] F 
				JOIN Test T ON T.FileID = F.FileID WHERE T.BreedingStationCode = @BrStationCode AND F.CropCode = @CropCode AND F.FileTitle =@TestName) 
			BEGIN
				EXEC PR_ThrowError 'File already exists.';
				RETURN;
			END

			--validation for siteID
			IF NOT EXISTS(SELECT SiteID FROM [SiteLocation] WHERE SiteID = @SiteID )
			BEGIN
				EXEC PR_ThrowError 'Invalid site location.';
				RETURN;
			END

			IF(ISNULL(@TestTypeID,0) <> 10) 
			BEGIN
				EXEC PR_ThrowError 'Invalid test type ID.';
				RETURN;
			END
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
		  [SyncCode], [ImportLevel], CountryCode, TestProtocolID, PlannedDate, MaterialTypeID,SiteID, LotSampleType)
		  VALUES(@TestTypeID, @FileID, @Source, @UserID, @TestName, GETUTCDATE(), 100, @BrStationCode, 
		  @SyncCode, @ImportLevel, @CountryCode, NULL, @PlannedDate, NULL , @SiteID, @SampleType);
		  --Get Last inserted testid
		  SELECT @TestID = SCOPE_IDENTITY();

		  --CREATE Materials if not already created

		  MERGE INTO MaterialLot T 
			 USING
			 (
				    SELECT R.MaterialKey
				    FROM @TVPRow R
				    --JOIN @TVPList L ON R.GID = L.GID --AND R.EntryCode = L.EntryCode
				    GROUP BY R.MaterialKey
			 ) S	ON S.MaterialKey = T.MaterialKey
		  WHEN NOT MATCHED THEN 
				    INSERT(MaterialType, MaterialKey,CropCode,RefExternal,BreedingStationCode)
				    VALUES (@ImportLevel, S.MaterialKey, @CropCode, @ObjectID, @BrStationCode)
		 WHEN MATCHED THEN --AND ISNULL(S.MaterialKey,0) <> ISNULL(T.OriginrowID,0)
				    UPDATE  SET T.RefExternal = @ObjectID ,BreedingStationCode = @BrStationCode
		 OUTPUT INSERTED.MaterialLotID, @TestID INTO @TblInsertedMaterial(MaterialLotID, TestID);
		

		--Merge data in testmaterial table
		MERGE INTO TestMaterial T
		USING 
		(
			SELECT * FROM @TblInsertedMaterial
		) S ON S.MaterialLotID = T.MaterialID AND S.TestID = T.TestID
		WHEN NOT MATCHED THEN 
			INSERT(TestID,MaterialID)
			VALUES(@TestID,S.MaterialLotID);

		--Add material to sample based on SampleType
		IF(ISNULL(@SampleType,'') = 'fruit')
		BEGIN
			--Create sample
			INSERT INTO LD_Sample(SampleName)
			OUTPUT inserted.SampleID INTO @CreatedSample(SampleID)
			VALUES('Sample1');

			--assign sample to test
			INSERT INTO LD_SampleTest(SampleID,TestID)
			OUTPUT INSERTED.SampleTestID INTO @CreatedSampleTest(SampleTestID)
			SELECT SampleID, @TestID FROM @CreatedSample;

			SELECT @SampleTestID = SampleTestID FROM @CreatedSampleTest;

			--add material to sample
			INSERT INTO LD_SampleTestMaterial(SampleTestID, MaterialLotID)
			SELECT @SampleTestID, MaterialLotID FROM @TblInsertedMaterial;
			
			
		END
		ELSE IF (ISNULL(@SampleType,'') = 'seedsample')
		BEGIN
			--Create sample
			INSERT INTO LD_Sample(SampleName)
			OUTPUT inserted.SampleID INTO @CreatedSample(SampleID)
			SELECT SampleName = CONCAT('Sample',ID) FROM @TblInsertedMaterial;

			--Assign sample to test
			INSERT INTO LD_SampleTest(SampleID,TestID)
			OUTPUT inserted.SampleTestID INTO @CreatedSampleTest(SampleTestID)
			SELECT SampleID, @TestID FROM @CreatedSample;

			--add material to sample
			INSERT INTO LD_SampleTestMaterial(SampleTestID, MaterialLotID)
			SELECT 
				ST.SampleTestID, 
				M.MaterialLotID 
			FROM @TblInsertedMaterial M
			JOIN @CreatedSampleTest ST ON ST.ID = M.ID;

		END



		END
		--import data to existing test/file
		ELSE BEGIN
			DECLARE @importtype NVARCHAR(MAX)='';

			IF NOT EXISTS (SELECT * FROM [File] WHERE FileID = @FileID)
			BEGIN
				EXEC PR_ThrowError 'Invalid FileID.';
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
				--@TestProtocolID = T.TestProtocolID,
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
			 MERGE INTO MaterialLot T 
				USING
				(
					SELECT R.MaterialKey
					FROM @TVPRow R
					GROUP BY R.MaterialKey
				) S	ON S.MaterialKey = T.MaterialKey
				WHEN NOT MATCHED THEN 
					INSERT(MaterialType, MaterialKey, CropCode,RefExternal, BreedingStationCode)
					VALUES (@ImportLevel, S.MaterialKey, @CropCode,@ObjectID, @BrStationCode)
				WHEN MATCHED THEN 
				    UPDATE  SET T.RefExternal = @ObjectID, BreedingStationCode= @BrStationCode
					OUTPUT INSERTED.MaterialLotID, @TestID INTO @TblInsertedMaterial(MaterialLotID, TestID);

				--Merge data in testmaterial table
				MERGE INTO TestMaterial T
				USING 
				(
					SELECT * FROM @TblInsertedMaterial
				) S ON S.MaterialLotID = T.MaterialID AND S.TestID = T.TestID
				WHEN NOT MATCHED THEN 
					INSERT(TestID,MaterialID)
					VALUES(@TestID,S.MaterialLotID);



				--need to add logic of creating sample and adding material to created sample




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





DROP PROCEDURE IF EXISTS [dbo].[PR_SH_GetSampleMaterial]
GO


/*
Author					Date			Description
Binod Gurung			2021/06/08		Get sample plot information for selected test
===================================Example================================
EXEC [PR_SH_GetSampleMaterial] 13786,1,100,''
EXEC [PR_SH_GetSampleMaterial] 12692,1,100,'SampleName like ''%_%''',20
*/
CREATE PROCEDURE [dbo].[PR_SH_GetSampleMaterial]
(
	@TestID INT,
	@Page INT,
	@PageSize INT,
	@FilterQuery NVARCHAR(MAX)
)
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @ReCalculate BIT, @ImportLevel NVARCHAR(20), @Offset INT, @TotalRowsWithoutFilter NVARCHAR(MAX);
	DECLARE @ColumnTable TVP_ColumnDetail;
	--DECLARE @RequiredColumns NVARCHAR(MAX), @RequiredColumns1 NVARCHAR(MAX);
	DECLARE @Query NVARCHAR(MAX), @Editable BIT;

	IF NOT EXISTS (SELECT TestID FROM Test WHERE TestID = @TestID AND TestTypeID = 10)
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

	SELECT @ReCalculate = RearrangePlateFilling, @ImportLevel = ImportLevel, @Editable = CASE WHEN StatusCode >= 500 THEN 0 ELSE 1 END FROM Test WHERE TestID = @TestID

	
	
	--now get total rows without filter value after recalculating.
	SELECT 
		@TotalRowsWithoutFilter = CAST(COUNT(ST.SampleID) AS NVARCHAR(MAX)) 
	FROM [LD_Sample] S
	JOIN [LD_SampleTest] ST ON ST.SampleID = S.SampleID
	JOIN Test T ON T.TestID = ST.TestID
	JOIN [File] F ON F.FileID = T.FileID	
	LEFT JOIN [LD_SampleTestMaterial] STM ON STM.SampleTestID = ST.SampleTestID
	LEFT JOIN [TestMaterial] TM ON TM.TestMaterialID = STM.MaterialLotID
	LEFT JOIN [MaterialLot] M ON M.MaterialLotID = TM.MaterialID
	LEFT JOIN [Row] R ON R.MaterialKey = M.MaterialKey AND R.FileID = F.FileID
	WHERE ST.TestID = @TestID AND T.TestID = @TestID

	INSERT @ColumnTable(ColumnID, ColumnLabel, [Order], Visible,AllowFilter,DataType,Editable,Width)
	VALUES  ('SampleID', 'SampleID', 0, 0 ,0, 'integer', 0,10),			
			('SampleName', 'Sample', 1, 1, 1, 'string', 0, 150),
			('MaterialID', 'MaterialID', 2, 1 ,1, 'integer', 0,150);

	

	SET @Query = ';WITH CTE AS
	(

		
	SELECT
		--[Delete] =	CASE 
		--				WHEN '+  CAST(@Editable AS NVARCHAR(MAX)) +' = 0 THEN 0
		--				WHEN (ISNULL(STM.SampleTestID,0) <> 0 AND @ImportLevel = ''PLOT'') THEN 1 
		--				ELSE 0 
		--			END,
		[Delete] = 0,
		S.SampleID,
		MaterialID = M.MaterialLotID,
		S.SampleName,		
		Total = '+@TotalRowsWithoutFilter+' 
	FROM [LD_Sample] S
	JOIN [LD_SampleTest] ST ON ST.SampleID = S.SampleID
	JOIN Test T ON T.TestID = ST.TestID
	JOIN [File] F ON F.FileID = T.FileID	
	LEFT JOIN [LD_SampleTestMaterial] STM ON STM.SampleTestID = ST.SampleTestID
	LEFT JOIN [TestMaterial] TM ON TM.TestMaterialID = STM.MaterialLotID
	LEFT JOIN [MaterialLot] M ON M.MaterialLotID = TM.MaterialID
	LEFT JOIN [Row] R ON R.MaterialKey = M.MaterialKey AND R.FileID = F.FileID
	
	WHERE T.TestID = @TestID '+@FilterQuery+' ), Count_CTE AS (SELECT COUNT([SampleID]) AS [TotalRows] FROM CTE) 

	SELECT CTE.*, Count_CTE.[TotalRows] FROM CTE, COUNT_CTE
	ORDER BY CTE.[SampleID]
	OFFSET ' + CAST(@Offset AS NVARCHAR) + ' ROWS
	FETCH NEXT ' + CAST (@PageSize AS NVARCHAR) + ' ROWS ONLY'

	
	PRINT @Query;
	EXEC sp_executesql @Query, N'@TestID INT, @ImportLevel NVARCHAR(MAX)', @TestID, @ImportLevel;	

	

	SELECT * FROM @ColumnTable ORDER BY [Order]


END
GO




DROP PROCEDURE IF EXISTS [dbo].[PR_SH_GetDataWithMarker]
GO

/*
Author					Date				Description
KRIAHNA GAUTAM			2021-06-11			#22641:SP created.

============Example===================
EXEC [PR_LFDISK_GetDataWithMarker] 13786, 1, 150, ''
EXEC [PR_LFDISK_GetDataWithMarker] 13786, 1, 150, 'SampleName like ''%_%'''
*/
CREATE PROCEDURE [dbo].[PR_SH_GetDataWithMarker]
(
    @TestID INT,
    @Page INT,
    @PageSize INT,
    @Filter NVARCHAR(MAX) = NULL
)
AS BEGIN
    SET NOCOUNT ON;

	DECLARE @totalRowsWithoutFilter INT;

	

    --DECLARE @Columns NVARCHAR(MAX),@ColumnIDs NVARCHAR(MAX), @Columns2 NVARCHAR(MAX), @ColumnID2s NVARCHAR(MAX), @Columns3 NVARCHAR(MAX), @ColumnIDs4 NVARCHAR(MAX);
    DECLARE @Offset INT, @Total INT, @FileID INT, @Query NVARCHAR(MAX),@ImportLevel NVARCHAR(MAX), @CropCode NVARCHAR(MAX);	
    DECLARE @TblColumns TABLE(ColumnID NVARCHAR(MAX), ColumnLabel NVARCHAR(MAX), ColumnType INT, ColumnNr INT, DataType NVARCHAR(MAX), Editable BIT, Visible BIT,AllowFilter BIT,Width INT);
	DECLARE @DeterminationColumns NVARCHAR(MAX), @DeterminationColumnIDS NVARCHAR(MAX), @Editable BIT;

    SELECT 
		@FileID = F.FileID,
		@ImportLevel = T.ImportLevel,
		@CropCode = F.CropCode,
		@Editable = CASE WHEN T.StatusCode >= 500 THEN 0 ELSE 1 END
    FROM [File] F
    JOIN Test T ON T.FileID = F.FileID 
    WHERE T.TestID = @TestID;
	

	SELECT @totalRowsWithoutFilter = COUNT(SampleTestID) FROM LD_SampleTest WHERE TestID = @TestID;

    --Determination columns
    INSERT INTO @TblColumns(ColumnID, ColumnLabel, ColumnType, ColumnNr, DataType, Editable,Visible,AllowFilter,Width)
    SELECT DeterminationID, ColumnLabel, 1, ROW_NUMBER() OVER(ORDER BY DeterminationID), 'boolean', @Editable, 1,0,100
    FROM
    (	

		SELECT 
			DeterminationID = CAST(D.DeterminationID AS NVARCHAR(MAX)),
			--CONCAT('D_', D.DeterminationID) AS TraitID,
			ColumnLabel = MAX(D.DeterminationName)
		FROM 
		LD_SampleTestDetermination STD 
		JOIN Determination D ON D.DeterminationID = STD.DeterminationID
		JOIN LD_SampleTest ST ON ST.SampleTestID = STD.SampleTestID		
		WHERE ST.TestID = @TestID
		GROUP BY D.DeterminationID

    ) V1;

   
	
    --get Get Determination Column
    SELECT 
	   @DeterminationColumns  = COALESCE(@DeterminationColumns + ',', '') + QUOTENAME(ColumnID),
	   @DeterminationColumnIDS  = COALESCE(@DeterminationColumnIDS + ',', '') + QUOTENAME(ColumnID)	  
    FROM @TblColumns
    WHERE ColumnType = 1
    GROUP BY ColumnID;

    --If there are no any determination assigned
	IF(ISNULL(@DeterminationColumns,'') = '')
	BEGIN
		SET 
		@Query = ';WITH CTE AS 
					(
						SELECT 
							--[Delete] = CASE 
							--				WHEN '+  CAST(@Editable AS NVARCHAR(MAX)) +' = 0 THEN 0
							--				WHEN ISNULL(T1.SampleTestID,0) = 0 THEN 1 
							--				ELSE 0 
							--			END,
							[Delete] = 0,
							ST.SampleTestID, 
							S.SampleName, 
							S.ReferenceCode, 
							Total = '+ CAST(@totalRowsWithoutFilter AS NVARCHAR(MAX))+' 
						FROM LD_SampleTest ST
						JOIN LD_Sample S ON S.SampleID  = ST.SampleID
						LEFT JOIN
						(
								SELECT SampleTestID FROM 
								LD_SampleTestMaterial
								GROUP BY SampleTestID
						) T1 ON T1.SampleTestID = ST.SampleTestID
						WHERE ST.TestID = @TestID
					';
	END	
	ELSE
	BEGIN
		SET 
			@Query = ';WITH CTE AS 
						(	
							SELECT 
								--[Delete] = CASE 
								--				WHEN '+  CAST(@Editable AS NVARCHAR(MAX)) +' = 0 THEN 0
								--				WHEN ISNULL(T1.SampleTestID,0) = 0 THEN 1 
								--				ELSE 0 
								--			END, 
								[Delete] = 0,
								ST.SampleTestID, 
								S.SampleName, 
								S.ReferenceCode, 
								'+ @DeterminationColumns+', 
								Total = '+ CAST(@totalRowsWithoutFilter AS NVARCHAR(MAX))+' 
							FROM LD_SampleTest ST
							JOIN LD_Sample S ON S.SampleID  = ST.SampleID
							LEFT JOIN 
							(
								SELECT * FROM
								(
									SELECT ST.SampleTestID, STD.DeterminationID FROM LD_SampleTestDetermination STD
									JOIN LD_SampleTest ST ON STD.SampleTestID = ST.SampleTestID
									WHERE ST.TestID = @TestID
								) SRC
								PIVOT
								(
									COUNT(DeterminationID)
									FOR DeterminationID IN ('+@DeterminationColumnIDS+')
								)
								PV

							) T1 ON T1.SampleTestID = ST.SampleTestID
							LEFT JOIN
							(
								SELECT SampleTestID FROM 
								LD_SampleTestMaterial
								GROUP BY SampleTestID
							) T2 ON T2.SampleTestID = ST.SampleTestID
							WHERE ST.TestID = @TestID';
	END

    IF(ISNULL(@Filter, '') <> '') BEGIN
	   SET @Query = @Query + ' AND ' + @Filter
    END
	

    SET @Query = @Query + N'
    ), CTE_COUNT AS (SELECT COUNT([SampleTestID]) AS [TotalRows] FROM CTE)
    SELECT
		CTE.*, 
		CTE_COUNT.TotalRows
    FROM CTE, CTE_COUNT
    ORDER BY SampleTestID
    OFFSET @Offset ROWS
    FETCH NEXT @PageSize ROWS ONLY';

    SET @Offset = @PageSize * (@Page -1);
	
	
    EXEC sp_executesql @Query,N' @Offset INT, @PageSize INT, @TestID INT', @Offset, @PageSize, @TestID;

	
	--Insert other columns
	INSERT INTO @TblColumns(ColumnID,ColumnLabel,ColumnNr,ColumnType,DataType,Editable,Visible,AllowFilter,Width)
	VALUES
	('SampleTestID','SampleTestID',1,0,'integer',0,0,1,10),
	('sampleName','Sample',2,0,'string',@Editable,1,1,150),
	('referenceCode','QRCode',3,0,'string',@Editable,1,1,100);
    
	DECLARE @ColumnDetail TVP_ColumnDetail;
	--This insert is done to provide same column property to UI.
	INSERT INTO @ColumnDetail(ColumnID,ColumnLabel,AllowFilter,[Order],DataType,Editable,Visible,Width)
		SELECT
			ColumnID,
			ColumnLabel, 	   
			AllowFilter, 
			ColumnNr = ROW_NUMBER() OVER(ORDER BY ColumnType, ColumnNr),
			DataType,
			Editable,
			Visible,
			Width
		FROM @TblColumns
		ORDER BY ColumnType, ColumnNr;	

	SELECT * FROM @ColumnDetail;
END
GO







