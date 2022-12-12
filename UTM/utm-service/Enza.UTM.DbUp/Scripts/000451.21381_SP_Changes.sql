DROP PROCEDURE IF EXISTS [dbo].[PR_GET_PlatePlan_With_Result]
GO


/*
	Author					Date			Description
-------------------------------------------------------------------
	Krishna Gautam			2020-03-12		#11351: Created Stored procedure to show results to excel
	Binod Gurung			2020-12-01		#16446: Export with and without control position for BTR type
-------------------------------------------------------------------
==============================Example==============================
EXEC PR_GET_PlatePlan_With_Result 7611, NULL
*/
CREATE PROCEDURE [dbo].[PR_GET_PlatePlan_With_Result]
(
	@TestID INT,
	@WithControlPosition BIT
)
AS BEGIN
	SET NOCOUNT ON;
	

	DECLARE @StatusCode INT, @FileID INT,@ColumnID INT, @ImportLabel NVARCHAR(20),@ColumnName NVARCHAR(100),@ColID NVARCHAR(MAX), @IsBTR BIT;
	DECLARE @Query NVARCHAR(MAX), @PivotQuery NVARCHAR(MAX), @FilterQuery NVARCHAR(MAX);
	DECLARE @DeterminationsIDS NVARCHAR(MAX), @DeterminationsName NVARCHAR(MAX);
	DECLARE @DeterminationTable TABLE(DeterminationID INT, DeterminationName NVARCHAR(MAX));

	DECLARE @StartRow VARCHAR(2), @EndRow VARCHAR(2), @StartColumn INT, @EndColumn INT, @RowCounter INT, @ColumnCounter INT;
	DECLARE @StaticTable TABLE(PlateName NVARCHAR(50), WellPosition NVARCHAR(10), PlateID INT, RowID INT, TestID INT, WellID INT);
	DECLARE @TotalPlates INT, @Count INT = 0, @PlateID INT = 0,@TestType INT,@PlateName NVARCHAR(150);
	DECLARE @Table1 Table (	Position NVARCHAR(5),PlateID INT,PlateName NVARCHAR(150));
	DECLARE @Table2 TVP_Test_Wells ;
	DECLARE @TempWellTable TVP_TempWellTable;


	IF NOT EXISTS (SELECT * FROM Test WHERE TestID = @TestID)
	BEGIN
		EXEC PR_ThrowError 'Invalid Test/PlatePlan.';
		RETURN;
	END

	SELECT @FileID = FileID,@ImportLabel = ImportLevel, @IsBTR = BTR, @TestType = TestTypeID, @StatusCode = StatusCode FROM Test where TestID = @TestID;
	SELECT @TotalPlates = COUNT(PlateID) FROM Plate	WHERE TestID = @TestID; 

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
		MAX(D.DeterminationName) 
	FROM Plate P 
	JOIN Well W ON W.PlateID = P.PlateID
	JOIN TestResult TR ON TR.WellID = W.WellID
	JOIN Determination D ON D.DeterminationID = TR.DeterminationID
	WHERE P.TestID = @TestID
	GROUP BY D.DeterminationID
	ORDER BY MAX(D.DeterminationName)

	SELECT 
		@DeterminationsName = COALESCE(@DeterminationsName +',','') + 'ISNULL(' + QUOTENAME(DeterminationID) + ','''') AS ' + QUOTENAME(DeterminationName),
		@DeterminationsIDS = COALESCE(@DeterminationsIDS +',','') + QUOTENAME(DeterminationID) 
	FROM @DeterminationTable
	ORDER BY DeterminationName;

	IF((ISNULL(@StatusCode,0) <= 600 AND @IsBTR = 0))
	BEGIN
		EXEC PR_ThrowError 'Result is not available yet.';
		RETURN;
	END

	IF((ISNULL(@StatusCode,0) <= 400 AND @IsBTR = 1))
	BEGIN
		EXEC PR_ThrowError 'Unable to export.';
		RETURN;
	END

	--generate 96 wells
	SELECT @StartRow = UPPER(StartRow), @EndRow = UPPER(EndRow), @StartColumn = StartColumn,@EndColumn = EndColumn
	FROM PlateType PT
	JOIN TestType TT ON TT.PlateTypeID = PT.PlateTypeID
	JOIN Test T ON T.TestTypeID = TT.TestTypeID
	WHERE T.TestID = @TestID;
		
	SET @RowCounter=Ascii(@StartRow)
	WHILE @RowCounter<=Ascii(@EndRow)	BEGIN
		SET @ColumnCounter = @StartColumn;
		WHILE(@ColumnCounter <= @EndColumn) BEGIN							
			INSERT INTO @TempWellTable(WellID)
				VALUES(CHAR(@RowCounter)+RIGHT('00'+CAST(@ColumnCounter AS VARCHAR),2))--CAST(@ColumnCounter AS VARCHAR))
			SET @ColumnCounter = @ColumnCounter +1;
		END
		SET @RowCounter=@RowCounter+1
	END

	--if BTR = 1 AND @WithControlPosition = 1 then display all positions
	IF(ISNULL(@IsBTR,0) = 1 AND ISNULL(@WithControlPosition,0) = 1)
		SET @FilterQuery = ' ';
	ELSE --normal display without control positions
		SET @FilterQuery = ' WHERE T0.RowID IS NOT NULL ';

	--Get result from static tables
	INSERT @StaticTable (PlateName, PlateID, WellPosition, RowID, TestID, WellID)
	SELECT
		P.PlateName,
		P.PlateID,
		Well = W.Position,
		R.RowID,
		T.TestID,
		W.WellID
	FROM Test T
	JOIN [File] F ON F.FileID = T.FileID
	JOIN [Row] R ON R.FileID = F.FileID
	JOIN Plate P ON P.TestID = T.TestID
	JOIN Well W ON W.PlateID = P.PlateID
	JOIN Material M ON M.Materialkey = R.Materialkey
	JOIN TestMaterialDeterminationWell TMDW ON TMDW.WellID = W.WellID AND TMDW.MaterialID = M.MaterialID	
	WHERE T.TestID = @TestID

	--Fill plate info in Blocked well
	WHILE(@Count < @TotalPlates) BEGIN
		SELECT @PlateID = PlateID,@PlateName = PlateName
		FROM Plate 
		WHERE TestID = @TestID
		ORDER BY PlateID
		OFFSET @Count ROWS
		FETCH NEXT 1 ROWS ONLY;

		IF(@TestType = 1 OR  @TestType = 2)
		BEGIN
			INSERT INTO @Table1(Position,PlateID,PlateName)
			SELECT PositionOnPlate,@PlateID,@PlateName
			FROM WellTypePosition WTP
			JOIN WellType WT ON WT.WellTypeID = WTP.WellTypeID
			WHERE TestTypeID = @TestType;
		END

		SET @Count = @Count +1;
	END

	--Final sorted full 96 wells
	INSERT @Table2(PlateID, PlateName, Position, RowID, TestID, WellID)
	SELECT 
		PlateID = COALESCE(T1.PlateID,T2.PlateID), 
		COALESCE(T1.PlateName,T2.PlateName),  
		T1.Position,
		T1.RowID  ,
		T1.TestID,
		T1.WellID
	FROM
	(
		SELECT ST.PlateName, ST.PlateID, Position = TT.WellID, ST.RowID, ST.TestID, ST.WellID FROM @TempWellTable TT
		LEFT JOIN @StaticTable ST ON ST.WellPosition = TT.WellID
	) T1
	LEFT JOIN @Table1 T2 ON T2.Position = T1.Position
	ORDER BY PlateID, T1.Position

	SET @PivotQuery = N'LEFT JOIN 
						(
							SELECT * FROM 
							(
								SELECT WellID,ObsValueChar,DeterminationID FROM TestResult 
							) SRC
							PIVOT
							(
								MAX(ObsValueChar)
								FOR DeterminationID IN ('+@DeterminationsIDS+')
							) PV

						) T2 ON T2.WellID = T0.WellID';

	SET @DeterminationsName = ',' + @DeterminationsName;

	SET @Query = N'
				SELECT 
					T0.PlateName,
					Well = T0.Position,
					' +QuoteName(@ColumnName)+ ' = ISNULL(T1.'+@ColID+','''')
					' +ISNULL(@DeterminationsName,'')+'
				FROM @Table2 T0
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
				) T1 ON T1.RowID = T0.RowID

				'+ ISNULL(@PivotQuery,'') + @FilterQuery +	
				' ORDER BY T0.PlateID , T0.Position'

	EXEC sp_executesql @Query,N'@Table2 TVP_Test_Wells readonly, @FileID INT, @ColumnID INT ', @Table2, @FileID, @ColumnID;

