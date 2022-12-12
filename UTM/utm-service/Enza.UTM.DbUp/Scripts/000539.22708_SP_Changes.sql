
DROP TYPE IF EXISTS [dbo].[TVP_ColumnDetail]
GO

CREATE TYPE [dbo].[TVP_ColumnDetail] AS TABLE(
	[ColumnID] [nvarchar](max) NULL,
	[TraitID] [int] NULL,
	[ColumnLabel] [nvarchar](100) NULL,
	[DataType] [nvarchar](20) NULL,
	[Editable] [bit] NULL,
	[Visible] [bit] NULL,
	[Order] [int] NULL,
	[AllowFilter] [bit] NULL,
	[AllowSort] [bit] NULL,
	[Width] INT 
)
GO


/*
Author							Date				Description
Binod Gurung					2021/06/08			Data for first tab of Assign request screen
=================Example===============
EXEC PR_LFDISK_GET_Data 56,'KATHMANDU\dsuvedi', 1, 3, '[Lotnr]   LIKE  ''%9%''   and [Crop]   LIKE  ''%LT%'''
EXEC PR_LFDISK_GET_Data 12690, 1, 100, ''
EXEC PR_LFDISK_GET_Data 12669, 1, 100, ''
EXEC PR_LFDISK_GET_Data 12700, 1, 100, '[Plant name]   LIKE  ''%401%'''
*/
ALTER PROCEDURE [dbo].[PR_LFDISK_GET_Data]
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
	DECLARE @Source VARCHAR(20), @PlantsColID INT, @PlantsOrder INT, @ImportLevel NVARCHAR(20);

	DECLARE @TotalRowsWithoutFilter VARCHAR(10);

	--DECLARE @ColumnTable TABLE(ColumnID NVARCHAR(MAX), TraitID INT, ColumnLabel NVARCHAR(MAX),[Order] INT, IsVisible BIT, Editable BIT, DataType NVARCHAR(MAX));
	DECLARE @ColumnTable TVP_ColumnDetail;
	

	SELECT @ImportLevel = ImportLevel FROM Test WHERE TestID = @TestID

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
	
	--INSERT @ColumnTable(ColumnID, TraitID, ColumnLabel, DataType, Editable, IsVisible, [Order])
	INSERT INTO @ColumnTable(ColumnID,TraitID,ColumnLabel, DataType,Editable, Visible, [Order],AllowFilter,AllowSort,Width)
	SELECT 
	   ColumnID, 
	   TraitID,
	   ColumLabel,
	   DataType, 
	   0, 
	   1,
	   ColumnNr,
	   1,
	   0,
	   100
	FROM [Column] 
	WHERE FileID = @FileID;
	
	SELECT 
		@Columns  = COALESCE(@Columns + ',', '') +QUOTENAME(MAX(ColumnID)) +' AS ' + ISNULL(QUOTENAME(TraitID), QUOTENAME(ColumnLabel)),
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
		SELECT R.RowID, R.MaterialKey, M.MaterialID, R.[RowNr], NrOfPlants = ISNULL(TM.NrOfPlants,1), Total = '''+ @TotalRowsWithoutFilter +''', ' + @Columns2 + ' 
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
		LEFT JOIN TestMaterial TM ON TM.MaterialID = M.MaterialID AND TM.TestID = ' + CAST(@TestID AS NVARCHAR(20)) + '				
		WHERE R.FileID = @FileID ' + @FilterClause + '
	), Count_CTE AS (SELECT COUNT([RowID]) AS [TotalRows] FROM CTE) 					
	SELECT CTE.RowID, CTE.MaterialID, CTE.MaterialKey, ' 
	+ CASE WHEN @ImportLevel = 'CROSSES/SELECTION' THEN '#plants = CTE.NrOfPlants, ' ELSE '' END
	+ @Columns2 + ', Count_CTE.[TotalRows], CTE.Total FROM CTE, COUNT_CTE
	ORDER BY CTE.[RowNr]
	OFFSET ' + CAST(@Offset AS NVARCHAR) + ' ROWS
	FETCH NEXT ' + CAST (@PageSize AS NVARCHAR) + ' ROWS ONLY
	OPTION (USE HINT ( ''FORCE_LEGACY_CARDINALITY_ESTIMATION'' ))';				
	
	--PRINT @Query;

	EXEC sp_executesql @Query, N'@FileID INT', @FileID;	
	
	IF(@ImportLevel = 'CROSSES/SELECTION')
	BEGIN

		--ColumnID
		SELECT @PlantsColID = MAX(ColumnID) FROM @ColumnTable;

		--push all columns one step behind after 2 to put #plants column
		UPDATE @ColumnTable
		SET [Order] = [Order] + 1
		WHERE [Order] >2

		INSERT @ColumnTable(ColumnID, TraitID, ColumnLabel, DataType, Editable, Visible, [Order],Width)
		VALUES(ISNULL(@PlantsColID,0) + 1,NULL,'#plants','integer',1,1,3,100);

	END

	SELECT 
		ColumnID,
		TraitID, 
		ColumnLabel,
		DataType = CASE WHEN DataType = 'NVARCHAR(255)' THEN 'String' ELSE DataType END,
		Editable,
		Visible,
		[Order], 
		AllowFilter,
		AllowSort,
		Width
	FROM @ColumnTable ORDER By [Order];

