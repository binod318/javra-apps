
ALTER PROCEDURE [dbo].[PR_PlateFillingForGroupTesting]
(
	@TestID INT
)
AS
BEGIN
	
	
	DECLARE @PlatesRequired INT =0, @TotalNrSample INT = 0, @PlatesCreated INT=0, @TotalWellsPerPlate INT, @TempWellTable TVP_TempWellTable,@TVP_Well TVP_Material, @TVP_Material TVP_Material,@MaterialWithWell TVP_TMDW;
	DECLARE @StartRow VARCHAR(2), @EndRow VARCHAR(2), @StartColumn INT, @EndColumn INT, @RowCounter INT, @ColumnCounter INT,@PlateID INT, @StatusCode INT;
	DECLARE @FileName NVARCHAR(MAX),@Crop NVARCHAR(MAX),@AssignedWellTypeID INT, @EmptyWellTypeID INT,@FixedWellTypeID INT,@TotalMaterial INT,@Count INT= 1,@NrOfSample INT=1, @NrOfSampleCount INT =0, @MaterialID INT;
	DECLARE @TestTypeID INT =0, @DeterminationRequired BIT,@WellsPerPlate INT=0;
	DECLARE @PlateToDelete TABLE(PlateID INT);
	DECLARE @ExcludeControlPosition BIT = 0;

		
	DECLARE @TVP_MaterialsWithNrOfSample AS TABLE(ID INT IDENTITY(1,1),MaterialID INT, NrOfSample INT);

	SELECT @FileName = F.FileTitle, @Crop = F.CropCode 
	FROM Test T 
	JOIN [File] F ON F.FileID = T.FileID WHERE T.TestID = @TestID;


	SELECT @StatusCode = StatusCode,@TestTypeID = TestTypeID
	FROM Test WHERE TestID = @TestID;

	SELECT @AssignedWellTypeID = WelltypeID 
	FROM WellType WHERE WellTypeName = 'A';
		
	SELECT @EmptyWellTypeID = WellTypeID
	FROM WellType WHERE WellTypeName = 'E';

	SELECT @FixedWellTypeID = WellTypeID
	FROM WellType WHERE WellTypeName = 'F';

	SELECT @DeterminationRequired = DeterminationRequired FROM TestType TT
	JOIN Test T ON T.TestTypeID = TT.TestTypeID AND T.TestID = @TestID;



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
				VALUES(CHAR(@RowCounter)+RIGHT('00'+CAST(@ColumnCounter AS VARCHAR),2))
			SET @ColumnCounter = @ColumnCounter +1;
		END
		SET @RowCounter=@RowCounter+1
	END
	IF(@TestTypeID = 1 OR (ISNULL(@ExcludeControlPosition,0) = 1 AND @TestTypeID = 2))
	BEGIN
		DELETE TT 
		FROM @TempWellTable TT
		JOIN WellTYpePosition WTP ON WTP.PositionOnPlate = TT.WellID
		JOIN WellType WT ON WT.WellTypeID = WTP.WellTypeID
		JOIN Test T ON T.TestTypeID = WTP.TestTypeID
		WHERE T.TestID = @TestID AND WT.WellTypeName = 'B'
	END

	SELECT @TotalWellsPerPlate = Count(NR) 
	FROM @TempWellTable TT1

	IF(@DeterminationRequired = 0)
	BEGIN
		SELECT @TotalNrSample = SUM(ISNULL(NrOfSamples,1))
		FROM [ROW] R
		JOIN Test T ON T.FileID = R.FileID
		WHERE T.TestID = @TestID AND R.Selected = 1;
		SELECT @PlatesRequired = CEILING (CAST(@TotalNrSample AS FLOAT) / CAST(@TotalWellsPerPlate AS FLOAT))

	END

	ELSE 
	BEGIN
		SELECT @TotalNrSample = SUM(NrOfSamples)
		FROM 
		(
			SELECT NrOfSamples = MAX(ISNULL(NrOfSamples,1))
			FROM [Test] T
			JOIN [ROW] R ON R.FileID = T.FileID
			JOIN Material M ON M.MaterialKey = R.MaterialKey
			JOIN TestMaterialDetermination TMD ON TMD.MaterialID = M.MaterialID AND TMD.TestID = @TestID
			WHERE T.TestID = @TestID
			GROUP BY M.MaterialID
		) T

		SELECT @PlatesRequired = CEILING (CAST(@TotalNrSample AS FLOAT) / CAST(@TotalWellsPerPlate AS FLOAT))

	END
		
	SELECT @PlatesCreated = ISNULL(COUNT(PlateID),0)
	FROM Plate P 
	JOIN Test T ON T.TestID = P.TestID
	WHERE T.TestID = @TestID;

	IF(@StatusCode > 200 AND @PlatesRequired > @PlatesCreated) BEGIN
		EXEC PR_ThrowError 'This requires more plates than reserved on LIMS. Reduce number of samples.';
		RETURN;
	END
	--create plate and well if not created
	WHILE(@PlatesCreated < @PlatesRequired) BEGIN
		--Create Plate here
		INSERT INTO Plate (PlateName,TestID)
		VALUES(@Crop +'_' + @FileName + '_' +RIGHT('000'+CAST(@PlatesCreated +1 AS NVARCHAR),2) ,@TestID);
		SELECT @PlateID = @@IDENTITY;
			
		--Create well here	
		INSERT INTO Well(PlateID,WellTypeID,Position)
		SELECT @PlateID,@AssignedWellTypeID, WellID FROM @TempWellTable ORDER BY Nr
		SET @PlatesCreated = @PlatesCreated + 1
	END


	IF(@DeterminationRequired = 0)
	BEGIN
		INSERT INTO @TVP_MaterialsWithNrOfSample(MaterialID, NrOfSample) 
		SELECT MaterialID,ISNULL(R.NrOfSamples,1)
		FROM Material M 
		JOIN [Row] R ON R.MaterialKey = M.MaterialKey
		JOIN Test T ON T.FileID = R.FileID
		WHERE T.TestID = @TestID AND R.Selected = 1
		ORDER BY R.RowNr;

	END

	ELSE
	BEGIN
		INSERT INTO @TVP_MaterialsWithNrOfSample(MaterialID, NrOfSample) 
		SELECT M.MaterialID,MAX(ISNULL(R.NrOfSamples,1))
		FROM Material M 
		JOIN [Row] R ON R.MaterialKey = M.MaterialKey
		JOIN Test T ON T.FileID = R.FileID
		JOIN TestMaterialDetermination TMD ON TMD.MaterialID = M.MaterialID AND TMD.TestID = @TestID
		WHERE T.TestID = @TestID
		GROUP BY M.MaterialID,R.RowNr
		ORDER BY R.RowNr;
	END
	

	SELECT @TotalMaterial = COUNT(MaterialID)
	FROM @TVP_MaterialsWithNrOfSample;

	--this loop is used to insert ordered material(list) into temptable
	WHILE(@Count <= @TotalMaterial) BEGIN

		SELECT @NrOfSample = NrOfSample, @MaterialID = MaterialID FROM @TVP_MaterialsWithNrOfSample WHERE ID = @Count;
		SET @NrOfSampleCount = 0;
		WHILE(@NrOfSampleCount < @NrOfSample) BEGIN
				
			INSERT INTO @TVP_Material(MaterialID)
			Values(@MaterialID)

			SET @NrOfSampleCount = @NrOfSampleCount +1
		END
		SET @Count = @Count +1
	END

	--insert ordered well into temptable
	INSERT INTO @TVP_Well(MaterialID)
	SELECT T.WellID
	FROM 
	(
		SELECT W.*, CAST(RIGHT(Position,LEN(Position)-1) AS INT) AS Position1
		,LEFT(Position,1) as Position2
		FROM Well W
		JOIN Plate P ON P.PlateID = W.PlateID
		WHERE P.TestID = @TestID
	) T
	ORDER BY PlateID,Position2,Position1

	--get this temptable to merge into table testmaterialdeterminationwell
	INSERT INTO @MaterialWithWell(MaterialID,WellID)
	SELECT M.MaterialID, W.MaterialID FROM @TVP_Material M
	JOIN @TVP_Well W ON W.RowNr = M.RowNr

	SELECT @TotalMaterial = COUNT(*) FROM @TVP_Material
	--delete last empty well which can be shifted forward on position.
	DELETE TMDW
	FROM TestMaterialDeterminationWell TMDW
	WHERE TMDW.WellID IN (SELECT MaterialID FROM @TVP_Well WHERE RowNr > @TotalMaterial)

	--insert or update data 
	MERGE TestMaterialDeterminationWell T
	USING @MaterialWithWell S
	ON T.WellID = S.WellID
	WHEN NOT MATCHED THEN 
	INSERT (MaterialID,WellID)
	VALUES (S.MaterialID,S.WellID)
	WHEN MATCHED AND T.MaterialID <> S.MaterialID THEN
	UPDATE SET T.MaterialID = S.MaterialID;

	--update welltype to assigned well type which contains material
	UPDATE W
	SET W.WellTypeID = @AssignedWellTypeID
	FROM Well W 
	JOIN @MaterialWithWell MW ON MW.WellID = W.WellID
	WHERE W.WellTypeID != @AssignedWellTypeID

		
	--update welltype to emtpy well which do not contain any meterial
	UPDATE W
	SET W.WellTypeID = @EmptyWellTypeID
	FROM Well W 
	JOIN @TVP_Well TW ON TW.MaterialID = W.WellID
	WHERE TW.RowNr > @TotalMaterial AND W.WellTypeID != @EmptyWellTypeID


	--remove unnecessary plates and well if sample is reduced.
	IF(@StatusCode < 200) BEGIN	
		
		select TOP 1 @WellsPerPlate = COUNT(W.WellID) FROM Plate P 
		JOIN Well W ON W.PlateID = P.PlateID
		where P.TestID = @TestID
		GROUP BY P.PlateID
			
		select TOP 1 @WellsPerPlate = COUNT(W.WellID) FROM Plate P 
		JOIN Well W ON W.PlateID = P.PlateID
		where P.TestID = @TestID
		GROUP BY P.PlateID
									
		INSERT INTO @PlateToDelete(PlateID)
		SELECT PlateID FROM
		(
			SELECT T.PlateID,SUM([Count]) AS [Count] FROM 
			(
				SELECT P.PlateID,WellTypeID,Count(WelltypeID) AS [Count] FROM Well W
							JOIN Plate P ON P.PlateID = W.PlateID
							WHERE P.TestID = @TestID
							GROUP BY P.PlateID,W.WellTypeID
			)T WHERE T.WellTypeID IN (@EmptyWellTypeID,@FixedWellTypeID)
			GROUP BY PlateID
		)T1 WHERE [Count] = @WellsPerPlate

		--delete from TestMaterialDeterminationWell if material present
		DELETE TMDW FROM TestMaterialDeterminationWell TMDW
		JOIN Well W ON W.WellID = TMDW.WellID
		JOIN @PlateToDelete P on P.PlateID = W.PlateID;

		--delete from well if all well are empty or fixed position
		DELETE W FROM Well W
		JOIN @PlateToDelete P ON P.PlateID = W.PlateID
				
		--delete plate no well is found
		DELETE P FROM Plate P 
		JOIN @PlateToDelete PD ON Pd.PlateID = P.PlateID;
	END

END
