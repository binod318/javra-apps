
/*
Author					Date				Description
KRIAHNA GAUTAM			2021-06-11			#22641:SP created.

============Example===================
EXEC [PR_LFDISK_GetDataWithMarker] 12675, 1, 150, 'SampleName like ''%sagarmatha_0%'''
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

	SELECT @totalRowsWithoutFilter = COUNT(SampleTestID) FROM LD_SampleTest WHERE TestID = @TestID;

    --DECLARE @Columns NVARCHAR(MAX),@ColumnIDs NVARCHAR(MAX), @Columns2 NVARCHAR(MAX), @ColumnID2s NVARCHAR(MAX), @Columns3 NVARCHAR(MAX), @ColumnIDs4 NVARCHAR(MAX);
    DECLARE @Offset INT, @Total INT, @FileID INT, @Query NVARCHAR(MAX),@ImportLevel NVARCHAR(MAX), @CropCode NVARCHAR(MAX);	
    DECLARE @TblColumns TABLE(ColumnID NVARCHAR(MAX), ColumnLabel NVARCHAR(MAX), ColumnType INT, ColumnNr INT, DataType NVARCHAR(MAX), Editable BIT, Visible BIT,AllowFilter BIT);
	DECLARE @DeterminationColumns NVARCHAR(MAX), @DeterminationColumnIDS NVARCHAR(MAX);

    SELECT 
		@FileID = F.FileID,
		@ImportLevel = T.ImportLevel,
		@CropCode = F.CropCode
    FROM [File] F
    JOIN Test T ON T.FileID = F.FileID 
    WHERE T.TestID = @TestID;
	
    --Determination columns
    INSERT INTO @TblColumns(ColumnID, ColumnLabel, ColumnType, ColumnNr, DataType, Editable,Visible,AllowFilter)
    SELECT DeterminationID, ColumnLabel, 1, ROW_NUMBER() OVER(ORDER BY DeterminationID), 'boolean', 1, 1,0
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
						SELECT ST.SampleTestID, S.SampleName, S.ReferenceCode, Total = '+ CAST(@totalRowsWithoutFilter AS NVARCHAR(MAX))+' FROM LD_SampleTest ST
						JOIN LD_Sample S ON S.SampleID  = ST.SampleID
						WHERE ST.TestID = @TestID
					';
	END	
	ELSE
	BEGIN
		SET 
			@Query = ';WITH CTE AS 
						(	
							SELECT ST.SampleTestID, S.SampleName, S.ReferenceCode, '+ @DeterminationColumns+', Total = '+ CAST(@totalRowsWithoutFilter AS NVARCHAR(MAX))+' FROM LD_SampleTest ST
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
    ORDER BY SampleName
    OFFSET @Offset ROWS
    FETCH NEXT @PageSize ROWS ONLY';

    SET @Offset = @PageSize * (@Page -1);
	PRINT @QUERY;
    EXEC sp_executesql @Query,N' @Offset INT, @PageSize INT, @TestID INT', @Offset, @PageSize, @TestID;

	
	--Insert other columns
	INSERT INTO @TblColumns(ColumnID,ColumnLabel,ColumnNr,ColumnType,DataType,Editable,Visible,AllowFilter)
	VALUES
	('SampleTestID','SampleTestID',1,0,'integer',0,0,1),
	('SampleName','Sample',2,0,'string',0,1,1),
	('ReferenceCode','QRCode',3,0,'string',1,1,1);
    
    SELECT
		ColumnID,
		ColumnLabel, 	   
		AllowFilter, 
		ColumnNr = ROW_NUMBER() OVER(ORDER BY ColumnType, ColumnNr),
		DataType,
		Editable,
		Visible
    FROM @TblColumns
    ORDER BY ColumnType, ColumnNr;	
END

GO


/*
Author					Date			Description
Binod Gurung			2021/06/08		Get sample plot information for selected test
===================================Example================================
EXEC [PR_LFDISK_GetSampleMaterial] 12692,1,100,'',20
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
	DECLARE @ColumnTable TABLE(ColumnID NVARCHAR(MAX), Label NVARCHAR(MAX),[Order] INT, IsVisible BIT, AllowFilter BIT, DataType NVARCHAR(MAX), Editable BIT);
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

	INSERT @ColumnTable(ColumnID, Label, [Order], IsVisible,AllowFilter,DataType,Editable)
	VALUES  ('SampleID', 'SampleID', 0, 0 ,0, 'integer', 0),
			('SampleName', 'Sample', 1, 1, 1, 'string', 0);

	IF(@ImportLevel = 'PLOT')
	BEGIN
		INSERT @ColumnTable(ColumnID, Label, [Order], IsVisible, AllowFilter, DataType, Editable)
		VALUES  
		('FEID', 'FEID', 2, 1, 1,'string',0),
		('Plot name', 'Plot name', 3, 1, 1,'string',0);
	END
	ELSE
	BEGIN
		INSERT @ColumnTable(ColumnID, Label, [Order], IsVisible, AllowFilter, DataType, Editable)
		VALUES  
		('GID', 'GID', 2, 1, 1,'string',0),
		('Origin', 'Origin', 3, 1, 1,'string',0),
		('Female code', 'Female code', 4, 1, 1,'string',0);
		
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

	
	EXEC sp_executesql @Query, N'@TestID INT, @ImportLevel NVARCHAR(MAX)', @TestID, @ImportLevel;	

	PRINT @Query;

	SELECT * FROM @ColumnTable ORDER BY [Order]


END
