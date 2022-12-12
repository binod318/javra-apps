
/*
Author					Date				Description
KRIAHNA GAUTAM			2019-Apr-25			Change of query after implementation of new table TestTypeDetermination for marker of testtype s2s.	
KRIAHNA GAUTAM			2021/07/08			#24004: Changed query because earlier query was not taking proper index and causing timeout.		 

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
	--	SELECT DISTINCT	
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
	ORDER BY C.ColumnID

END


GO