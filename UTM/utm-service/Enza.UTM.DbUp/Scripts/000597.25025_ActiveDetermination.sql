
/*
Author					Date				Description
KRIAHNA GAUTAM			2019-Apr-25			Change of query after implementation of new table TestTypeDetermination for marker of testtype s2s.
Krishna Gautam			2019-Dec-09			Changes for external file import
Krishna Gautam			2019-Dec-09			Recompile added to address parameter sniffing problem.
KRIAHNA GAUTAM			2021-12-21			only provide determination with status active.

=================Example===============
EXEC PR_GetDeterminationsForExternalTests 'LT', 1, 62

*/
ALTER PROCEDURE [dbo].[PR_GetDeterminationsForExternalTests]
(
	@CropCode NVARCHAR(10),
	@TestTypeID INT
) AS BEGIN
	SET NOCOUNT ON;
	SELECT 
		D.DeterminationID,
		DeterminationName = MAX(D.DeterminationName),
		DeterminationAlias = MAX(D.DeterminationAlias),
		ColumnLabel = MAX(D.DeterminationName)
	FROM Determination D	
	JOIN TestTypeDetermination TTD ON TTD.DeterminationID = D.DeterminationID
	JOIN RelationTraitDetermination RTD ON RTD.DeterminationID = D.DeterminationID	
	WHERE D.CropCode = @CropCode 
	AND TTD.TestTypeID = @TestTypeID
	AND D.[Status] = 'ACT'
	GROUP BY D.DeterminationID
	OPTION (RECOMPILE);

END
GO

/*
Author					Date				Description
KRIAHNA GAUTAM			2021-12-21			only provide determination with status active.

===============================
EXEC PR_GET_Determination_All '0010'
*/
ALTER PROCEDURE [dbo].[PR_GET_Determination_All]
(
	@DeterminationName NVARCHAR(100),
	@CropCode NVARCHAR(10)
)
AS
BEGIN
	SELECT TOP 200 DeterminationID,DeterminationName, DeterminationAlias 
	FROM Determination
	WHERE DeterminationName like '%'+ @DeterminationName+'%'
	AND CropCode = @CropCode
	AND [Status] = 'ACT'
END

GO



/*
Author					Date				Description
KRIAHNA GAUTAM			2019-Apr-25			Change of query after implementation of new table TestTypeDetermination for marker of testtype s2s.	
KRIAHNA GAUTAM			2021/07/08			#24004: Changed query because earlier query was not taking proper index and causing timeout.	
KRIAHNA GAUTAM			2021-12-21			only provide determination with status active.

=================Example===============
EXEC PR_GetDeterminations 'LT', 1, 62

*/
ALTER PROCEDURE [dbo].[PR_GetDeterminations]
(
	@CropCode	NVARCHAR(10),
	@TestTypeID	INT,
	@TestID		INT
) AS BEGIN
	SET NOCOUNT ON;
	DECLARE @Source NVARCHAR(20);

	--Earlier query

	--SELECT 
	--	T1.DeterminationID,
	--	T1.DeterminationName,
	--	T1.DeterminationAlias,
	--	T2.ColumnLabel
	--FROM Determination T1
	--JOIN
	--(
	--	SELECT DISTINCT				--need to remove distinct 
	--		--T1.CropCode,
	--		T1.DeterminationID,
	--		T.ColumnLabel,
	--		T2.ColumnNr
	--	FROM RelationTraitDetermination T1
	--	JOIN CropTrait CT ON CT.CropTraitID =T1.CropTraitID
	--	JOIN Trait T ON T.TraitID = CT.TraitID
	--	JOIN 
	--	(
	--		SELECT 
	--			C.TraitID,
	--			C.ColumnNr,
	--			T.RequestingSystem
	--		FROM [Column] C
	--		JOIN [File] F ON F.FileID = C.FileID
	--		JOIN Test T ON T.FileID = F.FileID
	--		WHERE T.TestID = @TestID			
	--	) T2 ON T2.TraitID = CT.TraitID
	--	AND T1.[StatusCode] = 100
	--) T2 
	--ON T2.DeterminationID = T1.DeterminationID
	--JOIN TestTypeDetermination TTD ON TTD.DeterminationID = T1.DeterminationID
	--WHERE T1.CropCode = @CropCode AND TTD.TestTypeID = @TestTypeID
	--ORDER BY T2.ColumnNr
	--OPTION (RECOMPILE);

	--changed query
	SELECT 
		D.DeterminationID,
		D.DeterminationName,
		D.DeterminationAlias,
		C.ColumLabel 
	FROM [Test] T 
	JOIN [File] F ON F.FileID = T.FileID
	JOIN [Column] C ON C.FileID = F.FileID
	JOIN Trait TR ON TR.TraitID = C.TraitID
	JOIN CropTrait CT ON CT.TraitID = TR.TraitID AND CT.CropCode = @CropCode
	JOIN RelationTraitDetermination RTD ON RTD.CropTraitID = CT.CropTraitID AND RTD.StatusCode = 100
	JOIN Determination D ON D.DeterminationID = RTD.DeterminationID
	JOIN TestTypeDetermination TTD ON TTD.DeterminationID = D.DeterminationID AND TTD.TestTypeID = @TestTypeID
	WHERE T.TestID = @TestID
	AND D.[Status] = 'ACT'
	ORDER BY C.ColumnID

END


GO

/*
Author					Date				Description
KRIAHNA GAUTAM			2021-06-09			#22641:SP created.
KRIAHNA GAUTAM			2021-12-21			only provide determination with status active.

=================Example===============
EXEC PR_LFDISK_GetDeterminations 'TO'

*/
ALTER PROCEDURE [dbo].[PR_LFDISK_GetDeterminations]
(	
	@CropCode NVARCHAR(MAX)
)
AS BEGIN
	SET NOCOUNT ON;
	DECLARE @Source NVARCHAR(20);

	SELECT 
		T1.DeterminationID,
		T1.DeterminationName,
		T1.DeterminationAlias,
		ColumnLabel = T1.DeterminationName
	FROM Determination T1	
	JOIN TestTypeDetermination TTD ON TTD.DeterminationID = T1.DeterminationID
	WHERE TTD.TestTypeID = 9
	AND T1.CropCode = @CropCode
	AND T1.[Status] = 'ACT';
	
END

GO


/*
Author					Date				Description
KRIAHNA GAUTAM			2021-11-16			#24838:SP created.
KRIAHNA GAUTAM			2021-12-21			only provide determination with status active.
=================Example===============
EXEC PR_SH_GetDeterminations 'TO'

*/
ALTER PROCEDURE [dbo].[PR_SH_GetDeterminations]
(	
	@CropCode NVARCHAR(MAX)
)
AS BEGIN
	SET NOCOUNT ON;
	DECLARE @Source NVARCHAR(20);

	SELECT 
		T1.DeterminationID,
		T1.DeterminationName,
		T1.DeterminationAlias,
		ColumnLabel = T1.DeterminationName
	FROM Determination T1	
	JOIN TestTypeDetermination TTD ON TTD.DeterminationID = T1.DeterminationID
	WHERE TTD.TestTypeID = 10
	AND T1.CropCode = @CropCode
	AND T1.[Status] = 'ACT';
	
END

GO
