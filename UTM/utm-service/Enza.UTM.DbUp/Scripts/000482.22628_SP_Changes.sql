DROP PROCEDURE IF EXISTS [dbo].[PR_Get_Files]
GO


/*
EXEC  PR_Get_Files 'ON', 'NLEN'
*/
CREATE PROCEDURE [dbo].[PR_Get_Files]
(
	--@UserID NVARCHAR(100),
	@CropCode NVARCHAR(10),
	@BreedingStationCode NVARCHAR(10),
	@TestID INT = NULL
) AS
BEGIN
	
	DECLARE @TotalWells INT,@BlockedWells INT;
	IF(ISNULL(@TestID,0)<> 0) BEGIN
		SELECT @BreedingStationCode = T.BreedingStationCode,@CropCode = F.CropCode FROM 
		[File] F 
		JOIN Test T ON T.FileID = F.FileID WHERE T.TestID = @TestID
	END

	SELECT @TotalWells = ((CAST(ASCII(EndRow) AS INT) - CAST(ASCII(StartRow) AS INT) +1)  * (EndColumn  - StartColumn + 1))
	FROM PlateType;

	SELECT                  
		F.FileID, 	                        
		F.CropCode, 
		F.FileTitle, 
		F.UserID, 
		F.ImportDateTime,
		T.TestID,
		T.TestTypeID,
		T.Remark,
		TT.RemarkRequired,
		T.StatusCode,
		T.MaterialStateID,
		T.MaterialTypeID,
		T.ContainerTypeID,
		T.Isolated,
		T.PlannedDate,
		ST.SlotID,
		WellsPerPlate = @TotalWells - ISNULL(T1.Blocked,0),
		T.BreedingStationCode,
		T.ExpectedDate,
		T.LabPlatePlanName,
		T.RequestingSystem,
		T.Cumulate,
		T.ImportLevel,
		ExcludeControlPosition = CAST(ISNULL(T.ExcludeControlPosition, 0) AS BIT),
		TestProtocolID
	FROM [File] F
	JOIN Test T ON T.FileID = F.FileID	
	JOIN TestType TT ON TT.TestTypeID = T.TestTypeID
	LEFT JOIN SlotTest ST ON ST.TestID = T.TestID
	LEFT JOIN 
	(
		SELECT Blocked = COUNT(TT.TestTypeID),TT.TestTypeID
		FROM TestType TT
		LEFT JOIN WellTypePosition WTP ON TT.TestTypeID = WTP.TestTypeID
		LEFT JOIN WellType WT ON WT.WellTypeID = WTP.WellTypeID
		WHERE WT.WellTypeName = 'B'
		GROUP BY TT.TestTypeID,WTP.WellTypeID
	) T1 ON T1.TestTypeID = T.TestTypeID
	WHERE --F.UserID = @UserID
	F.CropCode = @CropCode
	AND T.BreedingStationCode = @BreedingStationCode
	AND T.StatusCode <= 600 
	AND (ISNULL(@TestID, 0) = 0 OR T.TestID = @TestID)
	ORDER BY FileID DESC
	OPTION (RECOMPILE);
END
GO


DROP PROCEDURE IF EXISTS [dbo].[PR_GetTestsLookup]
GO

