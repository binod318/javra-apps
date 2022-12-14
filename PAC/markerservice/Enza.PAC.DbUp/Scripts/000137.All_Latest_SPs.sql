
/*
Author					Date			Remarks
Krishna Gautam			2020/01/14		Created Stored procedure to fetch data of provided periodID
Binod Gurung			2020-jan-23		Transcation isolation level implemented to avoid record lock

=================EXAMPLE=============

EXEC PR_GetPlatesOverview 4792
*/

ALTER PROCEDURE [dbo].[PR_GetPlatesOverview]
(
	@PeriodID INT
)
AS 
BEGIN

	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
	DECLARE @PeriodName NVARCHAR(50);
	DECLARE @TempTBL TABLE (TestID INT, NrOfSeeds INT,PeriodName NVARCHAR(50));
	
	IF NOT EXISTS(SELECT PeriodID FROM [Period] WHERE PeriodID = @PeriodID)
	BEGIN
		EXEC PR_ThrowError 'Invalid PeriodID';
		RETURN;
	END
	
	SELECT @PeriodName = CONCAT(PeriodName, FORMAT(StartDate, ' (MMM-dd-yy - ', 'en-US' ), FORMAT(EndDate, 'MMM-dd-yy)', 'en-US' ))
	FROM [Period] WHERE PeriodID = @PeriodID;

	INSERT INTO @TempTBL(TestID, NrOfSeeds,PeriodName)
		SELECT T.TestID, M.NrOfSeeds, @PeriodName FROM Test T 
		JOIN TestDetAssignment TDA ON T.TestID = TDA.TestID
		JOIN DeterminationAssignment DA ON DA.DetAssignmentID = TDA.DetAssignmentID
		JOIN Method M ON M.MethodCode = DA.MethodCode
		WHERE T.PeriodID = @PeriodID
		GROUP BY T.TestID, NrOfSeeds
	
	SELECT 
		T.FolderNr, 
		T.PlateID, 
		T.PlateNumber,
		Position = CASE WHEN NrOfSeeds = 23 THEN REPLACE(T.Position,'-','+')
						WHEN NrOfSeeds >=92 THEN ''
						ELSE T.Position
					END,
		T.BatchNr, 
		T.SampleNr, 
		PeriodName = @PeriodName,
		ReportType = CASE 
						WHEN NrOfSeeds = 23 THEN 1
						WHEN NrOfSeeds = 46 THEN 2
						WHEN NrOfSeeds >=92 THEN 3
						END
	FROM 
	(
	SELECT 
		FolderNr = MAX(T.TestName),
		W.PlateID,  
		PlateNumber = MAX(P.PlateName) , 
		Position = CONCAT(LEFT(MIN(w.Position),1),'-',LEFT(MAX(w.Position),1)) , 
		BatchNr= Max(DA.BatchNr), 
		SampleNr = MAX(DA.SampleNr), 
		W.DetAssignmentID,
		T.TestID,
		NrOfSeeds = MAX(T1.NrOfSeeds)
	FROM Test T
	JOIN @TempTBL T1 ON T1.TestID = T.TestID
	JOIN plate p ON T.TestID = P.TestID
	JOIN well W on W.PlateID = P.PlateID
	LEFT JOIN DeterminationAssignment DA ON DA.DetAssignmentID = W.DetAssignmentID
	LEFT JOIN Method M ON M.MethodCode = DA.MethodCode	
	WHERE W.Position NOT IN ('B01','D01','F01','H01') AND T.PeriodID = @PeriodID
	GROUP BY T.TestID, W.DetAssignmentID,W.PlateID 
	) T
	ORDER BY NrOfSeeds, T.PlateID, Position

END

GO



/*
Author					Date			Remarks
Binod Gurung			2020-jan-23		Transcation isolation level implemented to avoid record lock

=================EXAMPLE=============

-- [PR_GetDataForDecisionDetailScreen] 1444777
*/

