DROP PROCEDURE IF EXISTS PR_PlanAutoDeterminationAssignments
GO

/*
    DECLARE @ABSDataAsJson NVARCHAR(MAX) =  N'[{"DetAssignmentID":1736406,"MethodCode":"PAC-01","ABSCropCode": "SP","VarietyNr":"21063","PriorityCode": 1}]';
    EXEC PR_PlanAutoDeterminationAssignments 4779, @ABSDataAsJson
*/
CREATE PROCEDURE PR_PlanAutoDeterminationAssignments
(
    @PeriodID		INT,
    @ABSDataAsJson	NVARCHAR(MAX)
) AS BEGIN
    SET NOCOUNT ON;

    DECLARE @ABSCropCode NVARCHAR(10);
    DECLARE @MethodCode	NVARCHAR(25);
    DECLARE @RequiredPlates INT;
    DECLARE @UsedFor NVARCHAR(10);
    DECLARE @PlatesPerMethod	  DECIMAL(5,2);
    DECLARE @RequiredDeterminations INT;
    DECLARE @StartDate DATE, @EndDate DATE;
    DECLARE @IDX INT = 1;
    DECLARE @CNT INT = 0;
    
    SELECT
	   @StartDate = StartDate,
	   @EndDate = EndDate
    FROM [Period]
    WHERE PeriodID = @PeriodID;

    DECLARE @PlatformID INT = (SELECT PlatformID FROM [Platform] WHERE PlatformCode = 'LS'); --light scanner   

    DECLARE @Capacity TABLE
    (
	   UsedFor	    VARCHAR(5), 
	   ABSCropCode	    NVARCHAR(10), 
	   MethodCode	    NVARCHAR(50), 
	   ReservePlates   DECIMAL(5,2)
    );

    DECLARE @Groups TABLE
    (
	   ID		    INT IDENTITY(1, 1),    
	   ABSCropCode	    NVARCHAR(10), 
	   MethodCode	    NVARCHAR(50), 
	   UsedFor	    VARCHAR(5), 
	   ReservePlates   DECIMAL(5,2),
	   TotalPlates	DECIMAL(5,2)
    );

    --handle unplanned records if exists
    DECLARE @DeterminationAssignment TABLE
    (
	   DetAssignmentID	    INT,
	   SampleNr		    INT,
	   PriorityCode	    INT,
	   MethodCode		    NVARCHAR(25),
	   CropCode		    NVARCHAR(10),
	   ABSCropCode		   NVARCHAR(20),
	   VarietyNr		    INT,
	   BatchNr		    INT,
	   RepeatIndicator	    BIT,
	   ProcessNr		    NVARCHAR(100),
	   ProductStatus	    NVARCHAR(100),
	   BatchOutputDesc	    NVARCHAR(250),
	   PlannedDate		   DATE,
	   UtmostInlayDate	    DATE,
	   ExpectedReadyDate   DATE,
	   UsedFor		    NVARCHAR(10)
    );

    INSERT @Capacity(UsedFor, ABSCropCode, MethodCode, ReservePlates)
    SELECT
	   T1.UsedFor,
	   T1.ABSCropCode,
	   T1.MethodCode,
	   NrOfPlates = SUM(T1.NrOfPlates)
    FROM
    (
	   SELECT 
		  V1.ABSCropCode,
		  DA.MethodCode,
		  V1.UsedFor,
		  NrOfPlates = CAST((V1.NrOfSeeds / 92.0) AS DECIMAL(5,2))
	   FROM DeterminationAssignment DA
	   JOIN
	   (
		  SELECT 
			 PM.MethodCode,
			 AC.ABSCropCode,
			 PM.NrOfSeeds,
			 PCM.UsedFor
		  FROM Method PM
		  JOIN CropMethod PCM ON PCM.MethodID = PM.MethodID
		  JOIN ABSCrop AC ON AC.ABSCropCode = PCM.ABSCropCode
		  WHERE PCM.PlatformID = @PlatformID
		  AND PM.StatusCode = 100
	   ) V1 ON V1.ABSCropCode = DA.ABSCropCode AND V1.MethodCode = DA.MethodCode
	   WHERE CAST(DA.PlannedDate AS DATE) BETWEEN @StartDate AND @EndDate
    ) T1 
    GROUP BY T1.ABSCropCode, T1.MethodCode, T1.UsedFor;

    --SELECT * FROM @Capacity
    INSERT INTO @Groups(ABSCropCode, MethodCode, UsedFor, TotalPlates, ReservePlates)
    SELECT
	   V1.ABSCropCode,
	   V1.MethodCode,
	   V1.UsedFor,
	   ISNULL(V1.TotalPlates, 0),
	   ISNULL(V2.ReservePlates, 0)
    FROM
    (
	   SELECT 
		  PC.SlotName,
		  AC.ABSCropCode, 
		  PM.MethodCode,	
		  CM.UsedFor,
		  TotalPlates = SUM(PC.NrOfPlates)
	   FROM ReservedCapacity PC
	   JOIN CropMethod CM ON CM.CropMethodID = PC.CropMethodID
	   JOIN ABSCrop AC ON AC.ABSCropCode = CM.ABSCropCode
	   JOIN Method PM ON PM.MethodID = CM.MethodID
	   WHERE CM.PlatformID = @PlatformID AND PC.PeriodID = @PeriodID
	   GROUP BY PC.SlotName, AC.ABSCropCode, PM.MethodCode, CM.UsedFor
    ) V1
    LEFT JOIN @Capacity V2 ON V2.ABSCropCode = V1.ABSCropCode AND V2.MethodCode = V1.MethodCode AND V2.UsedFor = V1.UsedFor;

    INSERT @DeterminationAssignment
    (
	   DetAssignmentID, 
	   SampleNr, 
	   PriorityCode, 
	   MethodCode, 
	   ABSCropCode, 
	   VarietyNr, 
	   BatchNr, 
	   RepeatIndicator, 
	   ProcessNr, 
	   ProductStatus, 
	   BatchOutputDesc, 
	   PlannedDate, 
	   UtmostInlayDate, 
	   ExpectedReadyDate,
	   UsedFor
    )
    SELECT 
	   T1.*,
	   UsedFor = CASE WHEN V.HybOp = 0 AND V.[Type] = 'P' THEN 'Par' ELSE 'Hyb' END
    FROM OPENJSON(@ABSDataAsJson) WITH
    (
	   DetAssignmentID	   INT,
	   SampleNr		   INT,
	   PriorityCode	   INT,
	   MethodCode		   NVARCHAR(25),
	   ABSCropCode		   NVARCHAR(10),
	   VarietyNr		   INT,
	   BatchNr		   INT,
	   RepeatIndicator	   BIT,
	   ProcessNr		   NVARCHAR(100),
	   ProductStatus	   NVARCHAR(100),
	   BatchOutputDesc	   NVARCHAR(250),
	   PlannedDate		   DATETIME,
	   UtmostInlayDate	   DATETIME,
	   ExpectedReadyDate   DATETIME
    ) T1
    JOIN ABSCrop C ON C.ABSCropCode = T1.ABSCropCode
    JOIN Variety V ON V.VarietyNr = T1.VarietyNr
    JOIN Method M ON M.MethodCode = T1.MethodCode
    WHERE T1.PriorityCode NOT IN(4, 7, 8)
    ORDER BY T1.PriorityCode;
    	  
    SELECT @CNT = COUNT(ID) FROM @Groups;
    WHILE(@IDX <= @CNT) BEGIN
	   SELECT 
		  @ABSCropCode =  G.ABSCropCode,
		  @MethodCode = G.MethodCode,
		  @RequiredPlates = G.TotalPlates - G.ReservePlates,
		  @UsedFor = G.UsedFor
	   FROM @Groups G
	   WHERE ID = @IDX;
    	    
	   --PRINT @ABSCropCode
	   --PRINT @MethodCode
	   --PRINT @RequiredPlates  
    
	   IF(@RequiredPlates > 0) BEGIN	   
		  SELECT 
			 @PlatesPerMethod = NrOfSeeds / 92 
		  FROM Method 
		  WHERE MethodCode = @MethodCode;

		  SET @RequiredDeterminations = @RequiredPlates / @PlatesPerMethod;
		  --PRINT 'RequiredDeterminations'
		  --PRINT @RequiredDeterminations

		  --insert records into DeterminationAssignments and calculate required plates again
		  INSERT INTO DeterminationAssignment
		  (
			 DetAssignmentID, 
			 SampleNr, 
			 PriorityCode, 
			 MethodCode, 
			 ABSCropCode, 
			 VarietyNr, 
			 BatchNr, 
			 RepeatIndicator, 
			 ProcessNr, 
			 ProductStatus, 
			 BatchOutputDesc, 
			 PlannedDate, 
			 UtmostInlayDate, 
			 ExpectedReadyDate
		  )
		  SELECT TOP(@RequiredDeterminations) 
			 DetAssignmentID, 
			 SampleNr, 
			 PriorityCode, 
			 MethodCode, 
			 ABSCropCode, 
			 VarietyNr, 
			 BatchNr, 
			 RepeatIndicator, 
			 ProcessNr, 
			 ProductStatus, 
			 BatchOutputDesc, 
			 @EndDate, --PlannedDate, 
			 UtmostInlayDate, 
			 ExpectedReadyDate 
		  FROM @DeterminationAssignment D
		  WHERE D.ABSCropCode = @ABSCropCode 
		  AND D.MethodCode = @MethodCode
		  AND D.UsedFor = @UsedFor
		  AND ISNULL(PriorityCode, 0) <> 0 
		  ORDER BY D.PriorityCode;
		  --now check if plates are fulfilled already with priority	   
		  SET @RequiredPlates = @RequiredPlates - (@@ROWCOUNT * @PlatesPerMethod);
		  --if we still need determinations, get it based on expected ready date here
		  IF(@RequiredPlates > 0 AND  @RequiredPlates > @PlatesPerMethod) BEGIN
			 --PRINT 'we need more'
			 --determine how many determinations required for required plates
			 SET @RequiredDeterminations = @RequiredPlates / @PlatesPerMethod;

			 INSERT INTO DeterminationAssignment
			 (
				DetAssignmentID, 
				SampleNr, 
				PriorityCode, 
				MethodCode, 
				ABSCropCode, 
				VarietyNr, 
				BatchNr, 
				RepeatIndicator, 
				ProcessNr, 
				ProductStatus, 
				BatchOutputDesc, 
				PlannedDate, 
				UtmostInlayDate, 
				ExpectedReadyDate
			 )
			 SELECT TOP(@RequiredDeterminations) 
				DetAssignmentID, 
				SampleNr, 
				PriorityCode, 
				MethodCode, 
				ABSCropCode, 
				VarietyNr, 
				BatchNr, 
				RepeatIndicator, 
				ProcessNr, 
				ProductStatus, 
				BatchOutputDesc, 
				@EndDate, --PlannedDate, 
				UtmostInlayDate, 
				ExpectedReadyDate  
			 FROM @DeterminationAssignment D
			 WHERE D.ABSCropCode = @ABSCropCode 
			 AND D.MethodCode = @MethodCode
			 AND D.UsedFor = @UsedFor
			 AND ISNULL(PriorityCode, 0) = 0 
			 ORDER BY D.ExpectedReadyDate;
		  END
	   END
	   SET @IDX = @IDX + 1;
    END
