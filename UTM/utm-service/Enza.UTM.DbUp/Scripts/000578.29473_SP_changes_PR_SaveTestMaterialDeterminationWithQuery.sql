/*
Author:			KRISHNA GAUTAM
Created Date:	2017-DEC-05
Updated Date:	2071-DEC-06
Description:	Save test material determination. */

/*
=================Example===============
DECLARE @T1 TVP_Determinations
INSERT INTO @T1 VALUES(1);
INSERT INTO @T1 VALUES(2);
--EXEC PR_SaveTestMaterialDeterminationWithQuery 38,'KATHMANDU\dsuvedi', 1, '[960],[crop]', '[960]   LIKE  ''%9%''   and [Crop]   LIKE  ''%TO%'''
EXEC PR_SaveTestMaterialDeterminationWithQuery 13679,'TO', 13797, '''Numerical ID''','[Numerical ID] LIKE ''%100%''', @T1
*/
ALTER PROCEDURE [dbo].[PR_SaveTestMaterialDeterminationWithQuery]
(
	@FileID			INT,	
	--@UserID			NVARCHAR(50),
	@CropCode		NVARCHAR(10),
	@TestID			INT,
	@Columns		NVARCHAR(MAX) = NULL,
	@Filter	NVARCHAR(MAX) = NULL,
	@Determinations TVP_Determinations READONLY
) AS BEGIN
	SET NOCOUNT ON;
	DECLARE @ColumnQuery	NVARCHAR(MAX);
	DECLARE @Query			NVARCHAR(MAX);
	DECLARE @FilterClause	NVARCHAR(MAX)
	DECLARE @ColumnIDs		NVARCHAR(MAX);
	DECLARE @SelectColumns	NVARCHAR(MAX);
	DECLARE @TraitIDs		NVARCHAR(MAX);
	DECLARE @Tbl			TABLE (MaterialID INT, MaterialKey NVARCHAR(50));
	DECLARE @ColumnTable	TABLE([ColumnID] INT, [ColumnName] NVARCHAR(100));
	DECLARE @MaterialTable	TABLE(MaterialKey NVARCHAR(100));
	DECLARE @RequestingSystem	NVARCHAR(MAX);


	SELECT @RequestingSystem = T.RequestingSystem FROM Test T WHERE T.TestID = @TestID;
	
	IF(@RequestingSystem = 'External')
	BEGIN
		SELECT @Filter = REPLACE(@Filter,'Numerical ID','GID');
		SELECT @Filter = REPLACE(@Filter,'Sample Name','Plant Name');

		SELECT @Columns = REPLACE(@Columns,'Numerical ID','GID');
		SELECT @Columns = REPLACE(@Columns,'Sample Name','Plant Name');

	END

	IF(ISNULL(@Filter,'') <> '') BEGIN
		SET @FilterClause = ' AND '+ @Filter
	END
	ELSE BEGIN
		SET @FilterClause = '';

	END


	IF(ISNULL(@Columns,'') <> '') BEGIN
		SET @ColumnQuery = N'
			SELECT ColumnID,ColumnName 
			FROM 
			(
				SELECT ColumnID,COALESCE(CAST(TraitID AS NVARCHAR) ,ColumLabel,'''') as ColumnName FROM [COLUMN]
				WHERE FileID = @FileID 
			) AS T			
			WHERE ColumnName in ('+@Columns+');';

			PRINT @ColumnQuery;

		INSERT INTO @ColumnTable ([ColumnID],[ColumnName])
		EXEC sp_executesql @ColumnQuery, N'@FileID INT', @FileID;
		
		SELECT 
			@SelectColumns  = COALESCE(@SelectColumns + ',', '') + QUOTENAME([ColumnID])+ ' AS ' + QUOTENAME([ColumnName]),
			@ColumnIDs = COALESCE(@ColumnIDs + ',', '') + QUOTENAME([ColumnID])
		FROM @ColumnTable
		
		SET @Query = N'		
		SELECT R.[MaterialKey]
		FROM [ROW] R		
		LEFT JOIN 
		(
			SELECT PT.[MaterialKey], PT.[RowNr], ' + @SelectColumns + ' 
			FROM
			(
				SELECT *
				FROM 
				(
					SELECT 
						T3.[MaterialKey],T3.RowNr,T1.[ColumnID], T1.[Value]
					FROM [Cell] T1
					JOIN [Column] T2 ON T1.ColumnID = T2.ColumnID
					JOIN [Row] T3 ON T3.RowID = T1.RowID
					JOIN [FILE] T4 ON T4.FileID = T3.FileID
					WHERE T2.FileID = @FileID --AND T4.UserID = @UserID
				) SRC
				PIVOT
				(
					Max([Value])
					FOR [ColumnID] IN (' + @ColumnIDs + ')
				) PIV
			) AS PT 					
		) AS T1	ON R.[MaterialKey] = T1.MaterialKey  				
			WHERE R.FileID = @FileID ' + @FilterClause + '';

		

		INSERT INTO @MaterialTable ([MaterialKey])		
		--EXEC sp_executesql @Query, N'@FileID INT, @UserID NVARCHAR(100)', @FileID,@UserID;
		EXEC sp_executesql @Query, N'@FileID INT', @FileID;
	END
	ELSE BEGIN 
		INSERT INTO @MaterialTable ([MaterialKey])
		SELECT R.[MaterialKey]
		FROM [ROW] R
		WHERE R.FileID = @FileID	
	END;

	INSERT INTO @Tbl (MaterialID , MaterialKey)
	SELECT M.MaterialID, M.MaterialKey 
	FROM Material M
	JOIN @MaterialTable M2 ON M2.MaterialKey = M.MaterialKey;

		
	MERGE INTO TestMaterialDetermination T
	USING 
	( 
		SELECT 
			M.MaterialID, D.DeterminationID 
		FROM @Tbl M 
		CROSS JOIN 
		(
			SELECT DeterminationID  
			FROM @Determinations 
			GROUP BY DeterminationID
		) D 
		
	) S
	ON T.MaterialID = S.MaterialID AND T.TestID = @TestID AND T.DeterminationID = S.DeterminationID
	WHEN NOT MATCHED THEN 
	INSERT(TestID,MaterialID,DeterminationID) VALUES(@TestID,S.MaterialID,s.DeterminationID);
END