ALTER PROCEDURE [dbo].[PR_GetDataForDecisionDetailScreen]
(
    @DetAssignmentID INT
) 
AS 
BEGIN
    SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
	DECLARE @SQL NVARCHAR(MAX), @Columns NVARCHAR(MAX), @Columns2 NVARCHAR(MAX);

	SELECT
		@Columns = COALESCE(@Columns + ',', '') + QUOTENAME(MarkerID),
		@Columns2 = COALESCE(@Columns2 + ',', '') + QUOTENAME(MarkerID) + 'AS' + QUOTENAME(MarkerFullName)
	FROM
	(
		SELECT DISTINCT 
		   PR.MarkerID,
		   M.MarkerFullName    
		FROM Pattern P
		JOIN PatternResult PR ON PR.PatternID = P.PatternID
		JOIN Marker M ON M.MarkerID = PR.MarkerID
		WHERE P.DetAssignmentID = @DetAssignmentID
	) C;

	IF(ISNULL(@Columns, '') <> '')
	BEGIN
		SET @SQl = N'SELECT 
			[Pat#] = ROW_NUMBER() OVER (ORDER BY P.NrOfSamples DESC),
			[Sample] = P.NrOfSamples,
			[Sam%] = P.SamplePer,
			[Type:] = P.[Type],
			[Matching Varieties] = P.MatchingVar,
			' + @Columns2 + '
		FROM Pattern P
		JOIN
		(
			SELECT * FROM 
			(
				SELECT 
					P.PatternID,
					PR.MarkerID,
					PR.Score
				FROM Pattern P
				JOIN PatternResult PR ON PR.PatternID = P.PatternID
				WHERE P.DetAssignmentID = @DetAssignmentID
			) V1
			PIVOT
			(
				MAX(Score)
				FOR MarkerID IN(' + @Columns + ')
			) P1
		) P2 ON P2.PatternID = P.PatternID
		ORDER BY P.NrOfSamples DESC';
	END;
	ELSE 
	BEGIN
		SET @SQl = N'SELECT 
						[Pat#] = ROW_NUMBER() OVER (ORDER BY P.NrOfSamples DESC),
						[Sample] = P.NrOfSamples,
						[Sam%] = P.SamplePer,
						[Type:] = P.[Type],
						[Matching Varieties] = P.MatchingVar
					FROM Pattern P
					WHERE P.DetAssignmentID = @DetAssignmentID
					ORDER BY P.NrOfSamples DESC'
	END;

	EXEC sp_executesql @SQL, N'@DetAssignmentID INT', @DetAssignmentID;

END
GO

/*
Author					Date			Remarks
Binod Gurung			2020-jan-23		Transcation isolation level implemented to avoid record lock

=================EXAMPLE=============

--EXEC PR_GetDataForDecisionScreen 1568336
*/

ALTER PROCEDURE [dbo].[PR_GetDataForDecisionScreen]
(
    @DetAssignmentID INT
) 
AS 
BEGIN
    SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

	DECLARE @PeriodID INT;

	SELECT 
		@PeriodID = MAX(T.PeriodID)
	FROM Test T
	LEFT JOIN Plate P On P.TestID = T.TestID 
	LEFT JOIN Well W ON W.PlateID = P.PlateID
	WHERE W.DetAssignmentID = @DetAssignmentID --AND T.StatusCode = 500
	GROUP BY T.TestID
	
	--TestInfo
	SELECT 
		FolderName = MAX(T.TestName),
		Plates = 
		STUFF 
		(
			(
				SELECT ', ' + PlateName FROM Plate WHERE TestID = T.TestID FOR  XML PATH('')
			), 1, 2, ''
		),
		LastExport = CAST (GETDATE() AS DATETIME)
	FROM Test T
	LEFT JOIN Plate P On P.TestID = T.TestID 
	LEFT JOIN Well W ON W.PlateID = P.PlateID
	WHERE W.DetAssignmentID = @DetAssignmentID --AND T.StatusCode = 500
	GROUP BY T.TestID

	--DetAssignmentInfo
	SELECT 
		SampleNr,
		BatchNr,
		DetAssignmentID,
		Remarks,
		S.StatusName
	FROM DeterminationAssignment DA
	JOIN [Status] S ON S.StatusCode = Da.StatusCode AND S.StatusTable = 'DeterminationAssignment'
	WHERE DetAssignmentID = @DetAssignmentID

	--ResultInfo
	SELECT
		QualityClass = MAX(DA.QualityClass),
		OffTypes =  CAST ((MAX(Deviation) + '/' + MAX(ActualSamples)) AS NVARCHAR(20)) ,
		Inbred = CAST ((MAX(Inbreed) + '/' + MAX(ActualSamples)) AS NVARCHAR(20)),
		PossibleInbred = CAST ((MAX(Inbreed) + '/' + MAX(ActualSamples)) AS NVARCHAR(20)),
		TestResultQuality = CAST ((MAX(DA.ActualSamples) * 100 / SUM(P.NrOfSamples) + '%') AS NVARCHAR(20))
	FROM DeterminationAssignment DA
	JOIN Pattern P On P.DetAssignmentID = DA.DetAssignmentID 
	WHERE DA.DetAssignmentID = @DetAssignmentID
	GROUP BY DA.DetAssignmentID

	--ValidationInfo
	SELECT
		[Date] = FORMAT(ValidatedOn, 'yyyy-MM-dd', 'en-US'),
		[UserName] = ISNULL(ValidatedBy, '')
	FROM DeterminationAssignment
	WHERE DetAssignmentID = @DetAssignmentID

	--VarietyInfo
	EXEC PR_GetDeclusterResult @PeriodID, @DetAssignmentID;

END

GO

/*
Author					Date			Remarks
Binod Gurung			2020-jan-23		Transcation isolation level implemented to avoid record lock

=================EXAMPLE=============

--EXEC PR_GetDeclusterResult 4792, 1203784
*/

ALTER PROCEDURE [dbo].[PR_GetDeclusterResult]
(
    @PeriodID		    INT,
    @DetAssignmentID    INT
) AS BEGIN
    SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    DECLARE @StartDate DATE, @EndDate DATE;

    DECLARE @Variety TVP_Variety;
    DECLARE @Markers TABLE(MarkerID INT, MarkerName NVARCHAR(100), InIMS BIT, DisplayOrder INT);
    DECLARE @Determinations TABLE(DetAssignmentID INT);
    
    DECLARE @SQL NVARCHAR(MAX);
    DECLARE @Columns NVARCHAR(MAX);    
    
    SELECT
	   @StartDate = StartDate,
	   @EndDate = EndDate
    FROM [Period] 
    WHERE PeriodID = @PeriodID;    	      

    INSERT @Variety(VarietyNr, VarietyName, DisplayOrder)
    SELECT DISTINCT
	   V2.VarietyNr, 
	   V2.Shortname,
	   DisplayOrder =  CASE 
					   WHEN V2.VarietyNr = V1.Male THEN 3
					   WHEN V2.VarietyNr = V1.FeMale THEN 2
					   ELSE 1
				    END
    FROM
    (
	   SELECT
		  V.VarietyNr,
		  V.Female,
		  V.Male
	   FROM TestDetAssignment TDA
	   JOIN DeterminationAssignment DA ON DA.DetAssignmentID = TDA.DetAssignmentID
	   JOIN Variety V ON V.VarietyNr = DA.VarietyNr
	   WHERE DA.StatusCode = 300 
	   AND CAST(DA.PlannedDate AS DATE) BETWEEN @StartDate AND @EndDate
	   AND DA.DetAssignmentID = @DetAssignmentID
    ) V1
    JOIN Variety V2 ON V2.VarietyNr IN (V1.VarietyNr, V1.Female, V1.Male);

    INSERT @Determinations(DetAssignmentID)
    SELECT
	   MIN(DA.DetAssignmentID)
    FROM DeterminationAssignment DA
    JOIN @Variety V ON V.VarietyNr = DA.VarietyNr
    WHERE DA.StatusCode = 300 
    AND CAST(DA.PlannedDate AS DATE) BETWEEN @StartDate AND @EndDate
    GROUP BY DA.VarietyNr;
    
    --Prepare markers
    INSERT @Markers(MarkerID, MarkerName, InIMS, DisplayOrder)
	SELECT 
		M.MarkerID,
		M.MarkerFullName,
		M1.InIMS,
		M.MarkerID + 3
	FROM
	(
		SELECT 
			MarkerID,
			MTT.InIMS
		FROM MarkerToBeTested MTT
		JOIN @Determinations D ON D.DetAssignmentID = MTT.DetAssignmentID
		UNION
		SELECT
			MarkerID,
			0
		FROM
		MarkerPerVariety MPV
		JOIN @Variety V1 On V1.VarietyNr = MPV.VarietyNr 
		WHERE MPV.StatusCode = 100
	) M1
    JOIN Marker M ON M.MarkerID = M1.MarkerID

    SELECT 
	   @Columns  = COALESCE(@Columns + ',', '') + QUOTENAME(MarkerID)
    FROM @Markers C
	GROUP BY MarkerID
	ORDER By MarkerID;
	
    SET @Columns = ISNULL(@Columns, '');
	PRINT @Columns;
    SET @SQL = N'SELECT 
	   V.VarietyNr, 
	   V.VarietyName,
	   VarietyType = CASE 
		  WHEN V.DisplayOrder = 1 THEN ''Variety''
		  WHEN V.DisplayOrder = 2 THEN ''Female''
		  WHEN V.DisplayOrder = 3 THEN ''Male''
		  ELSE ''''
	   END ' +
	   CASE WHEN @Columns = '' THEN '' ELSE ', ' + @Columns END + 
    N'FROM @Variety V ' + 
    CASE WHEN @Columns = '' THEN '' ELSE
	   N'LEFT JOIN
	   (
		  SELECT * FROM 
		  (
			  SELECT 
				MVP.VarietyNr,
				MVP.MarkerID,
				[Value] = MVP.AlleleScore
			 FROM MarkerValuePerVariety MVP
			 JOIN @Variety V1 On V1.VarietyNr = MVP.VarietyNr
			 LEFT JOIN DeterminationAssignment DA ON DA.VarietyNr = MVP.VarietyNr
			 LEFT JOIN MarkerToBeTested MTT ON MTT.MarkerID = MVP.MarkerID AND MTT.DetAssignmentID = DA.DetAssignmentID
			 UNION
			 SELECT 
				MPV.VarietyNr,
				MPV.MarkerID,
				[Value] = MPV.ExpectedResult
			 FROM
			 MarkerPerVariety MPV
			 JOIN @Variety V1 On V1.VarietyNr = MPV.VarietyNr
			 WHERE MPV.StatusCode = 100
		  ) V
		  PIVOT
		  (
			 MAX([Value])
			 FOR MarkerID IN(' + @Columns + N')
		  ) P
	   ) M ON M.VarietyNr = V.VarietyNr '  
    END + 
    N'ORDER BY V.DisplayOrder';
	print @SQL;
    EXEC sp_executesql @SQL, N'@Variety TVP_Variety READONLY', @Variety;

	SELECT 
		ColumnID, 
		ColumnLabel, 
		InIMS
	FROM
	(
		SELECT *
		FROM
		(
			VALUES
			('VarietyNr', 'Variety Nr', 0, 0),
			('VarietyName', 'Variety Name', 0, 1),
			('VarietyType', 'Variety Type', 0, 2)
		) V(ColumnID, ColumnLabel, InIMS, [DisplayOrder]  )
		UNION
		SELECT 
			ColumnID = CAST(MarkerID AS VARCHAR(10)), 
			ColumnLabel = MarkerName,
			InIMS,
			DisplayOrder
		FROM @Markers
	) V1
	ORDER BY DisplayOrder
	
END

GO

/*
Author					Date			Remarks
Binod Gurung			2020-jan-23		Transcation isolation level implemented to avoid record lock

=================EXAMPLE=============

-- PR_GetDeterminationAssigmentForSetABS 4779
*/

ALTER PROCEDURE [dbo].[PR_GetDeterminationAssigmentForSetABS]
(
    @PeriodID INT
) 
AS 
BEGIN
    SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

	DECLARE @StartDate DATE, @EndDate DATE;
    DECLARE @PlatformID INT = (SELECT PlatformID FROM [Platform] WHERE PlatformCode = 'LS'); --light scanner   

    SELECT
	   @StartDate = StartDate,
	   @EndDate = EndDate
    FROM [Period]
    WHERE PeriodID = @PeriodID;

	SELECT 
		DetAssignmentID,
		2
	FROM DeterminationAssignment DA
	JOIN
    (
	   SELECT
		  AC.ABSCropCode,
		  PM.MethodCode
	   FROM CropMethod CM
	   JOIN ABSCrop AC ON AC.ABSCropCode = CM.ABSCropCode
	   JOIN Method PM ON PM.MethodID = CM.MethodID
	   WHERE CM.PlatformID = @PlatformID
    ) V1 ON V1.ABSCropCode = DA.ABSCropCode AND V1.MethodCode = DA.MethodCode
    JOIN Variety V ON V.VarietyNr = DA.VarietyNr
	WHERE CAST(DA.PlannedDate AS DATE) BETWEEN @StartDate AND @EndDate AND DA.StatusCode IN (200,300)

END
GO


/*
Author					Date			Remarks
Binod Gurung			2020-jan-21		Get information for UpdateDA
Binod Gurung			2020-jan-23		Transcation isolation level implemented to avoid record lock

=================EXAMPLE=============
EXEC PR_GetInfoForUpdateDA 1568336
*/
ALTER PROCEDURE [dbo].[PR_GetInfoForUpdateDA]
(
	@DetAssignmentID INT
)
AS
BEGIN
	
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;


	SELECT
		DetAssignmentID = Max(DA.DetAssignmentID),
		ValidatedOn		= FORMAT(MAX(ValidatedOn), 'yyyy-MM-dd', 'en-US'),
		Result			= CAST ((MAX(DA.ActualSamples) * 100 / SUM(P.NrOfSamples)) AS DECIMAL),
		QualityClass	= MAX(QualityClass),
		ValidatedBy		= MAX(ValidatedBy)
	FROM DeterminationAssignment DA
	LEFT JOIN Pattern P On P.DetAssignmentID = DA.DetAssignmentID 
	WHERE DA.DetAssignmentID = @DetAssignmentID
	GROUP BY DA.DetAssignmentID
	
END

GO