END
GO


DROP PROCEDURE IF EXISTS [dbo].[PR_GetExternalTestDataForExport]
GO

/*
Authror					Date				Description
KRISHNA GAUTAM			2019-JAN-21			Get data of external test.
KRIAHNA GAUTAM			2019-MAR-27			Performance Optimization and code cleanup 
KRIAHNA GAUTAM			2019-DEC-12			Change in export logic to send Numerical ID and Sample name.
KRIAHNA GAUTAM			2020-JAN-02			Change in export to solve issue of result not imported returned correctly.
KRIAHNA GAUTAM			2020-JUNE-30		#14023: Change logic to implement change request			

=================Example===============
EXEC PR_GetExternalTestDataForExport 6577,0
*/

CREATE PROCEDURE [dbo].[PR_GetExternalTestDataForExport]
(
	@TestID INT,
	@MarkAsExported BIT = 0,
	@TraitScore BIT = 0
) AS BEGIN
	SET NOCOUNT ON;

	DECLARE @MarkerColumns NVARCHAR(MAX), @MarkerColumnIDs NVARCHAR(MAX), @Columns NVARCHAR(MAX);
	DECLARE @Offset INT, @Total INT, @Query NVARCHAR(MAX);
	DECLARE @TblMarkerColumns TABLE(ColumnID NVARCHAR(MAX), ColumnLabel NVARCHAR(100), ColumnOrder INT);
	DECLARE @TblColumns TABLE(ColumnID NVARCHAR(MAX), ColumnLabel NVARCHAR(100), ColumnOrder INT);
	DECLARE @FileID INT, @CountryCode NVARCHAR(100), @CropCode NVARCHAR(10);

	SELECT @FileID = FileID ,@CountryCode = CountryCode
	FROM Test WHERE TestID = @TestID;

	SELECT @CropCode = CropCode FROM [File] WHERE FileID = @FileID;
	--Get Markers columns only
	IF(ISNULL(@TraitScore,0) = 0) BEGIN
		INSERT INTO @TblMarkerColumns(ColumnID, ColumnLabel)
		SELECT 
			D.DeterminationID,
			DeterminationName = MAX(D.DeterminationName)
		FROM TestMaterialDetermination TMD
		JOIN Determination D ON D.DeterminationID = TMD.DeterminationID
		WHERE TMD.TestID = @TestID
		GROUP BY D.DeterminationID
		ORDER BY DeterminationName
	END
	ELSE BEGIN
		INSERT INTO @TblMarkerColumns(ColumnID, ColumnLabel)
		SELECT 			
			D.DeterminationID,
			TraitName = ISNULL( Max(T.ColumnLabel), MAX(D.DeterminationName))
		FROM TestMaterialDetermination TMD
		JOIN Determination D ON D.DeterminationID = TMD.DeterminationID
		LEFT JOIN RelationTraitDetermination RTD ON RTD.DeterminationID = TMD.DeterminationID
		LEFT JOIN CropTrait CT ON CT.CropTraitID = RTD.CropTraitID
		LEFT JOIN Trait T ON T.TraitID = CT.TraitID AND CT.CropCode = @CropCode
		WHERE TMD.TestID = @TestID 
		GROUP BY D.DeterminationID
		ORDER BY TraitName
	END

	--Get columns of imported file
	INSERT INTO @TblColumns(ColumnID, ColumnLabel,ColumnOrder)
	SELECT 
		C.ColumnID,
		ColumLabel = CASE WHEN C.ColumLabel = 'GID' THEN 'Numerical ID' 
							WHEN C.ColumLabel = 'Plant Name' THEN 'Sample Name'
							ELSE ColumLabel 
					END,
		ColumnNr = CASE WHEN C.ColumLabel = 'GID' THEN 1 
						WHEN C.ColumLabel = 'Plant Name' THEN 2
						ELSE C.COlumnNr + 4
					END
	FROM [Column] C
	JOIN Test T ON T.FileID = C.FileID
	WHERE T.TestID = @TestID
	order by c.ColumnID;

	--Get columns of markers
	SELECT 
		@MarkerColumnIDs  = COALESCE(@MarkerColumnIDs + ',', '') + QUOTENAME(ColumnID) + ' AS ' + QUOTENAME('D_' + CAST(ColumnID AS VARCHAR(10))),
		@MarkerColumns  = COALESCE(@MarkerColumns + ',', '') + QUOTENAME(ColumnID)
	FROM @TblMarkerColumns
	ORDER BY ColumnLabel;

	--Get columns of test
	SELECT 
		@Columns  = COALESCE(@Columns + ',', '') + QUOTENAME(ColumnID)
	FROM @TblColumns;

	IF(ISNULL(@Columns,'') = '') BEGIN
		EXEC PR_ThrowError 'Didn''t find any data to export';
		RETURN;
	END

	IF(ISNULL(@MarkerColumns,'') = '') BEGIN
		EXEC PR_ThrowError 'Didn''t find any determinations to export';
		RETURN;
	END


	IF(@TraitScore = 0)	BEGIN

		SET @Query = N'SELECT
			V1.Country, '+@Columns+' , '  + @MarkerColumnIDs + '  FROM
		(
			SELECT RowID, Country =  '''+@CountryCode+''' , ' + @Columns + N' 
			FROM 
			(
				SELECT RowID, ColumnID,[Value] FROM dbo.VW_IX_Cell_Material
				WHERE FileID = @FileID
				AND ISNULL([Value],'''')<>'''' 

			) SRC
			PIVOT
			(
				Max([Value])
				FOR [ColumnID] IN (' + @Columns + N')
			) PV
		) V1
		LEFT JOIN 
		(
			SELECT *
			FROM 
			(
				SELECT				
					R.RowID,
					TR.DeterminationID,
					Result = TR.ObsValueChar	
				FROM Test T
				JOIN [Row] R ON R.FileID = T.FileID
				JOIN Material M ON M.MaterialKey = R.MaterialKey
				JOIN Plate P ON P.TestID = T.TestID
				JOIN Well W ON W.PlateID = P.PlateID	
				JOIN TestMaterialDeterminationWell TMDW ON TMDW.WellID = W.WellID AND TMDW.MaterialID = M.MaterialID
				JOIN TestMaterialDetermination TMD ON TMD.MaterialID = TMDW.MaterialID AND TMD.TestID = T.TestID
				JOIN TestResult TR ON TR.DeterminationID = TMD.DeterminationID AND TR.WellID = W.WellID
				WHERE T.TestID = @TestID		
			) SRC 
			PIVOT
			(
				MAX(Result)
				FOR [DeterminationID] IN (' + @MarkerColumns + N')
			) PV
		) 
		V2 ON V2.RowID = V1.RowID
		ORDER BY V1.RowID
		';
	END
	ELSE BEGIN
		SET @Query = N'SELECT
			V1.Country, '+@Columns+' , '  + @MarkerColumnIDs + '  FROM
		(
			SELECT RowID, Country =  '''+@CountryCode+''' , ' + @Columns + N' 
			FROM 
			(
				SELECT RowID, ColumnID,[Value] FROM dbo.VW_IX_Cell_Material
				WHERE FileID = @FileID
				AND ISNULL([Value],'''')<>'''' 

			) SRC
			PIVOT
			(
				Max([Value])
				FOR [ColumnID] IN (' + @Columns + N')
			) PV
		) V1
		LEFT JOIN 
		(
			SELECT *
			FROM 
			(
				SELECT
					R.RowID,
					TR.DeterminationID,
					Result = ISNULL(TDR.TraitResChar, TR.ObsValueChar)
				FROM Test T
				JOIN [Row] R ON R.FileID = T.FileID
				JOIN Material M ON M.MaterialKey = R.MaterialKey
				JOIN Plate P ON P.TestID = T.TestID
				JOIN Well W ON W.PlateID = P.PlateID	
				JOIN TestMaterialDeterminationWell TMDW ON TMDW.WellID = W.WellID AND TMDW.MaterialID = M.MaterialID
				JOIN TestMaterialDetermination TMD ON TMD.MaterialID = TMDW.MaterialID AND TMD.TestID = T.TestID
				JOIN TestResult TR ON TR.DeterminationID = TMD.DeterminationID AND TR.WellID = W.WellID
				LEFT JOIN dbo.RelationTraitDetermination RTD ON RTD.DeterminationID = TR.DeterminationID
				LEFT JOIN dbo.TraitDeterminationResult TDR ON TDR.RelationID = RTD.RelationID AND TDR.DetResChar = TR.ObsValueChar
				WHERE T.TestID = @TestID		
			) SRC 
			PIVOT
			(
				MAX(Result)
				FOR [DeterminationID] IN (' + @MarkerColumns + N')
			) PV
		) 
		V2 ON V2.RowID = V1.RowID
		ORDER BY V1.RowID
		';
	END

	EXEC sp_executesql @Query, N'@TestID INT, @FileID INT', @TestID, @FileID;

	--Insert country record
	INSERT INTO @TblColumns(ColumnID, ColumnLabel,ColumnOrder)
	VALUES
	('Country','Country',3);

	
	SELECT ColumnID,ColumnLabel FROM 
	(
		SELECT 
			ColumnID = CAST(C1.ColumnID AS VARCHAR(10)),
			C1.ColumnLabel,
			C1.ColumnOrder,
			1 as [order]
		FROM @TblColumns C1
		UNION ALL
		SELECT 
			CONCAT('D_', CAST(C2.ColumnID AS VARCHAR(10))),
			C2.ColumnLabel,
			C2.ColumnOrder,
			2 as [order]
		FROM @TblMarkerColumns C2
	) T order by [order], ColumnOrder

	--update test with today's date if it was marked as exported
	IF(@MarkAsExported = 1) BEGIN
		UPDATE Test SET StatusCode = 700 WHERE TestID = @TestID;
	END
END
GO


