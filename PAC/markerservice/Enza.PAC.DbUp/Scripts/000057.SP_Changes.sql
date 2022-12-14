ALTER TABLE DeterminationAssignment
ADD IsLabPriority BIT
GO

DROP PROCEDURE IF EXISTS [dbo].[PR_GetDeterminationAssignments]
GO


/*
    DECLARE @UnPlannedDataAsJson NVARCHAR(MAX) = N'[{"DetAssignmentID":1,"MethodCode":"PAC-01","ABSCropCode": "HP","VarietyNr":"21046"}]';
    EXEC PR_GetDeterminationAssignments 4780, @UnPlannedDataAsJson
*/
CREATE PROCEDURE [dbo].[PR_GetDeterminationAssignments]
(
    @PeriodID			   INT,
    @UnPlannedDataAsJson	   NVARCHAR(MAX) = NULL
) 
AS 
BEGIN
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
	   BatchNr			  INT,
	   RepeatIndicator    BIT,
	   Process			  NVARCHAR(100),
	   ProductStatus	  NVARCHAR(100),
	   Remarks			  NVARCHAR(250),
	   PlannedDate		  DATETIME,
	   UtmostInlayDate    DATETIME,
	   ExpectedReadyDate  DATETIME,
	   ReceiveDate		  DATETIME,
	   ReciprocalProd	  BIT,
	   BioIndicator		  BIT,
	   LogicalClassificationCode	BIT,
	   LocationCode					BIT,
	   IsLabPriority				BIT
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
	   Process		  NVARCHAR(100),
	   ProductStatus	  NVARCHAR(100),
	   Remarks			  NVARCHAR(250),
	   PlannedDate		  DATETIME,
	   UtmostInlayDate    DATETIME,
	   ExpectedReadyDate  DATETIME,
	   IsPlanned		  BIT,
	   UsedFor		  NVARCHAR(10),
	   CanEdit		  BIT,
	   IsLabPriority	  BIT
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
	   Process,		
	   ProductStatus,	
	   Remarks, 
	   PlannedDate,	   
	   IsPlanned,		
	   UsedFor,
	   CanEdit,
	   IsLabPriority
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
	   DA.Process,
	   DA.ProductStatus,
	   DA.Remarks,
	   DA.PlannedDate,
	   IsPlanned = 1,
	   UsedFor = CASE WHEN V.HybOp = 0 AND V.[Type] = 'P' THEN 'Par' ELSE 'Hyb' END,
	   CASE WHEN DA.StatusCode < 200 THEN 1 ELSE 0 END,
	   ISNULL(DA.IsLabPriority, 0)
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
		  Process, 
		  ProductStatus, 
		  Remarks, 
		  PlannedDate, 
		  UtmostInlayDate, 
		  ExpectedReadyDate,
		  ReceiveDate,
		  ReciprocalProd,
		  BioIndicator,
		  LogicalClassificationCode,
		  LocationCode,
		  IsLabPriority
	   )
	   SELECT *, IsLabPriority = 0 
	   FROM OPENJSON(@UnPlannedDataAsJson) WITH
	   (
		  DetAssignmentID    INT,
		  SampleNr		  INT,
		  PriorityCode	  INT,
		  MethodCode		  NVARCHAR(25),
		  ABSCropCode		  NVARCHAR(10),
		  VarietyNr		  INT,
		  BatchNr		  INT,
		  RepeatIndicator    BIT,
		  Process		  NVARCHAR(100),
		  ProductStatus	  NVARCHAR(100),
		  Remarks				NVARCHAR(250),
		  PlannedDate			DATETIME,
		  UtmostInlayDate   DATETIME,
		  ExpectedReadyDate DATETIME,
		  ReceiveDate		DATETIME,
		  ReciprocalProd	BIT,
		  BioIndicator		BIT,
		  LogicalClassificationCode	BIT,
		  LocationCode				NVARCHAR(20)
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
		  Process,		
		  ProductStatus,	
		  Remarks, 
		  PlannedDate,	   
		  IsPlanned,		
		  UsedFor,
		  CanEdit,
		  IsLabPriority
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
		  DA.Process,
		  DA.ProductStatus,
		  DA.Remarks,
		  DA.PlannedDate,
		  IsPlanned = 0,
		  UsedFor = CASE WHEN V.HybOp = 0 AND V.[Type] = 'P' THEN 'Par' ELSE 'Hyb' END,
		  CASE WHEN DA.PriorityCode IN(4, 7, 8) THEN 0 ELSE 1 END,
		  0
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
		  FROM DeterminationAssignment
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
		  R.ABSCropCode,
		  R.MethodCode,
		  R.UsedFor,
		  TotalRows = COUNT( R.DetAssignmentID)
	   FROM @Result R
	   GROUP BY R.ABSCropCode, R.MethodCode, R.UsedFor
    ) V ON V.ABSCropCode = G.ABSCropCode AND V.MethodCode = G.MethodCode AND V.UsedFor = G.UsedFor
    WHERE V.TotalRows > 0;

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
	   Process,		
	   ProductStatus,	
	   Remarks, 
	   PlannedDate = FORMAT(PlannedDate, 'dd/MM/yyyy'),
	   IsPlanned,		
	   UsedFor,
	   CanEditPlanning = CanEdit,
	   IsLabPriority
    FROM @Result T
    ORDER BY IsPlanned DESC, SampleNr ASC;
