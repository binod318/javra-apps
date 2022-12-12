
/*
	Author					Date			Description
-------------------------------------------------------------------
	Krishna Gautam			2020-03-12		#11351: Created Stored procedure to show results to excel
	Binod Gurung			2020-12-01		#16446: Export with and without control position for BTR type
	Binod Gurung			2022-04-22		#36609: Export data in excel for dna isolation type.
-------------------------------------------------------------------
==============================Example==============================
EXEC PR_GET_PlatePlan_With_Result 7611, NULL
*/
ALTER PROCEDURE [dbo].[PR_GET_PlatePlan_With_Result]
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
	DECLARE @DeadWellTypeID INT;

	SELECT @DeadWellTypeID = WellTypeID FROM WellType WHERE WellTypeName = 'D';


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

	IF(@TestType = 2 )
	BEGIN
		EXEC PR_GET_Test_With_Plate_And_Well @TestID, 1;
		RETURN;
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

	--for dna test type we can export data without result
	

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
				' +QuoteName(@ColumnName)+ ' = ISNULL(T1.'+@ColID+','''')
					,T0.PlateName,
					Well = T0.Position					
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

	--now get the dead material
	SELECT PlateName, W.Position FROM Well W
	JOIN Plate P ON P.PlateID = W.PlateID
	JOIN Test T ON T.TestID = P.TestID
	WHERE WellTypeID = @DeadWellTypeID AND T.TestID = @TestID;

END

GO


/*
	Author					Date			Description
-------------------------------------------------------------------
	Krishna Gautam			2020-03-16		#11243 : Created Stored procedure to test detail in excel
	Binod Gurung			2021-05-10		#21339 : Export with/without control position for both 2GB/DNA Isolation
-------------------------------------------------------------------
==============================Example==============================
EXEC PR_GET_Test_With_Plate_And_Well 5575, NULL
*/

ALTER PROCEDURE [dbo].[PR_GET_Test_With_Plate_And_Well]
(
	@TestID INT,
	@WithControlPosition BIT = NULL
)
AS BEGIN
	SET NOCOUNT ON;

	DECLARE @StatusCode INT, @FileID INT,@ColumnID INT, @ImportLabel NVARCHAR(20),@ColumnName NVARCHAR(100),@ColID NVARCHAR(MAX),@Query NVARCHAR(MAX);

	DECLARE @StartRow VARCHAR(2), @EndRow VARCHAR(2), @StartColumn INT, @EndColumn INT, @RowCounter INT, @ColumnCounter INT, @FilterQuery NVARCHAR(MAX);
	DECLARE @StaticTable TABLE(PlateName NVARCHAR(50), WellPosition NVARCHAR(10), PlateID INT, RowID INT, TestID INT, WellID INT);
	DECLARE @TotalPlates INT, @Count INT = 0, @PlateID INT = 0,@TestType INT,@PlateName NVARCHAR(150);
	DECLARE @Table1 Table (	Position NVARCHAR(5),PlateID INT,PlateName NVARCHAR(150));
	DECLARE @Table2 TVP_Test_Wells ;
	DECLARE @TempWellTable TVP_TempWellTable;
	DECLARE @DeadWellTypeID INT;

	SELECT @DeadWellTypeID = WellTypeID FROM WellType WHERE WellTypeName = 'D';

	IF NOT EXISTS (SELECT * FROM Test WHERE TestID = @TestID)
	BEGIN
		EXEC PR_ThrowError 'Invalid Test/PlatePlan.';
		RETURN;
	END

	SELECT @FileID = FileID,@ImportLabel = ImportLevel,@TestType = TestTypeID FROM Test where TestID = @TestID;
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
	
	--if @WithControlPosition = 1 then display all positions
	IF(ISNULL(@WithControlPosition,0) = 1)
		SET @FilterQuery = ' ';
	ELSE --normal display without control positions
	BEGIN
		SET @FilterQuery = ' WHERE T0.Position NOT IN (SELECT PositionOnPlate FROM WellTypePosition WTP WHERE WTP.TestTypeID = @TestType) ';
	END

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
	LEFT JOIN @Table1 T2 ON T2.Position = T1.Position AND T1.PlateID IS NULL
	ORDER BY PlateID, T1.Position
	
	SET @Query = N'
		SELECT			
			' +QuoteName(ISNULL(@ColumnName,''))+ ' = T1.'+@ColID+',
			T0.PlateName,
			--[Row] = LEFT(W.Position,1),
			--Well = CAST(SUBSTRING(W.Position,2,2) AS INT)
			Well = T0.Position
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

		)T1 ON T0.RowID = T1.RowID
		' + @FilterQuery +	
		' ORDER BY T0.PlateID , T0.Position' --T0.WellID

	EXEC sp_executesql @Query,N'@Table2 TVP_Test_Wells readonly, @FileID INT, @TestID INT, @ColumnID INT, @TestType INT ', @Table2, @FileID, @TestID, @ColumnID, @TestType;

	--now get the dead material
	SELECT PlateName, W.Position FROM Well W
	JOIN Plate P ON P.PlateID = W.PlateID
	JOIN Test T ON T.TestID = P.TestID
	WHERE WellTypeID = @DeadWellTypeID AND T.TestID = @TestID;
END
GO