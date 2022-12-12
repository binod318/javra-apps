
/*
Author					Date			Description
Binod Gurung			2021/06/08		Get sample plot information for selected test
===================================Example================================
EXEC [PR_SH_GetSampleMaterial] 13786,1,100,''
EXEC [PR_SH_GetSampleMaterial] 12692,1,100,'SampleName like ''%_%''',20
*/
ALTER PROCEDURE [dbo].[PR_SH_GetSampleMaterial]
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
	DECLARE @Query NVARCHAR(MAX), @Editable BIT, @SampleType NVARCHAR(MAX);

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

	SELECT @ReCalculate = RearrangePlateFilling, @ImportLevel = ImportLevel, @SampleType = LotSampleType, @Editable = CASE WHEN StatusCode >= 500 THEN 0 ELSE 1 END FROM Test WHERE TestID = @TestID

	
	
	--now get total rows without filter value after recalculating.
	SELECT 
		@TotalRowsWithoutFilter = CAST(COUNT(ST.SampleID) AS NVARCHAR(MAX)) 
	FROM [LD_Sample] S
	JOIN [LD_SampleTest] ST ON ST.SampleID = S.SampleID
	JOIN Test T ON T.TestID = ST.TestID
	JOIN [File] F ON F.FileID = T.FileID	
	LEFT JOIN [LD_SampleTestMaterial] STM ON STM.SampleTestID = ST.SampleTestID
	LEFT JOIN [TestMaterial] TM ON TM.MaterialID = STM.MaterialLotID AND TM.TestID = ST.TestID
	LEFT JOIN [MaterialLot] M ON M.MaterialLotID = TM.MaterialID
	
	WHERE ST.TestID = @TestID AND T.TestID = @TestID

	INSERT @ColumnTable(ColumnID, ColumnLabel, [Order], Visible,AllowFilter,DataType,Editable,Width)
	VALUES  ('SampleID', 'SampleID', 0, 0 ,0, 'integer', 0,10),	
			('MaterialID', 'MaterialID', 1, 1 ,1, 'integer', 0,150),
			('SampleName', 'Sample', 2, 1, 1, 'string', 0, 150),			
			('ID','ID',3,1,1,'string',0,150);

	

	SET @Query = ';WITH CTE AS
	(

		
	SELECT		
		[Delete] = CASE 
					WHEN '+  CAST(@Editable AS NVARCHAR(MAX)) +' = 0 THEN 0
					WHEN (ISNULL(STM.SampleTestID,0) <> 0 AND @SampleType = ''seedcluster'') THEN 1 
					ELSE 0
				  END,
		S.SampleID,
		MaterialID = M.MaterialLotID,
		S.SampleName,
		ID = M.MaterialKey,
		Total = '+@TotalRowsWithoutFilter+' 
	FROM [LD_Sample] S
	JOIN [LD_SampleTest] ST ON ST.SampleID = S.SampleID
	JOIN Test T ON T.TestID = ST.TestID
	JOIN [File] F ON F.FileID = T.FileID	
	LEFT JOIN [LD_SampleTestMaterial] STM ON STM.SampleTestID = ST.SampleTestID
	LEFT JOIN [TestMaterial] TM ON TM.MaterialID = STM.MaterialLotID AND TM.TestID = ST.TestID
	LEFT JOIN [MaterialLot] M ON M.MaterialLotID = TM.MaterialID
	
	
	
	WHERE ST.TestID = @TestID AND  T.TestID = @TestID '+@FilterQuery+' ), Count_CTE AS (SELECT COUNT([SampleID]) AS [TotalRows] FROM CTE) 

	SELECT CTE.*, Count_CTE.[TotalRows] FROM CTE, COUNT_CTE
	ORDER BY CTE.[SampleID]
	OFFSET ' + CAST(@Offset AS NVARCHAR) + ' ROWS
	FETCH NEXT ' + CAST (@PageSize AS NVARCHAR) + ' ROWS ONLY'

	
	PRINT @Query;
	EXEC sp_executesql @Query, N'@TestID INT, @SampleType NVARCHAR(MAX)', @TestID, @SampleType;	

	

	SELECT * FROM @ColumnTable ORDER BY [Order]


END
