/*
=========Changes====================
Changed By			Date				Description

										#15150: Created Stored Procedure	
Krishna Gautam		2021-03-17			Stored procedure changes.

========Example=============
EXEC PR_RDT_GetScore 10628

*/
ALTER PROCEDURE [dbo].[PR_RDT_ReceiveResults]
(
	@TestID INT,
	@TestFlowType INT,
	@TVP_RDTScore TVP_RDTScore READONLY
) AS

BEGIN
SET NOCOUNT ON;
	BEGIN TRY
		BEGIN TRANSACTION;
					
			INSERT INTO RDTTestResult(TestID, DeterminationID, MaterialID, Score, ResultStatus, SusceptibilityPercent, ValueColumn)
			SELECT @TestID, DeterminationID = MAX(D.DeterminationID), T1.MaterialID, T1.Score, 100, SusceptibilityPercent, ValueColumn	
			FROM @TVP_RDTScore T1
			JOIN Determination D ON D.OriginID = T1.OriginID AND D.Source = 'StarLims'
			JOIN TestMaterialDetermination TMD ON TMD.DeterminationID = D.DeterminationID AND TMD.MaterialID = T1.MaterialID
			WHERE TMD.TestID = @TestID
			GROUP BY T1.OriginID, T1.MaterialID, T1.Score, T1.SusceptibilityPercent, T1.ValueColumn;

			UPDATE Test 
				SET StatusCode = 550, --Partially Received
					TestFlowType = @TestFlowType
			WHERE TestID = @TestID;
			
		COMMIT;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
            ROLLBACK;
		THROW;
	END CATCH
END


GO



/*
=========Changes====================
Changed By			Date				Description

Krishna Gautam		2020-08-10			#15150: Created Stored Procedure	

========Example=============
EXEC PR_RDT_GetScore 10628

*/


ALTER PROCEDURE [dbo].[PR_RDT_GetScore]
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
		--here left join is required
		LEFT JOIN RDTTraitDetResult TDR ON TDR.RelationID = RTD.RelationID AND ISNULL(TDR.DetResult,'') = ISNULL(TR.Score,'')
		WHERE T.TestID = @TestID AND TR.ResultStatus IN (100,200)
		ORDER BY M.MaterialID
	END
	ELSE IF (@FlowType = 2)
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
		LEFT JOIN RDTTraitDetResult TDR ON 
					TDR.RelationID = RTD.RelationID
					AND (CASE 
							WHEN TR.SusceptibilityPercent BETWEEN TDR.MinPercent AND TDR.MaxPercent THEN 1
							WHEN TDR.DetResult = TR.Score AND ISNULL(TR.Score,'') <> ''  AND (ISNULL(TDR.MinPercent,0) = 0 AND ISNULL(TDR.MaxPercent,0) = 0)   THEN 1
							ELSE 0
							END) = 1
					AND (CASE 
							WHEN ISNULL(TM.MaterialStatus,'') = ISNULL(TDR.MaterialStatus,'') THEN 1
							WHEN ISNULL(TDR.MaterialStatus,'') = '' THEN 1
							ELSE 0
							END) = 1
		WHERE T.TestID = @TestID AND TR.ResultStatus IN (100,200)
		order by M.MaterialID,T1.TraitID,TM.MaterialStatus DESC
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
		LEFT JOIN RDTTraitDetResult TDR ON 
					TDR.RelationID = RTD.RelationID
					AND ISNULL(TDR.MappingCol,'') = ISNULL(TR.MappingColumn,'') 
		WHERE T.TestID = @TestID AND TR.ResultStatus IN (100,200)
		ORDER BY MaterialID
	END

END

GO