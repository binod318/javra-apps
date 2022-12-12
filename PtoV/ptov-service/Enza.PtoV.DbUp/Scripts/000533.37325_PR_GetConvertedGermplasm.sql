/*
Author					Date				Description

KRIAHNA GAUTAM			2020-JAN-02			Change on query to allow to see data even if no valid trait columns is available for selected crop.
KRIAHNA GAUTAM			2020-JAN-02			Issue on query for now showing data if there is some column but not trait column issue fixed.
KRIAHNA GAUTAM			2020-March-19		#11780:Issue on query for now showing data if there is some column but not trait column issue fixed.

=================Example===============

DECLARE @P1 TVP_GermPlasm
--INSERT INTO @P1
--SELECT GID FROM Variety WHERE TransferType not in ('Male', 'Female', 'Maintainer');
EXEC [PR_GetConvertedGermplasm] 'ON', 1 ,100, @P1,0
*/

ALTER PROCEDURE [dbo].[PR_GetConvertedGermplasm]
(
	@FileName NVARCHAR(MAX),	
	@PageNumber INT,
	@PageSize INT,
	@TVP_GermPlasm TVP_GermPlasm READONLY,
	@SendToVarmas BIT = 0,
	@FilterQuery NVARCHAR(MAX) = NULL,
	@Sort NVARCHAR(MAX) = NULL,
	@IsHybrid BIT = 1,
	@StatusCode INT = NULL
)
AS BEGIN
	
	SET NOCOUNT ON;	
	DECLARE @FileID INT =0;
	DECLARE @FilterClause NVARCHAR(MAX);
	DECLARE @Offset INT;
	DECLARE @Query NVARCHAR(MAX),@PivotTraitQuery NVARCHAR(MAX),@LeftJoinQuery NVARCHAR(MAX),@FilterParam NVARCHAR(MAX);;
	DECLARE @ParentTable TABLE(GID INT);
	--DECLARE @MGIDs NVARCHAR(MAX),@FGIDS NVARCHAR(MAX),@MTGIDS NVARCHAR(MAX),@PGIDS NVARCHAR(MAX);
	DECLARE @PGIDS NVARCHAR(MAX);
	DECLARE @Columns2 NVARCHAR(MAX),@Traits2 NVARCHAR(MAX);
	DECLARE @Columns NVARCHAR(MAX),@Traits NVARCHAR(MAX);
	DECLARE @Columns3 NVARCHAR(MAX),@Columns4 NVARCHAR(MAX);
	DECLARE @ColumnIDs NVARCHAR(MAX),@TraitIDS NVARCHAR(MAX);
	DECLARE @columnTable TABLE(TraitID INT,ColumnLabel nvarchar(max), DataType NVARCHAR(MAX), ColumnNr INT, IsTraitColumn BIT,RefColumn NVARCHAR(20),ColorCode INT);
	DECLARE @CropCode NVARCHAR(10);
	DECLARE @ExcludeType NVARCHAR(MAX) = '';

	--SET @CropCode = @FileName;

	If(ISNULL(@FileName,'')<> '') BEGIN
		SELECT @FileID = FileID FROM [File] WHERE FileTitle = @FileName
	END
	ELSE BEGIN
		SELECT TOP 1 @FileID = FileID FROM [Row] T1
		JOIN @TVP_GermPlasm T2 ON T1.MaterialKey = T2.GermplasmID
	END

	IF(ISNULL(@FileID, 0) = 0) BEGIN
		--EXEC PR_ThrowError 'Record not found.';
		RETURN;
	END
	
	SELECT @CropCode = CropCode FROM [File] WHERE FileID = @FileID;

	IF(@SendToVarmas = 0) BEGIN
		IF(@IsHybrid =1)
		BEGIN
			SET @ExcludeType =  ' WHERE CropCode = @CropCode AND TransferType NOT IN (''Female'',''Male'',''Maintainer'') AND StatusCode = ISNULL(@StatusCode,100)'
		END
		ELSE
		BEGIN
			SET @ExcludeType =  ' WHERE CropCode = @CropCode AND StatusCode = ISNULL(@StatusCode,100)'
		END
	END
	ELSE BEGIN
		SET @ExcludeType =  ' WHERE CropCode = @CropCode'
	END

	INSERT INTO @ParentTable(GID)
	SELECT 		
		--@MGIDs  = COALESCE(@MGIDs + ',', '') + CAST(MalePar AS NVARCHAR(MAX))
		MalePar
	FROM Variety V
	JOIN @TVP_GermPlasm T ON T.GermplasmID = V.GID
	WHERE MalePar IS NOT NULL;

	INSERT INTO @ParentTable(GID)
	SELECT 		
		--@FGIDS  = COALESCE(@FGIDS + ',', '') + CAST(FemalePar AS NVARCHAR(MAX))
		FemalePar
	FROM Variety V
	JOIN @TVP_GermPlasm T ON T.GermplasmID = V.GID
	WHERE FemalePar IS NOT NULL
	
	INSERT INTO @ParentTable(GID)
	SELECT 		
		--@MTGIDS  = COALESCE(@MTGIDS + ',', '') + CAST(ISNULL(Maintainer,0) AS NVARCHAR(MAX))
		Maintainer
	FROM Variety V
	WHERE V.GID IN (
		SELECT FemalePar
		FROM Variety V
		JOIN @TVP_GermPlasm T ON T.GermplasmID = V.GID
		WHERE FemalePar IS NOT NULL
	)
	

	--SELECT @PGIDS =  COALESCE(@MGIDS + ',','') + COALESCE(@FGIDS + ',','') + COALESCE(@MTGIDs + ',','');
	SELECT @PGIDS = COALESCE(@PGIDs + ',', '') + CAST(GID AS NVARCHAR(MAX))
	FROM @ParentTable WHERE ISNULL(GID,0) <> 0;


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

	DECLARE @fixedCols AS TABLE(ColName NVARCHAR(100), ColName2 NVARCHAR(100));
	INSERT INTO @fixedCols(ColName, ColName2)
	VALUES ('GID', 'GID'),
	('Name','Name'),
	('ENumber', 'E-number'),	
	('FemalePar', 'FemalePar'), 
	('MalePar', 'MalePar'),
	('Maintainer', 'Maintainer'),
	('GenerationCode', 'Gen'), 
	('StembookShort', 'Pedigree'), 
	('MasterNr', 'MasterNr'),
	('PONumber', 'PO nr'), 
	('Stem', 'Stem'), 
	('PlasmaType', 'Plasma typ'), 
	('CMSSource', 'CMS source'), 
	('GMS', 'GMS'), 
	('RestorerGenes', 'Rest.genes'),
	('TransferType', 'TransferType'),	
	('LotGID','LotGID'),
	('VarietyName','Variety');
	
	SELECT 
		@Columns  = COALESCE(@Columns + ',', '') +'CAST(MAX('+ QUOTENAME(ColumnID) +') AS '+ C.[Datatype] +')' + ' AS ' + ISNULL(QUOTENAME(TraitID),QUOTENAME(ColumLabel)),
		@Columns2  = COALESCE(@Columns2 + ',', '') + ISNULL(QUOTENAME(TraitID),QUOTENAME(ColumLabel)),
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

	SELECT 
		@Traits  = COALESCE(@Traits + ',', '') + 'MAX(' + QUOTENAME(ColumLabel) + ') AS ' + QUOTENAME(CAST(TraitID AS NVARCHAR(MAX)) + '_T'),
		@Traits2  = COALESCE(@Traits2 + ',', '') + + QUOTENAME(CAST(TraitID AS NVARCHAR(MAX)) + '_T'),
		@TraitIDS  = COALESCE(@TraitIDS + ',', '') + QUOTENAME(ColumLabel)
	FROM [Column] C
	WHERE FileID = @FileID
	AND NOT EXISTS
	(	
		SELECT ColName 
		FROM @fixedCols 
		WHERE ColName2 = C.ColumLabel
	)
	AND C.TraitID IS NOT NULL
	ORDER BY [ColumnNr] ASC;

	--GET LIST of fixed cols
	SELECT 
		@Columns3  = COALESCE(@Columns3 + ',', '') + QUOTENAME(ColName) + ' AS ' + QUOTENAME(ColName2),
		@Columns4 = COALESCE(@Columns4 + ',', '') + QUOTENAME(ColName2)
	FROM @fixedCols;

	IF(ISNULL(@Columns, '') = '')	
	BEGIN
		SET @Columns = '';
		SET @Columns2 = '';
		SET @Traits = ' ';
		SET @Traits2 = ' ';
		SET @LeftJoinQuery= '';


	END
	ELSE
	BEGIN

		SET @Columns = ',' + @Columns;
		SET @Columns2 = ',' + @Columns2;
		
		IF(ISNULL(@TraitIDS,'') <> '')
		BEGIN
			SET @Traits = ',' + @Traits;
			SET @Traits2 = ',' + @Traits2;
			SET @PivotTraitQuery = ' PIVOT
								(
									Max([CellColorValue])
									FOR [ColumLabel] IN (' + @TraitIDS + ')
								) PIV1';
		END
		ELSE 
		BEGIN
			SET @Traits = ' ';
			SET @Traits2 = ' ';
			SET @TraitIDS = ' ';
			SET @PivotTraitQuery = ''

		END

		IF(ISNULL(@PGIDS,'') <> '')
			SET @FilterParam = ' AND R.Materialkey IN ('+@PGIDS + N')';
		ELSE
			SET @FilterParam = '';
		
		
		SET @LeftJoinQuery = 'LEFT JOIN 
								(
									SELECT PT.[MaterialKey]  ' + @Columns + '  '+ @Traits + N'
									FROM
									(
										SELECT *
										FROM 
										(
											SELECT 
												R.[MaterialKey],
												C1.[ColumnID], 
												C.[ColumLabel],
												CASE WHEN ISNULL(TSR.ScreeningValue,'''') = '''' THEN C1.[Value] ELSE CONCAT (ISNULL(TSR.ScreeningValue,''''), '' ('',C1.[Value] ,'')'') END AS CellValue,			
												CellColorValue = CASE WHEN ISNULL(T.ListOfValues,0) = 0 THEN 0 WHEN TSR.TraitValueChar = C1.[Value] THEN 0 ELSE 1 END
											FROM [File] F
											JOIN [Row] R ON R.FileID = F.FileID
											JOIN [Column] C ON C.FileID = F.FileID
											JOIN [Cell] C1 ON C1.RowID = R.RowID AND C.ColumnID = C1.ColumnID
											LEFT JOIN Trait T ON T.TraitID = C.TraitID	AND T.ListOfValues = 1				
											LEFT JOIN CropTrait CT ON CT.TraitID = T.TraitID AND CT.CropCode = F.CropCode
											LEFT JOIN RelationTraitScreening RTS ON RTS.CropTraitID = CT.CropTraitID
											LEFT JOIN TraitScreeningResult TSR ON TSR.TraitScreeningID = RTS.TraitScreeningID AND TSR.TraitValueChar = C1.[Value]
											WHERE F.FileID = @FileID' +@FilterParam+'
										) SRC
										PIVOT
										(
											Max([CellValue])
											FOR [ColumnID] IN (' + @ColumnIDs + ')
										) PIV'
											+@PivotTraitQuery +
											'
									) AS PT 
				
									GROUP BY PT.[MaterialKey]	
									
								) AS T1	ON R.[MaterialKey] = T1.MaterialKey 
								';



	END

	--if PGID is not null then get parent information otherwise get germplasm information

	IF(ISNULL(@PGIDS,'') <> '') BEGIN
		SET @Query = N';WITH CTE AS 
		(
			SELECT * FROM
			(
				SELECT R.FileID,R.[RowID], T5.* ' + @Columns2 + ' '+@Traits2 +' 
				FROM [ROW] R 
				JOIN 
				(
					SELECT
						VarietyID,
						GID AS V_GID,
						NewCropCode AS [NewCrop],
						CountryOfOrigin AS [Origin Country],
						ProdSegCode AS [Prod.Segment], ' + 
						@Columns3 + N' 
					FROM Variety
					WHERE GID IN ('+@PGIDS+ N')
					AND CropCode = @CropCode
							
				) T5 ON R.FileID = @FileID AND T5.V_GID = R.MaterialKey
				'+@LeftJoinQuery+'
				WHERE R.FIleID = @FileID
			) V	
		)					
		SELECT VarietyID, CTE.[NewCrop],CTE.[Origin Country], CTE.[Prod.Segment], '+ @Columns4 + ' ' + @Columns2 + ' ' + @Traits2 + ' FROM CTE';
		PRINT @Query;
		EXEC sp_executesql @Query, N'@FileID INT,@CropCode NVARCHAR(10)', @FileID,@CropCode

	END

	ELSE BEGIN

		SET @Query = N';WITH CTE AS 
		(
			SELECT * FROM
			(
				SELECT R.FileID,R.[RowID], T5.* ' + @Columns2 + ' '+@Traits2 +' 
				FROM [ROW] R
				JOIN 
				(
					SELECT
						VarietyID,
						GID AS V_GID,
						NewCropCode AS [NewCrop],
						CountryOfOrigin AS [Origin Country],
						ProdSegCode AS [Prod.Segment], ' + 
						@Columns3 + N' 
					FROM Variety
					'+@ExcludeType+N'	
				) T5 ON R.FileID = @FileID AND T5.V_GID = R.MaterialKey
				'+@LeftJoinQuery +'
				WHERE R.FIleID = @FileID
			) V							
			WHERE V.FileID = @FileID ' + @FilterClause + '
		), Count_CTE AS (SELECT COUNT([RowID]) AS [TotalRows] FROM CTE) 					
		SELECT VarietyID, CTE.[NewCrop], CTE.[Origin Country], CTE.[Prod.Segment], '+ @Columns4 + ' ' + @Columns2 + ' ' + @Traits2 + ' , Count_CTE.[TotalRows] FROM CTE, COUNT_CTE
		'+@Sort+
		'
		OFFSET ' + CAST(@Offset AS NVARCHAR) + ' ROWS
		FETCH NEXT ' + CAST (@PageSize AS NVARCHAR) + ' ROWS ONLY';
		PRINT @Query;
		EXEC sp_executesql @Query, N'@FileID INT,@CropCode NVARCHAR(10), @StatusCode INT', @FileID,@CropCode, @StatusCode

		INSERT INTO @columnTable(TraitID,ColumnLabel, DataType, ColumnNr, IsTraitColumn,RefColumn,ColorCode)
		SELECT [TraitID], [ColumLabel] as ColumnLabel, [DataType],
			CASE WHEN [ColumnNr] = 0 THEN [ColumnNr] ELSE ColumnNr + 4 END,
			CASE WHEN [TraitID] IS NULL THEN 0 ELSE 1 END AS IsTraitColumn, CAST(TraitID AS NVARCHAR(20)) + '_T' ,
			CASE WHEN [TraitID] IS NULL THEN 0 ELSE 1 END		
		FROM [Column] C
		WHERE [FileID]= @FileID
		AND NOT EXISTS
		(
			SELECT ColName2 
			FROM @fixedCols 
			WHERE ColName2 = C.ColumLabel
		);

		UPDATE C
		--SET C.ColorCode = CASE WHEN T.ListOfValues = 0 THEN 0 WHEN ISNULL(RTS.TraitScreeningID,0) = 0 THEN 1 ELSE 0 END,
		SET C.ColorCode = CASE WHEN ISNULL(RTS.TraitScreeningID,0) = 0 THEN 1 ELSE 0 END,
		C.ColumnLabel = CASE WHEN ISNULL(SF.SFColumnLabel,'') = '' THEN C.ColumnLabel ELSE CONCAT(SF.SFColumnLabel,' (', C.ColumnLabel,')') END --ISNULL(SF.SFColumnLabel,C.ColumnLabel)
		FROM @columnTable C
		JOIN Trait T ON T.TraitID = C.TraitID
		JOIN CropTrait CT ON CT.TraitID = T.TraitID
		LEFT JOIN RelationTraitScreening RTS ON RTS.CropTraitID = CT.CropTraitID
		LEFT JOIN ScreeningField SF ON SF.ScreeningFieldID = RTS.ScreeningFieldID
		WHERE CT.CropCode =@CropCode;

		INSERT INTO @columnTable(TraitID,ColumnLabel, DataType, ColumnNr, IsTraitColumn,RefColumn,ColorCode)
		VALUES(NULL,'NewCrop','NVARCHAR(255)',1,0,NULL,0),
		(NULL,'Prod.Segment','NVARCHAR(255)',2,0,NULL,0); --Note: Please don't change the character case of ColumnLabel here. case here is very important for UI
		
		--add country of origin column
		INSERT INTO @columnTable(TraitID,ColumnLabel, DataType, ColumnNr, IsTraitColumn,RefColumn,ColorCode)
		VALUES(NULL,'Origin Country','NVARCHAR(255)',3,0,NULL,0);

		----add enumber column
		--INSERT INTO @columnTable(TraitID,ColumnLabel, DataType, ColumnNr, IsTraitColumn,RefColumn,ColorCode)
		--VALUES(NULL,'ENumber','NVARCHAR(255)',4,0,NULL,0);

		--add fixed columns as well
		INSERT INTO @columnTable(TraitID,ColumnLabel, DataType, ColumnNr, IsTraitColumn,RefColumn,ColorCode)
		SELECT NULL, ColName2, 'NVARCHAR(255)', 4, 0,NULL,0
		FROM @fixedCols C
		WHERE NOT EXISTS
		(
			SELECT ColumnLabel 
			FROM @columnTable 
			WHERE ColumnLabel  = C.ColName
		);

		SELECT 
			T1.*,
			T2.ScreeningFieldNr 
		FROM @columnTable T1
		LEFT JOIN
		(
			SELECT 
				CT.TraitID,
				SF.ScreeningFieldNr
			FROM CropTrait CT
			JOIN RelationTraitScreening RTS ON RTS.CropTraitID = CT.CropTraitID
			JOIN ScreeningField SF ON SF.ScreeningFieldID = RTS.ScreeningFieldID
			WHERE CT.CropCode = @CropCode
		) T2 ON T2.TraitID = T1.TraitID
		ORDER BY T1.ColumnNr;

	END
	
END