END
GO


DROP PROCEDURE IF EXISTS [dbo].[PR_PlanAutoDeterminationAssignments]
GO

/*
    DECLARE @ABSDataAsJson NVARCHAR(MAX) =  N'[{"DetAssignmentID":1736406,"MethodCode":"PAC-01","ABSCropCode": "SP","VarietyNr":"21063","PriorityCode": 1}]';
    EXEC PR_PlanAutoDeterminationAssignments 4779, @ABSDataAsJson
*/
CREATE PROCEDURE [dbo].[PR_PlanAutoDeterminationAssignments]
(
    @PeriodID		INT,
    @ABSDataAsJson	NVARCHAR(MAX)
) 
AS 
BEGIN
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
	   Process		    NVARCHAR(100),
	   ProductStatus	    NVARCHAR(100),
	   Remarks	    NVARCHAR(250),
	   PlannedDate		   DATE,
	   UtmostInlayDate	    DATE,
	   ExpectedReadyDate   DATE,
	   ReceiveDate		  DATETIME,
	   ReciprocalProd	  BIT,
	   BioIndicator		  BIT,
	   LogicalClassificationCode	BIT,
	   LocationCode					BIT,
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
		Process, 
		ProductStatus, 
		Remarks, 
		PlannedDate, 
		UtmostInlayDate, 
		ExpectedReadyDate,
		ReceiveDate,
		ReciprocalProd,
		BioIndicator,
		LogicalClassificationCode,
		LocationCode,
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
		Process		   NVARCHAR(100),
		ProductStatus	   NVARCHAR(100),
		Remarks	   NVARCHAR(250),
		PlannedDate		   DATETIME,
		UtmostInlayDate	   DATETIME,
		ExpectedReadyDate   DATETIME,	   
		ReceiveDate		DATETIME,
		ReciprocalProd	BIT,
		BioIndicator		BIT,
		LogicalClassificationCode	BIT,
		LocationCode				NVARCHAR(20)
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
			 Process, 
			 ProductStatus, 
			 Remarks, 
			 PlannedDate, 
			 UtmostInlayDate, 
			 ExpectedReadyDate,
			 StatusCode,
			 ReceiveDate,
			 ReciprocalProd,
			 BioIndicator,
			 LogicalClassificationCode,
			 LocationCode
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
			 Process, 
			 ProductStatus, 
			 Remarks, 
			 CASE WHEN CAST(D.PlannedDate AS DATE) BETWEEN @StartDate AND @EndDate THEN D.PlannedDate ELSE @EndDate END,
			 UtmostInlayDate, 
			 ExpectedReadyDate,
			 100,
			 ReceiveDate,
			 ReciprocalProd,
			 BioIndicator,
			 LogicalClassificationCode,
			 LocationCode
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
				Process, 
				ProductStatus, 
				Remarks, 
				PlannedDate, 
				UtmostInlayDate, 
				ExpectedReadyDate,
				StatusCode,
				ReceiveDate,
				ReciprocalProd,
				BioIndicator,
				LogicalClassificationCode,
				LocationCode
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
				Process, 
				ProductStatus, 
				Remarks, 
				CASE WHEN CAST(D.PlannedDate AS DATE) BETWEEN @StartDate AND @EndDate THEN D.PlannedDate ELSE @EndDate END,
				UtmostInlayDate, 
				ExpectedReadyDate,
				100,
				ReceiveDate,
				ReciprocalProd,
				BioIndicator,
				LogicalClassificationCode,
				LocationCode
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