END

GO
/*
Author					Date			Description
Binod Gurung			2021/06/08		Get sample plot information for selected test
===================================Example================================
EXEC [PR_LFDISK_GetSampleMaterial] 12692,1,100,'SampleName like ''%_%''',20
*/
ALTER PROCEDURE [dbo].[PR_LFDISK_GetSampleMaterial]
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
	DECLARE @ReCalculate BIT, @ImportLevel NVARCHAR(20), @Offset INT, @TotalRowsWithoutFilter NVARCHAR(MAX);
	--DECLARE @ColumnTable TABLE(ColumnID NVARCHAR(MAX), Label NVARCHAR(MAX),[Order] INT, IsVisible BIT, AllowFilter BIT, DataType NVARCHAR(MAX), Editable BIT);
	DECLARE @ColumnTable TVP_ColumnDetail;
	DECLARE @RequiredColumns NVARCHAR(MAX), @RequiredColumns1 NVARCHAR(MAX)

	DECLARE @Query NVARCHAR(MAX);

	SELECT @TotalRowsWithoutFilter = CAST(COUNT(ST.SampleID) AS NVARCHAR(MAX)) FROM [LD_Sample] S
	JOIN [LD_SampleTest] ST ON ST.SampleID = S.SampleID
	JOIN Test T ON T.TestID = ST.TestID
	JOIN [File] F ON F.FileID = T.FileID	
	LEFT JOIN [LD_SampleTestMaterial] STM ON STM.SampleTestID = ST.SampleTestID
	LEFT JOIN [LD_MaterialPlant] MP On MP.MaterialPlantID = STM.MaterialPlantID
	LEFT JOIN [TestMaterial] TM ON TM.TestMaterialID = MP.TestmaterialID
	LEFT JOIN [Material] M ON M.MaterialID = TM.MaterialID
	LEFT JOIN [Row] R ON R.MaterialKey = M.MaterialKey AND R.FileID = F.FileID
	WHERE ST.TestID = @TestID AND T.TestID = @TestID

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

	INSERT @ColumnTable(ColumnID, ColumnLabel, [Order], Visible,AllowFilter,DataType,Editable,Width)
	VALUES  ('SampleID', 'SampleID', 0, 0 ,0, 'integer', 0,10),
			('SampleName', 'Sample', 1, 1, 1, 'string', 0, 150);

	IF(@ImportLevel = 'PLOT')
	BEGIN
		INSERT @ColumnTable(ColumnID, ColumnLabel, [Order], Visible, AllowFilter, DataType, Editable,Width)
		VALUES  
		('FEID', 'FEID', 2, 1, 1,'string',0, 100),
		('Plot name', 'Plot name', 3, 1, 1,'string',0, 100);
	END
	ELSE
	BEGIN
		INSERT @ColumnTable(ColumnID, ColumnLabel, [Order], Visible, AllowFilter, DataType, Editable,Width)
		VALUES  
		('GID', 'GID', 2, 1, 1,'string',0, 100),
		('Origin', 'Origin', 3, 1, 1,'string',0, 100),
		('Female code', 'Female code', 4, 1, 1,'string',0, 100);
		
	END

	SELECT 
		@RequiredColumns = COALESCE(@RequiredColumns + ',', '') + QUOTENAME(ColumnID),
		@RequiredColumns1 = COALESCE(@RequiredColumns1 + ',', '') + QUOTENAME(ColumnID,'''')
	FROM @ColumnTable WHERE [Order] >= 2;

	SET @Query = ';WITH CTE AS
	(

		
	SELECT
		[Delete] = CASE WHEN (ISNULL(STM.SampleTestID,0) <> 0 AND @ImportLevel = ''PLOT'') THEN 1 ELSE 0 END,
		S.SampleID,
		S.SampleName,
		'+@RequiredColumns+',
		Total = '+@TotalRowsWithoutFilter+' 
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
				WHERE T.TestID = @TestID AND C.ColumLabel IN('+@RequiredColumns1+')
			) T1
			PIVOT
			(
				Max(CellValue)
				FOR [ColumLabel] IN ('+@RequiredColumns+')
			) T2
	) T3 ON T3.MaterialKey = R.MaterialKey AND T3.TestID = ST.TestID
	WHERE T.TestID = @TestID '+@FilterQuery+' ), Count_CTE AS (SELECT COUNT([SampleID]) AS [TotalRows] FROM CTE) 

	SELECT CTE.*, Count_CTE.[TotalRows] FROM CTE, COUNT_CTE
	ORDER BY CTE.[SampleID]
	OFFSET ' + CAST(@Offset AS NVARCHAR) + ' ROWS
	FETCH NEXT ' + CAST (@PageSize AS NVARCHAR) + ' ROWS ONLY'

	
	PRINT @Query;
	EXEC sp_executesql @Query, N'@TestID INT, @ImportLevel NVARCHAR(MAX)', @TestID, @ImportLevel;	

	IF(@ImportLevel <> 'PLOT')
	BEGIN
		INSERT @ColumnTable(ColumnID, ColumnLabel, [Order], Visible, AllowFilter, DataType, Editable,Width)
		VALUES
		('Name', 'Name', 5, 1, 1,'string',0,150);
	END

	SELECT * FROM @ColumnTable ORDER BY [Order]


END
GO

/*
Author					Date				Description
KRIAHNA GAUTAM			2021-06-11			#22641:SP created.

============Example===================
EXEC [PR_LFDISK_GetDataWithMarker] 12721, 1, 150, 'SampleName like ''%_%'''
*/
ALTER PROCEDURE [dbo].[PR_LFDISK_GetDataWithMarker]
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
	DECLARE @DeterminationColumns NVARCHAR(MAX), @DeterminationColumnIDS NVARCHAR(MAX);

    SELECT 
		@FileID = F.FileID,
		@ImportLevel = T.ImportLevel,
		@CropCode = F.CropCode
    FROM [File] F
    JOIN Test T ON T.FileID = F.FileID 
    WHERE T.TestID = @TestID;
	

	SELECT @totalRowsWithoutFilter = COUNT(SampleTestID) FROM LD_SampleTest WHERE TestID = @TestID;

    --Determination columns
    INSERT INTO @TblColumns(ColumnID, ColumnLabel, ColumnType, ColumnNr, DataType, Editable,Visible,AllowFilter,Width)
    SELECT DeterminationID, ColumnLabel, 1, ROW_NUMBER() OVER(ORDER BY DeterminationID), 'boolean', 1, 1,0,100
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
						SELECT [Delete] = CASE WHEN ISNULL(T1.SampleTestID,0) = 0 THEN 1 ELSE 0 END, ST.SampleTestID, S.SampleName, S.ReferenceCode, Total = '+ CAST(@totalRowsWithoutFilter AS NVARCHAR(MAX))+' FROM LD_SampleTest ST
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
							SELECT [Delete] = CASE WHEN (ISNULL(T1.SampleTestID,0) = 0 AND ISNULL(T2.SampleTestID,0) = 0) THEN 1 ELSE 0 END, ST.SampleTestID, S.SampleName, S.ReferenceCode, '+ @DeterminationColumns+', Total = '+ CAST(@totalRowsWithoutFilter AS NVARCHAR(MAX))+' FROM LD_SampleTest ST
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
	
	PRINT @Query;
    EXEC sp_executesql @Query,N' @Offset INT, @PageSize INT, @TestID INT', @Offset, @PageSize, @TestID;

	
	--Insert other columns
	INSERT INTO @TblColumns(ColumnID,ColumnLabel,ColumnNr,ColumnType,DataType,Editable,Visible,AllowFilter,Width)
	VALUES
	('SampleTestID','SampleTestID',1,0,'integer',0,0,1,10),
	('sampleName','Sample',2,0,'string',1,1,1,150),
	('referenceCode','QRCode',3,0,'string',1,1,1,100);
    
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