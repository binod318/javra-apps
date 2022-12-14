DROP PROCEDURE IF EXISTS [dbo].[EZ_GetDeterminationAssignment]
GO


--EXEC [EZ_GetDeterminationAssignment] NULL, '2019-09-02', '2019-09-08' , 'PAC-01,PAC-EL', 'TO,SP,HP,EP', '5', '1,2,3,5,7', 0, 100;
CREATE PROCEDURE [dbo].[EZ_GetDeterminationAssignment] 
     @Determination_assignment INT = 0 --= 1207375                               [OPTIONAL VALUE!!]
       ,@Planned_date_From DateTime --= '2016-03-04 00:00:00.000'  
       ,@Planned_date_To DateTime --= '2018-12-06 00:00:00.000'
       ,@MethodCode Varchar(MAX) --= 'PAC-01'
       ,@ABScrop Varchar(MAX) --= 'SP'
       ,@StatusCode Varchar(MAX) --= '5'
       ,@Priority Varchar(MAX) --= '1,2,3,4'
       ,@PageNumber INT --= 0
       ,@PageSize INT --= 10

AS 
BEGIN

SET @StatusCode = replace(@StatusCode, ' ', '') 
SET @Priority = replace(@Priority, ' ', '') 

DECLARE @TotalCount INT
SELECT @TotalCount = Count(*) 
 FROM ABS_Determination_assignments
WHERE 
       CASE WHEN @Determination_assignment IS NULL OR @Determination_assignment = 0
             THEN 1
             ELSE Determination_assignment
       END = CASE WHEN @Determination_assignment IS NULL OR @Determination_assignment = 0
                           THEN 1
                           ELSE @Determination_assignment
       END
   --    And 
	  --(
	  -- (ISNULL(@Planned_date_From, '') = '' OR Date_booked >= @Planned_date_From)
	  -- And 
	  -- (ISNULL(@Planned_date_To, '') = '' OR Date_booked <= @Planned_date_To)
	  -- )
       AND Method_code IN (SELECT [value] FROM STRING_SPLIT(@MethodCode, ','))
       AND Crop_code   IN (SELECT [value] FROM STRING_SPLIT(@ABScrop, ','))
    AND Determination_status_code IN (SELECT [value] FROM STRING_SPLIT(@StatusCode, ','))
    AND Priority_code IN (SELECT [value] FROM STRING_SPLIT(@Priority, ','))
	
	
SELECT DA.[Determination_assignment] AS DeterminationAssignment
         ,DA.[Date_booked] AS planned_date 
         ,DA.[Sample_number] AS Sample
         ,DA.[Priority_code] AS Prio
         ,DA.[Method_code] AS MethodCode
         ,DA.[Crop_code] AS ABScrop
         ,DA.[Primary_number] AS VarietyNumber
         ,DA.[Batch_number] AS BatchNumber
         ,DA.[Repeat_indicator] AS RepeatIndicator
         ,DA.[Process_code] AS Process
         ,DA.Determination_status_code AS ProductStatus                          -- Vervangen voor juiste kolom
         ,PL.Batch_output_description AS BatchOutputDescription           -- Zie [ABS_DATA].[dbo].[Process_lots] 
         ,DA.[Utmost_inlay_date] AS UtmostInlayDate
         ,DA.[Expected_date_ready] AS ExpectedReadyDate
		 ,GETUTCDATE()
		 ,CAST(0 AS BIT)
		 ,CAST(0 AS BIT)
		 ,'M3'
		 ,'NLEN'
         ,@TotalCount AS TotalCount
  FROM ABS_Determination_assignments DA
  LEFT JOIN dbo.ABS_Process_lots PL
  ON PL.Batch_number = DA.Batch_number
  WHERE 
       CASE WHEN @Determination_assignment IS NULL OR @Determination_assignment = 0
             THEN 1
             ELSE Determination_assignment
       END = CASE WHEN @Determination_assignment IS NULL OR @Determination_assignment = 0
                           THEN 1
                           ELSE @Determination_assignment
       END
   --   And 
	  --(
	  -- (ISNULL(@Planned_date_From, '') = '' OR Date_booked >= @Planned_date_From)
	  -- And 
	  -- (ISNULL(@Planned_date_To, '') = '' OR Date_booked <= @Planned_date_To)
	  -- )
       AND Method_code IN (SELECT [value] FROM STRING_SPLIT(@MethodCode, ','))
       AND Crop_code   IN (SELECT [value] FROM STRING_SPLIT(@ABScrop, ','))
	AND Determination_status_code IN (SELECT [value] FROM STRING_SPLIT(@StatusCode, ','))
       AND Priority_code IN (SELECT [value] FROM STRING_SPLIT(@Priority, ','))
  ORDER BY Crop_code 
  OFFSET @PageSize * (@PageNumber -1) ROWS 
  FETCH NEXT @PageSize ROWS ONLY

END

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
	   LogicalClassificationCode	NVARCHAR(20),
	   LocationCode					NVARCHAR(20),
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
		  LogicalClassificationCode	NVARCHAR(20),
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