DROP PROCEDURE IF EXISTS [dbo].[PR_ConfirmPlanning]
GO


/*
Author					Date			Description
Binod Gurung			2019-Sept-04	Service to confirm planning

===================================Example================================

EXEC PR_ConfirmPlanning 4780, N'[{"DetAssignmentID":733313,"MethodCode":"PAC-01","ABSCropCode":"HP","SampleNr":1223714,"UtmostInlayDate":"11/03/2016","ExpectedReadyDate":"08/03/2016",
"PriorityCode":1,"BatchNr":0,"RepeatIndicator":false,"VarietyNr":20993,"ProcessNr":"0","ProductStatus":"5","Remarks":null,"PlannedDate":"08/01/2016","IsPlanned":false,"UsedFor":"Hyb",
"CanEditPlanning":true,"can":true,"init":false,"flag":true,"change":true,"Action":"i"}]';
*/
CREATE PROCEDURE [dbo].[PR_ConfirmPlanning]
(
    @PeriodID	 INT,
    @DataAsJson NVARCHAR(MAX)
)
AS 
BEGIN
    SET NOCOUNT ON;

    DECLARE @TransCount BIT = 0;
    DECLARE @StartDate DATE, @EndDate DATE;    
    SELECT 
	   @StartDate = P.StartDate,
	   @EndDate = P.EndDate
    FROM [Period] P 
    WHERE P.PeriodID = @PeriodID;

    BEGIN TRY
	   IF @@TRANCOUNT = 0 BEGIN
		  BEGIN TRANSACTION;
		  SET @TransCount = 1;
	   END
	   
	   DELETE DA
	   FROM DeterminationAssignment DA
	   JOIN OPENJSON(@DataAsJson) WITH
	   (
		  DetAssignmentID INT,
		  [Action]	   CHAR(1)
	   ) S ON S.DetAssignmentID = DA.DetAssignmentID
	   WHERE S.[Action] = 'D'
	   AND CAST(DA.PlannedDate AS DATE) BETWEEN @StartDate AND @EndDate;

	   --Change status to 200 of those records which falls under that period
	   UPDATE DA
	   SET DA.StatusCode = 200
	   FROM DeterminationAssignment DA
	   JOIN OPENJSON(@DataAsJson) WITH
	   (
		  DetAssignmentID INT,
		  [Action]	   CHAR(1)
	   ) S ON S.DetAssignmentID = DA.DetAssignmentID
	   WHERE S.[Action] = 'U'
	   AND CAST(DA.PlannedDate AS DATE) BETWEEN @StartDate AND @EndDate;

	   --update status of all records of that particular week if there are no any data comes in json
	   UPDATE DA
		  SET DA.StatusCode = 200
	   FROM DeterminationAssignment DA
	   WHERE DA.StatusCode = 100 
	   AND CAST(DA.PlannedDate AS DATE) BETWEEN @StartDate AND @EndDate; 
	   	   
	   --validate
	   DECLARE @Groups TABLE
	   (
		  ABSCropCode	    NVARCHAR(10), 
		  MethodCode	    NVARCHAR(50), 
		  UsedFor	    VARCHAR(5), 
		  ReservePlates   DECIMAL(5,2),
		  TotalPlates	DECIMAL(5,2)
	   );

	   INSERT @Groups(ABSCropCode, MethodCode, UsedFor, ReservePlates, TotalPlates)
	   EXEC PR_ValidateCapacityPerFolder @PeriodID, @DataAsJson;

	   IF @@ROWCOUNT > 0 BEGIN
		  SELECT 
			 ABSCropCode, 
			 MethodCode, 
			 UsedFor, 
			 ReservePlates, 
			 TotalPlates
		  FROM @Groups;
		  
		  IF @TransCount = 1 
			 ROLLBACK;

		  RETURN;
	   END
	   
	   --insert new records if it is not in automatic plan but user has checked it up
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
			Process, 
			ProductStatus, 
			Remarks, 
			PlannedDate, 
			UtmostInlayDate, 
			ExpectedReadyDate,
			StatusCode,		  
			ReceiveDate,
			ReciprocalProd,
			BioIndicator,
			LogicalClassificationCode,
			LocationCode,
			IsLabPriority
	   )
	   SELECT 
			S.DetAssignmentID, 
			S.SampleNr, 
			S.PriorityCode, 
			S.MethodCode, 
			S.ABSCropCode, 
			S.VarietyNr, 
			S.BatchNr, 
			S.RepeatIndicator, 
			S.Process, 
			S.ProductStatus, 
			S.Remarks, 
			CASE WHEN CAST(S.PlannedDate AS DATE) BETWEEN @StartDate AND @EndDate THEN S.PlannedDate ELSE @EndDate END,
			S.UtmostInlayDate, 
			S.ExpectedReadyDate,
			200,	  
			S.ReceiveDate,
			S.ReciprocalProd,
			S.BioIndicator,
			S.LogicalClassificationCode,
			S.LocationCode,
			S.IsLabPriority
	   FROM OPENJSON(@DataAsJson) WITH
	   (
			DetAssignmentID	   INT,
			SampleNr		   INT,
			PriorityCode	   INT,
			MethodCode		   NVARCHAR(25),
			ABSCropCode		   NVARCHAR(10),
			VarietyNr		   INT,
			BatchNr		   INT,
			RepeatIndicator	   BIT,
			Process			   NVARCHAR(100),
			ProductStatus	   NVARCHAR(100),
			Remarks			   NVARCHAR(250),
			PlannedDate		   DATETIME,
			UtmostInlayDate	   DATETIME,
			ExpectedReadyDate   DATETIME,
			IsLabPriority	  BIT,
			[Action]	   CHAR(1),	   
			ReceiveDate		DATETIME,
			ReciprocalProd	BIT,
			BioIndicator		BIT,
			LogicalClassificationCode	BIT,
			LocationCode				NVARCHAR(20)
	   ) S
	   JOIN Variety V ON V.VarietyNr = S.VarietyNr
	   LEFT JOIN DeterminationAssignment DA ON DA.DetAssignmentID = S.DetAssignmentID	   
	   WHERE S.[Action] = 'I'
	   AND S.PriorityCode NOT IN(4, 7, 8)
	   AND DA.DetAssignmentID IS NULL;

	   --Generate folder structure based on confirmed data
	   EXEC PR_GenerateFolderDetails @PeriodID;
	   
	   IF @TransCount = 1 
		  COMMIT;
    END TRY
    BEGIN CATCH
	   IF @TransCount = 1 
		  ROLLBACK;
	   THROW;
    END CATCH
