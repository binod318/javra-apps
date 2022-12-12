/*
	Author					Date			Description
-------------------------------------------------------------------
	Binod Gurung			2021-05-10		#21376 : Export RDT result with marker score and trait score
	Krishna Gautam			2021-07-13		#24075 : Change on logic when both resistance and Susceptibility percent result is provided for same material.
	Krishna Gautam			2021-09-28		#26091 : Change on logic to send data that have relation only and ignore other result.
-------------------------------------------------------------------
==============================Example==============================
EXEC PR_RDT_GetResultForExcel 10622, 1
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
	DECLARE @FlowType INT, @LimsPivotQuery NVARCHAR(MAX);
	DECLARE @Query NVARCHAR(MAX), @PivotQuery NVARCHAR(MAX), @MainQuery NVARCHAR(MAX);
	DECLARE @IDS NVARCHAR(MAX), @Name NVARCHAR(MAX), @LimsIDS NVARCHAR(MAX), @LimsName NVARCHAR(MAX), @DetIDs NVARCHAR(MAX);
	DECLARE @Table TABLE(ID NVARCHAR(MAX), [Name] NVARCHAR(MAX), [Type] INT, [Order] INT);
	
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

	--IF((ISNULL(@StatusCode,0) < 550))
	--BEGIN
	--	EXEC PR_ThrowError 'Result is not available yet.';
	--	RETURN;
	--END

	--insert unique determination on table variable
	IF(ISNULL(@IsMarkerScore,0) = 1)
	BEGIN
		INSERT INTO @Table(ID,[Name],[Type], [Order])
		SELECT 
			ID = CONCAT( D.DeterminationID, ISNULL(MappingColumn,'')),
			--[Name] = CASE WHEN ISNULL(@IsMarkerScore,0) = 1 THEN MAX(D.DeterminationName) ELSE MAX(T1.ColumnLabel) END
			CONCAT(MAX(D.DeterminationName), CASE WHEN ISNULL(MappingColumn,'') <> '' THEN ' (' + MappingColumn + ')' ELSE '' END),
			1,
			ROW_NUMBER() OVER(ORDER BY  D.DeterminationID)
		FROM RDTTestResult TR
		JOIN Determination D ON D.DeterminationID = TR.DeterminationID
		JOIN RelationTraitDetermination RTD ON RTD.DeterminationID = TR.DeterminationID
		JOIN CropTrait CT ON CT.CropTraitID = RTD.CropTraitID AND CT.CropCode = @CropCode
		JOIN Trait T1 ON T1.TraitID = CT.TraitID
		WHERE TR.TestID = @TestID
		GROUP BY D.DeterminationID,MappingColumn
		--ORDER BY CASE WHEN ISNULL(@IsMarkerScore,0) = 1 THEN MAX(D.DeterminationName) ELSE MAX(T1.ColumnLabel) END
		ORDER BY D.DeterminationID

		--now insert lims ID into table with type value to  2
		INSERT INTO @Table(ID,[Name],[Type], [Order])
		SELECT 
			TMD.DeterminationID,
			MAX(D.DeterminationName) + ' (LimsID)',
			2,
			ROW_NUMBER() OVER(ORDER BY  TMD.DeterminationID)
		FROM TestMaterialDetermination TMD
		JOIN RDTTestResult TR ON TR.DeterminationID = TMD.DeterminationID AND TR.MaterialID = TMD.MaterialID AND TMD.TestID = TR.TestID
		JOIN Determination D ON D.DeterminationID = TR.DeterminationID
		WHERE TMD.TestID = @TestID
		GROUP BY TMD.DeterminationID
		ORDER BY TMD.DeterminationID
	END
	ELSE
	BEGIN

		IF(@FlowType = 3)
		BEGIN
			--For flowtype 3 show data that have relation only so no left join
			INSERT INTO @Table(ID,[Name],[Type],[Order])
			SELECT
				ID = CT.TraitID,			
				CONCAT(MAX(T.ColumnLabel),  ' (LimsID)'),
				2,
				ROW_NUMBER() OVER(ORDER BY  CT.CropTraitID)
			FROM TestMaterialDetermination T1
			JOIN RDTTestResult TR ON TR.DeterminationID = T1.DeterminationID AND TR.MaterialID = T1.MaterialID AND T1.TestID = TR.TestID
			JOIN Determination T2 ON T2.DeterminationID = T1.DeterminationID
			JOIN RelationTraitDetermination T3 ON T3.DeterminationID = T1.DeterminationID
			JOIN RDTTraitDetResult TDR ON TDR.RelationID = T3.RelationID and ISNULL(TR.MappingColumn,'') = ISNULL(TDR.MappingCol,'')
			JOIN CropTrait CT ON CT.CropTraitID = T3.CropTraitID
			JOIN Trait T ON T.TraitID = CT.TraitID				
			WHERE T1.TestID = @TestID			
			GROUP BY CT.CropTraitID, CT.TraitID
			ORDER BY CT.CropTraitID;
		END
		ELSE
		BEGIN
			--insert lims id columns
			INSERT INTO @Table(ID,[Name],[Type],[Order])
			SELECT
				ID = CT.TraitID,			
				CONCAT(MAX(T.ColumnLabel),  ' (LimsID)'),
				2,
				ROW_NUMBER() OVER(ORDER BY  CT.CropTraitID)
			FROM TestMaterialDetermination T1
			JOIN RDTTestResult TR ON TR.DeterminationID = T1.DeterminationID AND TR.MaterialID = T1.MaterialID AND T1.TestID = TR.TestID
			JOIN Determination T2 ON T2.DeterminationID = T1.DeterminationID
			JOIN RelationTraitDetermination T3 ON T3.DeterminationID = T1.DeterminationID
			LEFT JOIN RDTTraitDetResult TDR ON TDR.RelationID = T3.RelationID and ISNULL(TR.MappingColumn,'') = ISNULL(TDR.MappingCol,'')
			JOIN CropTrait CT ON CT.CropTraitID = T3.CropTraitID
			JOIN Trait T ON T.TraitID = CT.TraitID				
			WHERE T1.TestID = @TestID			
			GROUP BY CT.CropTraitID, CT.TraitID
			ORDER BY CT.CropTraitID;
		END

		IF(@FlowType = 2)
		BEGIN
			
			INSERT INTO @Table(ID,[Name],[Type],[Order])
			SELECT
				ID = CT.CropTraitID,			
				CONCAT(MAX(T1.ColumnLabel),  CASE WHEN ISNULL(MAX(MappingColumn),'') <> '' THEN ' (' + MAX(MappingColumn) + ')' ELSE '' END),
				1,
				ROW_NUMBER() OVER(ORDER BY  CT.CropTraitID)
			FROM RDTTestResult TR
			JOIN TestMaterial TM ON TM.TestID = TR.TestID
			JOIN Determination D ON D.DeterminationID = TR.DeterminationID
			JOIN RelationTraitDetermination RTD ON RTD.DeterminationID = TR.DeterminationID
			JOIN CropTrait CT ON CT.CropTraitID = RTD.CropTraitID AND CT.CropCode = @CropCode
			JOIN Trait T1 ON T1.TraitID = CT.TraitID
			--Left Join is added to fetch result which do not have result mapping
			LEFT JOIN RDTTraitDetResult TDR ON TDR.RelationID = RTD.RelationID and ISNULL(TR.MappingColumn,'') = ISNULL(TDR.MappingCol,'')
			WHERE TR.TestID = @TestID
			GROUP BY CT.CropTraitID, CT.TraitID
			--ORDER BY CASE WHEN ISNULL(@IsMarkerScore,0) = 1 THEN MAX(D.DeterminationName) ELSE MAX(T1.ColumnLabel) END
			ORDER BY CT.CropTraitID
			
		END

		ELSE IF(@FlowType = 3)
		BEGIN
			
			INSERT INTO @Table(ID,[Name],[Type],[Order])
			SELECT
				ID = CONCAT(CAST(CT.CropTraitID AS NVARCHAR(MAX)), ISNULL(MappingColumn,'')),			
				CONCAT(MAX(T1.ColumnLabel),  CASE WHEN ISNULL(MappingColumn,'') <> '' THEN ' (' + MappingColumn + ')' ELSE '' END),
				1,
				ROW_NUMBER() OVER(ORDER BY  CT.CropTraitID)
			FROM RDTTestResult TR
			JOIN TestMaterial TM ON TM.TestID = TR.TestID
			JOIN Determination D ON D.DeterminationID = TR.DeterminationID
			JOIN RelationTraitDetermination RTD ON RTD.DeterminationID = TR.DeterminationID
			JOIN CropTrait CT ON CT.CropTraitID = RTD.CropTraitID AND CT.CropCode = @CropCode
			JOIN Trait T1 ON T1.TraitID = CT.TraitID
			--no left join just join is required for flowtype 3
			JOIN RDTTraitDetResult TDR ON TDR.RelationID = RTD.RelationID and ISNULL(TR.MappingColumn,'') = ISNULL(TDR.MappingCol,'')
			WHERE TR.TestID = @TestID
			GROUP BY CT.CropTraitID, CT.TraitID, MappingColumn
			--ORDER BY CASE WHEN ISNULL(@IsMarkerScore,0) = 1 THEN MAX(D.DeterminationName) ELSE MAX(T1.ColumnLabel) END
			ORDER BY CT.CropTraitID
			
		END

		ELSE
		BEGIN
			INSERT INTO @Table(ID,[Name],[Type],[Order])
			SELECT
				ID = CT.CropTraitID,
				CONCAT(MAX(T1.ColumnLabel),  CASE WHEN ISNULL(MAX(MappingColumn),'') <> '' THEN ' (' + MAX(MappingColumn) + ')' ELSE '' END),
				--CONCAT(MAX(T1.ColumnLabel),  CASE WHEN ISNULL(MappingColumn,'') <> '' THEN ' (' + MappingColumn + ')' ELSE '' END),
				1,
				ROW_NUMBER() OVER(ORDER BY  CT.CropTraitID)
			FROM RDTTestResult TR
			JOIN Determination D ON D.DeterminationID = TR.DeterminationID
			JOIN RelationTraitDetermination RTD ON RTD.DeterminationID = TR.DeterminationID --here join is enough because we do not have releation then we can igonre the result.
			JOIN RDTTraitDetResult TDR ON TDR.RelationID = RTD.RelationID AND ISNULL(TR.MappingColumn,'') = ISNULL(TDR.MappingCol,'')
			JOIN CropTrait CT ON CT.CropTraitID = RTD.CropTraitID AND CT.CropCode = @CropCode
			JOIN Trait T1 ON T1.TraitID = CT.TraitID
			WHERE TR.TestID = @TestID
			GROUP BY CT.CropTraitID
			--ORDER BY CASE WHEN ISNULL(@IsMarkerScore,0) = 1 THEN MAX(D.DeterminationName) ELSE MAX(T1.ColumnLabel) END
			ORDER BY CT.CropTraitID
		END
	END

	--columns of score
	SELECT 
		--@Name = COALESCE(@Name +',','') + 'ISNULL(' + QUOTENAME(ID) + ','''') AS ' + QUOTENAME([Name]),
		@IDS = COALESCE(@IDS +',','') + QUOTENAME(ID) 
	FROM @Table
	WHERE [Type] = 1
	ORDER BY [Order];

	--Lims ID columns
	SELECT		
		@DetIDs = COALESCE(@DetIDS +',','') + QUOTENAME(ID) 
	FROM @Table
	WHERE [Type] = 2
	ORDER BY [Order];

	--not get names of both type
	--here first LIMS id column and then score column
	SELECT		
		@Name = CASE 
			WHEN [Type] = 2 THEN  COALESCE(@Name +',','') + 'ISNULL( TTLimsID.' + QUOTENAME(ID) + ','''') AS ' + QUOTENAME([Name])
			ELSE COALESCE(@Name +',','') + 'ISNULL( T2.' + QUOTENAME(ID) + ','''') AS ' + QUOTENAME([Name])
			END
	FROM @Table	
	ORDER BY [Order], [Type] desc;
	
		
	--Common query
	SET @MainQuery = N'
						SELECT 
							GID = ISNULL(T1.'+@GIDColID+','''')
							,' +QuoteName(@ColumnName)+ ' = ISNULL(T1.'+@ColID+','''')
							--, LimsID = TMD.InterfaceRefID
							, Folder = T.LabPlatePlanName
							,' +ISNULL(@Name,'')+'
						FROM Test T
						JOIN TestMaterial TM ON TM.TestID = T.TestID
						JOIN Material M ON M.MaterialID = TM.MaterialID
						--JOIN TestMaterialDetermination TMD ON TMD.TestID = T.TestID AND TMD.MaterialID = M.MaterialID
						JOIN [Row] R ON R.MaterialKey = M.MaterialKey AND R.FileID = T.FileID
					';
	--LIMS pivot query
	IF(@IsMarkerScore = 1)
	BEGIN
		SET @LimsPivotQuery = '
				LEFT JOIN 
				(
					SELECT MaterialID, ' + @DetIDs  + N'
					FROM 
					(
						SELECT T2.MaterialID,T2.MaterialKey, T1.DeterminationID, T1.InterfaceRefID
						FROM [TestMaterialDetermination] T1
						JOIN Material T2 ON T2.MaterialID = T1.MaterialID
						WHERE T1.TestID = @TestID
					) SRC 
					PIVOT
					(
						MAX(InterfaceRefID)
						FOR [DeterminationID] IN (' + @DetIDs + N')
					) PV
				
				) AS TTLimsID			
				ON TTLimsID.MaterialID = M.MaterialID ';
	END
	ELSE
	BEGIN
			SET @LimsPivotQuery = '
				LEFT JOIN 
				(
					SELECT MaterialID, ' + @DetIDs  + N'
					FROM 
					(
						SELECT T1.MaterialID, DeterminationID = T.TraitiD, T1.InterfaceRefID						
						FROM TestMaterialDetermination T1
						JOIN RDTTestResult TR ON TR.DeterminationID = T1.DeterminationID AND TR.MaterialID = T1.MaterialID AND T1.TestID = TR.TestID
						JOIN Determination T2 ON T2.DeterminationID = T1.DeterminationID
						JOIN RelationTraitDetermination T3 ON T3.DeterminationID = T1.DeterminationID
						JOIN CropTrait CT ON CT.CropTraitID = T3.CropTraitID
						JOIN Trait T ON T.TraitID = CT.TraitID				
						WHERE T1.TestID = @TestID
					) SRC 
					PIVOT
					(
						MAX(InterfaceRefID)
						FOR [DeterminationID] IN (' + @DetIDs + N')
					) PV
				
				) AS TTLimsID			
				ON TTLimsID.MaterialID = M.MaterialID ';

	END

	SET @MainQuery = @MainQuery + @LimsPivotQuery;
	
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
															WHEN ISNULL(TR.MappingColumn,'''') = ''resistantper'' THEN COALESCE(CAST(TR.[percentage] AS NVARCHAR(MAX)), TR.Score,'''') 
															
															WHEN ISNULL(TR.MappingColumn,'''') = ''SusceptibilityPer'' THEN COALESCE(TR.Score, TDR.TraitResult,'''')
															WHEN ISNULL(TDR.TraitResult,'''') <> '''' THEN TDR.TraitResult
															ELSE TR.Score 
														END
											FROM RDTTestResult TR
											JOIN TestMaterial TM ON TM.TestID = TR.TestID
											JOIN RelationTraitDetermination RTD ON RTD.DeterminationID = TR.DeterminationID
											JOIN RDTTraitDetResult TDR ON TDR.RelationID = RTD.RelationID
																			AND (CASE
																					WHEN (TR.MappingColumn = ''SusceptibilityPer'' AND TDR.MappingCol = ''SusceptibilityPer'' AND (TR.Score IS NOT NULL OR TR.[Percentage] BETWEEN TDR.MinPercent AND TDR.MaxPercent)) THEN 1
																					WHEN (TR.MappingColumn = ''resistantper'' AND TDR.MappingCol = ''resistantper'' AND (TR.[Percentage] IS NOT NULL OR TR.Score IS NOT NULL)) THEN 1
																					WHEN TDR.DetResult = TR.Score THEN 1
																					ELSE 0
																				END ) = 1
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
											CropTraitID = CONCAT(CAST(CropTraitID AS NVARCHAR(MAX)),ISNULL(MappingColumn,'''')),
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


GO


/*
=========Changes====================
Changed By			Date				Description

Krishna Gautam		2020-08-10			#15150: Created Stored Procedure	
Binod Gurung		2021-05-14			#21384: Resistant value included for flow 2
Krishna Gautam		2021-07-13			#24074: Change on logic when both resistance and Susceptibility percent result is provided for same material.
Binod Gurung		2021-08-25			#21384: Undetermined value (U) handled for resistance and susceptibility percentage
Krishna Gautam		2021-09-28			#26091: Changed logic on getting data for flowtype 3 to get data that do not have relation too.
========Example=============
EXEC PR_RDT_GetScore 10622

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
		--Left Join is added to fetch result which do not have result mapping
		LEFT JOIN RDTTraitDetResult TDR ON TDR.RelationID = RTD.RelationID AND ISNULL(TDR.DetResult,'') = ISNULL(TR.Score,'')
		WHERE T.TestID = @TestID AND TR.ResultStatus IN (100,150,200)
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
			RDTTestResultID = MAX(RDTTestResultID),
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
			JOIN CropTrait CT ON CT.CropTraitID = RTD.CropTraitID AND CT.CropCode = @CropCode
			JOIN Trait T1 ON T1.TraitID = CT.TraitID
			JOIN RDTTraitDetResult TDR ON 
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
			WHERE T.TestID = @TestID AND TR.ResultStatus IN (100,150,200)
		) T
		WHERE ISNULL(Score,'') <> ''
		GROUP BY TestID, MaterialID, ColumnLabel
		ORDER BY MaterialID, TraitID, MaterialStatus DESC
		--This order by is used in executable and it will select first data and ignore second data if same observationID is found.
	END
	ELSE IF (@FlowType = 3)
	BEGIN
		SELECT 
			TR.TestID, 
			MaterialKey, 
			RefExternal, 
			T1.ColumnLabel, 
			TR.Score, 
			PhenomeObsID,
			ImportLevel, 
			TM.MaterialID,
			TR.RDTTestResultID,
			TR.ResultStatus,
			RDTTraitDetResultID,
			TraitResult,
			FlowType = 3
		FROM 
		Test T 
		JOIN TestMaterial TM ON TM.TestID = T.TestID
		JOIN Material M ON M.MaterialID = TM.MaterialID
		JOIN RDTTestResult TR ON T.TestID = TR.TestID AND TR.MaterialID = M.MaterialID
		LEFT JOIN
		(
			SELECT 
				TR.TestID,
				T1.ColumnLabel, 
				TR.Score,
				TR.RDTTestResultID,
				TR.ResultStatus,
				TDR.RDTTraitDetResultID,
				TDR.TraitResult
			FROM 
			RDTTEstResult TR 
			JOIN RelationTraitDetermination RTD ON RTD.DeterminationID = TR.DeterminationID
			JOIN CropTrait CT ON CT.CropTraitID = RTD.CropTraitID AND CT.CropCode = @CropCode
			JOIN Trait T1 ON T1.TraitID = CT.TraitID		
			JOIN RDTTraitDetResult TDR ON 
						TDR.RelationID = RTD.RelationID
						AND ISNULL(TDR.MappingCol,'') = ISNULL(TR.MappingColumn,'')
			WHERE  TR.TestID = @TestID AND TR.ResultStatus IN (100,150, 200)
		) T1 ON T1.RDTTestResultID = TR.RDTTestResultID
		WHERE TR.TestID = @TestID AND TR.ResultStatus IN (100,150, 200)
		ORDER BY TM.MaterialID
	END

END
GO