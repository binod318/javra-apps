ALTER PROCEDURE [dbo].[PR_RDT_GetMappingMissingScore]
(
	@TestID INT
)
AS 
BEGIN
	DECLARE @CropCode NVARCHAR(MAX), @TestName NVARCHAR(MAX);
	DECLARE @FlowType INT;
	DECLARE @ConversionFound TABLE (RDTTestResultID INT);
	

	SELECT @CropCode = CropCode, @FlowType = TestFlowType, @TestName = T.TestName
	FROM [File] F 
	JOIN Test T ON T.FileID = F.FileID
	WHERE T.TestID = @TestID;

	--IF(@FlowType = 1)
	--BEGIN
		
	--	SELECT
	--		Cropcode = @CropCode,
	--		T.TestName,
	--		D.DeterminationName,
	--		T1.ColumnLabel,
	--		TR.Score,
	--		MappingColumn,
	--		TR.RDTTestResultID
	--	FROM Test T
	--	JOIN TestMaterial TM ON TM.TestID = T.TestID
	--	JOIN Material M ON M.MaterialID = TM.MaterialID
	--	JOIN RDTTestResult TR ON TR.TestID = T.TestID AND M.MaterialID = TR.MaterialID
	--	JOIN RelationTraitDetermination RTD ON RTD.DeterminationID = TR.DeterminationID
	--	JOIN Determination D ON D.DeterminationID = RTD.DeterminationID
	--	JOIN CropTrait CT ON CT.CropTraitID = RTD.CropTraitID AND CT.CropCode = @CropCode
	--	JOIN Trait T1 ON T1.TraitID = CT.TraitID
	--	JOIN 
	--	(
	--		SELECT C.TraitID FROM [Column] C
	--		JOIN [File] F ON F.FileID = C.FileID
	--		JOIN [Test] T ON T.FileID = F.FileID
	--		WHERE T.TestID = @TestID AND ISNULL(C.TraitID,0) > 0
	--	) C1 ON C1.TraitID = T1.TraitID
	--	LEFT JOIN RDTTraitDetResult TDR ON TDR.RelationID = RTD.RelationID AND ISNULL(TDR.DetResult,'') = ISNULL(TR.Score,'')
	--	WHERE 
	--		T.TestID = @TestID 
	--		AND TR.ResultStatus IN (100,200) 
	--		AND TDR.RDTTraitDetResultID IS NULL
		
	--END
	--ELSE IF (@FlowType = 2)
	IF(@FlowType = 2)
	BEGIN
		INSERT INTO @ConversionFound(RDTTestResultID)
		SELECT
			RDTTestResultID
		FROM
		(
			SELECT 
				D.DeterminationName,
				T.TestID, 
				M.MaterialKey, 
				M.RefExternal, 
				T1.ColumnLabel, 
				T.TestName,
				Score = CASE 							
							WHEN ISNULL(TR.MappingColumn,'') = 'resistantper' THEN COALESCE(CAST(TR.[percentage] AS NVARCHAR(MAX)), TR.Score,'')
							WHEN ISNULL(TR.MappingColumn,'') = 'SusceptibilityPer' THEN COALESCE(TR.Score, TDR.TraitResult,'')
							WHEN ISNULL(TDR.TraitResult,'') <> '' THEN TDR.TraitResult
							ELSE TR.Score 
						END,
				TM.PhenomeObsID,
				T.ImportLevel, 
				M.MaterialID,
				TR.RDTTestResultID,
				TR.ResultStatus,
				TDR.RDTTraitDetResultID,
				TDR.TraitResult,
				FlowType = @FlowType,
				T1.TraitID,
				TM.MaterialStatus,
				TR.MappingColumn
			FROM Test T
			JOIN TestMaterial TM ON TM.TestID = T.TestID
			JOIN Material M ON M.MaterialID = TM.MaterialID
			JOIN RDTTestResult TR ON TR.TestID = T.TestID AND M.MaterialID = TR.MaterialID
			JOIN RelationTraitDetermination RTD ON RTD.DeterminationID = TR.DeterminationID
			JOIN Determination D ON D.DeterminationID = RTD.DeterminationID
			JOIN CropTrait CT ON CT.CropTraitID = RTD.CropTraitID AND CT.CropCode = @CropCode
			JOIN Trait T1 ON T1.TraitID = CT.TraitID
			LEFT JOIN RDTTraitDetResult TDR ON 
						TDR.RelationID = RTD.RelationID
						AND (CASE
								WHEN (TR.MappingColumn = 'SusceptibilityPer' AND TDR.MappingCol = 'SusceptibilityPer' AND (TR.Score IS NOT NULL OR TR.[Percentage] BETWEEN TDR.MinPercent AND TDR.MaxPercent)) THEN 1
								WHEN (TR.MappingColumn = 'resistantper' AND TDR.MappingCol = 'resistantper' AND (TR.[Percentage] IS NOT NULL OR TR.Score IS NOT NULL)) THEN 1
								WHEN TDR.DetResult = TR.Score THEN 1
								ELSE 0
							END ) = 1
							
						AND (CASE 
								WHEN ISNULL(TM.MaterialStatus,'') = ISNULL(TDR.MaterialStatus,'') THEN 1
								WHEN ISNULL(TDR.MaterialStatus,'') = '' THEN 1
								ELSE 0
								END) = 1
			WHERE T.TestID = @TestID AND TR.ResultStatus IN (100,200)
		) T		
		GROUP BY RDTTestResultID

		SELECT
			Cropcode = @CropCode,
			T.TestName,
			D.DeterminationName,
			T1.ColumnLabel,
			Score = concat( COALESCE(CAST(TR.[percentage] AS NVARCHAR(MAX)), TR.Score,''), ' (',MappingColumn ,')'),
			MappingColumn,
			TR.RDTTestResultID
		FROM Test T 
		JOIN TestMaterial TM ON TM.TestID = T.TestID
		JOIN Material M ON M.MaterialID = TM.MaterialID
		JOIN RDTTestResult TR ON TR.TestID = T.TestID AND M.MaterialID = TR.MaterialID
		JOIN RelationTraitDetermination RTD ON RTD.DeterminationID = TR.DeterminationID
		JOIN Determination D ON D.DeterminationID = RTD.DeterminationID
		JOIN CropTrait CT ON CT.CropTraitID = RTD.CropTraitID AND CT.CropCode = @CropCode
		JOIN Trait T1 ON T1.TraitID = CT.TraitID
		LEFT JOIN @ConversionFound C ON C.RDTTestResultID = TR.RDTTestResultID
		WHERE T.TestID = @TestID 
			AND TR.ResultStatus IN (100,200)
			AND C.RDTTestResultID IS NULL
	END
	--ELSE IF (@FlowType = 3)
	--BEGIN
	--	SELECT 
	--		CropCode = @CropCode,
	--		T.TestName,
	--		D.DeterminationName,
	--		T1.ColumnLabel,
	--		TR.Score,
	--		MappingColumn,
	--		TR.RDTTestResultID
	--	FROM Test T
	--	JOIN TestMaterial TM ON TM.TestID = T.TestID
	--	JOIN Material M ON M.MaterialID = TM.MaterialID
	--	JOIN RDTTestResult TR ON TR.TestID = T.TestID AND M.MaterialID = TR.MaterialID
	--	JOIN RelationTraitDetermination RTD ON RTD.DeterminationID = TR.DeterminationID
	--	JOIN Determination D ON D.DeterminationID = RTD.DeterminationID
	--	JOIN CropTrait CT ON CT.CropTraitID = RTD.CropTraitID AND CT.CropCode = @CropCode
	--	JOIN Trait T1 ON T1.TraitID = CT.TraitID		
	--	LEFT JOIN RDTTraitDetResult TDR ON 
	--				TDR.RelationID = RTD.RelationID
	--				AND ISNULL(TDR.MappingCol,'') = ISNULL(TR.MappingColumn,'') 
	--	WHERE T.TestID = @TestID AND TR.ResultStatus IN (100,200) AND TDR.RDTTraitDetResultID IS NULL
		
	--END

END
