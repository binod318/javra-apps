/*
=========Changes====================
Changed By			Date				Description

										Created Stored Procedure	
Krishna Gautam		2021-may-03			#22085:Changes on stored procedure to show OPasParent for all crops with opasparent checked true and hybrid true (earlier it was only shown for crop wiht CMS false and opasparent true and hybrid to true.

========Example=============


DECLARE @P1 TVP_GermPlasm
--INSERT INTO @P1
--SELECT GID FROM Variety WHERE TransferType not in ('Male', 'Female', 'Maintainer');
EXEC [PR_GetGermplasm] 'CF', 1 ,100,@P1, '[StatusCode] IN (100)', NULL, 0
*/

ALTER  PROCEDURE [dbo].[PR_GetGermplasm]
(
	@FileName NVARCHAR(MAX),	
	@PageNumber INT,
	@PageSize INT,
	@TVP_GermPlasm TVP_GermPlasm READONLY,
	@FilterQuery NVARCHAR(MAX) = NULL,
	@Sort NVARCHAR(MAX) = NULL,
	@IsHybrid	BIT = 1
)
AS BEGIN
	
	SET NOCOUNT ON;	
	DECLARE @FileID INT =0, @CropCode NVARCHAR(10)='';
	DECLARE @FilterClause NVARCHAR(MAX);
	DECLARE @Offset INT;
	DECLARE @Query NVARCHAR(MAX),@PivotQuery NVARCHAR(MAX);
	DECLARE @MGIDs NVARCHAR(MAX),@FGIDS NVARCHAR(MAX), @MTGIDS NVARCHAR(MAX);
	DECLARE @PGIDS NVARCHAR(MAX);
	DECLARE @Columns2 NVARCHAR(MAX)
	DECLARE @Columns NVARCHAR(MAX);	
	DECLARE @Columns3 NVARCHAR(MAX), @Columns4 NVARCHAR(MAX);
	DECLARE @ColumnIDs NVARCHAR(MAX);
	DECLARE @columnTable TABLE(TraitID INT,ColumnLabel nvarchar(max), DataType NVARCHAR(MAX), ColumnNr INT, IsTraitColumn BIT);
	DECLARE @fixedCols AS TABLE(ColName NVARCHAR(100), ColName2 NVARCHAR(100));
	DECLARE @Asparent BIT =0;

	If(ISNULL(@FileName,'')<> '') BEGIN
		SELECT @FileID = FileID, @CropCode = CropCode FROM [File] WHERE FileTitle = @FileName
	END
	ELSE BEGIN
		SELECT TOP 1 @FileID = FileID FROM [Row] T1
		JOIN @TVP_GermPlasm T2 ON T1.MaterialKey = T2.GermplasmID
	END


	--IF EXISTS(SELECT * FROM CropRD WHERE CropCode = @CropCode AND HasHybrid = 1 AND HasCms =0 AND HasOp = 1)
	IF EXISTS(SELECT * FROM CropRD WHERE CropCode = @CropCode AND HasOp = 1 AND HasHybrid = 1)
	BEGIN
		SET @Asparent = 1;
	END
	
	IF(ISNULL(@FileID, 0) = 0) BEGIN
		--EXEC PR_ThrowError 'Record not found.';
		RETURN;
	END

	SELECT 
		@MGIDs  = COALESCE(@MGIDs + ',', '') + CAST(MalePar AS NVARCHAR(MAX))
	FROM Variety V
	JOIN @TVP_GermPlasm T ON T.GermplasmID = V.GID
	WHERE MalePar IS NOT NULL;

	SELECT
		@FGIDS  = COALESCE(@FGIDS + ',', '') + CAST(FemalePar AS NVARCHAR(MAX))
	FROM Variety V
	JOIN @TVP_GermPlasm T ON T.GermplasmID = V.GID
	WHERE FemalePar IS NOT NULL
	
	SELECT 		
		@MTGIDS  = COALESCE(@MTGIDS + ',', '') + CAST(ISNULL(Maintainer,0) AS NVARCHAR(MAX))
	FROM Variety V
	WHERE V.GID IN (
		SELECT FemalePar
		FROM Variety V
		JOIN @TVP_GermPlasm T ON T.GermplasmID = V.GID
		WHERE FemalePar IS NOT NULL
	)

	SELECT @PGIDS =  COALESCE(@MGIDS + ',','') + COALESCE(@FGIDS + ',','') + COALESCE(@MTGIDs + ',','');

	--Remove last comma 
	IF(ISNULL(@PGIDS,'') <> '') BEGIN
		SELECT @PGIDS = LEFT (@PGIDS, LEN(@PGIDs) -1);
	END


	IF(ISNULL(@FilterQuery,'')<>'')
	BEGIN
		SET @FilterClause = ' AND ('+ @FilterQuery + ')';
	END
	ELSE
	BEGIN
		SET @FilterClause = '';
	END

	IF(ISNULL(@Sort,'') <> '') BEGIN
		SET @Sort =' ORDER BY '+ @Sort;
	END
	ELSE BEGIN
		SET @Sort = 'ORDER BY CTE.[RowID] DESC';
	END

	SET @Offset = @PageSize * (@PageNumber -1);


	INSERT INTO @fixedCols(ColName, ColName2) 
	VALUES ('GID', 'GID'),
	('Name','Name'),
	('ENumber', 'E-number'),		
	('GenerationCode', 'Gen'), 
	('StembookShort', 'Pedigree'), 
	('MasterNr', 'MasterNr'),
	('PONumber', 'PO nr'), 
	('Stem', 'Stem'), 
	('PlasmaType', 'Plasma typ'), 
	('CMSSource', 'CMS source'), 
	('GMS', 'GMS'), 
	('RestorerGenes', 'Rest.genes'),	
	('VarietyName','Variety'),
	('Status','Status');
	
	SELECT 
		@Columns  = COALESCE(@Columns + ',', '') +'CAST(' + QUOTENAME(ColumnID) + ' AS ' + C.[Datatype] + ')' + ' AS ' + ISNULL(QUOTENAME(TraitID), QUOTENAME(ColumLabel)),
		@Columns2  = COALESCE(@Columns2 + ',', '') + ISNULL(QUOTENAME(TraitID), QUOTENAME(ColumLabel)),
		@ColumnIDs  = COALESCE(@ColumnIDs + ',', '') + QUOTENAME(ColumnID)
	FROM [Column] C
	WHERE FileID = @FileID
	AND NOT EXISTS
	(	
		SELECT ColName 
		FROM @fixedCols 
		WHERE ColName2 = C.ColumLabel
	)
	ORDER BY [ColumnNr] ASC;

	--GET LIST of fixed cols
	SELECT 
		@Columns3  = COALESCE(@Columns3 + ',', '') + QUOTENAME(ColName) + ' AS ' + QUOTENAME(ColName2),
		@Columns4 = COALESCE(@Columns4 + ',', '') +'CTE.'+ QUOTENAME(ColName2)
	FROM @fixedCols
	WHERE ColName NOT IN('Status');--These are fixed but handled manually in different way

	IF(ISNULL(@Columns, '') = '') 
	BEGIN
		--EXEC PR_ThrowError 'At lease 1 columns should be specified';
		--RETURN;
		SET @PivotQuery = '';
		SET @Columns ='';
		SET @Columns2 = '';
	END
	ELSE
	BEGIN
		SET @Columns = N', ' + @Columns;
		SET @Columns2 = N', '+@Columns2;
		DECLARE @Clause NVARCHAR(MAX) ='';
		IF(ISNULL(@PGIDS,'') <> '')
		BEGIN
			SET @Clause = N'WHERE T3.MaterialKey IN (' + @PGIDS + N')';
		END
		ELSE
		BEGIN
			SET @Clause = '';
		END

		SET @PivotQuery = N'LEFT JOIN 
				(
					SELECT PT.[MaterialKey], PT.[RowID] ' + @Columns + N' 
					FROM
					(
						SELECT *
						FROM 
						(
							SELECT 
								T3.[MaterialKey],
								T3.RowID,
								T1.[ColumnID], 
								T1.[Value]
							FROM [Cell] T1
							JOIN [Column] T2 ON T1.ColumnID = T2.ColumnID
							JOIN [Row] T3 ON T3.RowID = T1.RowID
							JOIN [FILE] T4 ON T4.FileID = T3.FileID AND T4.FileId = @FileID
							'
							+@Clause+
							'
						) SRC
						PIVOT
						(
							Max([Value])
							FOR [ColumnID] IN (' + @ColumnIDs + N')
						) PIV
					) AS PT			
				) AS T1	ON R.FileID = @FileID AND R.[MaterialKey] = T1.MaterialKey
				'
	END

	--if PGID is not null then get parent information otherwise get germplasm information
	IF(ISNULL(@PGIDS,'') <> '') BEGIN
	
		SET @Query = N';WITH CTE AS 
		(
			SELECT * FROM
			(
				SELECT 
					R.FileID, 
					R.[RowID], 
					OPAsParent = CAST(CASE WHEN @AsParent = 1 AND T5.TransferType = ''OP'' THEN 1 ELSE 0 END AS BIT), 
					T5.* ' + @Columns2 + '
				FROM [ROW] R 
				JOIN 
				(
					SELECT
						V.VarietyID,
						V.GID AS V_GID, 
						V.NewCropCode AS [NewCrop],
						V.ProdSegCode AS [Prod.Segment],
						V.CountryOfOrigin AS [CntryOfOrigin],
						V.MalePar,
						V.FemalePar,
						V.Maintainer,
						V.LotGid,
						V.TransferType,   
						V.StatusCode,
						[Status] = CASE WHEN V.StatusCode > 100 THEN ISNULL(S2.StatusDescription,s.StatusName) ELSE s.StatusName END,
						V.ReplacedLot,						
						Raciprocated = CAST(ISNULL(V.Raciprocated, 0) AS BIT), '+ 
						@Columns3 + N',						
						CanDelete = CAST(0 AS BIT) --always false
					FROM Variety V
					JOIN [Status] S ON S.StatusCode = V.StatusCode AND S.StatusTable = ''Variety''
					LEFT JOIN [Status] S2 ON S2.StatusCode = V.VarmasStatusCode AND S2.StatusTable = ''VarmasStatus''
					WHERE V.GID IN (' + @PGIDS + N') AND V.CropCode = @CropCode
						
				) T5 ON R.FileID = @FileID AND T5.V_GID = R.MaterialKey
				'+@PivotQuery +
				'			
			) V							
		) 					
		SELECT 
			VarietyID, 
			OPAsParent, 
			CTE.[NewCrop],
			CTE.[CntryOfOrigin], 
			CTE.[Prod.Segment],
			CTE.[MalePar],
			CTE.[FemalePar],
			CTE.[Maintainer],
			CTE.[TransferType],
			CTE.[LotGid],  
			CTE.[StatusCode], 
			CTE.[Status], 
			CTE.ReplacedLot, 
			CTE.Raciprocated,  '+ @Columns4 + ' ' + @Columns2 + N',
			CTE.CanDelete
		FROM CTE'
					
		EXEC sp_executesql @Query, N'@FileID INT, @AsParent BIT,@CropCode NVARCHAR(10)', @FileID, @Asparent,@CropCode
	END
	
	--get germplasm data here
	ELSE BEGIN
		--Filter on all records regardless of hybrid and parents
		IF (@IsHybrid = 0) BEGIN
			
			SET @Query = N';WITH CTE AS 
				(
					SELECT * FROM
					(
						SELECT 
							R.FileID, 
							R.[RowID], 
							OPAsParent = CAST(CASE WHEN @AsParent = 1 AND T5.TransferType = ''OP'' THEN 1 ELSE 0 END AS BIT),  
							T5.* ' + @Columns2 + N'
						FROM [ROW] R 
						JOIN 
						(
							SELECT
								V.VarietyID,
								V.GID AS V_GID, 
								V.NewCropCode AS [NewCrop],
								V.CountryOfOrigin AS [CntryOfOrigin],
								V.ProdSegCode AS [Prod.Segment], 
								V.MalePar,
								V.FemalePar,
								V.Maintainer,
								V.TransferType,
								V.LotGid,  
								V.StatusCode,
								[Status] = CASE WHEN V.StatusCode > 100 THEN ISNULL(S2.StatusDescription,s.StatusName) ELSE s.StatusName END,
								V.ReplacedLot,
								Raciprocated = CAST(ISNULL(V.Raciprocated, 0) AS BIT), '+ 
								@Columns3 + N'
							FROM Variety V
							JOIN [Status] S ON S.StatusCode = V.StatusCode AND S.StatusTable = ''Variety''	
							LEFT JOIN [Status] S2 ON S2.StatusCode = V.VarmasStatusCode AND S2.StatusTable = ''VarmasStatus''
							WHERE V.CropCode = @CropCode
						) T5 ON R.FileID = @FileID AND T5.V_GID = R.MaterialKey
						'
						+@PivotQuery +
						'				
					) V							
					WHERE V.FileID = @FileID ' + @FilterClause + N'
				), Count_CTE AS (SELECT COUNT([RowID]) AS [TotalRows] FROM CTE) 					
				SELECT 
					CTE.VarietyID, 
					CTE.OPAsParent, 
					CTE.[NewCrop],
					CTE.[CntryOfOrigin], 
					CTE.[Prod.Segment],
					CTE.[MalePar],
					CTE.[FemalePar],
					CTE.[Maintainer],
					CTE.[TransferType],
					CTE.[LotGid],
					CTE.[StatusCode], 
					CTE.[Status], 
					CTE.ReplacedLot, 
					CTE.Raciprocated,  '+ @Columns4 + ' ' + @Columns2 + N', 
					--CTE.CanDelete,
					CanDelete = CASE WHEN V.VarietyID > 0 OR V.StatusCode >=200 THEN CAST(0 AS BIT) ELSE CAST(1 AS BIT) END,
					Count_CTE.[TotalRows] 
				FROM CTE
				LEFT JOIN Variety V ON V.MalePar = CTE.GID OR V.FemalePar = CTE.GID OR V.Maintainer = CTE.GID OR (V.LotGID = CTE.GID AND V.GID <> V.LotGID), COUNT_CTE
				' + @Sort + N'
				OFFSET ' + CAST(@Offset AS NVARCHAR) + ' ROWS
				FETCH NEXT ' + CAST (@PageSize AS NVARCHAR) + ' ROWS ONLY
				OPTION (USE HINT ( ''FORCE_LEGACY_CARDINALITY_ESTIMATION'' ))';

			EXEC sp_executesql @Query, N'@FileID INT, @AsParent BIT, @CropCode NVARCHAR(10)', @FileID, @Asparent,@CropCode
	
		END
		ELSE BEGIN
			IF NOT EXISTS(SELECT * FROM @TVP_GermPlasm) BEGIN
				SET @Query = N';WITH CTE AS 
				(
					SELECT * FROM
					(
						SELECT 
							R.FileID, 
							R.RowID,
							OPAsParent = CAST(CASE WHEN @AsParent = 1 AND T5.TransferType = ''OP'' THEN 1 ELSE 0 END AS BIT),  
							T5.* ' + @Columns2 + '
						FROM [ROW] R 
						JOIN 
						(
							SELECT
								V.VarietyID,
								V.GID AS V_GID, 
								V.NewCropCode AS [NewCrop],
								V.CountryOfOrigin AS [CntryOfOrigin],
								V.ProdSegCode AS [Prod.Segment],
								V.MalePar,
								V.FemalePar,
								V.Maintainer,
								V.TransferType,
								V.LotGid,  
								V.StatusCode,
								[Status] = CASE WHEN V.StatusCode > 100 THEN ISNULL(S2.StatusDescription, s.StatusName) ELSE s.StatusName END,
								V.ReplacedLot,
								Raciprocated = CAST(ISNULL(V.Raciprocated, 0) AS BIT), '+ 
								@Columns3 + N',
								CanDelete =  CASE WHEN V.StatusCode < 200 THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END
							FROM Variety V
							JOIN [Status] S ON S.StatusCode = V.StatusCode AND S.StatusTable = ''Variety''
							LEFT JOIN [Status] S2 ON S2.StatusCode = V.VarmasStatusCode AND S2.StatusTable = ''VarmasStatus''
							WHERE V.TransferType NOT IN (''Female'',''Male'',''Maintainer'') AND V.CropCode = @CropCode
						
						) T5 ON T5.V_GID = R.MaterialKey
						'+@PivotQuery+
						'
					) V							
					WHERE V.FileID = @FileID ' + @FilterClause + N'
				), COUNT_CTE AS (SELECT COUNT([RowID]) AS [TotalRows] FROM CTE) 					
				SELECT 
					VarietyID, 
					CTE.OPAsParent, 
					CTE.[NewCrop],
					CTE.[CntryOfOrigin], 
					CTE.[Prod.Segment], 
					CTE.[MalePar],
					CTE.[FemalePar],
					CTE.[Maintainer],
					CTE.[TransferType],
					CTE.[LotGid], 
					CTE.[StatusCode], 
					CTE.[Status], 
					CTE.ReplacedLot, 
					CTE.Raciprocated,  ' + @Columns4 + ' ' + @Columns2 + N', 
					CTE.CanDelete,
					Count_CTE.[TotalRows] 
				FROM CTE, COUNT_CTE
				' + @Sort + N'
				OFFSET ' + CAST(@Offset AS NVARCHAR) + ' ROWS
				FETCH NEXT ' + CAST (@PageSize AS NVARCHAR) + ' ROWS ONLY
				OPTION (USE HINT ( ''FORCE_LEGACY_CARDINALITY_ESTIMATION'' ))';

				EXEC sp_executesql @Query, N'@FileID INT, @AsParent BIT, @CropCode NVARCHAR(10)', @FileID, @Asparent,@CropCode

			END	
		END	
		
		INSERT INTO @columnTable(TraitID,ColumnLabel, DataType, ColumnNr, IsTraitColumn)
		SELECT 
			[TraitID], 
			[ColumLabel] as ColumnLabel, 
			[DataType],
			CASE 
				WHEN [ColumnNr] = 0 THEN [ColumnNr] 
				ELSE ColumnNr + 6 
			END,
			CASE 
				WHEN [TraitID] IS NULL THEN 0 
				ELSE 1 
			END AS IsTraitColumn 
		FROM [Column] C
		WHERE [FileID]= @FileID;


		--add columns in the list which are fixed columns but not available in phenome
		INSERT INTO @columnTable(TraitID, ColumnLabel, DataType, ColumnNr, IsTraitColumn)
		SELECT 
			TraitID, 
			ColumnLabel, 
			DataType, 
			ColumnNr, 
			IsTraitColumn 
		FROM
		(
			VALUES	(NULL, 'NewCrop', 'NVARCHAR(255)', 1, 0),
					(NULL, 'Prod.Segment', 'NVARCHAR(255)', 2, 0),
					(NULL, 'CntryOfOrigin', 'NVARCHAR(255)', 3, 0),
					(NULL, 'FemalePar', 'NVARCHAR(255)', 4, 0),
					(NULL, 'MalePar', 'NVARCHAR(255)', 5, 0),
					(NULL, 'Maintainer', 'NVARCHAR(255)', 6, 0),
					(NULL, 'TransferType', 'NVARCHAR(255)', 9, 0),
					(NULL, 'LotGid', 'NVARCHAR(255)', 9, 0),
					(NULL, 'StatusCode', 'NVARCHAR(255)', 500, 0),
					(NULL, 'Status', 'NVARCHAR(255)', 501, 0)
		) F (TraitID, ColumnLabel, DataType, ColumnNr, IsTraitColumn)
		WHERE NOT EXISTS
		(
			SELECT ColumnLabel
			FROM @columnTable
			WHERE ColumnLabel = F.ColumnLabel
		);

		IF(@Asparent = 1)
		BEGIN
			INSERT INTO @columnTable(TraitID,ColumnLabel, DataType, ColumnNr, IsTraitColumn)
			SELECT TOP 1 NULL,'OPAsParent','NVARCHAR(255)', MAX(ColumnNr+1), 0 
			FROM @columnTable;
		END

		SELECT * FROM @columnTable order by ColumnNr;
	END
END