-- =============================================  
-- Author:  Binod Gurung  
-- Create date: 12/14/2017  
-- Description: Get List of Test to fill combo box   
-- =============================================  
-- EXEC [PR_GetTestsLookup] 'ON', 'NLEN'  
CREATE PROCEDURE [dbo].[PR_GetTestsLookup]   
(    
    @CropCode NVARCHAR(10),  
    @BreedingStationCode NVARCHAR(10)  
)  
AS  
BEGIN  
  
    SET NOCOUNT ON;  
  
	DECLARE @FixedWellTypeID INT,@BlockedWellTpeID iNT
    DECLARE @TotalWells INT;  
    DECLARE @tbl1 TABLE(TestID INT, TotalFixed INT);
    --DECLARE @tbl2 TABLE(TestID INT, ReplicatedCount INT);
    DECLARE @tbl3 TABLE(TestTypeID INT, Blocked INT);

	SELECT @BlockedWellTpeID = WellTypeID FROM WellType WHERE WellTypeName = 'B';
	SELECT @FixedWellTypeID = WellTypeID FROM WellType WHERE WellTypeName = 'F';
    
  
    SELECT 
	   @TotalWells = ((CAST(ASCII(EndRow) AS INT) - CAST(ASCII(StartRow) AS INT) +1)  * (EndColumn  - StartColumn + 1))  
    FROM PlateType;

    INSERT INTO @tbl1(TestID, TotalFixed)
    SELECT 
	   T.TestID, 
	   COUNT(W.WellTypeID) AS TotalFixed  
    FROM Well W
    JOIN Plate P ON P.PlateID = W.PlateID  
    JOIN Test T ON T.TestID = P.TestID  
    JOIN [File] F ON F.FileID = T.FileID  
    WHERE 
		W.WellTypeID = @FixedWellTypeID AND
		T.BreedingStationCode = @BreedingStationCode AND 
		F.CropCode = @CropCode  
    GROUP BY T.TestID;

    INSERT INTO @tbl3(TestTypeID, Blocked)
    SELECT 
	   TT.TestTypeID,
	   Blocked = COUNT(TT.TestTypeID)
    FROM TestType TT  
    LEFT JOIN WellTypePosition WTP ON TT.TestTypeID = WTP.TestTypeID  
    LEFT JOIN WellType WT ON WT.WellTypeID = WTP.WellTypeID  
    WHERE WT.WellTypeName = 'B'  
    GROUP BY TT.TestTypeID,WTP.WellTypeID;
   
    SELECT   
	 T.TestID,   
	 T.TestName,   
	 TT.TestTypeID,   
	 TT.TestTypeName,  
	 T.Remark,  
	 TT.RemarkRequired,  
	 T.StatusCode,  
	 FixedPositionAssigned = CAST((CASE WHEN ISNULL(T1.TotalFixed,0) = 0 THEN 0 ELSE 1 END) AS BIT),  
	 T.MaterialStateID,  
	 T.MaterialTypeID,  
	 T.ContainerTypeID,  
	 MaterialReplicated =CAST( 0 AS BIT),-- CAST((CASE WHEN ISNULL(T2.ReplicatedCount,1) = 1 THEN 0 ELSE 1 END) AS BIT),  
	 T.PlannedDate,  
	 T.Isolated,  
	 ST1.SlotID,  
	 WellsPerPlate = CASE WHEN (TT.TestTypeID = 1 OR (ISNULL(T.ExcludeControlPosition,0) = 1 AND T.TestTypeID = 2)) THEN  @TotalWells - ISNULL(T3.Blocked,0) ELSE @TotalWells END,  
	 T.BreedingStationCode,  
	 F.CropCode,  
	 T.ExpectedDate,  
	 S1.SlotName,  
	 T.LabPlatePlanName,  
	 T.RequestingSystem,  
	 T.Cumulate,  
	 T.ImportLevel,
	 T.TestProtocolID 
	FROM [File] F  
	JOIN Test T ON T.FileID = F.FileID  
	JOIN TestType TT ON T.TestTypeID = TT.TestTypeID  
	LEFT JOIN [Status] ST ON ST.StatusCode = T.StatusCode AND ST.StatusTable = 'Test'  
	LEFT JOIN @tbl1 T1 ON T1.TestID = T.TestID  
	--LEFT JOIN @tbl2 T2 ON T2.TestID = T.TestID  
	LEFT JOIN SlotTest ST1 ON ST1.TestID = T.TestID  
	LEFT JOIN Slot S1 ON S1.SlotID = ST1.SlotID  
	LEFT JOIN @tbl3 T3 ON T3.TestTypeID = T.TestTypeID  
	WHERE
		F.CropCode = @CropCode AND 
		T.BreedingStationCode = @BreedingStationCode AND 
		T.StatusCode <= 600  
	ORDER BY TestID DESC  
	OPTION (RECOMPILE);
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
    DECLARE @TblDonor TABLE(RowID INT, DonorNr NVARCHAR(200));
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
				    UPDATE  SET T.OriginrowID = S.MaterialKey,T.RefExternal = @ObjectID ,BreedingStationCode = @BrStationCode;
		
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
				    UPDATE  SET T.OriginrowID = S.MaterialKey,T.RefExternal = @ObjectID, BreedingStationCode= @BrStationCode;
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


DROP PROCEDURE IF EXISTS [dbo].[PR_LFDISK_GET_Data]
GO


