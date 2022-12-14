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
	   NrOfResPlates = ISNULL(V2.NrOfResPlates, 0)
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