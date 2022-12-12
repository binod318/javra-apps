/*

Author					Date					Description
KRISHNA GAUTAM			2020-July-10			Get Material and with assigned test data.
KRISHNA GAUTAM			2021-March-17			Show limsID and Nr of plants based on test status and import type.
Krishna Gautam			2021-05-19				#21381: Change in service to display max select.

=================Example===============
EXEC PR_RDT_GetMaterialWithTests 10622,1, 150, '[D_88222] like ''%0%'''
EXEC PR_RDT_GetMaterialWithTests 10639,1, 200, ''

*/

ALTER PROCEDURE [dbo].[PR_RDT_GetMaterialWithTests]
(
	@TestID INT,
	@Page INT,
	@PageSize INT,
	@Filter NVARCHAR(MAX) = NULL
)
AS BEGIN
	SET NOCOUNT ON;

	DECLARE @DetColumns NVARCHAR(MAX),@DetColumnIDs NVARCHAR(MAX), @ImportedColumns NVARCHAR(MAX), @ImportedColumnIDs NVARCHAR(MAX), @AllColumns NVARCHAR(MAX),@DateColumns NVARCHAR(MAX), @LimsIDColumns NVARCHAR(MAX), @NrOfPlantsColumns NVARCHAR(MAX), @MaxSelectColumns NVARCHAR(MAX);

	DECLARE @LimsIDPivotQuery NVARCHAR(MAX) =  '', @NrOfPlantsPivotQuery NVARCHAR(MAX), @MaxSelectPivotQuery NVARCHAR(MAX);

	DECLARE @Offset INT, @FileID INT,@ReturnValue INT, @Query NVARCHAR(MAX),@ImportLevel NVARCHAR(MAX);	
	DECLARE @TblColumns TABLE(ColumnID INT, TraitID VARCHAR(MAX), ColumnLabel NVARCHAR(MAX), ColumnType INT, ColumnNr INT, DataType NVARCHAR(MAX),Updatable BIT,ColumnOrder INT);
	DECLARE @TblTempColumn TABLE(ColumnID INT, TraitID VARCHAR(MAX), ColumnLabel NVARCHAR(MAX), ColumnNr INT, DeterminationCount INT);
	DECLARE @TestStatusCode INT;
	DECLARE @UpdateDetermination BIT = 0, @UpdateDate BIT = 0, @UpdateMaxSelect BIT = 0, @UpdateMaterialStatus BIT = 0;
	

	SELECT 
		@FileID = F.FileID,
		@ImportLevel = T.ImportLevel, 
		@TestStatusCode = T.StatusCode,
		@UpdateDetermination = CASE WHEN T.StatusCode BETWEEN 100 AND 549 THEN 1 ELSE 0 END,
		@UpdateDate = CASE WHEN T.StatusCode = 100 THEN 1 ELSE 0 END,
		@UpdateMaxSelect = CASE WHEN T.StatusCode BETWEEN 450 AND 549 THEN 1 ELSE 0 END,
		@UpdateMaterialStatus = CASE WHEN T.StatusCode = 100 THEN 1 ELSE 0 END
	FROM [File] F
	JOIN Test T ON T.FileID = F.FileID 
	WHERE T.TestID = @TestID;

	--insert into temp table
	INSERT INTO @TblTempColumn(ColumnID, TraitID, ColumnLabel, ColumnNr, DeterminationCount)
	SELECT DeterminationID, TraitID, ColumnLabel, ColumnNr, DeterminationCount
	FROM
	(	
		SELECT 
			T1.DeterminationID,
			T1.DeterminationID AS TraitID,
			ColumnLabel = T4.ColumLabel,
			ColumnNr = MAX(T4.ColumnNR),
			DeterminationCount = COUNT(T1.DeterminationID)
		FROM TestMaterialDetermination T1
		JOIN Determination T2 ON T2.DeterminationID = T1.DeterminationID
		JOIN RelationTraitDetermination T3 ON T3.DeterminationID = T1.DeterminationID
		JOIN CropTrait CT ON CT.CropTraitID = T3.CropTraitID
		JOIN Trait T ON T.TraitID = CT.TraitID
		JOIN [Column] T4 ON T4.TraitID = T.TraitID AND ISNULL(T4.TraitID, 0) <> 0		
		WHERE T1.TestID = @TestID
		AND T4.FileID = @FileID			
		GROUP BY T1.DeterminationID,T4.ColumLabel	
	) V1
	ORDER BY V1.ColumnNr;


	--Determination columns
	INSERT INTO @TblColumns(ColumnID, TraitID, ColumnLabel, ColumnType, ColumnNr, Updatable,DataType,ColumnOrder)
	SELECT 
		ColumnID, CONCAT('D_', TraitID), CONCAT(ColumnLabel , ' (', DeterminationCount ,')'), 5, ColumnNr, @UpdateDetermination, 'Bool',0		
	FROM @TblTempColumn
	order by ColumnNr;
	
	--Get date Columns
	INSERT INTO @TblColumns(ColumnID, TraitID, ColumnLabel, ColumnType, ColumnNr, Updatable, DataType,ColumnOrder)
	SELECT 
		ColumnID, CONCAT('Date_', TraitID), CONCAT(ColumnLabel , ', Exp date'), 4, ColumnNr, @UpdateDate, 'Date',1		
	FROM @TblTempColumn
	order by ColumnNr;

	--Trait and Property columns
	INSERT INTO @TblColumns(ColumnID, TraitID, ColumnLabel, ColumnType, ColumnNr, DataType,Updatable)
	SELECT MAX(ColumnID), TraitID, ColumLabel, 0, MAX(ColumnNr), MAX(DataType), 0
	FROM [Column]
	WHERE FileID = @FileID
	GROUP BY ColumLabel,TraitID
	
	--get Get Determination Column
	SELECT 
		@DetColumns  = COALESCE(@DetColumns + ',', '') + CONCAT(QUOTENAME(MAX(ColumnID)), ' AS ', QUOTENAME(MAX(TraitID))),
		@DetColumnIDs  = COALESCE(@DetColumnIDs + ',', '') + QUOTENAME(MAX(ColumnID))
	FROM @TblColumns
	WHERE ColumnType = 5
	GROUP BY TraitID;

	--insert limsID column
	IF(ISNULL(@TestStatusCode,0) >= 450)
	BEGIN
		INSERT INTO @TblColumns(ColumnID, TraitID, ColumnLabel, ColumnType, ColumnNr,Updatable,DataType,ColumnOrder)
		SELECT TraitID,    CONCAT('limsRefID',TraitID), ColumnLabel+', LimsID', 3, ColumnNr, 0, 'NVARCHAR(MAX)',2 FROM @TblTempColumn ORDER BY ColumnNr;

	END

	--insert NrPlants column and maxselect column
	IF(ISNULL(@TestStatusCode,0) >= 450 AND ISNULL(@ImportLevel,'') <> 'PLT')
	BEGIN
		INSERT INTO @TblColumns(ColumnID, TraitID, ColumnLabel, ColumnType, ColumnNr,Updatable,DataType,ColumnOrder)
		SELECT TraitID,  CONCAT('nrofPlt', TraitID), CONCAT(ISNULL(ColumnLabel,''), ', NrPlts'),  2, ColumnNr, 0, 'NVARCHAR(MAX)',3 FROM @TblTempColumn ORDER BY ColumnNr;

		--insert max select 
		INSERT INTO @TblColumns(ColumnID, TraitID, ColumnLabel, ColumnType, ColumnNr,Updatable,DataType,ColumnOrder)
		SELECT TraitID,  CONCAT('maxSelect', TraitID), CONCAT(ISNULL(ColumnLabel,''), ', MaxSelect'),  1, ColumnNr, 0, 'NVARCHAR(MAX)', 4 FROM @TblTempColumn ORDER BY ColumnNr;

	END

	--get date column
	SELECT 
		@DateColumns  = COALESCE(@DateColumns + ',', '') + CONCAT(QUOTENAME(MAX(ColumnID)), ' AS ', QUOTENAME(MAX(TraitID)))
	FROM @TblColumns
	WHERE ColumnType = 4
	GROUP BY TraitID;


	--get limsid columm
	IF(ISNULL(@TestStatusCode,0) >= 450)
	BEGIN
		SELECT 
			@LimsIDColumns  = COALESCE(@LimsIDColumns + ',', '') + CONCAT(QUOTENAME(MAX(ColumnID)), ' AS ', QUOTENAME(MAX(TraitID)))
			--@LimsIDColumns  = COALESCE(@LimsIDColumns + ',', '') + CONCAT(QUOTENAME(MAX(ColumnID)), ' AS ', QUOTENAME(MAX(TraitID)))
		FROM @TblColumns
		WHERE ColumnType = 3
		GROUP BY TraitID;

		SET @LimsIDPivotQuery = '
			LEFT JOIN 
			(
				SELECT MaterialID, MaterialKey, ' + @LimsIDColumns  + N'
				FROM 
				(
					SELECT T2.MaterialID,T2.MaterialKey, T1.DeterminationID, T1.InterfaceRefID
					FROM [TestMaterialDetermination] T1
					JOIN Material T2 ON T2.MaterialID = T1.MaterialID
					WHERE T1.TestID = @TestID
				) SRC 
				PIVOT
				(
					MAX(InterfaceRefID)
					FOR [DeterminationID] IN (' + @DetColumnIDs + N')
				) PV
				
			) AS TTLimsID			
			ON TTLimsID.MaterialID = M.MaterialID '

	END

	--insert NrPlants column
	IF(ISNULL(@TestStatusCode,0) >= 450 AND ISNULL(@ImportLevel,'') <> 'PLT')
	BEGIN
		SELECT 
			@NrOfPlantsColumns  = COALESCE(@NrOfPlantsColumns + ',', '') + CONCAT(QUOTENAME(MAX(ColumnID)), ' AS ', QUOTENAME(MAX(TraitID)))
		FROM @TblColumns
		WHERE ColumnType = 2
		GROUP BY TraitID;

		SET @NrOfPlantsPivotQuery = '
			LEFT JOIN 
			(
				SELECT MaterialID, MaterialKey, ' + @NrOfPlantsColumns  + N'
				FROM 
				(
					SELECT T2.MaterialID,T2.MaterialKey, T1.DeterminationID, T1.NrPlants
					FROM [TestMaterialDetermination] T1
					JOIN Material T2 ON T2.MaterialID = T1.MaterialID
					WHERE T1.TestID = @TestID
				) SRC 
				PIVOT
				(
					MAX(NrPlants)
					FOR [DeterminationID] IN (' + @DetColumnIDs + N')
				) PV
				
			) AS TTPlantNr			
			ON TTPlantNr.MaterialID = M.MaterialID '

	END

	--insert max select column
	IF(ISNULL(@TestStatusCode,0) >= 450 AND ISNULL(@ImportLevel,'') <> 'PLT')
	BEGIN
		SELECT 
			@MaxSelectColumns  = COALESCE(@MaxSelectColumns + ',', '') + CONCAT(QUOTENAME(MAX(ColumnID)), ' AS ', QUOTENAME(MAX(TraitID)))
		FROM @TblColumns
		WHERE ColumnType = 1
		GROUP BY TraitID;

		SET @MaxSelectPivotQuery = '
			LEFT JOIN 
			(
				SELECT MaterialID, MaterialKey, ' + @MaxSelectColumns  + N'
				FROM 
				(
					SELECT T2.MaterialID,T2.MaterialKey, T1.DeterminationID, T1.MaxSelect
					FROM [TestMaterialDetermination] T1
					JOIN Material T2 ON T2.MaterialID = T1.MaterialID
					WHERE T1.TestID = @TestID
				) SRC 
				PIVOT
				(
					MAX(MaxSelect)
					FOR [DeterminationID] IN (' + @DetColumnIDs + N')
				) PV
				
			) AS TTMaxSelect			
			ON TTMaxSelect.MaterialID = M.MaterialID '

	END

	SELECT 
		@ImportedColumns  = COALESCE(@ImportedColumns + ',', '') + CONCAT(QUOTENAME(ColumnID), ' AS ', QUOTENAME(ISNULL(TraitID,ColumnLabel))),
		@ImportedColumnIDs  = COALESCE(@ImportedColumnIDs + ',', '') + QUOTENAME(ColumnID)
	FROM @TblColumns
	WHERE ColumnType = 0
	--ORDER BY [ColumnNr] ASC;

	SELECT 
		@AllColumns  = COALESCE(@AllColumns + ',', '') +  QUOTENAME(ISNULL(MAX(TraitID), MAX(ColumnLabel))) +' = ISNULL('+QUOTENAME(ISNULL(MAX(TraitID), MAX(ColumnLabel)))+',0)'
	FROM @TblColumns
	WHERE ColumnType IN (2,3,4,5)
	GROUP BY TraitID;


	SELECT 
		@AllColumns  = COALESCE(@AllColumns + ',', '') +  QUOTENAME(ISNULL(MAX(TraitID), MAX(ColumnLabel)))
	FROM @TblColumns
	WHERE ColumnType = 1
	GROUP BY TraitID

	SELECT 
		@AllColumns  = COALESCE(@AllColumns + ',', '') +  QUOTENAME(ISNULL(TraitID, ColumnLabel))
	FROM @TblColumns
	WHERE ColumnType NOT IN (1,2,3,4,5)
	ORDER BY [ColumnNr] ASC;


	IF(ISNULL(@DetColumns,'') = '') BEGIN
		
		SET @Query = N';WITH CTE AS
		(
			SELECT * FROM 
			(
			SELECT M.MaterialID,  TM.MaterialStatus, T1.RowID, T1.MaterialKey,' + @AllColumns + N'
			FROM 
			(
				SELECT MaterialKey, RowID, ' + @ImportedColumns + N'  
				FROM 
				(
					SELECT MaterialKey,RowID,ColumnID,Value
					FROM VW_IX_Cell_Material
					WHERE FileID = @FileID
					AND ISNULL([Value],'''')<>''''
				) SRC
				PIVOT
				(
					Max([Value])
					FOR [ColumnID] IN (' + @ImportedColumnIDs + N')
				) PV
			) AS T1
			JOIN Material M ON M.MaterialKey = T1.MaterialKey
			LEFT JOIN TestMaterial TM ON TM.TestID = @TestID AND TM.MaterialID = M.MaterialID
			) AS T
			WHERE 1= 1
			
			'
	END
	ELSE BEGIN
		SET @Query = N';WITH CTE AS
		(
			SELECT * FROM 
			(
			SELECT M.MaterialID, TM.MaterialStatus, T1.RowID, T1.MaterialKey, ' + @AllColumns + N'
			FROM 
			(
				SELECT MaterialKey, RowID, ' + @ImportedColumns + N'  FROM 
				(
					SELECT MaterialKey,RowID,ColumnID,Value
					FROM VW_IX_Cell_Material
					WHERE FileID = @FileID
					AND ISNULL([Value],'''')<>'''' 
				) SRC
				PIVOT
				(
					Max([Value])
					FOR [ColumnID] IN (' + @ImportedColumnIDs + N')
				) PV
			) AS T1
			
			JOIN Material M ON M.MaterialKey = T1.MaterialKey
			LEFT JOIN TestMaterial TM ON TM.TestID = @TestID AND TM.MaterialID = M.MaterialID

			--determination pivot columns
			LEFT JOIN 
			(
				SELECT MaterialID, MaterialKey, ' + @DetColumns  + N'
				FROM 
				(
					SELECT T2.MaterialID,T2.MaterialKey, T1.DeterminationID
					FROM [TestMaterialDetermination] T1
					JOIN Material T2 ON T2.MaterialID = T1.MaterialID
					WHERE T1.TestID = @TestID
				) SRC 
				PIVOT
				(
					COUNT(DeterminationID)
					FOR [DeterminationID] IN (' + @DetColumnIDs + N')
				) PV
				
			) AS T2			
			ON T2.MaterialID = M.MaterialID

			--date pivot column
			LEFT JOIN 
			(
				SELECT MaterialID, MaterialKey, ' + @DateColumns  + N'
				FROM 
				(
					SELECT T2.MaterialID,T2.MaterialKey, T1.DeterminationID,ExpectedDate = CONVERT(varchar,T1.ExpectedDate,103)
					FROM [TestMaterialDetermination] T1
					JOIN Material T2 ON T2.MaterialID = T1.MaterialID
					WHERE T1.TestID = @TestID
				) SRC 
				PIVOT
				(
					MAX(ExpectedDate)
					FOR [DeterminationID] IN (' + @DetColumnIDs + N')
				) PV
				
			) AS T3			
			ON T3.MaterialID = M.MaterialID

			--LIMSID pivoted query
			'+ISNULL(@LimsIDPivotQuery,'')+'

			--PlantNr pivoted query
			'+ISNULL(@NrOfPlantsPivotQuery,'') +'

			--MaxSelect pivoted query
			'+ISNULL(@MaxSelectPivotQuery,'') +'



			) AS T
			WHERE 1= 1';
		END

		IF(ISNULL(@Filter, '') <> '') BEGIN
			SET @Query = @Query + ' AND ' + @Filter
		END

		SET @Query = @Query + N'
		), CTE_COUNT AS (SELECT COUNT([MaterialID]) AS [TotalRows] FROM CTE)
	
		SELECT MaterialID, MaterialKey, MaterialStatus, ' + @AllColumns + N', NULL AS [Print], CTE_COUNT.TotalRows 
		FROM CTE, CTE_COUNT
		ORDER BY RowID
		OFFSET @Offset ROWS
		FETCH NEXT @PageSize ROWS ONLY
		OPTION (USE HINT ( ''FORCE_LEGACY_CARDINALITY_ESTIMATION'' ))';

		SET @Offset = @PageSize * (@Page -1);

		--SELECT @Query;

		
		
		EXEC sp_executesql @Query,N'@FileID INT, @Offset INT, @PageSize INT, @TestID INT', @FileID, @Offset, @PageSize, @TestID;

		IF(ISNULL(@ImportLevel,'PLT') = 'LIST')
		BEGIN
			INSERT INTO @TblColumns(ColumnLabel, ColumnType, ColumnNr, Updatable,DataType)
			VALUES('MaterialStatus', 0,1,1,'NVARCHAR(255)')
		END

		INSERT INTO @TblColumns(ColumnLabel,ColumnType,ColumnNr,Updatable)
			SELECT 'Print',0, MAX(ColumnNr) +1, 0 FROM @TblColumns;

		SELECT 
			TraitID, 
			ColumnLabel, 
			ColumnType = CASE WHEN ColumnType <> 0 THEN 1 ELSE ColumnType END, 
			ColumnNr, 
			DataType,
			Fixed = CASE WHEN ColumnLabel = 'Crop' OR ColumnLabel = 'GID' OR ColumnLabel = 'Plantnr' OR ColumnLabel = 'Plant name' OR ColumnLabel = 'MaterialStatus' THEN 1 ELSE 0 END,
			Updatable
		FROM @TblColumns T1
		ORDER BY Fixed desc, ColumnType DESC, ColumnNr, ColumnOrder;

		
END