END
GO


DROP PROCEDURE IF EXISTS [dbo].[PR_Decluster]
GO


-- =============================================
-- Author:		Binod Gurung
-- Create date: 2019/10/16
-- Description:	Procedure to decluster varieties
-- =============================================
/*	
	DECLARE @ReturnVarieties NVARCHAR(MAX);
	EXEC [PR_Decluster] 1297740, @ReturnVarieties OUTPUT;
	SELECT @ReturnVarieties;
*/
CREATE PROCEDURE [dbo].[PR_Decluster]
(
	@DetAssignmentID	INT,
	@ReturnVarieties	NVARCHAR(MAX) OUTPUT
)
AS
BEGIN

	DECLARE @VarietyNr INT, @Female INT, @Male INT, @IsParent BIT, @Crop NVARCHAR(10), @MarkerID INT, @PlatformID INT, @InMMS BIT, @Score NVARCHAR(10), @VarietyScore NVARCHAR(10), @ImsMarker INT, @Reciprocal BIT;
	DECLARE @ClusteredVarieties NVARCHAR(MAX), @CountClusteredVarieties INT, @Json NVARCHAR(MAX), @List NVARCHAR(MAX) = '';
	DECLARE @MarkerTbl TABLE(DetAssignmentID INT, MarkerID INT, InEDS BIT, InIMS BIT);
	DECLARE @MMSMarkerTbl TABLE (MarkerID INT, MarkerValue NVARCHAR(10));
	DECLARE @EdmMarkerTbl TABLE (MarkerID INT, MarkerValue NVARCHAR(10));
	DECLARE @EdmMarkerTblOrig TABLE (MarkerID INT, MarkerValue NVARCHAR(10));	
	DECLARE @JsonTbl TABLE (ID INT IDENTITY(1,1), MarkerID INT, MarkerValue NVARCHAR(10));
	DECLARE @ClusterVarTbl TABLE(VarietyNr INT);
	DECLARE @EffectPerMarkerTbl Table(MarkerID INT, Total INT);
	DECLARE @Count1 INT, @Count2 INT, @HighestScore INT, @HighestMarker INT;	
	
	SET NOCOUNT ON;

	SET @ReturnVarieties = '';
	
	-- step 1 : calculate cluster varieties

	--delete all previous marker test before starting new
	DELETE MarkerToBeTested
	WHERE DetAssignmentID = @DetAssignmentID;

	--find variety linked to determination assignment
	SELECT 
		@VarietyNr = VarietyNr,
		@Reciprocal = ReciprocalProd
	FROM DeterminationAssignment WHERE DetAssignmentID = @DetAssignmentID;

	--find variety information
	SELECT 
		@Crop = CropCode,
		@Female = V.Female,
		@Male = V.Male,
		@IsParent = (CASE WHEN V.HybOp = 0 AND V.[Type] = 'P' THEN 1 ELSE 0 END)
	FROM Variety V WHERE V.VarietyNr = @VarietyNr;

	DECLARE Marker_Cursor CURSOR LOCAL FAST_FORWARD FOR
		SELECT MarkerID, P.PlatformID, InMMS FROM MarkerCropPlatform MCP
		JOIN [Platform] P ON P.PlatformID = MCP.PlatformID 
		WHERE CropCode = @Crop AND P.UsedForPac = 1
	OPEN Marker_Cursor;
	FETCH NEXT FROM Marker_Cursor INTO @MarkerID, @PlatformID, @InMMS;
	
	WHILE @@FETCH_STATUS = 0
	BEGIN

		SELECT @Score = MVPV.AlleleScore FROM MarkerValuePerVariety MVPV WHERE MVPV.VarietyNr = @VarietyNr AND MarkerID = @MarkerID;

		-- if no score available and marker is in MMS
		IF(ISNULL(@Score,'') = '' AND @InMMS = 1)
			RETURN; --return 

		IF(ISNULL(@Score,'') <> '')
		BEGIN

			IF((@InMMS = 1 OR @IsParent = 1)) --and platform of test and marker is same
			BEGIN
				
				INSERT INTO @MMSMarkerTbl
				VALUES(@MarkerID, @Score);

				INSERT INTO @MarkerTbl
				VALUES(@DetAssignmentID, @MarkerID, ~@InMMS, 0)

			END;
			ELSE IF (@InMMS = 0)
			BEGIN
				
				INSERT INTO @EdmMarkerTbl
				VALUES(@MarkerID, @Score);

			END
		END

		FETCH NEXT FROM Marker_Cursor INTO @MarkerID, @PlatformID, @InMMS;
	END
	
	CLOSE Marker_Cursor;
	DEALLOCATE Marker_Cursor;

	--variables used on next step
	--@MMSMarkerTbl

	--step 2: call findmatchingvarieties
	
	--prepare json to feed sp
	INSERT INTO @JsonTbl(MarkerID, MarkerValue)
	SELECT MarkerID, MarkerValue from @MMSMarkerTbl

	SET @Json = (SELECT * FROM @JsonTbl FOR JSON AUTO);
	EXEC PR_FindMatchingVarieties @Json, @Crop, @VarietyNr, @ClusteredVarieties OUTPUT;

	--insert comma separated list of varieties to table
	INSERT INTO @ClusterVarTbl
	SELECT [value] FROM STRING_SPLIT(@ClusteredVarieties, ',');

	--variables used on next step
	--@ClusterVarTbl, @EdmMarkerTbl

	--step 3 : Apply extra declustering markers

	--data in @EdmMarkerTbl table gets lesser everytime so we need the original list later for finding inbred marker
	INSERT INTO @EdmMarkerTblOrig
	SELECT * FROM @EdmMarkerTbl;

	SELECT @CountClusteredVarieties = COUNT(VarietyNr) FROM @ClusterVarTbl;
			
	--declusterloop
	WHILE (@CountClusteredVarieties > 1)
	BEGIN

		INSERT INTO @EffectPerMarkerTbl
		SELECT MVPV.MarkerID, COUNT(MVPV.MarkerID) FROM 
		(
			SELECT VarietyNr, ED.MarkerID, ED.MarkerValue FROM @ClusterVarTbl
			CROSS APPLY @EdmMarkerTbl ED
		) V2
		LEFT JOIN MarkerValuePerVariety MVPV ON MVPV.VarietyNr = V2.VarietyNr AND MVPV.MarkerID = V2.MarkerID
		WHERE dbo.FN_IsMatching(V2.MarkerValue, MVPV.AlleleScore) = 0
		GROUP BY MVPV.MarkerID
		
		-- Get score and marker with highest score count
		SET @HighestScore = 0;
		SET @HighestMarker = 0;

		SELECT TOP 1
			@HighestMarker = EP.MarkerID,
			@HighestScore = EP.Total
		FROM @EffectPerMarkerTbl EP 
		ORDER BY EP.Total DESC
		--WHERE EP.Total = (SELECT MAX(Total) FROM @EffectPerMarkerTbl)
				
		--if no marker found with @EffectPerMarkerTbl then quit this loop
		IF(ISNULL(@HighestScore, 0) = 0)
			BREAK;

		-- if marker found then remove marker from edm markerlist
		DELETE FROM @EdmMarkerTbl
		WHERE MarkerID = @HighestMarker

		--Remove varieties from Clusteredlist that no longer match the variety in test - that has markervaluepervariety record but not matcing
		
		SELECT TOP 1 @VarietyScore = AlleleScore FROM MarkerValuePerVariety WHERE VarietyNr = @VarietyNr AND MarkerID = @MarkerID;

		DELETE CV FROM @ClusterVarTbl CV
		JOIN MarkerValuePerVariety MVPV ON MVPV.VarietyNr = CV.VarietyNr AND MVPV.MarkerID = @HighestMarker AND dbo.FN_IsMatching(@VarietyScore, MVPV.AlleleScore) = 0
								
		--Keep input variety in list in case removed
		IF NOT EXISTS (SELECT * FROM @ClusterVarTbl WHERE VarietyNr = @VarietyNr)
		BEGIN
			INSERT INTO @ClusterVarTbl
			VALUES(@VarietyNr);
		END;

		--Create marker to be tested in temptable
		INSERT INTO @MarkerTbl
		VALUES(@DetAssignmentID, @HighestMarker, 1, 0)

		SELECT @CountClusteredVarieties = COUNT(VarietyNr) FROM @ClusterVarTbl;
	END

	--step 4 : Try to find inbred marker
			
	-- find inbred marker if crop allows inbred
	IF EXISTS (SELECT * FROM CropRD WHERE CropCode = @Crop AND InBreed = 1)
	BEGIN

		--convert table column value to comma separated list
		SET @List = '';
		SELECT @List = @List + MarkerValue + ',' from @MMSMarkerTbl;
		SET @List = SUBSTRING(@List, 0, LEN(@List));

		EXEC [PR_FindInbredMarker] @List, @VarietyNr, @Female, @Male, @Reciprocal, @ImsMarker OUTPUT; --Reciprocal indicator not available in db so 0 used for now

		-- if no inbred marker found using MMSMarkers
		IF(@ImsMarker = 0)
		BEGIN			

			--convert table column value to comma separated list
			SET @List = '';
			SELECT @List = @List + MarkerValue + ',' from @EdmMarkerTblOrig;
			SET @List = SUBSTRING(@List, 0, LEN(@List));

			EXEC [PR_FindInbredMarker] @List, @VarietyNr, @Female, @Male, 0, @ImsMarker OUTPUT; --Reciprocal indicator not available in db so 0 used for now

		END;

		--if marker found
		IF(@ImsMarker > 0)
		BEGIN

			--If record already exists for same test/marker update InIms to true
			MERGE INTO @MarkerTbl T
			USING
			(
				SELECT @ImsMarker AS Marker
			) S ON T.MarkerID = S.Marker
			WHEN NOT MATCHED THEN
				INSERT (DetAssignmentID, MarkerID, InEDS, InIMS)
				VALUES (@DetAssignmentID, @ImsMarker, 0, 1)
			WHEN MATCHED THEN
				UPDATE SET T.InIMS = 1;

		END;

	END;
			
	--Create MarkerToBeTested record in database from temptable @MarkerTbl
	INSERT INTO MarkerToBeTested (DetAssignmentID, MarkerID, InEDS, InIMS, [Audit])
	SELECT DetAssignmentID, MarkerID, InEDS, InIMS, 'AutoDecluster, ' + CONVERT(NVARCHAR(50), getdate()) FROM @MarkerTbl

	--convert table column value to comma separated list
	SET @List = '';
	SELECT @List = @List + CONVERT(NVARCHAR(20),VarietyNr) + ',' from @ClusterVarTbl;
	SET @List = SUBSTRING(@List, 0, LEN(@List));
	SET @ReturnVarieties = @List;
	
