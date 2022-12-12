/*
	Author					Date			Description
-------------------------------------------------------------------
	Binod Gurung			2021-05-10		#21376 : Export RDT result with marker score and trait score
	Krishna Gautam			2021-07-13		#24075 : Change on logic when both resistance and Susceptibility percent result is provided for same material.
-------------------------------------------------------------------
==============================Example==============================
EXEC PR_RDT_GetResultForExcel 10623, 1
*/

ALTER PROCEDURE [dbo].[PR_RDT_GetResultForExcel]
(
	@TestID INT,
	@IsMarkerScore BIT
)
AS BEGIN
	SET NOCOUNT ON;
	
	DECLARE @StatusCode INT, @FileID INT,@ColumnID INT, @ImportLabel NVARCHAR(20),@ColumnName NVARCHAR(100),@ColID NVARCHAR(MAX);
	DECLARE @CropCode NVARCHAR(10), @GIDColID NVARCHAR(MAX), @GIDColumnID INT;
	DECLARE @FlowType INT;
	DECLARE @Query NVARCHAR(MAX), @PivotQuery NVARCHAR(MAX), @MainQuery NVARCHAR(MAX);
	DECLARE @IDS NVARCHAR(MAX), @Name NVARCHAR(MAX);
	DECLARE @Table TABLE(ID NVARCHAR(MAX), [Name] NVARCHAR(MAX));
	
	SELECT @CropCode = CropCode, @FlowType = TestFlowType, @StatusCode = StatusCode, @FileID = F.FileID  
	FROM [File] F 
	JOIN Test T ON T.FileID = F.FileID
	WHERE T.TestID = @TestID;

	IF NOT EXISTS (SELECT * FROM Test WHERE TestID = @TestID)
	BEGIN
		PRINT 'Invalid Test/PlatePlan.';
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
		PRINT 'Plant Name or Entry code Column not found.';
		RETURN;
	END
	
	SELECT @GIDColumnID = ColumnID, @GIDColID = QUOTENAME(ColumnID) FROM [Column] WHERE FileID = @FileID AND ColumLabel = 'GID';

	IF(ISNULL(@GIDColumnID,0) = 0)
	BEGIN
		PRINT 'GID Column not found.';
		RETURN;
	END

	--insert unique determination on table variable
	IF(ISNULL(@IsMarkerScore,0) = 1)
	BEGIN
		INSERT INTO @Table(ID,[Name])
		SELECT 
			ID = CONCAT( D.DeterminationID, ISNULL(MappingColumn,'')),
			--[Name] = CASE WHEN ISNULL(@IsMarkerScore,0) = 1 THEN MAX(D.DeterminationName) ELSE MAX(T1.ColumnLabel) END
			CONCAT(MAX(D.DeterminationName), CASE WHEN ISNULL(MappingColumn,'') <> '' THEN ' (' + MappingColumn + ')' ELSE '' END)
		FROM RDTTestResult TR
		JOIN Determination D ON D.DeterminationID = TR.DeterminationID
		JOIN RelationTraitDetermination RTD ON RTD.DeterminationID = TR.DeterminationID
		JOIN CropTrait CT ON CT.CropTraitID = RTD.CropTraitID AND CT.CropCode = @CropCode
		JOIN Trait T1 ON T1.TraitID = CT.TraitID
		WHERE TR.TestID = @TestID
		GROUP BY D.DeterminationID,MappingColumn
		--ORDER BY CASE WHEN ISNULL(@IsMarkerScore,0) = 1 THEN MAX(D.DeterminationName) ELSE MAX(T1.ColumnLabel) END
		ORDER BY D.DeterminationID
	END
	ELSE
	BEGIN
		IF(@FlowType = 3)
		BEGIN
			INSERT INTO @Table(ID,[Name])
			SELECT
			ID = CT.CropTraitID,			
			CONCAT(MAX(T1.ColumnLabel),  CASE WHEN ISNULL(MAX(MappingColumn),'') <> '' THEN ' (' + MAX(MappingColumn) + ')' ELSE '' END)
		FROM RDTTestResult TR
		JOIN TestMaterial TM ON TM.TestID = TR.TestID
		JOIN Determination D ON D.DeterminationID = TR.DeterminationID
		JOIN RelationTraitDetermination RTD ON RTD.DeterminationID = TR.DeterminationID
		JOIN CropTrait CT ON CT.CropTraitID = RTD.CropTraitID AND CT.CropCode = @CropCode
		JOIN Trait T1 ON T1.TraitID = CT.TraitID
		JOIN RDTTraitDetResult TDR ON TDR.RelationID = RTD.RelationID and ISNULL(TR.MappingColumn,'') = ISNULL(TDR.MappingCol,'')
			WHERE TR.TestID = @TestID
			GROUP BY CT.CropTraitID
			--ORDER BY CASE WHEN ISNULL(@IsMarkerScore,0) = 1 THEN MAX(D.DeterminationName) ELSE MAX(T1.ColumnLabel) END
			ORDER BY CT.CropTraitID
			
		END
		ELSE
		BEGIN
			INSERT INTO @Table(ID,[Name])
			SELECT
				ID = CT.CropTraitID,
				CONCAT(MAX(T1.ColumnLabel),  CASE WHEN ISNULL(MAX(MappingColumn),'') <> '' THEN ' (' + MAX(MappingColumn) + ')' ELSE '' END)
			FROM RDTTestResult TR
			JOIN Determination D ON D.DeterminationID = TR.DeterminationID
			JOIN RelationTraitDetermination RTD ON RTD.DeterminationID = TR.DeterminationID
			JOIN CropTrait CT ON CT.CropTraitID = RTD.CropTraitID AND CT.CropCode = @CropCode
			JOIN Trait T1 ON T1.TraitID = CT.TraitID
			WHERE TR.TestID = @TestID
			GROUP BY CT.CropTraitID
			--ORDER BY CASE WHEN ISNULL(@IsMarkerScore,0) = 1 THEN MAX(D.DeterminationName) ELSE MAX(T1.ColumnLabel) END
			ORDER BY CT.CropTraitID
		END
	END

	SELECT 
		@Name = COALESCE(@Name +',','') + 'ISNULL(' + QUOTENAME(ID) + ','''') AS ' + QUOTENAME([Name]),
		@IDS = COALESCE(@IDS +',','') + QUOTENAME(ID) 
	FROM @Table
	ORDER BY [Name];

	IF((ISNULL(@StatusCode,0) < 550))
	BEGIN
		EXEC PR_ThrowError 'Result is not available yet.';
		RETURN;
	END
		
	--Common query
	SET @MainQuery = N'
						SELECT 
							GID = ISNULL(T1.'+@GIDColID+','''')
							,' +QuoteName(@ColumnName)+ ' = ISNULL(T1.'+@ColID+','''')
							, LimsID = TMD.InterfaceRefID
							, Folder = T.LabPlatePlanName
							,' +ISNULL(@Name,'')+'
						FROM Test T
						JOIN TestMaterial TM ON TM.TestID = T.TestID
						JOIN Material M ON M.MaterialID = TM.MaterialID
						JOIN TestMaterialDetermination TMD ON TMD.TestID = T.TestID AND TMD.MaterialID = M.MaterialID
						JOIN [Row] R ON R.MaterialKey = M.MaterialKey AND R.FileID = T.FileID
					';
	
	--Marker score
	IF(ISNULL(@IsMarkerScore,0) = 1)
		SET @PivotQuery = N'LEFT JOIN 
							(
								SELECT * FROM 
								(
									SELECT 
										TestID, 
										MaterialID, 
										DeterminationID = CONCAT( DeterminationID, ISNULL(MappingColumn,'''')),
										Score
									FROM 
									(
										SELECT 
											TestID, 
											MaterialID, 
											DeterminationID,
											MappingColumn,
											Score = COALESCE(Score, CAST([Percentage] as nvarchar(10)), '''')
										FROM RDTTestResult 
										WHERE TestID = @TestID
									) ResTbl 
									
								) SRC
								PIVOT
								(
									MAX(Score)
									FOR DeterminationID IN ('+@IDS+')
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
											CropTraitID,
											Score
										FROM 
										(
											SELECT 
												TestID, 
												MaterialID, 
												RTD.CropTraitID, 
												MappingColumn,
												Score = CASE WHEN ISNULL(TDR.TraitResult,'''') <> '''' THEN TDR.TraitResult ELSE TR.Score END
											FROM RDTTestResult  TR
											JOIN RelationTraitDetermination RTD ON RTD.DeterminationID = TR.DeterminationID
											LEFT JOIN RDTTraitDetResult TDR ON TDR.RelationID = RTD.RelationID AND ISNULL(TDR.DetResult,'''') = ISNULL(TR.Score,'''')
										) ResTbl 
									) SRC
									PIVOT
									(
										MAX(Score)
										FOR CropTraitID IN ('+@IDS+')
									) PV
								) T2 ON T2.TestID = T.TestID AND T2.MaterialID = M.MaterialID';
		ELSE IF(@FlowType = 2)
			SET @PivotQuery = N'LEFT JOIN 
								(
									SELECT * FROM
									(
										SELECT 
											TestID, 
											MaterialID, 
											CropTraitID,
											Score
										FROM 
										(
											SELECT 
												TR.TestID, 
												TR.MaterialID, 
												RTD.CropTraitID,
												MappingColumn,
												Score = CASE 
															WHEN ISNULL(TR.MappingColumn,'''') = ''resistantper'' THEN CAST(TR.[Percentage] as nvarchar(10))
															WHEN ISNULL(TDR.TraitResult,'''') <> '''' THEN TDR.TraitResult
															ELSE TR.Score 
														END
											FROM RDTTestResult  TR
											JOIN TestMaterial TM ON TM.TestID = TR.TestID
											JOIN RelationTraitDetermination RTD ON RTD.DeterminationID = TR.DeterminationID
											JOIN RDTTraitDetResult TDR ON TDR.RelationID = RTD.RelationID
																			AND (CASE 
																					WHEN TR.[Percentage] BETWEEN TDR.MinPercent AND TDR.MaxPercent AND ISNULL(TDR.MappingCol,'''') = ISNULL(TR.MappingColumn,'''')  AND ISNULL(TDR.MappingCol,'''') = ''SusceptibilityPer'' THEN 1 --Susceptibility
																					WHEN ISNULL(TR.[Percentage],0) <> 0  AND ISNULL(TDR.MappingCol,'''') = ISNULL(TR.MappingColumn,'''') AND ISNULL(TDR.MappingCol,'''') = ''Resistantper'' THEN 1 --Resistance
																					WHEN TDR.DetResult = TR.Score AND ISNULL(TR.Score,'''') <> ''''  AND (ISNULL(TDR.MinPercent,0) = 0 AND ISNULL(TDR.MaxPercent,0) = 0) AND ISNULL(TDR.MappingCol,'''') = ISNULL(TR.MappingColumn,'''') THEN 1
																					ELSE 0
																					END) = 1
																			AND (CASE 
																					WHEN ISNULL(TM.MaterialStatus,'''') = ISNULL(TDR.MaterialStatus,'''') THEN 1
																					WHEN ISNULL(TDR.MaterialStatus,'''') = '''' THEN 1
																					ELSE 0
																					END) = 1
										) ResTbl
									) SRC
									PIVOT
									(
										MAX(Score)
										FOR CropTraitID IN ('+@IDS+')
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
											CropTraitID,
											Score
										FROM 
										(
											SELECT 
												TestID, 
												MaterialID, 
												RTD.CropTraitID,
												MappingColumn,
												Score = CASE WHEN ISNULL(TDR.TraitResult,'''') <> '''' THEN TDR.TraitResult ELSE TR.Score END
											FROM RDTTestResult  TR
											JOIN RelationTraitDetermination RTD ON RTD.DeterminationID = TR.DeterminationID
											JOIN RDTTraitDetResult TDR ON TDR.RelationID = RTD.RelationID
																		AND ISNULL(TDR.MappingCol,'''') = ISNULL(TR.MappingColumn,'''') 
										) ResTbl
									) SRC
									PIVOT
									(
										MAX(Score)
										FOR CropTraitID IN ('+@IDS+')
									) PV
								) T2 ON T2.TestID = T.TestID AND T2.MaterialID = M.MaterialID';
			
	END;

	SET @Name = ',' + @Name;

	SET @Query = @MainQuery +  
				N'
				LEFT JOIN
				(
					SELECT *  
					FROM 
					(
						SELECT FileID, RowID, ColumnID, [Value] FROM VW_IX_Cell VW
						WHERE VW.FileID = @FileID AND VW.ColumnID IN ( @ColumnID, @GIDColumnID)
						AND ISNULL([Value], '''') <> ''''
			
					) SRC
					PIVOT
					(
						Max([Value])
						FOR ColumnID IN ('+@ColID+', ' + @GIDColID + ')
					) PV
				) T1 ON T1.RowID = R.RowID

				'+ ISNULL(@PivotQuery,'') + 
				' WHERE T.TestID = @TestID'

			
	EXEC sp_executesql @Query,N' @FileID INT, @ColumnID INT, @GIDColumnID INT, @TestID INT ', @FileID, @ColumnID, @GIDColumnID, @TestID;

END
