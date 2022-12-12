DROP PROCEDURE IF EXISTS [dbo].[PR_SH_GetSampleMaterial]
GO

/*
Author					Date			Description
Binod Gurung			2021/06/08		Get sample plot information for selected test
===================================Example================================
EXEC [PR_SH_GetSampleMaterial] 14772,1,100,''
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
	DECLARE @ReCalculate BIT, @FileID INT, @ImportLevel NVARCHAR(20), @Offset INT, @TotalRowsWithoutFilter NVARCHAR(MAX);
	DECLARE @ColumnTable TVP_ColumnDetail;
	DECLARE @RequiredColumns NVARCHAR(MAX), @RequiredColumns1 NVARCHAR(MAX);
	DECLARE @Query NVARCHAR(MAX), @SubQuery NVARCHAR(MAX), @Editable BIT, @SampleType NVARCHAR(MAX);

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

	SELECT @ReCalculate = RearrangePlateFilling, @FileID = FileID, @ImportLevel = ImportLevel, @SampleType = LotSampleType, @Editable = CASE WHEN StatusCode >= 500 THEN 0 ELSE 1 END FROM Test WHERE TestID = @TestID
		
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
			('MaterialID', 'MaterialID', 1, 0 ,1, 'integer', 0,150),
			('SampleName', 'Sample', 2, 1, 1, 'string', 0, 150),			
			('SampleTestID', 'SampleID', 3, 1, 1, 'integer', 0, 150),
			('MaterialKey','PhenomeID',4,1,1,'string',0,150);

	IF EXISTS ( SELECT ColumnID FROM [Column] WHERE FileID = @FileID AND ColumLabel = 'MasterNr') 
	BEGIN
		INSERT @ColumnTable(ColumnID, ColumnLabel, [Order], Visible,AllowFilter,DataType,Editable,Width)
		VALUES  ('MasterNr', 'MasterNr', 5, 1, 1,'string',0, 150);
	END

	IF EXISTS ( SELECT ColumnID FROM [Column] WHERE FileID = @FileID AND ColumLabel = 'Plantnumbr') 
	BEGIN
		INSERT @ColumnTable(ColumnID, ColumnLabel, [Order], Visible,AllowFilter,DataType,Editable,Width)
		VALUES  ('Plantnumbr', 'Plantnumbr', 6, 1, 1,'string',0, 150);
	END

	SELECT 
		@RequiredColumns = COALESCE(@RequiredColumns + ',', '') + QUOTENAME(ColumnID),
		@RequiredColumns1 = COALESCE(@RequiredColumns1 + ',', '') + QUOTENAME(ColumnID,'''')
	FROM @ColumnTable WHERE [Order] >= 5;

	IF(ISNULL(@RequiredColumns,'') = NULL)
	BEGIN

		SET @RequiredColumns = '';
		SET @RequiredColumns1 = '';

	END

	IF(ISNULL(@RequiredColumns,'') = '') 
		SET @SubQuery = '' 
	ELSE
		SET @SubQuery = 'LEFT JOIN
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
		) T3 ON T3.MaterialKey = M.MaterialKey AND T3.TestID = ST.TestID
		';
	

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
		ST.SampleTestID,
		M.MaterialKey,
		'+ (CASE WHEN ISNULL(@RequiredColumns,'') = '' THEN '' ELSE ( @RequiredColumns+',' ) END) + '
		Total = '+@TotalRowsWithoutFilter+' 
	FROM [LD_Sample] S
	JOIN [LD_SampleTest] ST ON ST.SampleID = S.SampleID
	JOIN Test T ON T.TestID = ST.TestID
	JOIN [File] F ON F.FileID = T.FileID	
	LEFT JOIN [LD_SampleTestMaterial] STM ON STM.SampleTestID = ST.SampleTestID
	LEFT JOIN [TestMaterial] TM ON TM.MaterialID = STM.MaterialLotID AND TM.TestID = ST.TestID
	LEFT JOIN [MaterialLot] M ON M.MaterialLotID = TM.MaterialID
	' + @SubQuery + '
	WHERE ST.TestID = @TestID AND  T.TestID = @TestID '+@FilterQuery+' ), Count_CTE AS (SELECT COUNT([SampleID]) AS [TotalRows] FROM CTE) 

	SELECT CTE.*, Count_CTE.[TotalRows] FROM CTE, COUNT_CTE
	ORDER BY CTE.[SampleID]
	OFFSET ' + CAST(@Offset AS NVARCHAR) + ' ROWS
	FETCH NEXT ' + CAST (@PageSize AS NVARCHAR) + ' ROWS ONLY';

	EXEC sp_executesql @Query, N'@TestID INT, @SampleType NVARCHAR(MAX)', @TestID, @SampleType;	
	
	SELECT * FROM @ColumnTable ORDER BY [Order]


END
GO


DROP PROCEDURE IF EXISTS [dbo].[PR_SH_GetDataWithMarker]
GO

/*
Author					Date				Description
KRIAHNA GAUTAM			2021-11-16			#22641:SP created.

============Example===================
EXEC [PR_SH_GetDataWithMarker] 14772, 1, 150, ''
EXEC [PR_SH_GetDataWithMarker] 13793, 1, 150, 'SampleName like ''%_%'''
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
	DECLARE @DeterminationColumns NVARCHAR(MAX), @DeterminationColumnIDS NVARCHAR(MAX), @Editable BIT,  @SampleType NVARCHAR(MAX);

    SELECT 
		@FileID = F.FileID,
		@ImportLevel = T.ImportLevel,
		@CropCode = F.CropCode,
		 @SampleType = LotSampleType,
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
							[Delete] = CASE 
											WHEN '+  CAST(@Editable AS NVARCHAR(MAX)) +' = 0 THEN 0
											WHEN (ISNULL(T1.SampleTestID,0) = 0 AND @SampleType = ''seedcluster'') THEN 1
											ELSE 0 
										END,
							ST.SampleTestID, 
							S.SampleName, 
							S.Quantity, 
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
								[Delete] = CASE 
												WHEN '+  CAST(@Editable AS NVARCHAR(MAX)) +' = 0 THEN 0
												WHEN (ISNULL(T1.SampleTestID,0) = 0 AND @SampleType = ''seedcluster'') THEN 1 
												ELSE 0 
											END,
								ST.SampleTestID, 
								S.SampleName, 
								S.Quantity, 
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
	
	--PRINT @Query;
    EXEC sp_executesql @Query,N' @Offset INT, @PageSize INT, @TestID INT,  @SampleType NVARCHAR(MAX)', @Offset, @PageSize, @TestID, @SampleType;

	
	--Insert other columns
	INSERT INTO @TblColumns(ColumnID,ColumnLabel,ColumnNr,ColumnType,DataType,Editable,Visible,AllowFilter,Width)
	VALUES
	('sampleName','Sample',1,0,'string',@Editable,1,1,150),
	('sampleTestID','SampleID',2,0,'integer',0,1,1,100),
	('quantity','Quantity',3,0,'integer',@Editable,1,1,140);
    
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


