DROP PROCEDURE IF EXISTS [dbo].[PR_RDT_GetScore]
GO


/*
=========Changes====================
Changed By			Date				Description

Krishna Gautam		2020-08-10			#15150: Created Stored Procedure	
Binod Gurung		2021-05-14			#21384: Resistant value included for flow 2
Krishna Gautam		2021-07-13			#24074: Change on logic when both resistance and Susceptibility percent result is provided for same material.
Binod Gurung		2021-08-25			#21384: Undetermined value (U) handled for resistance and susceptibility percentage
========Example=============
EXEC PR_RDT_GetScore 10622

*/


CREATE PROCEDURE [dbo].[PR_RDT_GetScore]
(
	@TestID INT
)
AS 
BEGIN
	DECLARE @CropCode NVARCHAR(MAX);
	DECLARE @FlowType INT;
	

	SELECT @CropCode = CropCode, @FlowType = TestFlowType
	FROM [File] F 
	JOIN Test T ON T.FileID = F.FileID
	WHERE T.TestID = @TestID;

	IF(@FlowType = 1)
	BEGIN
		
		SELECT 
			T.TestID, 
			M.MaterialKey, 
			M.RefExternal, 
			T1.ColumnLabel, 
			Score = CASE WHEN ISNULL(TDR.TraitResult,'') <> '' THEN TDR.TraitResult ELSE TR.Score END, 
			TM.PhenomeObsID,
			T.ImportLevel, 
			M.MaterialID,
			TR.RDTTestResultID,
			TR.ResultStatus,
			TDR.RDTTraitDetResultID,
			TDR.TraitResult,
			FlowType = @FlowType 
		FROM Test T
		JOIN TestMaterial TM ON TM.TestID = T.TestID
		JOIN Material M ON M.MaterialID = TM.MaterialID
		JOIN RDTTestResult TR ON TR.TestID = T.TestID AND M.MaterialID = TR.MaterialID
		JOIN RelationTraitDetermination RTD ON RTD.DeterminationID = TR.DeterminationID
		JOIN CropTrait CT ON CT.CropTraitID = RTD.CropTraitID AND CT.CropCode = @CropCode
		JOIN Trait T1 ON T1.TraitID = CT.TraitID
		JOIN 
		(
			SELECT C.TraitID FROM [Column] C
			JOIN [File] F ON F.FileID = C.FileID
			JOIN [Test] T ON T.FileID = F.FileID
			WHERE T.TestID = @TestID AND ISNULL(C.TraitID,0) > 0
		) C1 ON C1.TraitID = T1.TraitID
		--Left Join is added to fetch result which do not have result mapping
		LEFT JOIN RDTTraitDetResult TDR ON TDR.RelationID = RTD.RelationID AND ISNULL(TDR.DetResult,'') = ISNULL(TR.Score,'')
		WHERE T.TestID = @TestID AND TR.ResultStatus IN (100,200)
		ORDER BY M.MaterialID
	END
	ELSE IF (@FlowType = 2)
	BEGIN

		SELECT 
			TestID, --= MAX(TestID),
			MaterialKey= MAX(MaterialKey),
			RefExternal = MAX(RefExternal),
			ColumnLabel = MAX(ColumnLabel),
			Score = MAX(Score),
			PhenomeObsID = MAX(PhenomeObsID),
			ImportLevel = MAX(ImportLevel),
			MaterialID, --= MAX(MaterialID),
			RDTTestResultID,
			ResultStatus = MAX(ResultStatus),
			RDTTraitDetResultID = MAX(RDTTraitDetResultID),
			TraitResult = MAX(TraitResult),
			FlowType = MAX(FlowType),
			TraitID = MAX(TraitID),
			MaterialStatus = MAX(MaterialStatus),
			MappingColumn = MAX(MappingColumn)
		FROM
		(
			SELECT 
				T.TestID, 
				M.MaterialKey, 
				M.RefExternal, 
				T1.ColumnLabel,  
				Score = CASE 
							WHEN ISNULL(TR.MappingColumn,'') = 'resistantper' THEN
								CASE WHEN ISNULL(TR.[Percentage],0) <> 0 THEN CAST(TR.[Percentage] as nvarchar(10)) ELSE TR.Score END
							WHEN ISNULL(TR.MappingColumn,'') = 'SusceptibilityPer' AND ISNULL(TR.Score,'') <> '' THEN TR.Score
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
			JOIN CropTrait CT ON CT.CropTraitID = RTD.CropTraitID AND CT.CropCode = @CropCode
			JOIN Trait T1 ON T1.TraitID = CT.TraitID
			LEFT JOIN RDTTraitDetResult TDR ON 
						TDR.RelationID = RTD.RelationID
						AND (CASE 
								--For Resistant/Susceptible 'U' means Undetermined - in this case same value should be sent to Phenome
								WHEN ((ISNULL(TR.[Percentage],0) BETWEEN TDR.MinPercent AND TDR.MaxPercent) OR ISNULL(TR.[Score],'') <> '') AND ISNULL(TDR.MappingCol,'') = ISNULL(TR.MappingColumn,'') AND ISNULL(TDR.MappingCol,'') = 'SusceptibilityPer' THEN 1 --Susceptibility
								WHEN (ISNULL(TR.[Percentage],0) <> 0 OR ISNULL(TR.[Score],'') <> '') AND ISNULL(TDR.MappingCol,'') = ISNULL(TR.MappingColumn,'')  AND ISNULL(TDR.MappingCol,'') = 'Resistantper' THEN 1 --Resistant
								WHEN TDR.DetResult = TR.Score AND ISNULL(TR.Score,'') <> ''  AND (ISNULL(TDR.MinPercent,0) = 0 AND ISNULL(TDR.MaxPercent,0) = 0)   THEN 1
								ELSE 0
								END) = 1
						AND (CASE 
								WHEN ISNULL(TM.MaterialStatus,'') = ISNULL(TDR.MaterialStatus,'') THEN 1
								WHEN ISNULL(TDR.MaterialStatus,'') = '' THEN 1
								ELSE 0
								END) = 1
			WHERE T.TestID = @TestID AND TR.ResultStatus IN (100,200)
		) T
		WHERE ISNULL(Score,'') <> ''
		GROUP BY TestID, MaterialID, RDTTestResultID
		ORDER BY MaterialID, TraitID, MaterialStatus DESC
		--This order by is used in executable and it will select first data and ignore second data if same observationID is found.
	END
	ELSE IF (@FlowType = 3)
	BEGIN
		SELECT 
			T.TestID, 
			M.MaterialKey, 
			M.RefExternal, 
			T1.ColumnLabel, 
			TR.Score, 
			TM.PhenomeObsID,
			T.ImportLevel, 
			M.MaterialID,
			TR.RDTTestResultID,
			TR.ResultStatus,
			TDR.RDTTraitDetResultID,
			TDR.TraitResult,
			FlowType = @FlowType
		FROM Test T
		JOIN TestMaterial TM ON TM.TestID = T.TestID
		JOIN Material M ON M.MaterialID = TM.MaterialID
		JOIN RDTTestResult TR ON TR.TestID = T.TestID AND M.MaterialID = TR.MaterialID
		JOIN RelationTraitDetermination RTD ON RTD.DeterminationID = TR.DeterminationID
		JOIN CropTrait CT ON CT.CropTraitID = RTD.CropTraitID AND CT.CropCode = @CropCode
		JOIN Trait T1 ON T1.TraitID = CT.TraitID		
		JOIN RDTTraitDetResult TDR ON 
					TDR.RelationID = RTD.RelationID
					AND ISNULL(TDR.MappingCol,'') = ISNULL(TR.MappingColumn,'') 
		WHERE T.TestID = @TestID AND TR.ResultStatus IN (100,200)
		ORDER BY MaterialID
	END

END
GO


