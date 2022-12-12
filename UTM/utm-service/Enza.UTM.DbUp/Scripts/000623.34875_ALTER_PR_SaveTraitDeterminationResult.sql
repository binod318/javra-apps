/*
Author					Date			Description
Krishna Gautam			2022/04/01		#34875: Validation added for duplicate value.
===================================Example================================

*/

ALTER PROCEDURE [dbo].[PR_SaveTraitDeterminationResult]
(
	@CropCode	NCHAR(2),
	@TVP		TVP_TraitDeterminationResult READONLY
) AS BEGIN
	SET NOCOUNT ON;

	--check if same realtion have a mapping with different traitresult
	IF EXISTS
	(	
		SELECT 
			T1.TraitDeterminationResultID  
		FROM TraitDeterminationResult T1
		JOIN @TVP T2 ON T1.RelationID = T2.RelationID AND T1.DetResChar = T2.DetResChar AND T2.[Action] = 'I'
	)
	BEGIN
		EXEC PR_ThrowError N'Unable to insert record. Mapping already exists with different value.';
		RETURN;
	END

	----validation check if value if determination value is changed but that value already have mapping
	IF EXISTS
	(
		SELECT 
			T1.TraitDeterminationResultID 
		FROM TraitDeterminationResult T1
		JOIN @TVP T2 ON T1.RelationID = T2.RelationID  AND T2.[Action] = 'U' AND T2.DetResChar = T1.DetResChar AND T1.TraitDeterminationResultID <> T2.TraitDeterminationResultID
	) BEGIN
		EXEC PR_ThrowError N'Unable to update record.Mapping already exists with same value.';
		RETURN;
	END
	
	

	--New Insert
	INSERT INTO TraitDeterminationResult(RelationID, TraitResChar, DetResChar)
	SELECT T1.RelationID, T1.TraitResChar, T1.DetResChar
	FROM @TVP T1
	LEFT JOIN TraitDeterminationResult T2 ON T2.RelationID = T1.RelationID AND T2.TraitResChar = T1.TraitResChar AND T2.DetResChar = T1.DetResChar
	WHERE T2.TraitDeterminationResultID IS NULL
	AND T1.[Action] = 'I'

	--Update existing
	UPDATE T2 SET
		T2.TraitResChar = T1.TraitResChar,
		T2.DetResChar = T1.DetResChar
	FROM @TVP T1
	JOIN TraitDeterminationResult T2 ON T2.TraitDeterminationResultID = T1.TraitDeterminationResultID
	WHERE T1.[Action] = 'U'
	AND NOT EXISTS
	(
		SELECT TraitDeterminationResultID FROM TraitDeterminationResult
		WHERE RelationID = T1.RelationID
		AND TraitResChar = T1.TraitResChar
		AND DetResChar = T1.DetResChar
	)

	--Delete existing
	DELETE R
	FROM TraitDeterminationResult R 
	JOIN @TVP T1 ON T1.TraitDeterminationResultID = R.TraitDeterminationResultID
	WHERE T1.[Action] = 'D';
END
