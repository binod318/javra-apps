
DROP PROCEDURE IF EXISTS PR_RDT_ImportRDTRelation 
GO

DROP TYPE IF EXISTS TVP_TraitDeterminationRelationResult_RDT
GO
/*
Authror					Date				Description
Krishna Gatuam			2021/07/05			#23317: Sp created

============================Example====================================
*/

CREATE TYPE TVP_TraitDeterminationRelationResult_RDT AS TABLE
(

	Crop NVARCHAR(10),
	TraitLabel NVARCHAR(MAX),
	DeterminationLabel NVARCHAR(MAX),
	MaterialStatus NVARCHAR(MAX),
	Minpercent NVARCHAR(MAX),
	MaxPercent NVARCHAR(MAX),
	TraitValue NVARCHAR(MAX),
	DetermiantionValue NVARCHAR(MAX),
	MappingCol NVARCHAR(MAX)
)
GO


CREATE PROCEDURE PR_RDT_ImportRDTRelation
(
	@TVP_TraitDeterminationRelationResult_RDT TVP_TraitDeterminationRelationResult_RDT READONLY
)
AS
BEGIN
	
	DECLARE @RelationTraitDetermination AS TABLE
		(
			CropTraitID INT,
			DeterminationID INT,
			MaterialStatus NVARCHAR(MAX),
			Minpercent DECIMAL(18,3),
			MaxPercent DECIMAL(18,3),
			TraitValue NVARCHAR(MAX),
			DetermiantionValue NVARCHAR(MAX),
			MappingCol NVARCHAR(MAX)

		);

		INSERT INTO @RelationTraitDetermination(CropTraitID,DeterminationID, MaterialStatus, Minpercent, MaxPercent, TraitValue, DetermiantionValue, MappingCol)
		SELECT 
			T.CropTraitID,
			D.DeterminationID,
			R.MaterialStatus, 
			TRY_PARSE(R.Minpercent AS decimal(18,3)), 
			TRY_PARSE(R.MaxPercent AS decimal(18,3)), 
			R.TraitValue,
			R.DetermiantionValue,
			R.MappingCol 
		FROM @TVP_TraitDeterminationRelationResult_RDT R
		JOIN 
		(
			SELECT CT.CropTraitID, CT.CropCode, CT.TraitID, T.ColumnLabel FROM Trait T
			JOIN CropTrait CT ON CT.TraitID = T.TraitID
		) T ON T.ColumnLabel = R.TraitLabel AND T.CropCode = R.Crop
		JOIN Determination D ON D.DeterminationName = R.DeterminationLabel;

		
		MERGE INTO RelationTraitDetermination T		
		USING 
		(
			SELECT CropTraitID,DeterminationID FROM @RelationTraitDetermination
			GROUP BY CropTraitID, DeterminationID
		) S ON S.CropTraitID = T.CropTraitID AND S.DeterminationID = T.DeterminationID
		WHEN NOT MATCHED THEN
		INSERT(CropTraitID,DeterminationID,StatusCode)
		VALUES (S.CropTraitID, S.DeterminationID,100);


		MERGE INTO RDTTraitDetResult T		
		USING 
		(
			SELECT 
				R.RelationID,
				T1.TraitValue, 
				T1.DetermiantionValue, 
				T1.MaterialStatus,
				T1.MinPercent,
				T1.MaxPercent,
				T1.MappingCol
			FROM @RelationTraitDetermination T1
			JOIN RelationTraitDetermination R ON R.CropTraitID = T1.CropTraitID AND R.DeterminationID = T1.DeterminationID
		) S ON S.RelationID = T.RelationID 
			AND ISNULL(T.TraitResult,'') = ISNULL(S.TraitValue,'') 
			AND ISNULL(T.DetResult,'') = ISNULL(S.DetermiantionValue,'')
			AND ISNULL(T.MaterialStatus,'') = ISNULL(S.MaterialStatus,'')
			AND ISNULL(T.MinPercent,0) = ISNULL(S.MinPercent,0)
			AND ISNULL(T.MaxPercent, 0) = ISNULL(S.MaxPercent,0)
			AND ISNULL(T.MappingCol,'') = ISNULL(S.MappingCol,'')
		WHEN NOT MATCHED THEN
		INSERT(RelationID, DetResult, TraitResult, MaterialStatus, MinPercent, MaxPercent, MappingCol)
		VALUES (S.RelationID, S.DetermiantionValue, S.TraitValue, S.MaterialStatus, S.MinPercent, S.Maxpercent, S.MappingCol);

		--SELECT * FROM @T1;
		--SELECT * FROM @T2;
END