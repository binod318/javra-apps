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
	DECLARE @ColumnTable TVP_ColumnDetail;
	DECLARE @RequiredColumns NVARCHAR(MAX), @RequiredColumns1 NVARCHAR(MAX);
	DECLARE @Query NVARCHAR(MAX), @Editable BIT;

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

	SELECT @ReCalculate = RearrangePlateFilling, @ImportLevel = ImportLevel, @Editable = CASE WHEN StatusCode >= 500 THEN 0 ELSE 1 END FROM Test WHERE TestID = @TestID

	--Automatic calculate platefilling for Selection/Crosses
	IF(@ImportLevel = 'CROSSES/SELECTION' AND ISNULL(@ReCalculate,1) = 1 )
	BEGIN
		EXEC PR_LFDISK_Calculate_Sample_Filling @TestID, @TotalPlantsInSample;
	END
	
	--now get total rows without filter value after recalculating.
	SELECT 
		@TotalRowsWithoutFilter = CAST(COUNT(ST.SampleID) AS NVARCHAR(MAX)) 
	FROM [LD_Sample] S
	JOIN [LD_SampleTest] ST ON ST.SampleID = S.SampleID
	JOIN Test T ON T.TestID = ST.TestID
	JOIN [File] F ON F.FileID = T.FileID	
	LEFT JOIN [LD_SampleTestMaterial] STM ON STM.SampleTestID = ST.SampleTestID
	LEFT JOIN [LD_MaterialPlant] MP On MP.MaterialPlantID = STM.MaterialPlantID
	LEFT JOIN [TestMaterial] TM ON TM.TestMaterialID = MP.TestmaterialID
	LEFT JOIN [Material] M ON M.MaterialID = TM.MaterialID
	LEFT JOIN [Row] R ON R.MaterialKey = M.MaterialKey AND R.FileID = F.FileID
	WHERE ST.TestID = @TestID AND T.TestID = @TestID

	INSERT @ColumnTable(ColumnID, ColumnLabel, [Order], Visible,AllowFilter,DataType,Editable,Width)
	VALUES  ('SampleID', 'SampleID', 0, 0 ,0, 'integer', 0,10),
			('MaterialID', 'MaterialID', 0, 0 ,0, 'integer', 0,10),
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
		[Delete] =	CASE 
						WHEN '+  CAST(@Editable AS NVARCHAR(MAX)) +' = 0 THEN 0
						WHEN (ISNULL(STM.SampleTestID,0) <> 0 AND @ImportLevel = ''PLOT'') THEN 1 
						ELSE 0 
					END,
		S.SampleID,
		M.MaterialID,
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