END
GO


DROP PROCEDURE IF EXISTS [dbo].[PR_ConfirmPlanning]
GO


/*
Author					Date			Description
Binod Gurung			2019-Sept-04	Service to confirm planning

===================================Example================================

EXEC PR_ConfirmPlanning 4780, N'[{"DetAssignmentID":733313,"MethodCode":"PAC-01","ABSCropCode":"HP","SampleNr":1223714,"UtmostInlayDate":"11/03/2016","ExpectedReadyDate":"08/03/2016",
"PriorityCode":1,"BatchNr":0,"RepeatIndicator":false,"VarietyNr":20993,"ProcessNr":"0","ProductStatus":"5","Remarks":null,"PlannedDate":"08/01/2016","IsPlanned":false,"UsedFor":"Hyb",
"CanEditPlanning":true,"can":true,"init":false,"flag":true,"change":true,"Action":"i"}]';
*/
CREATE PROCEDURE [dbo].[PR_ConfirmPlanning]
(
    @PeriodID	 INT,
    @DataAsJson NVARCHAR(MAX)
)
AS 
BEGIN
    SET NOCOUNT ON;

    DECLARE @TransCount BIT = 0;
    DECLARE @StartDate DATE, @EndDate DATE;    
    SELECT 
	   @StartDate = P.StartDate,
	   @EndDate = P.EndDate
    FROM [Period] P 
    WHERE P.PeriodID = @PeriodID;

    BEGIN TRY
	   IF @@TRANCOUNT = 0 BEGIN
		  BEGIN TRANSACTION;
		  SET @TransCount = 1;
	   END
	   
	   DELETE DA
	   FROM DeterminationAssignment DA
	   JOIN OPENJSON(@DataAsJson) WITH
	   (
		  DetAssignmentID INT,
		  [Action]	   CHAR(1)
	   ) S ON S.DetAssignmentID = DA.DetAssignmentID
	   WHERE S.[Action] = 'D'
	   AND CAST(DA.PlannedDate AS DATE) BETWEEN @StartDate AND @EndDate;

	   --Change status to 200 of those records which falls under that period
	   UPDATE DA SET 
		  DA.IsLabPriority = S.IsLabPriority
	   FROM DeterminationAssignment DA
	   JOIN OPENJSON(@DataAsJson) WITH
	   (
		  DetAssignmentID INT,
		  IsLabPriority   BIT,
		  [Action]	   CHAR(1)
	   ) S ON S.DetAssignmentID = DA.DetAssignmentID
	   WHERE S.[Action] = 'U'
	   AND CAST(DA.PlannedDate AS DATE) BETWEEN @StartDate AND @EndDate;

	   --update status of all records of that particular week if there are no any data comes in json
	   UPDATE DA
		  SET DA.StatusCode = 200
	   FROM DeterminationAssignment DA
	   WHERE DA.StatusCode = 100 
	   AND CAST(DA.PlannedDate AS DATE) BETWEEN @StartDate AND @EndDate; 
	   	   
	   --validate
	   DECLARE @Groups TABLE
	   (
		  ABSCropCode	    NVARCHAR(10), 
		  MethodCode	    NVARCHAR(50), 
		  UsedFor	    VARCHAR(5), 
		  ReservePlates   DECIMAL(5,2),
		  TotalPlates	DECIMAL(5,2)
	   );

	   INSERT @Groups(ABSCropCode, MethodCode, UsedFor, ReservePlates, TotalPlates)
	   EXEC PR_ValidateCapacityPerFolder @PeriodID, @DataAsJson;

	   IF @@ROWCOUNT > 0 BEGIN
		  SELECT 
			 ABSCropCode, 
			 MethodCode, 
			 UsedFor, 
			 ReservePlates, 
			 TotalPlates
		  FROM @Groups;
		  
		  IF @TransCount = 1 
			 ROLLBACK;

		  RETURN;
	   END
	   
	   --insert new records if it is not in automatic plan but user has checked it up
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
			Process, 
			ProductStatus, 
			Remarks, 
			PlannedDate, 
			UtmostInlayDate, 
			ExpectedReadyDate,
			StatusCode,		  
			ReceiveDate,
			ReciprocalProd,
			BioIndicator,
			LogicalClassificationCode,
			LocationCode,
			IsLabPriority
	   )
	   SELECT 
			S.DetAssignmentID, 
			S.SampleNr, 
			S.PriorityCode, 
			S.MethodCode, 
			S.ABSCropCode, 
			S.VarietyNr, 
			S.BatchNr, 
			S.RepeatIndicator, 
			S.Process, 
			S.ProductStatus, 
			S.Remarks, 
			CASE WHEN CAST(S.PlannedDate AS DATE) BETWEEN @StartDate AND @EndDate THEN S.PlannedDate ELSE @EndDate END,
			S.UtmostInlayDate, 
			S.ExpectedReadyDate,
			200,	  
			S.ReceiveDate,
			S.ReciprocalProd,
			S.BioIndicator,
			S.LogicalClassificationCode,
			S.LocationCode,
			S.IsLabPriority
	   FROM OPENJSON(@DataAsJson) WITH
	   (
			DetAssignmentID	   INT,
			SampleNr		   INT,
			PriorityCode	   INT,
			MethodCode		   NVARCHAR(25),
			ABSCropCode		   NVARCHAR(10),
			VarietyNr		   INT,
			BatchNr		   INT,
			RepeatIndicator	   BIT,
			Process			   NVARCHAR(100),
			ProductStatus	   NVARCHAR(100),
			Remarks			   NVARCHAR(250),
			PlannedDate		   DATETIME,
			UtmostInlayDate	   DATETIME,
			ExpectedReadyDate   DATETIME,
			IsLabPriority	  BIT,
			[Action]	   CHAR(1),	   
			ReceiveDate		DATETIME,
			ReciprocalProd	BIT,
			BioIndicator		BIT,
			LogicalClassificationCode	BIT,
			LocationCode				NVARCHAR(20)
	   ) S
	   JOIN Variety V ON V.VarietyNr = S.VarietyNr
	   LEFT JOIN DeterminationAssignment DA ON DA.DetAssignmentID = S.DetAssignmentID	   
	   WHERE S.[Action] = 'I'
	   AND S.PriorityCode NOT IN(4, 7, 8)
	   AND DA.DetAssignmentID IS NULL;

	   --Generate folder structure based on confirmed data
	   EXEC PR_GenerateFolderDetails @PeriodID;
	   
	   IF @TransCount = 1 
		  COMMIT;
    END TRY
    BEGIN CATCH
	   IF @TransCount = 1 
		  ROLLBACK;
	   THROW;
    END CATCH
END
GO


