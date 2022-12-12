DROP PROCEDURE [dbo].[PR_RDT_GetResultForExcel]
GO

/*
	Author					Date			Description
-------------------------------------------------------------------
	Binod Gurung			2021-05-10		#21376 : Export RDT result with marker score and trait score
	Krishna Gautam			2021-07-13		#24075 : Change on logic when both resistance and Susceptibility percent result is provided for same material.
	Krishna Gautam			2021-09-28		#26091 : Change on logic to send data that have relation only and ignore other result.
	Krishna Gautam			2022-05-18		#37674 : Change on test flow type which will be based on determination of test instead of complete test.
-------------------------------------------------------------------
==============================Example==============================
EXEC PR_RDT_GetResultForExcel 10622, 1
*/

CREATE PROCEDURE [dbo].[PR_RDT_GetResultForExcel]
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
	DECLARE @IDS1 NVARCHAR(MAX), @IDS2 NVARCHAR(MAX), @IDS3 NVARCHAR(MAX), @Name NVARCHAR(MAX), @LimsIDS NVARCHAR(MAX), @LimsName NVARCHAR(MAX), @DetIDs NVARCHAR(MAX);
	DECLARE @Table TABLE(ID NVARCHAR(MAX), [Name] NVARCHAR(MAX), [Type] INT, [Order] INT, FlowType INT, OrderOfName NVARCHAR(MAX));
	
	SELECT @CropCode = CropCode, @StatusCode = StatusCode, @FileID = F.FileID  
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
		ORDER BY D.DeterminationID

		--now insert lims ID into table with type value to  2
		INSERT INTO @Table(ID,[Name],[Type], [Order], OrderOfName)
		SELECT 
			TMD.DeterminationID,
			MAX(D.DeterminationName) + '  (LimsID)',
			2,
			ROW_NUMBER() OVER(ORDER BY  TMD.DeterminationID),
			MAX(D.DeterminationName)
		FROM TestMaterialDetermination TMD
		JOIN RDTTestResult TR ON TR.DeterminationID = TMD.DeterminationID AND TR.MaterialID = TMD.MaterialID AND TMD.TestID = TR.TestID
		JOIN Determination D ON D.DeterminationID = TR.DeterminationID
		WHERE TMD.TestID = @TestID
		GROUP BY TMD.DeterminationID
		ORDER BY TMD.DeterminationID
	END
	ELSE
	BEGIN

		--INSERT LIMS ID COLUMNS 
		--Flow type 1 and 2 have same flow but flow type 3 have different flow
		--first insert limsID for flowType 3
		--For flowtype 3 show data that have relation only so no left join
		INSERT INTO @Table(ID,[Name],[Type],[Order], OrderOfName)
		SELECT
			ID = CT.TraitID,			
			CONCAT(MAX(T.ColumnLabel),  '  (LimsID)'),
			2,
			ROW_NUMBER() OVER(ORDER BY  CT.CropTraitID),
			MAX(T.ColumnLabel)
		FROM TestMaterialDetermination T1
		JOIN RDTTestResult TR ON TR.DeterminationID = T1.DeterminationID AND TR.MaterialID = T1.MaterialID AND T1.TestID = TR.TestID
		JOIN TestDeterminationFlowType TDFT ON TDFT.TestID = TR.TestID AND TDFT.DeterminationID = TR.DeterminationID AND TDFT.TestFlowType = 3 --Flow Type 3
		JOIN Determination T2 ON T2.DeterminationID = T1.DeterminationID
		JOIN RelationTraitDetermination T3 ON T3.DeterminationID = T1.DeterminationID
		JOIN RDTTraitDetResult TDR ON TDR.RelationID = T3.RelationID and ISNULL(TR.MappingColumn,'') = ISNULL(TDR.MappingCol,'')
		JOIN CropTrait CT ON CT.CropTraitID = T3.CropTraitID
		JOIN Trait T ON T.TraitID = CT.TraitID				
		WHERE T1.TestID = @TestID			
		GROUP BY CT.CropTraitID, CT.TraitID
		ORDER BY CT.CropTraitID;

		--insert data for flow type 1 and 2 		
		INSERT INTO @Table(ID,[Name],[Type],[Order], OrderOfName)
		SELECT
			ID = CT.TraitID,			
			CONCAT(MAX(T.ColumnLabel),  '  (LimsID)'),
			2,
			ROW_NUMBER() OVER(ORDER BY  CT.CropTraitID),
			MAX(T.ColumnLabel)
		FROM TestMaterialDetermination T1
		JOIN RDTTestResult TR ON TR.DeterminationID = T1.DeterminationID AND TR.MaterialID = T1.MaterialID AND T1.TestID = TR.TestID
		JOIN TestDeterminationFlowType TDFT ON TDFT.TestID = TR.TestID AND TDFT.DeterminationID = TR.DeterminationID AND TDFT.TestFlowType IN (1, 2) --Flow Type 1 and 2
		JOIN Determination T2 ON T2.DeterminationID = T1.DeterminationID
		JOIN RelationTraitDetermination T3 ON T3.DeterminationID = T1.DeterminationID
		LEFT JOIN RDTTraitDetResult TDR ON TDR.RelationID = T3.RelationID and ISNULL(TR.MappingColumn,'') = ISNULL(TDR.MappingCol,'')
		JOIN CropTrait CT ON CT.CropTraitID = T3.CropTraitID
		JOIN Trait T ON T.TraitID = CT.TraitID				
		WHERE T1.TestID = @TestID			
		GROUP BY CT.CropTraitID, CT.TraitID
		ORDER BY CT.CropTraitID;
		
		--INSERT RESULT COLUMS
		--FLOW TYPE 1
		INSERT INTO @Table(ID,[Name],[Type],[Order], FlowType, OrderOfName)
		SELECT
			ID = CT.CropTraitID,
			CONCAT(MAX(T1.ColumnLabel),  CASE WHEN ISNULL(MAX(MappingColumn),'') <> '' THEN ' (' + MAX(MappingColumn) + ')' ELSE '' END),
			1,
			ROW_NUMBER() OVER(ORDER BY  CT.CropTraitID),
			1,
			MAX(T1.ColumnLabel)
		FROM RDTTestResult TR
		JOIN TestDeterminationFlowType TDFT ON TDFT.TestID = TR.TestID AND TDFT.DeterminationID = TR.DeterminationID AND TDFT.TestFlowType = 1  --Flow Type 1
		JOIN Determination D ON D.DeterminationID = TR.DeterminationID
		JOIN RelationTraitDetermination RTD ON RTD.DeterminationID = TR.DeterminationID --here join is enough because we do not have releation then we can igonre the result.
		JOIN RDTTraitDetResult TDR ON TDR.RelationID = RTD.RelationID AND ISNULL(TR.MappingColumn,'') = ISNULL(TDR.MappingCol,'')
		JOIN CropTrait CT ON CT.CropTraitID = RTD.CropTraitID AND CT.CropCode = @CropCode
		JOIN Trait T1 ON T1.TraitID = CT.TraitID
		WHERE TR.TestID = @TestID
		GROUP BY CT.CropTraitID
		ORDER BY CT.CropTraitID


		--FLOW TYPE 2
		INSERT INTO @Table(ID,[Name],[Type],[Order], FlowType, OrderOfName)
		SELECT
			ID = CT.CropTraitID,			
			CONCAT(MAX(T1.ColumnLabel),  CASE WHEN ISNULL(MAX(MappingColumn),'') <> '' THEN ' (' + MAX(MappingColumn) + ')' ELSE '' END),
			1,
			ROW_NUMBER() OVER(ORDER BY  CT.CropTraitID),
			2,
			MAX(T1.ColumnLabel)
		FROM RDTTestResult TR
		JOIN TestDeterminationFlowType TDFT ON TDFT.TestID = TR.TestID AND TDFT.DeterminationID = TR.DeterminationID AND TDFT.TestFlowType = 2  --Flow Type 2
		JOIN TestMaterial TM ON TM.TestID = TR.TestID
		JOIN Determination D ON D.DeterminationID = TR.DeterminationID
		JOIN RelationTraitDetermination RTD ON RTD.DeterminationID = TR.DeterminationID
		JOIN CropTrait CT ON CT.CropTraitID = RTD.CropTraitID AND CT.CropCode = @CropCode
		JOIN Trait T1 ON T1.TraitID = CT.TraitID
		--Left Join is added to fetch result which do not have result mapping
		LEFT JOIN RDTTraitDetResult TDR ON TDR.RelationID = RTD.RelationID and ISNULL(TR.MappingColumn,'') = ISNULL(TDR.MappingCol,'')
		WHERE TR.TestID = @TestID
		GROUP BY CT.CropTraitID, CT.TraitID
		ORDER BY CT.CropTraitID

		--FLOW TYPE 3
		INSERT INTO @Table(ID,[Name],[Type],[Order],FlowType, OrderOfName)
		SELECT
			ID = CONCAT(CAST(CT.CropTraitID AS NVARCHAR(MAX)), ISNULL(MappingColumn,'')),			
			CONCAT(MAX(T1.ColumnLabel),  CASE WHEN ISNULL(MappingColumn,'') <> '' THEN ' (' + MappingColumn + ')' ELSE '' END),
			1,
			ROW_NUMBER() OVER(ORDER BY  CT.CropTraitID),
			3,
			MAX(T1.ColumnLabel)
		FROM RDTTestResult TR
		JOIN TestDeterminationFlowType TDFT ON TDFT.TestID = TR.TestID AND TDFT.DeterminationID = TR.DeterminationID AND TDFT.TestFlowType = 3  --Flow Type 2
		JOIN TestMaterial TM ON TM.TestID = TR.TestID
		JOIN Determination D ON D.DeterminationID = TR.DeterminationID
		JOIN RelationTraitDetermination RTD ON RTD.DeterminationID = TR.DeterminationID
		JOIN CropTrait CT ON CT.CropTraitID = RTD.CropTraitID AND CT.CropCode = @CropCode
		JOIN Trait T1 ON T1.TraitID = CT.TraitID
		--no left join just join is required for flowtype 3
		JOIN RDTTraitDetResult TDR ON TDR.RelationID = RTD.RelationID and ISNULL(TR.MappingColumn,'') = ISNULL(TDR.MappingCol,'')
		WHERE TR.TestID = @TestID
		GROUP BY CT.CropTraitID, CT.TraitID, MappingColumn
		ORDER BY CT.CropTraitID
	END

	--columns of score
	IF(ISNULL(@IsMarkerScore,0) = 1)
	BEGIN
		SELECT 
			--@Name = COALESCE(@Name +',','') + 'ISNULL(' + QUOTENAME(ID) + ','''') AS ' + QUOTENAME([Name]),
			@IDS1 = COALESCE(@IDS1 +',','') + QUOTENAME(ID) 
		FROM @Table
		WHERE [Type] = 1
		ORDER BY [Order];
	END
	ELSE
	BEGIN
		SELECT 
			--@Name = COALESCE(@Name +',','') + 'ISNULL(' + QUOTENAME(ID) + ','''') AS ' + QUOTENAME([Name]),
			@IDS1 = COALESCE(@IDS1 +',','') + QUOTENAME(ID) 
		FROM @Table
		WHERE [Type] = 1 AND FlowType = 1
		ORDER BY [Order];

		SELECT 
			--@Name = COALESCE(@Name +',','') + 'ISNULL(' + QUOTENAME(ID) + ','''') AS ' + QUOTENAME([Name]),
			@IDS2 = COALESCE(@IDS2 +',','') + QUOTENAME(ID) 
		FROM @Table
		WHERE [Type] = 1 AND FlowType = 2
		ORDER BY [Order];

		SELECT 
			--@Name = COALESCE(@Name +',','') + 'ISNULL(' + QUOTENAME(ID) + ','''') AS ' + QUOTENAME([Name]),
			@IDS3 = COALESCE(@IDS3 +',','') + QUOTENAME(ID) 
		FROM @Table
		WHERE [Type] = 1 AND FlowType = 3
		ORDER BY [Order];
	END
	
	
	--Lims ID columns
	SELECT		
		@DetIDs = COALESCE(@DetIDS +',','') + QUOTENAME(ID) 
	FROM @Table
	WHERE [Type] = 2
	ORDER BY [Order];

	--not get names of both type
	--here first LIMS id column and then score column
	IF(ISNULL(@IsMarkerScore,0) = 1)
	BEGIN
		SELECT		
			
			@Name = CASE 
				WHEN [Type] = 2 THEN  COALESCE(@Name +',','') + 'ISNULL( TTLimsID.' + QUOTENAME(ID) + ','''') AS ' + QUOTENAME([Name])
				ELSE COALESCE(@Name +',','') + 'ISNULL( T2.' + QUOTENAME(ID) + ','''') AS ' + QUOTENAME([Name])
				END
		FROM @Table	
		ORDER BY [Name];
	EnD
	ELSE
	BEGIN
		SELECT		
			@Name = CASE 
				WHEN [Type] = 2 THEN  COALESCE(@Name +',','') + 'ISNULL( TTLimsID.' + QUOTENAME(ID) + ','''') AS ' + QUOTENAME([Name])
				WHEN FlowType = 1 THEN COALESCE(@Name +',','') + 'ISNULL( T2.' + QUOTENAME(ID) + ','''') AS ' + QUOTENAME([Name])
				WHEN FlowType = 2 THEN COALESCE(@Name +',','') + 'ISNULL( T3.' + QUOTENAME(ID) + ','''') AS ' + QUOTENAME([Name])
				WHEN FlowType = 3 THEN COALESCE(@Name +',','') + 'ISNULL( T4.' + QUOTENAME(ID) + ','''') AS ' + QUOTENAME([Name])
				END
			FROM @Table	
		ORDER BY OrderOfName, [Type] Desc, [Name]

	END
	
	--Common query
	SET @MainQuery = N'
						SELECT 
							GID = ISNULL(T1.'+@GIDColID+','''')
							,' +QuoteName(@ColumnName)+ ' = ISNULL(T1.'+@ColID+','''')
							, Folder = T.LabPlatePlanName
							,' +ISNULL(@Name,'')+'
						FROM Test T
						JOIN TestMaterial TM ON TM.TestID = T.TestID
						JOIN Material M ON M.MaterialID = TM.MaterialID
						JOIN [Row] R ON R.MaterialKey = M.MaterialKey AND R.FileID = T.FileID
					';
	--LIMS ID pivot query
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
						LEFT JOIN RDTTestResult TR ON TR.DeterminationID = T1.DeterminationID AND TR.MaterialID = T1.MaterialID AND T1.TestID = TR.TestID
						LEFT JOIN Determination T2 ON T2.DeterminationID = T1.DeterminationID
						LEFT JOIN RelationTraitDetermination T3 ON T3.DeterminationID = T1.DeterminationID
						LEFT JOIN CropTrait CT ON CT.CropTraitID = T3.CropTraitID
						LEFT JOIN Trait T ON T.TraitID = CT.TraitID				
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
									FOR DeterminationID IN ('+@IDS1+')
								) PV

							) T2 ON T2.TestID = T.TestID AND T2.MaterialID = M.MaterialID';
	--Trait score
	ELSE
	BEGIN

		--IF(@FlowType = 1)
		IF EXISTS(SELECT TOP 1 * FROM TestDeterminationFlowType WHERE TestID = @TestID AND TestFlowType = 1)
		BEGIN		
			SET @PivotQuery = ISNULL(@PivotQuery,'') + 
								N'
								LEFT JOIN
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
												MaterialID, 
												RTD.CropTraitID, 
												MappingColumn,
												Score = CASE WHEN ISNULL(TDR.TraitResult,'''') <> '''' THEN TDR.TraitResult ELSE TR.Score END
											FROM RDTTestResult  TR
											JOIN TestDeterminationFlowType TDFT ON TDFT.TestID = TR.TestID AND TDFT.DeterminationID = TR.DeterminationID AND TDFT.TestFlowType = 1 --Flow Type 1
											JOIN RelationTraitDetermination RTD ON RTD.DeterminationID = TR.DeterminationID
											LEFT JOIN RDTTraitDetResult TDR ON TDR.RelationID = RTD.RelationID AND ISNULL(TDR.DetResult,'''') = ISNULL(TR.Score,'''')
										) ResTbl 
									) SRC
									PIVOT
									(
										MAX(Score)
										FOR CropTraitID IN ('+@IDS1+')
									) PV
								) T2 ON T2.TestID = T.TestID AND T2.MaterialID = M.MaterialID';

			Print 'pivot';
			PRINT @pivotQuery;
		END
		--ELSE IF(@FlowType = 2)
		IF EXISTS(SELECT TOP 1 * FROM TestDeterminationFlowType WHERE TestID = @TestID AND TestFlowType = 2)
		BEGIN
		
			SET @PivotQuery = ISNULL(@PivotQuery,'') + 
								N'
								LEFT JOIN 
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
											JOIN TestDeterminationFlowType TDFT ON TDFT.TestID = TR.TestID AND TDFT.DeterminationID = TR.DeterminationID AND TDFT.TestFlowType = 2 --Flow Type 2
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
										FOR CropTraitID IN ('+@IDS2+')
									) PV
								) T3 ON T3.TestID = T.TestID AND T3.MaterialID = M.MaterialID';
		END
		--ELSE IF (@FlowType = 3) 
		IF EXISTS(SELECT TOP 1 * FROM TestDeterminationFlowType WHERE TestID = @TestID AND TestFlowType = 3)
		BEGIN		
			SET @PivotQuery =  ISNULL(@PivotQuery,'') + 
								N'
								LEFT JOIN 
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
												TR.TestID, 
												MaterialID, 
												RTD.CropTraitID,
												MappingColumn,
												Score = CASE WHEN ISNULL(TDR.TraitResult,'''') <> '''' THEN TDR.TraitResult ELSE TR.Score END
											FROM RDTTestResult  TR
											JOIN TestDeterminationFlowType TDFT ON TDFT.TestID = TR.TestID AND TDFT.DeterminationID = TR.DeterminationID AND TDFT.TestFlowType = 3 --Flow Type 3
											JOIN RelationTraitDetermination RTD ON RTD.DeterminationID = TR.DeterminationID
											JOIN RDTTraitDetResult TDR ON TDR.RelationID = RTD.RelationID
																		AND ISNULL(TDR.MappingCol,'''') = ISNULL(TR.MappingColumn,'''') 
										) ResTbl
									) SRC
									PIVOT
									(
										MAX(Score)
										FOR CropTraitID IN ('+@IDS3+')
									) PV
								) T4 ON T4.TestID = T.TestID AND T4.MaterialID = M.MaterialID';
		END
			
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
				' WHERE T.TestID = @TestID';		
		
	EXEC sp_executesql @Query,N' @FileID INT, @ColumnID INT, @GIDColumnID INT, @TestID INT ', @FileID, @ColumnID, @GIDColumnID, @TestID;	
END

GO
