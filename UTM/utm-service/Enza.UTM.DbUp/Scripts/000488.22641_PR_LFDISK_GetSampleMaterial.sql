
/*
Author					Date			Description
Binod Gurung			2021/06/08		Get sample plot information for selected test
===================================Example================================
EXEC [PR_LFDISK_GetSampleMaterial] 12655,1,100,'',20
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
	DECLARE @ReCalculate BIT, @ImportLevel NVARCHAR(20), @Offset INT;
	DECLARE @ColumnTable TABLE(ColumnID NVARCHAR(MAX), Label NVARCHAR(MAX),[Order] INT, IsVisible BIT);

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
			('SampleName', 'SampleName', 1, 1),
			('GID', 'GID', 2, 1),
			('Plot name', 'Plot name', 3, 1);

	SET @Query = ';WITH CTE AS
	(

		
	SELECT 
		S.SampleID,
		S.SampleName,
		GID = ISNULL(T3.GID,''''),
		Plotname = ISNULL(T3.[Plot name],'''')
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
				WHERE C.ColumLabel IN(''GID'', ''Plot name'')
			) T1
			PIVOT
			(
				Max(CellValue)
				FOR [ColumLabel] IN ([GID], [Plot name])
			) T2
	) T3 ON T3.MaterialKey = M.MaterialKey AND T3.TestID = ST.TestID
	WHERE ST.TestID = @TestID '+@FilterQuery+' ), Count_CTE AS (SELECT COUNT([SampleID]) AS [TotalRows] FROM CTE) 

	SELECT CTE.*, Count_CTE.[TotalRows] FROM CTE, COUNT_CTE
	ORDER BY CTE.[SampleID]
	OFFSET ' + CAST(@Offset AS NVARCHAR) + ' ROWS
	FETCH NEXT ' + CAST (@PageSize AS NVARCHAR) + ' ROWS ONLY'

	EXEC sp_executesql @Query, N'@TestID INT', @TestID;	

	SELECT * FROM @ColumnTable ORDER BY [Order]

END
