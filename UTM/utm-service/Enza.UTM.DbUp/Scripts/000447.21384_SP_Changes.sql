DROP PROCEDURE IF EXISTS [dbo].[PR_RDT_GetResultForExcel]
GO


/*
	Author					Date			Description
-------------------------------------------------------------------
	Binod Gurung			2021-05-10		#21376 : Export RDT result with marker score and trait score
-------------------------------------------------------------------
==============================Example==============================
EXEC PR_RDT_GetResultForExcel 6348, 1
*/

CREATE PROCEDURE [dbo].[PR_RDT_GetResultForExcel]
(
	@TestID INT,
	@IsMarkerScore BIT
)
AS BEGIN
	SET NOCOUNT ON;

	DECLARE @StatusCode INT, @FileID INT,@ColumnID INT, @ImportLabel NVARCHAR(20),@ColumnName NVARCHAR(100),@ColID NVARCHAR(MAX);
	DECLARE @CropCode NVARCHAR(10);
	DECLARE @FlowType INT;
	DECLARE @Query NVARCHAR(MAX), @PivotQuery NVARCHAR(MAX), @MainQuery NVARCHAR(MAX);
	DECLARE @DeterminationsIDS NVARCHAR(MAX), @DeterminationsName NVARCHAR(MAX);
	DECLARE @DeterminationTable TABLE(DeterminationID INT, DeterminationName NVARCHAR(MAX));
	
	SELECT @CropCode = CropCode, @FlowType = TestFlowType, @StatusCode = StatusCode, @FileID = F.FileID  
	FROM [File] F 
	JOIN Test T ON T.FileID = F.FileID
	WHERE T.TestID = @TestID;

	IF NOT EXISTS (SELECT * FROM Test WHERE TestID = @TestID)
	BEGIN
		EXEC PR_ThrowError 'Invalid Test/PlatePlan.';
		RETURN;
	END

	IF(@ImportLabel = 'PLT')
	BEGIN
		SET @ColumnName = 'Plant Name';
	END
	ELSE
	BEGIN
		SET @ColumnName = 'Entry code';
	END

	SELECT @ColumnID = ColumnID,@ColID = QUOTENAME(ColumnID) FROM [Column] WHERE FileID = @FileID AND ColumLabel = @ColumnName;

	IF(ISNULL(@ColumnID,0) = 0)
	BEGIN
		EXEC PR_ThrowError 'Plant Name or Entry code Column not found.';
		RETURN;
	END

	--insert unique determination on table variable
	INSERT INTO @DeterminationTable(DeterminationID,DeterminationName)
	SELECT 
		D.DeterminationID, 
		CASE WHEN ISNULL(@IsMarkerScore,0) = 1 THEN MAX(D.DeterminationName) ELSE MAX(T1.ColumnLabel) END 
	FROM RDTTestResult TR
	JOIN Determination D ON D.DeterminationID = TR.DeterminationID
	JOIN RelationTraitDetermination RTD ON RTD.DeterminationID = TR.DeterminationID
	JOIN CropTrait CT ON CT.CropTraitID = RTD.CropTraitID AND CT.CropCode = @CropCode
	JOIN Trait T1 ON T1.TraitID = CT.TraitID
	WHERE TR.TestID = @TestID
	GROUP BY D.DeterminationID
	ORDER BY CASE WHEN ISNULL(@IsMarkerScore,0) = 1 THEN MAX(D.DeterminationName) ELSE MAX(T1.ColumnLabel) END

	SELECT 
		@DeterminationsName = COALESCE(@DeterminationsName +',','') + 'ISNULL(' + QUOTENAME(DeterminationID) + ','''') AS ' + QUOTENAME(DeterminationName),
		@DeterminationsIDS = COALESCE(@DeterminationsIDS +',','') + QUOTENAME(DeterminationID) 
	FROM @DeterminationTable;

	IF((ISNULL(@StatusCode,0) < 550))
	BEGIN
		EXEC PR_ThrowError 'Result is not available yet.';
		RETURN;
	END
		
	SELECT @ColumnID = ColumnID, @ColID = QUOTENAME(ColumnID) FROM [Column] WHERE FileID = @FileID AND ColumLabel = @ColumnName;

	--Common query
	SET @MainQuery = N'
						SELECT 
							M.MaterialKey
							,' +QuoteName(@ColumnName)+ ' = ISNULL(T1.'+@ColID+','''')
							,' +ISNULL(@DeterminationsName,'')+'
						FROM Test T
						JOIN TestMaterial TM ON TM.TestID = T.TestID
						JOIN Material M ON M.MaterialID = TM.MaterialID
						JOIN [Row] R ON R.MaterialKey = M.MaterialKey AND R.FileID = T.FileID
					';
	
	--Marker score
	IF(ISNULL(@IsMarkerScore,0) = 1)
		SET @PivotQuery = N'LEFT JOIN 
							(
								SELECT * FROM 
								(
									SELECT TestID, MaterialID, DeterminationID, Score = COALESCE(Score, CAST([Percentage] as nvarchar(10)), '''') FROM RDTTestResult 
								) SRC
								PIVOT
								(
									MAX(Score)
									FOR DeterminationID IN ('+@DeterminationsIDS+')
								) PV

							) T2 ON T2.TestID = T.TestID AND T2.MaterialID = M.MaterialID';
	--Trait score
	ELSE
	BEGIN

		IF(@FlowType = 1)
			SET @PivotQuery = N'LEFT JOIN
								(
									SELECT * FROM
									(
										SELECT 
											TestID, 
											MaterialID, 
											TR.DeterminationID, 
											Score = CASE WHEN ISNULL(TDR.TraitResult,'''') <> '''' THEN TDR.TraitResult ELSE TR.Score END
										FROM RDTTestResult  TR
										JOIN RelationTraitDetermination RTD ON RTD.DeterminationID = TR.DeterminationID
										LEFT JOIN RDTTraitDetResult TDR ON TDR.RelationID = RTD.RelationID AND ISNULL(TDR.DetResult,'''') = ISNULL(TR.Score,'''')
									) SRC
									PIVOT
									(
										MAX(Score)
										FOR DeterminationID IN ('+@DeterminationsIDS+')
									) PV
								) T2 ON T2.TestID = T.TestID AND T2.MaterialID = M.MaterialID';
		ELSE IF(@FlowType = 2)
			SET @PivotQuery = N'LEFT JOIN 
								(
									SELECT * FROM
									(
										SELECT 
											TR.TestID, 
											TR.MaterialID, 
											TR.DeterminationID, 
											Score = CASE 
														WHEN ISNULL(TR.MappingColumn,'''') = ''resistantper'' THEN CAST(TR.[Percentage] as nvarchar(10))
														WHEN ISNULL(TDR.TraitResult,'''') <> '''' THEN TDR.TraitResult
														ELSE TR.Score 
													END
										FROM RDTTestResult  TR
										JOIN TestMaterial TM ON TM.TestID = TR.TestID
										JOIN RelationTraitDetermination RTD ON RTD.DeterminationID = TR.DeterminationID
										LEFT JOIN RDTTraitDetResult TDR ON TDR.RelationID = RTD.RelationID
																		AND (CASE 
																				--WHEN TR.SusceptibilityPercent BETWEEN TDR.MinPercent AND TDR.MaxPercent THEN 1
																				WHEN TR.[Percentage] BETWEEN TDR.MinPercent AND TDR.MaxPercent AND ISNULL(TDR.MappingCol,'''') = ISNULL(TR.MappingColumn,'''') THEN 1 --Susceptibility
																				WHEN TDR.DetResult = CAST(TR.[Percentage] as nvarchar(10)) AND ISNULL(TR.[Percentage],0) <> 0  AND ISNULL(TDR.MappingCol,'''') = ISNULL(TR.MappingColumn,'''') THEN 1 --Resistance
																				WHEN TDR.DetResult = TR.Score AND ISNULL(TR.Score,'''') <> ''''  AND (ISNULL(TDR.MinPercent,0) = 0 AND ISNULL(TDR.MaxPercent,0) = 0)   THEN 1
																				ELSE 0
																				END) = 1
																		AND (CASE 
																				WHEN ISNULL(TM.MaterialStatus,'''') = ISNULL(TDR.MaterialStatus,'''') THEN 1
																				WHEN ISNULL(TDR.MaterialStatus,'''') = '''' THEN 1
																				ELSE 0
																				END) = 1
									) SRC
									PIVOT
									(
										MAX(Score)
										FOR DeterminationID IN ('+@DeterminationsIDS+')
									) PV
								) T2 ON T2.TestID = T.TestID AND T2.MaterialID = M.MaterialID';
		ELSE IF (@FlowType = 3) 
			SET @PivotQuery = N'LEFT JOIN 
								(
									SELECT * FROM
									(
										SELECT 
											TestID, 
											MaterialID, 
											TR.DeterminationID, 
											Score = CASE WHEN ISNULL(TDR.TraitResult,'''') <> '''' THEN TDR.TraitResult ELSE TR.Score END
										FROM RDTTestResult  TR
										JOIN RelationTraitDetermination RTD ON RTD.DeterminationID = TR.DeterminationID
										LEFT JOIN RDTTraitDetResult TDR ON TDR.RelationID = RTD.RelationID AND ISNULL(TDR.DetResult,'''') = ISNULL(TR.Score,'''')
										LEFT JOIN RDTTraitDetResult TDR ON TDR.RelationID = RTD.RelationID
																		AND ISNULL(TDR.MappingCol,'''') = ISNULL(TR.MappingColumn,'''') 
									) SRC
									PIVOT
									(
										MAX(Score)
										FOR DeterminationID IN ('+@DeterminationsIDS+')
									) PV
								) T2 ON T2.TestID = T.TestID AND T2.MaterialID = M.MaterialID';
			
	END;

	SET @DeterminationsName = ',' + @DeterminationsName;

	SET @Query = @MainQuery +  
				N'
				LEFT JOIN
				(
					SELECT *  
					FROM 
					(
						SELECT FileID, RowID, ColumnID, [Value] FROM VW_IX_Cell VW
						WHERE VW.FileID = @FileID AND VW.ColumnID = @ColumnID
						AND ISNULL([Value], '''') <> ''''
			
					) SRC
					PIVOT
					(
						Max([Value])
						FOR ColumnID IN ('+@ColID+')
					) PV
				) T1 ON T1.RowID = R.RowID

				'+ ISNULL(@PivotQuery,'') + 
				' WHERE T.TestID = @TestID'

	EXEC sp_executesql @Query,N' @FileID INT, @ColumnID INT, @TestID INT ', @FileID, @ColumnID, @TestID;

END
GO


DROP PROCEDURE IF EXISTS [dbo].[PR_RDT_GetScore]
GO


/*
=========Changes====================
Changed By			Date				Description

Krishna Gautam		2020-08-10			#15150: Created Stored Procedure	
Binod Gurung		2021-05-14			#21384: Resistance value included for flow 2
========Example=============
EXEC PR_RDT_GetScore 6348

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
			Score = CASE 
						WHEN ISNULL(TR.MappingColumn,'') = 'resistantper' THEN CAST(TR.[Percentage] as nvarchar(10))
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
							WHEN TR.[Percentage] BETWEEN TDR.MinPercent AND TDR.MaxPercent AND ISNULL(TDR.MappingCol,'') = ISNULL(TR.MappingColumn,'') THEN 1 --Susceptibility
							WHEN TDR.DetResult = CAST(TR.[Percentage] as nvarchar(10)) AND ISNULL(TR.[Percentage],0) <> 0  AND ISNULL(TDR.MappingCol,'') = ISNULL(TR.MappingColumn,'') THEN 1 --Resistance
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


