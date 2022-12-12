DROP PROCEDURE IF EXISTS PR_SH_Get_TraitDeterminationResult
GO
/*
EXEC PR_SH_Get_TraitDeterminationResult 200, 1, NULL, ''
EXEC PR_SH_Get_TraitDeterminationResult 200, 1, 'CF', ''
*/
CREATE PROCEDURE [dbo].[PR_SH_Get_TraitDeterminationResult]
(
	@PageSize	INT,
	@PageNumber INT,
	@Crops NVARCHAR(MAX),
	@Filter NVARCHAR(MAX)
)
AS
BEGIN
	DECLARE @Offset INT;
	SET @Offset = @PageSize * (@PageNumber -1);
	DECLARE @SQL NVARCHAR(MAX);
	DECLARE @CropCodes NVARCHAR(MAX);


	SELECT @CropCodes = COALESCE(@CropCodes + ',', '') + ''''+ T.[value] +'''' FROM 
	string_split(@Crops,',') T

	--PRINT @CropCodes

	IF(ISNULL(@Filter,'') <> '') BEGIN
	SET @Filter =' WHERE '+ @Filter;
	END

	ELSE BEGIN
		SET @Filter = '';
	END

	SET @SQL = N'
	;WITH CTE AS
	(
		SELECT * FROM 
		(
			SELECT 
				TDR.SHTraitDetResultID AS ID,
				Crop = CT.CropCode,
				CT.CropTraitID,
				Trait = T.ColumnLabel,
				D.DeterminationID,
				Determination = D.DeterminationName,
				D.DeterminationAlias,
				TDR.SampleType,				
				MappingCol,				
				ListOfValues = CAST(ISNULL(T.ListOfValues, 0) AS BIT),
				RTD.RelationID
			FROM SHTraitDetResult TDR
			JOIN RelationTraitDetermination RTD ON TDR.RelationID = RTD.RelationID
			JOIN CropTrait CT ON CT.CropTraitID = RTD.CropTraitID
			JOIN Determination D ON D.DeterminationID = RTD.DeterminationID
			JOIN Trait T ON T.TraitID = CT.TraitID
			WHERE T.Property = 0 AND CT.CropCode in ('+@CropCodes+')
		) AS T ' +@Filter +' 
	), CTE_COUNT AS
	(
		SELECT COUNT(ID) AS TotalRows FROM CTE
	)

	SELECT * FROM CTE, CTE_COUNT'

	SET @SQL = @SQL + '	ORDER BY CTE.Crop, CTE.Trait, CTE.CropTraitID
	OFFSET @Offset ROWS
	FETCH NEXT @PageSize ROWS ONLY';

	--PRINT @SQL;
	EXEC sp_executesql @SQL, N'@Offset INT, @PageSize INT', @Offset,@PageSize;
END

GO

DROP PROCEDURE IF EXISTS PR_SH_SaveTraitDeterminationResult
GO

CREATE PROCEDURE [dbo].[PR_SH_SaveTraitDeterminationResult]
(
	@TVP		TVP_SHTraitDeterminationResult READONLY
) AS BEGIN
	SET NOCOUNT ON;

	IF EXISTS(SELECT R.SHTraitDetResultID FROM @TVP T
	JOIN SHTraitDetResult R ON  ISNULL(T.MappingCol,'') = ISNULL(R.MappingCol,'') AND ISNULL(T.SampleType,'') = ISNULL(R.SampleType,'') AND ISNULL(T.RelationID,0) = ISNULL(R.RelationID,0)
	WHERE T.Action = 'I')
	BEGIN		
		EXEC PR_ThrowError 'Cannot insert duplicate value.';
		RETURN;

	END

	--merge statement
	MERGE INTO SHTraitDetResult T
	USING @TVP S ON S.SHTraitDetResultID = T.SHTraitDetResultID
	WHEN MATCHED AND S.[Action] = 'U' THEN
	UPDATE SET			
			T.MappingCol = (CASE WHEN ISNULL(S.MappingCol,'') <> '' THEN S.MappingCol ELSE NULL END),
			T.SampleType = (CASE WHEN ISNULL(S.SampleType,'') <> '' THEN S.SampleType ELSE NULL END)			
	WHEN MATCHED AND S.[Action] = 'D' THEN
	DELETE
	WHEN NOT MATCHED AND S.[Action] = 'I'
	THEN INSERT (RelationID, MappingCol, SampleType)
	VALUES 
	(
		S.RelationID,		
		(CASE WHEN ISNULL(S.MappingCol,'') <> '' THEN S.MappingCol ELSE NULL END),		
		(CASE WHEN ISNULL(S.SampleType,'') <> '' THEN S.SampleType ELSE NULL END)
	);

END

GO