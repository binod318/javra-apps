/*
    DECLARE @UnPlannedDataAsJson NVARCHAR(MAX) = N'[{"DetAssignmentID":1,"MethodCode":"PAC-01","ABSCropCode": "HP","PlannedDate":"2019-07-04"}]';
    EXEC PR_GetDeterminationAssignments 4779, '2019-09-02', '2019-09-08', @UnPlannedDataAsJson
*/
ALTER PROCEDURE [dbo].[PR_GetDeterminationAssignments]
(
    @PeriodID			   INT,
    @StartDate			   DATE,
    @EndDate			   DATE,
    @UnPlannedDataAsJson	   NVARCHAR(MAX) = NULL
) AS BEGIN
    SET NOCOUNT ON;

    DECLARE @SQL NVARCHAR(MAX);
    DECLARE @PlatformID INT = (SELECT PlatformID FROM [Platform] WHERE PlatformCode = 'LS'); --light scanner   

    DECLARE @Capacity TABLE
    (
	   UsedFor VARCHAR(5), 
	   CropCode NVARCHAR(10), 
	   MethodCode NVARCHAR(50), 
	   NrOfResPlates DECIMAL(5,2)
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
   
    INSERT @Capacity(UsedFor, CropCode, MethodCode, NrOfResPlates)
    SELECT
	   T1.UsedFor,
	   T1.CropCode,
	   T1.MethodCode,
	   NrOfPlates = SUM(T1.NrOfPlates)
    FROM
    (
	   SELECT 
		  V1.CropCode,
		  DA.MethodCode,
		  V1.UsedFor,
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
			 AC.CropCode,
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
    GROUP BY T1.CropCode, T1.MethodCode, T1.UsedFor;
    
    --Get groups
    SELECT
	   V1.SlotName,
	   V1.CropCode,
	   V1.MethodCode,
	   V1.UsedFor,
	   V1.TotalPlates,
	   V2.NrOfResPlates
    FROM
    (
	   SELECT 
		  PC.SlotName,
		  AC.CropCode, 
		  PM.MethodCode,	
		  CM.UsedFor,
		  TotalPlates = SUM(PC.NrOfPlates)
	   FROM ReservedCapacity PC
	   JOIN CropMethod CM ON CM.CropMethodID = PC.CropMethodID
	   JOIN ABSCrop AC ON AC.ABSCropCode = CM.ABSCropCode
	   JOIN Method PM ON PM.MethodID = CM.MethodID
	   WHERE CM.PlatformID = @PlatformID AND PC.PeriodID = @PeriodID
	   GROUP BY PC.SlotName, AC.CropCode, PM.MethodCode, CM.UsedFor
    ) V1
    LEFT JOIN @Capacity V2 ON V2.CropCode = V1.CropCode AND V2.MethodCode = V1.MethodCode AND V2.UsedFor = V1.UsedFor;
    
    SELECT 
	   V2.DetAssignmentID,
	   V1.CropCode,
	   MethodCode = ISNULL(DA.MethodCode, DA2.MethodCode),
	   V1.UsedFor,
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
		  WHERE CAST(PlannedDate AS DATE) BETWEEN @StartDate AND @EndDate
	   ) T1 
	   GROUP BY DetAssignmentID
    ) V2
    LEFT JOIN @DeterminationAssignment DA2 ON DA2.DetAssignmentID = V2.DetAssignmentID AND CAST(DA2.PlannedDate AS DATE) BETWEEN @StartDate AND @EndDate
    LEFT JOIN DeterminationAssignment DA ON DA.DetAssignmentID = V2.DetAssignmentID AND CAST(DA.PlannedDate AS DATE) BETWEEN @StartDate AND @EndDate
    JOIN
    (
	   SELECT
		  AC.CropCode,
		  AC.ABSCropCode,
		  PM.MethodCode,
		  CM.UsedFor
	   FROM CropMethod CM
	   JOIN ABSCrop AC ON AC.ABSCropCode = CM.ABSCropCode
	   JOIN Method PM ON PM.MethodID = CM.MethodID
	   WHERE CM.PlatformID = @PlatformID
    ) V1 ON V1.ABSCropCode = ISNULL(DA.ABSCropCode, DA2.ABSCropCode) AND V1.MethodCode = ISNULL(DA.MethodCode, DA2.MethodCode)
    ORDER BY V2.IsPlanned DESC, SampleNr ASC;
END
GO