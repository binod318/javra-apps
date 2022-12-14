DROP PROCEDURE IF EXISTS PR_PlanAutoDeterminationAssignments
GO

/*
    DECLARE @ABSDataAsJson NVARCHAR(MAX) =  N'[{"DetAssignmentID":1736406,"MethodCode":"PAC-01","ABSCropCode": "SP","VarietyNr":"21063","PriorityCode": 1}]';
    EXEC PR_PlanAutoDeterminationAssignments 4779, @ABSDataAsJson
*/
CREATE PROCEDURE [dbo].[PR_PlanAutoDeterminationAssignments]
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

    SELECT * FROM @Capacity

    RETURN;

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
			 @PlatesPerMethod = CAST((NrOfSeeds / 92.0) AS DECIMAL(5,2))
		  FROM Method 
		  WHERE MethodCode = @MethodCode;

		  SET @RequiredDeterminations = @RequiredPlates / @PlatesPerMethod;

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
			 ExpectedReadyDate,
			 StatusCode
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
			 ExpectedReadyDate,
			 100
		  FROM @DeterminationAssignment D
		  WHERE D.ABSCropCode = @ABSCropCode 
		  AND D.MethodCode = @MethodCode
		  AND D.UsedFor = @UsedFor
		  AND ISNULL(D.PriorityCode, 0) <> 0 
		  AND NOT EXISTS
		  (
			 SELECT 
				DetAssignmentID 
			 FROM DeterminationAssignment
			 WHERE DetAssignmentID = D.DetAssignmentID
		  )
		  ORDER BY D.PriorityCode;
		  --now check if plates are fulfilled already with priority	   
		  SET @RequiredPlates = @RequiredPlates - (@@ROWCOUNT * @PlatesPerMethod);
		  --if we still need determinations, get it based on expected ready date here
		  IF(@RequiredPlates > 0 AND @RequiredPlates > @PlatesPerMethod) BEGIN
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
				ExpectedReadyDate,
				StatusCode
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
				ExpectedReadyDate,
				100
			 FROM @DeterminationAssignment D
			 WHERE D.ABSCropCode = @ABSCropCode 
			 AND D.MethodCode = @MethodCode
			 AND D.UsedFor = @UsedFor
			 AND ISNULL(PriorityCode, 0) = 0 
			 AND NOT EXISTS
			 (
				SELECT 
				    DetAssignmentID 
				FROM DeterminationAssignment
				WHERE DetAssignmentID = D.DetAssignmentID
			 )
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
    EXEC PR_GetDeterminationAssignments 4780, @UnPlannedDataAsJson
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
    
    DECLARE @Groups TABLE
    (
	   SlotName	    NVARCHAR(100),
	   ABSCropCode	    NVARCHAR(20), 
	   MethodCode	    NVARCHAR(50), 
	   UsedFor	    NVARCHAR(10),
	   TotalPlates	    INT,
	   NrOfResPlates	    DECIMAL(5,2)
    ); 
    DECLARE @Capacity TABLE
    (
	   ABSCropCode	    NVARCHAR(20), 
	   MethodCode	    NVARCHAR(50), 
	   ResPlates   DECIMAL(5,2)
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
    --Prapare output of details records
    DECLARE @Result TABLE
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
	   ExpectedReadyDate  DATETIME,
	   IsPlanned		  BIT,
	   UsedFor		  NVARCHAR(10),
	   CanEdit		  BIT
    );

    SELECT
	   @StartDate = StartDate,
	   @EndDate = EndDate
    FROM [Period]
    WHERE PeriodID = @PeriodID;

    --Preapre capacities of planned records
    INSERT @Capacity(ABSCropCode, MethodCode, ResPlates)
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
	   FROM DeterminationAssignment DA
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
    
    --Prepare Grops of planned records groups
    INSERT @Groups(SlotName, ABSCropCode, MethodCode, UsedFor, TotalPlates, NrOfResPlates)
    SELECT
	   V1.SlotName,
	   V1.ABSCropCode,
	   V1.MethodCode,
	   V1.UsedFor,
	   V1.TotalPlates,
	   ResPlates = ISNULL(V2.ResPlates, 0)
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
    JOIN @Capacity V2 ON V2.ABSCropCode = V1.ABSCropCode AND V2.MethodCode = V1.MethodCode;

    --Get details of planned determinations    
    INSERT @Result
    (
	   DetAssignmentID,	 
	   MethodCode,		
	   ABSCropCode,
	   SampleNr,
	   UtmostInlayDate, 
	   ExpectedReadyDate,
	   PriorityCode,	
	   BatchNr,	
	   RepeatIndicator, 
	   VarietyNr,
	   ProcessNr,		
	   ProductStatus,	
	   BatchOutputDesc, 
	   PlannedDate,	   
	   IsPlanned,		
	   UsedFor,
	   CanEdit
    )
    SELECT 
	   DA.DetAssignmentID,
	   DA.MethodCode,
	   DA.ABSCropCode,
	   DA.SampleNr,
	   DA.UtmostInlayDate,
	   DA.ExpectedReadyDate, 
	   DA.PriorityCode,	   
	   DA.BatchNr,
	   DA.RepeatIndicator,
	   DA.VarietyNr,
	   DA.ProcessNr,
	   DA.ProductStatus,
	   DA.BatchOutputDesc,
	   DA.PlannedDate,
	   IsPlanned = 1,
	   UsedFor = CASE WHEN V.HybOp = 0 AND V.[Type] = 'P' THEN 'Par' ELSE 'Hyb' END,
	   CASE WHEN DA.StatusCode < 200 THEN 1 ELSE 0 END
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
    WHERE CAST(DA.PlannedDate AS DATE) BETWEEN @StartDate AND @EndDate;   
    	 	 
    --Process unplannded records    
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
	   
	   --no need to process @Capacity, res plates is always 0 for unplanned records
	   --Prepare Grops of planned records groups
	   INSERT @Groups(SlotName, ABSCropCode, MethodCode, UsedFor, TotalPlates, NrOfResPlates)
	   SELECT
		  V1.SlotName,
		  V1.ABSCropCode,
		  V1.MethodCode,
		  V1.UsedFor,
		  V1.TotalPlates,
		  ResPlates = 0
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
	   WHERE NOT EXISTS
	   (
		  SELECT ABSCropCode, MethodCode
		  FROM @Groups
		  WHERE ABSCropCode = V1.ABSCropCode AND MethodCode = V1.MethodCode
	   );

	   --Get details of planned determinations    
	   INSERT @Result
	   (
		  DetAssignmentID,	 
		  MethodCode,		
		  ABSCropCode,
		  SampleNr,
		  UtmostInlayDate, 
		  ExpectedReadyDate,
		  PriorityCode,	
		  BatchNr,	
		  RepeatIndicator, 
		  VarietyNr,
		  ProcessNr,		
		  ProductStatus,	
		  BatchOutputDesc, 
		  PlannedDate,	   
		  IsPlanned,		
		  UsedFor,
		  CanEdit
	   )
	   SELECT 
		  DA.DetAssignmentID,
		  DA.MethodCode,
		  DA.ABSCropCode,
		  DA.SampleNr,
		  DA.UtmostInlayDate,
		  DA.ExpectedReadyDate, 
		  DA.PriorityCode,	   
		  DA.BatchNr,
		  DA.RepeatIndicator,
		  DA.VarietyNr,
		  DA.ProcessNr,
		  DA.ProductStatus,
		  DA.BatchOutputDesc,
		  DA.PlannedDate,
		  IsPlanned = 0,
		  UsedFor = CASE WHEN V.HybOp = 0 AND V.[Type] = 'P' THEN 'Par' ELSE 'Hyb' END,
		  1
	   FROM @DeterminationAssignment DA
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
	   WHERE NOT EXISTS
	   (
		  SELECT DetAssignmentID 
		  FROM @Result
		  WHERE DetAssignmentID = DA.DetAssignmentID
	   );	   
    END  

    --return groups
    SELECT 
	   * 
    FROM @Groups G
    JOIN
    (
	   SELECT 
		  ABSCropCode,
		  MethodCode
	   FROM @Result
	   GROUP BY ABSCropCode, MethodCode
    ) V ON V.ABSCropCode = G.ABSCropCode AND V.MethodCode = G.MethodCode;

    --return details
    SELECT 
	   DetAssignmentID,	 
	   MethodCode,		
	   ABSCropCode,
	   SampleNr,
	   UtmostInlayDate = FORMAT(UtmostInlayDate, 'dd/MM/yyyy'), 
	   ExpectedReadyDate = FORMAT(ExpectedReadyDate, 'dd/MM/yyyy'),
	   PriorityCode,	
	   BatchNr,	
	   RepeatIndicator, 
	   VarietyNr,
	   ProcessNr,		
	   ProductStatus,	
	   BatchOutputDesc, 
	   PlannedDate = FORMAT(PlannedDate, 'dd/MM/yyyy'),
	   IsPlanned,		
	   UsedFor,
	   CanEditPlanning = CanEdit
    FROM @Result
    ORDER BY IsPlanned DESC, SampleNr ASC;
END
GO