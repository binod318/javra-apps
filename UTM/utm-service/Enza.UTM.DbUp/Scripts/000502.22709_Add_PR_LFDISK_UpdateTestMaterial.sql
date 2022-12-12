DROP PROCEDURE IF EXISTS [dbo].[PR_LFDISK_UpdateTestMaterial]
GO


/*
Author					Date			Description
Binod Gurung			2021/06/21		Save number of plants in TestMaterial
===================================Example================================
DECLARE @Json NVARCHAR(MAX) = N'[{
									"MaterialID": "70228",
									"NrOfPlants": "2"
								}, {
									"MaterialID": "70229",
									"NrOfPlants": "15"
								}]'
EXEC [PR_LFDISK_UpdateTestMaterial] 12679, @Json
*/
CREATE PROCEDURE [dbo].[PR_LFDISK_UpdateTestMaterial]
(
	@TestID INT,
	@Json NVARCHAR(MAX)
)
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @ImportLevel NVARCHAR(20), @TestTypeID INT, @StatusCode INT;
	DECLARE @Material TABLE(MaterialID INT, NrOfPlants INT);

	IF NOT EXISTS (SELECT TestID FROM Test WHERE TestID = @TestID)
	BEGIN
		EXEC PR_ThrowError 'Invalid test.'; 
		RETURN;
	END

	SELECT @ImportLevel = ImportLevel, @TestTypeID = TestTypeID, @StatusCode = StatusCode FROM Test WHERE TestID = @TestID

	IF (@TestTypeID <> 9)
	BEGIN
		EXEC PR_ThrowError 'Invalid test type.';
		RETURN;
	END

	IF (@ImportLevel <> 'CROSSES/SELECTION')
	BEGIN
		EXEC PR_ThrowError 'Number of Plants can be updated only for Selection/Crosses';
		RETURN;
	END
	
	IF (@StatusCode >= 500)
	BEGIN
		EXEC PR_ThrowError 'Material info can not be updated for test already sent to LIMS.';
		RETURN;
	END

	INSERT @Material(MaterialID, NrOfPlants)
	SELECT MaterialID, NrOfPlants
	FROM OPENJSON(@Json) WITH
	(
		MaterialID	INT '$.MaterialID',
		NrOfPlants	INT '$.NrOfPlants'
	);

	MERGE INTO TestMaterial T
	USING @Material S
	ON T.TestID = @TestID AND S.MaterialID = T.MaterialID
	WHEN MATCHED THEN
		UPDATE 
		SET T.NrOfPlants = S.NrOfPlants;

END
GO


DROP PROCEDURE IF EXISTS [dbo].[PR_LFDISK_GET_Data]
GO


/*
Author							Date				Description
Binod Gurung					2021/06/08			Data for first tab of Assign request screen
=================Example===============
EXEC PR_LFDISK_GET_Data 56,'KATHMANDU\dsuvedi', 1, 3, '[Lotnr]   LIKE  ''%9%''   and [Crop]   LIKE  ''%LT%'''
EXEC PR_LFDISK_GET_Data 12679, 1, 100, ''
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
	DECLARE @Source VARCHAR(20), @PlantsColID INT, @PlantsOrder INT;

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
	PRINT 'fffff';
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
		LEFT JOIN TestMaterial TM ON TM.MaterialID = M.MaterialID				
		WHERE R.FileID = @FileID ' + @FilterClause + '
	), Count_CTE AS (SELECT COUNT([RowID]) AS [TotalRows] FROM CTE) 					
	SELECT CTE.RowID, CTE.MaterialID, CTE.MaterialKey, #plants = CTE.NrOfPlants, '+ @Columns2 + ', Count_CTE.[TotalRows], CTE.Total FROM CTE, COUNT_CTE
	ORDER BY CTE.[RowNr]
	OFFSET ' + CAST(@Offset AS NVARCHAR) + ' ROWS
	FETCH NEXT ' + CAST (@PageSize AS NVARCHAR) + ' ROWS ONLY
	OPTION (USE HINT ( ''FORCE_LEGACY_CARDINALITY_ESTIMATION'' ))';				
	
	EXEC sp_executesql @Query, N'@FileID INT', @FileID;	
	
	--ColumnID
	SELECT @PlantsColID = MAX(ColumnID) FROM @ColumnTable;

	--push all columns one step behind after 2 to put #plants column
	UPDATE @ColumnTable
	SET [Order] = [Order] + 1
	WHERE [Order] >2

	INSERT @ColumnTable(ColumnID, TraitID, ColumnLabel, DataType, Editable, IsVisible, [Order])
	VALUES(ISNULL(@PlantsColID,0) + 1,NULL,'#plants','number',1,1,3);

	SELECT * FROM @ColumnTable ORDER By [Order];

END

GO