/*
Author							Date				Description
Binod Gurung					2021/06/08			Data for first tab of Assign request screen
=================Example===============
EXEC PR_LFDISK_GET_Data 56,'KATHMANDU\dsuvedi', 1, 3, '[Lotnr]   LIKE  ''%9%''   and [Crop]   LIKE  ''%LT%'''
EXEC PR_LFDISK_GET_Data 4556, 1, 100, ''
EXEC PR_LFDISK_GET_Data 4556, 1, 100, '[Plant name]   LIKE  ''%401%'''
*/
CREATE PROCEDURE [dbo].[PR_LFDISK_GET_Data]
(
	@TestID INT,
	@Page INT,
	@PageSize INT,
	@FilterQuery NVARCHAR(MAX) = NULL
)
AS BEGIN
	SET NOCOUNT ON;
	DECLARE @FileID INT;
	DECLARE @FilterClause NVARCHAR(MAX);
	DECLARE @Offset INT;
	DECLARE @Query NVARCHAR(MAX);
	DECLARE @Columns2 NVARCHAR(MAX)
	DECLARE @Columns NVARCHAR(MAX);	
	DECLARE @ColumnIDs NVARCHAR(MAX);
	DECLARE @Source VARCHAR(20);

	DECLARE @TotalRowsWithoutFilter VARCHAR(10);

	DECLARE @ColumnTable TABLE(ColumnID NVARCHAR(MAX), TraitID INT, ColumnLabel NVARCHAR(MAX),[Order] INT, IsVisible BIT, Editable BIT, DataType NVARCHAR(MAX));

	IF(ISNULL(@FilterQuery,'')<>'')
	BEGIN
		SET @FilterClause = ' AND '+ @FilterQuery
	END
	ELSE
	BEGIN
		SET @FilterClause = '';
	END

	SET @Offset = @PageSize * (@Page -1);

	SELECT @totalRowsWithoutFilter = CAST( COUNT(RowID) AS VARCHAR(10)) FROM [Row] R
	JOIN [File] F ON F.FileID = R.FileID
	JOIN [Test] T ON T.FileID = F.FileID
	WHERE T.TestID = @TestID;

	--get file id based on testid
	SELECT 
	   @FileID = FileID,
	   @Source = RequestingSystem
	FROM Test 
	WHERE TestID = @TestID;

	IF(ISNULL(@FileID, 0) = 0) BEGIN
		EXEC PR_ThrowError 'Invalid file or test.';
		RETURN;
	END
	
	INSERT @ColumnTable(ColumnID, TraitID, ColumnLabel, DataType, Editable, IsVisible, [Order])
	SELECT 
	   ColumnID, 
	   TraitID,
	   ColumLabel,
	   DataType, 
	   0, 
	   1,
	   ColumnNr
	FROM [Column] 
	WHERE FileID = @FileID;
	
	SELECT 
		@Columns  = COALESCE(@Columns + ',', '') +'CAST('+ QUOTENAME(MAX(ColumnID)) +' AS '+ MAX(Datatype) +')' + ' AS ' + ISNULL(QUOTENAME(TraitID), QUOTENAME(ColumnLabel)),
		@Columns2  = COALESCE(@Columns2 + ',', '') + ISNULL(QUOTENAME(TraitID), QUOTENAME(ColumnLabel)),
		@ColumnIDs  = COALESCE(@ColumnIDs + ',', '') + QUOTENAME(MAX(ColumnID))
	FROM @ColumnTable
	GROUP BY ColumnLabel,TraitID

	IF(ISNULL(@Columns, '') = '') BEGIN
		EXEC PR_ThrowError 'At lease 1 columns should be specified';
		RETURN;
	END

	SET @Query = N' ;WITH CTE AS 
	(
		SELECT R.RowID, R.MaterialKey, M.MaterialID, R.[RowNr], Total = '''+ @TotalRowsWithoutFilter +''', ' + @Columns2 + ' 
		FROM [ROW] R 
		JOIN Material M ON M.MaterialKey = R.MaterialKey
		LEFT JOIN 
		(
			SELECT PT.[RowID], ' + @Columns + ' 
			FROM
			(
				SELECT *
				FROM 
				(
					SELECT * FROM dbo.VW_IX_Cell
					WHERE FileID = @FileID
					AND ISNULL([Value],'''')<>'''' 
				) SRC
				PIVOT
				(
					Max([Value])
					FOR [ColumnID] IN (' + @ColumnIDs + ')
				) PIV
			) AS PT 					
		) AS T1	ON R.[RowID] = T1.RowID  				
			WHERE R.FileID = @FileID ' + @FilterClause + '
	), Count_CTE AS (SELECT COUNT([RowID]) AS [TotalRows] FROM CTE) 					
	SELECT CTE.RowID, CTE.MaterialID, CTE.MaterialKey, '+ @Columns2 + ', Count_CTE.[TotalRows], CTE.Total FROM CTE, COUNT_CTE
	ORDER BY CTE.[RowNr]
	OFFSET ' + CAST(@Offset AS NVARCHAR) + ' ROWS
	FETCH NEXT ' + CAST (@PageSize AS NVARCHAR) + ' ROWS ONLY
	OPTION (USE HINT ( ''FORCE_LEGACY_CARDINALITY_ESTIMATION'' ))';				
	
	EXEC sp_executesql @Query, N'@FileID INT', @FileID;	
	
	SELECT * FROM @ColumnTable ORDER By [Order];

END

GO


