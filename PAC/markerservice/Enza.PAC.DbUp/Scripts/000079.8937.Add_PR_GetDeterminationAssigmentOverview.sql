DROP PROCEDURE IF EXISTS [dbo].[PR_GetDeterminationAssigmentOverview]
GO

-- PR_GetDeterminationAssigmentOverview 4779
CREATE PROCEDURE [dbo].[PR_GetDeterminationAssigmentOverview]
(
    @PeriodID INT
) AS BEGIN
    SET NOCOUNT ON;

	DECLARE @StartDate DATE, @EndDate DATE;
    DECLARE @PlatformID INT = (SELECT PlatformID FROM [Platform] WHERE PlatformCode = 'LS'); --light scanner   

    SELECT
	   @StartDate = StartDate,
	   @EndDate = EndDate
    FROM [Period]
    WHERE PeriodID = @PeriodID;

	SELECT 
	   DA.DetAssignmentID,
	   DA.SampleNr,   
	   DA.BatchNr,
	   Article = V.Shortname,
	   'Status' = COALESCE(S.StatusName, CAST(DA.StatusCode AS NVARCHAR(10))),
	   'Exp Ready' = DA.ExpectedReadyDate, 
	   V2.Folder,
	   'Quality Class' = DA.QualityClass
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
	JOIN
	(
		SELECT W.DetAssignmentID, MAX(T.TestName) AS Folder FROM Test T
		JOIN Plate P ON P.TestID = T.TestID
		JOIN Well W ON W.PlateID = P.PlateID
		WHERE T.StatusCode >= 500
		GROUP BY W.DetAssignmentID
	) V2 On V2.DetAssignmentID = DA.DetAssignmentID
	JOIN [Status] S ON S.StatusCode = DA.StatusCode AND S.StatusTable = 'DeterminationAssignment'
    WHERE CAST(DA.PlannedDate AS DATE) BETWEEN @StartDate AND @EndDate AND DA.StatusCode IN (600,650);   

END
GO

DROP PROCEDURE IF EXISTS [dbo].[PR_GetDeclusterResult]
GO

--EXEC PR_GetDeclusterResult 4779, 748257
CREATE PROCEDURE [dbo].[PR_GetDeclusterResult]
(
    @PeriodID		    INT,
    @DetAssignmentID    INT
) AS BEGIN
    SET NOCOUNT ON;

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
	   MTT.InIMS,
	   M.MarkerID + 3
    FROM MarkerToBeTested MTT
    JOIN @Determinations D ON D.DetAssignmentID = MTT.DetAssignmentID
    JOIN Marker M ON M.MarkerID = MTT.MarkerID

    SELECT 
	   @Columns  = COALESCE(@Columns + ',', '') + QUOTENAME(MarkerID)
    FROM @Markers C
	ORDER By MarkerID;
	print @Columns;
    SET @Columns = ISNULL(@Columns, '');

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
			 LEFT JOIN DeterminationAssignment DA ON DA.VarietyNr = MVP.VarietyNr
			 LEFT JOIN MarkerToBeTested MTT ON MTT.MarkerID = MVP.MarkerID AND MTT.DetAssignmentID = DA.DetAssignmentID
		  ) V
		  PIVOT
		  (
			 MAX([Value])
			 FOR MarkerID IN(' + @Columns + N')
		  ) P
	   ) M ON M.VarietyNr = V.VarietyNr '  
    END + 
    N'ORDER BY V.DisplayOrder';

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
		UNION ALL
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