END
GO

DROP PROCEDURE IF EXISTS PR_GetDeterminationAssignments
GO
/*
    DECLARE @UnPlannedDataAsJson NVARCHAR(MAX) = N'[{"DetAssignmentID":1,"MethodCode":"PAC-01","ABSCropCode": "HP","VarietyNr":"21046"}]';
    EXEC PR_GetDeterminationAssignments 4779, @UnPlannedDataAsJson
*/
CREATE PROCEDURE [dbo].[PR_GetDeterminationAssignments]
(
    @PeriodID			   INT,
    @UnPlannedDataAsJson	   NVARCHAR(MAX) = NULL
) AS BEGIN
    SET NOCOUNT ON;

    DECLARE @StartDate DATE, @EndDate DATE;
    DECLARE @SQL NVARCHAR(MAX);
    DECLARE @PlatformID INT = (SELECT PlatformID FROM [Platform] WHERE PlatformCode = 'LS'); --light scanner   

    DECLARE @Capacity TABLE
    (
	   ABSCropCode	    NVARCHAR(20), 
	   MethodCode	    NVARCHAR(50), 
	   NrOfResPlates   DECIMAL(5,2)
    );
    --handle unplanned records if exists
    DECLARE @DeterminationAssignment TABLE
    (
	   DetAssignmentID    INT,
	   SampleNr		  INT,
	   PriorityCode	  INT,
	   MethodCode		  NVARCHAR(25),
	   ABSCropCode		  NVARCHAR(10),
	   VarietyNr		  INT,
	   BatchNr		  INT,
	   RepeatIndicator    BIT,
	   ProcessNr		  NVARCHAR(100),
	   ProductStatus	  NVARCHAR(100),
	   BatchOutputDesc    NVARCHAR(250),
	   PlannedDate		  DATETIME,
	   UtmostInlayDate    DATETIME,
	   ExpectedReadyDate  DATETIME
    );

    SELECT
	   @StartDate = StartDate,
	   @EndDate = EndDate
    FROM [Period]
    WHERE PeriodID = @PeriodID;

    IF(ISNULL(@UnPlannedDataAsJson, '') <> '') BEGIN
	   INSERT @DeterminationAssignment
	   (
		  DetAssignmentID, 
		  SampleNr, 
		  PriorityCode, 
		  MethodCode, 
		  ABSCropCode, 
		  VarietyNr, 
		  BatchNr, 
		  RepeatIndicator, 
		  ProcessNr, 
		  ProductStatus, 
		  BatchOutputDesc, 
		  PlannedDate, 
		  UtmostInlayDate, 
		  ExpectedReadyDate
	   )
	   SELECT * FROM OPENJSON(@UnPlannedDataAsJson) WITH
	   (
		  DetAssignmentID    INT,
		  SampleNr		  INT,
		  PriorityCode	  INT,
		  MethodCode		  NVARCHAR(25),
		  ABSCropCode		  NVARCHAR(10),
		  VarietyNr		  INT,
		  BatchNr		  INT,
		  RepeatIndicator    BIT,
		  ProcessNr		  NVARCHAR(100),
		  ProductStatus	  NVARCHAR(100),
		  BatchOutputDesc    NVARCHAR(250),
		  PlannedDate		  DATETIME,
		  UtmostInlayDate    DATETIME,
		  ExpectedReadyDate  DATETIME
	   );
    END
   
    INSERT @Capacity(ABSCropCode, MethodCode, NrOfResPlates)
    SELECT
	   T1.ABSCropCode,
	   T1.MethodCode,
	   NrOfPlates = SUM(T1.NrOfPlates)
    FROM
    (
	   SELECT 
		  V1.ABSCropCode,
		  DA.MethodCode,
		  NrOfPlates = CAST((V1.NrOfSeeds / 92.0) AS DECIMAL(5,2))
	   FROM 
	   (
		  SELECT 
			 MethodCode,
			 ABSCropCode,
			 PlannedDate
		  FROM DeterminationAssignment
		  UNION
		  SELECT 
			 MethodCode,
			 ABSCropCode,
			 PlannedDate
		  FROM @DeterminationAssignment
	   ) DA
	   JOIN
	   (
		  SELECT 
			 PM.MethodCode,
			 AC.ABSCropCode,
			 PM.NrOfSeeds
		  FROM Method PM
		  JOIN CropMethod PCM ON PCM.MethodID = PM.MethodID
		  JOIN ABSCrop AC ON AC.ABSCropCode = PCM.ABSCropCode
		  WHERE PCM.PlatformID = @PlatformID
		  AND PM.StatusCode = 100
	   ) V1 ON V1.ABSCropCode = DA.ABSCropCode AND V1.MethodCode = DA.MethodCode
	   WHERE CAST(DA.PlannedDate AS DATE) BETWEEN @StartDate AND @EndDate
    ) T1 
    GROUP BY T1.ABSCropCode, T1.MethodCode;
    
    --Get groups
    SELECT
	   V1.SlotName,
	   V1.ABSCropCode,
	   V1.MethodCode,
	   V1.UsedFor,
	   V1.TotalPlates,
	   V2.NrOfResPlates
    FROM
    (
	   SELECT 
		  PC.SlotName,
		  AC.ABSCropCode, 
		  PM.MethodCode,
		  CM.UsedFor,
		  TotalPlates = SUM(PC.NrOfPlates)
	   FROM ReservedCapacity PC
	   JOIN CropMethod CM ON CM.CropMethodID = PC.CropMethodID
	   JOIN ABSCrop AC ON AC.ABSCropCode = CM.ABSCropCode
	   JOIN Method PM ON PM.MethodID = CM.MethodID
	   WHERE CM.PlatformID = @PlatformID AND PC.PeriodID = @PeriodID
	   GROUP BY PC.SlotName, AC.ABSCropCode, PM.MethodCode, CM.UsedFor
    ) V1
    LEFT JOIN @Capacity V2 ON V2.ABSCropCode = V1.ABSCropCode AND V2.MethodCode = V1.MethodCode;
    
    WITH CTE AS 
    (
	   SELECT 
		  V2.DetAssignmentID,
		  MethodCode = ISNULL(DA.MethodCode, DA2.MethodCode),
		  ABSCropCode = ISNULL(DA.ABSCropCode, DA2.ABSCropCode),
		  SampleNr = ISNULL(DA.SampleNr, DA2.SampleNr),
		  UtmostInlayDate = ISNULL(DA.UtmostInlayDate, DA2.UtmostInlayDate),
		  ExpectedReadyDate = ISNULL(DA.ExpectedReadyDate, DA2.ExpectedReadyDate), 
		  PriorityCode = ISNULL(DA.PriorityCode, DA2.PriorityCode),	   
		  BatchNr = ISNULL(DA.BatchNr, DA2.BatchNr),
		  RepeatIndicator = ISNULL(DA.RepeatIndicator, DA2.RepeatIndicator),
		  VarietyNr = ISNULL(DA.VarietyNr, DA2.VarietyNr),
		  ProcessNr = ISNULL(DA.ProcessNr, DA2.ProcessNr),
		  ProductStatus = ISNULL(DA.ProductStatus, DA2.ProductStatus),
		  BatchOutputDesc = ISNULL(DA.BatchOutputDesc, DA2.BatchOutputDesc),
		  IsPlanned = CAST(V2.IsPlanned AS BIT)
	   FROM
	   (
		  SELECT 
			 T1.DetAssignmentID,
			 IsPlanned = MAX(T1.IsPlanned)
		  FROM
		  (
			 SELECT
				DetAssignmentID,
				IsPlanned = 1
			 FROM DeterminationAssignment
			 WHERE CAST(PlannedDate AS DATE) BETWEEN @StartDate AND @EndDate
			 UNION ALL
			 SELECT
				DetAssignmentID,
				IsPlanned = 0
			 FROM @DeterminationAssignment
		  ) T1 
		  GROUP BY DetAssignmentID
	   ) V2
	   LEFT JOIN @DeterminationAssignment DA2 ON DA2.DetAssignmentID = V2.DetAssignmentID
	   LEFT JOIN DeterminationAssignment DA ON DA.DetAssignmentID = V2.DetAssignmentID AND CAST(DA.PlannedDate AS DATE) BETWEEN @StartDate AND @EndDate
	   JOIN
	   (
		  SELECT
			 AC.ABSCropCode,
			 PM.MethodCode
		  FROM CropMethod CM
		  JOIN ABSCrop AC ON AC.ABSCropCode = CM.ABSCropCode
		  JOIN Method PM ON PM.MethodID = CM.MethodID
		  WHERE CM.PlatformID = @PlatformID
	   ) V1 ON V1.ABSCropCode = ISNULL(DA.ABSCropCode, DA2.ABSCropCode) AND V1.MethodCode = ISNULL(DA.MethodCode, DA2.MethodCode)
    )
    SELECT 
	   CTE.*
	   , UsedFor = CASE WHEN V.HybOp = 0 AND V.[Type] = 'P' THEN 'Par' ELSE 'Hyb' END
    FROM CTE
    JOIN Variety V ON V.VarietyNr = CTE.VarietyNr
    ORDER BY CTE.IsPlanned DESC, CTE.SampleNr ASC;
END
GO