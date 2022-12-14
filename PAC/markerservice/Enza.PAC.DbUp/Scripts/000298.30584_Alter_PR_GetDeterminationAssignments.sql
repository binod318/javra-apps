DROP PROCEDURE IF EXISTS [dbo].[PR_GetDeterminationAssignments]
GO



/*
Author					Date			Description
Binod Gurung			2020-jan-23		Transcation isolation level implemented to avoid record lock
Dibya					2020-Feb-19		Performance improvements on unplanned data
Dibya					2020-Feb-25		Included NrOfPlates on response to calculate Plates on check changed event on client side.
Binod Gurung			2021-dec-22		Display empty slots on planning capacity screen [#30584]
BInod Gurung			2021-dec-27		Find invalid determination assignments which has mismatch information from ABS to PAC database [30904]
===================================Example================================

    DECLARE @UnPlannedDataAsJson NVARCHAR(MAX) = N'[{"DetAssignmentID":1,"MethodCode":"PAC-01","ABSCropCode": "HP","VarietyNr":"21046"}]';
    EXEC PR_GetDeterminationAssignments 4780, @UnPlannedDataAsJson
*/

CREATE PROCEDURE [dbo].[PR_GetDeterminationAssignments]
(
    @PeriodID	INT,
    @DeterminationAssignment TVP_DeterminationAssignment READONLY,
	@InvalidIDs NVARCHAR(256) OUTPUT
) 
AS 
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    DECLARE @StartDate DATE, @EndDate DATE;
    DECLARE @SQL NVARCHAR(MAX);
    DECLARE @PlatformID INT = (SELECT PlatformID FROM [Platform] WHERE PlatformCode = 'LS'); --light scanner   
    DECLARE @MaxSeqNr INT = 0
    
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
    --Prapare output of details records
    DECLARE @Result TABLE
    (
	   SeqNr			  INT,
	   DetAssignmentID    INT,
	   SampleNr		  INT,
	   PriorityCode	  INT,
	   MethodCode		  NVARCHAR(25),
	   ABSCropCode		  NVARCHAR(10),
	   Article		  NVARCHAR(100),
	   VarietyNr		  INT,
	   BatchNr		  INT,
	   RepeatIndicator    BIT,
	   Process		  NVARCHAR(100),
	   ProductStatus	  NVARCHAR(100),
	   Remarks			  NVARCHAR(MAX),
	   PlannedDate		  DATETIME,
	   UtmostInlayDate    DATETIME,
	   ExpectedReadyDate  DATETIME,
	   IsPlanned		  BIT,
	   UsedFor			NVARCHAR(10),
	   CanEdit			BIT,
	   IsLabPriority	BIT,
	   IsPacComplete	BIT,
	   IsInfoMissing	BIT
    );

    SELECT
	   @StartDate = StartDate,
	   @EndDate = EndDate
    FROM [Period]
    WHERE PeriodID = @PeriodID;
	--select * from @DeterminationAssignment; return;
    --Prepare capacities of planned records
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
				PM.NrOfSeeds,
				pcm.UsedFor
			FROM Method PM
			JOIN CropMethod PCM ON PCM.MethodID = PM.MethodID
			JOIN ABSCrop AC ON AC.ABSCropCode = PCM.ABSCropCode
			WHERE PCM.PlatformID = @PlatformID
			AND PM.StatusCode = 100
		) V1 ON V1.ABSCropCode = DA.ABSCropCode AND V1.MethodCode = DA.MethodCode
		--handle if same method is used for hybrid and parent
		JOIN
		(
			SELECT 
				VarietyNr, 
				UsedFor = CASE WHEN HybOp = 1 AND [Type] <> 'P' THEN 'Hyb' ELSE 'Par' END
			FROM Variety
		) V ON V.VarietyNr = DA.VarietyNr AND V.UsedFor = V1.UsedFor
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
	   SeqNr,
	   DetAssignmentID,	 
	   MethodCode,		
	   ABSCropCode,
	   SampleNr,
	   UtmostInlayDate, 
	   ExpectedReadyDate,
	   PriorityCode,	
	   BatchNr,	
	   RepeatIndicator, 
	   Article,
	   VarietyNr,
	   Process,		
	   ProductStatus,	
	   Remarks, 
	   PlannedDate,	   
	   IsPlanned,		
	   UsedFor,
	   CanEdit,
	   IsLabPriority,
	   IsPacComplete
    )
    SELECT 
	   DA.SeqNr,
	   DA.DetAssignmentID,
	   DA.MethodCode,
	   DA.ABSCropCode,
	   DA.SampleNr,
	   DA.UtmostInlayDate,
	   DA.ExpectedReadyDate, 
	   DA.PriorityCode,	   
	   DA.BatchNr,
	   DA.RepeatIndicator,
	   V.Shortname,
	   V.VarietyNr,
	   DA.Process,
	   DA.ProductStatus,
	   DA.Remarks,
	   DA.PlannedDate,
	   IsPlanned = 1,
	   UsedFor = V.UsedFor,
	   --UsedFor = V1.UsedFor,
	   CASE WHEN DA.StatusCode < 200 THEN 1 ELSE 0 END,
	   ISNULL(DA.IsLabPriority, 0),
	   1 --Pac complete profile true for already planned DA
    FROM DeterminationAssignment DA
    JOIN
    (
	   SELECT
		  AC.ABSCropCode,
		  PM.MethodCode,
		  CM.UsedFor
	   FROM CropMethod CM
	   JOIN ABSCrop AC ON AC.ABSCropCode = CM.ABSCropCode
	   JOIN Method PM ON PM.MethodID = CM.MethodID
	   WHERE CM.PlatformID = @PlatformID
    ) V1 ON V1.ABSCropCode = DA.ABSCropCode AND V1.MethodCode = DA.MethodCode
	JOIN
	(
		SELECT 
			VarietyNr, 
			Shortname,
			UsedFor = CASE WHEN HybOp = 1 AND [Type] <> 'P' THEN 'Hyb' ELSE 'Par' END
		FROM Variety
	) V ON V.VarietyNr = DA.VarietyNr AND V.UsedFor = V1.UsedFor
    WHERE CAST(DA.PlannedDate AS DATE) BETWEEN @StartDate AND @EndDate
	
    --Process unplannded records    
    IF EXISTS (SELECT DetAssignmentID FROM @DeterminationAssignment) BEGIN
	   SELECT 
		  @MaxSeqNr = MAX(SeqNr) 
	   FROM @Result;
	   
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
	   
	   --Get details of unplanned determinations    
	   INSERT @Result
	   (
		  SeqNr,
		  DetAssignmentID,	 
		  MethodCode,		
		  ABSCropCode,
		  SampleNr,
		  UtmostInlayDate, 
		  ExpectedReadyDate,
		  PriorityCode,	
		  BatchNr,	
		  RepeatIndicator, 
		  Article,
		  VarietyNr,
		  Process,		
		  ProductStatus,	
		  Remarks, 
		  PlannedDate,	   
		  IsPlanned,		
		  UsedFor,
		  CanEdit,
		  IsLabPriority,
		  IsPacComplete,
		  IsInfoMissing
	   )
	   SELECT 
		  SeqNr = ROW_NUMBER() OVER(ORDER BY DetAssignmentID) + @MaxSeqNr,
		  DA.DetAssignmentID,
		  DA.MethodCode,
		  DA.ABSCropCode,
		  DA.SampleNr,
		  DA.UtmostInlayDate,
		  DA.ExpectedReadyDate, 
		  DA.PriorityCode,	   
		  DA.BatchNr,
		  DA.RepeatIndicator,
		  V.Shortname,
		  V.VarietyNr,
		  DA.Process,
		  DA.ProductStatus,
		  DA.Remarks,
		  DA.PlannedDate,
		  IsPlanned = 0,
		  UsedFor = V.UsedFor,
		  --UsedFor = V1.UsedFor,
		  CASE WHEN DA.PriorityCode IN(4, 7, 8) THEN 0 ELSE 1 END,
		  0,
		  dbo.FN_IsPacProfileComplete (DA.VarietyNr, @PlatformID, V1.CropCode), --#8068 Check PAC profile complete 
		  IsInfoMissing = CASE WHEN V1.ABSCropCode IS NULL OR V.VarietyNr IS NULL THEN 1 ELSE 0 END
	   FROM @DeterminationAssignment DA
	   JOIN
	   (
		  SELECT
			 AC.ABSCropCode,
			 AC.CropCode,
			 PM.MethodCode,
			 CM.UsedFor
		  FROM CropMethod CM
		  JOIN ABSCrop AC ON AC.ABSCropCode = CM.ABSCropCode
		  JOIN Method PM ON PM.MethodID = CM.MethodID
		  WHERE CM.PlatformID = @PlatformID
	   ) V1 ON V1.ABSCropCode = DA.ABSCropCode AND V1.MethodCode = DA.MethodCode
	   --JOIN ABSCrop AC ON AC.ABSCropCode = DA.ABSCropCode
	   JOIN
	   (
			SELECT 
				VarietyNr, 
				Shortname,
				UsedFor = CASE WHEN HybOp = 1 AND [Type] <> 'P' THEN 'Hyb' ELSE 'Par' END
			FROM Variety
	   ) V ON V.VarietyNr = DA.VarietyNr AND V.UsedFor = V1.UsedFor
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
    WHERE G.TotalPlates > 0;

    --return details
    SELECT 
	   DetAssignmentID,	 
	   T.MethodCode,		
	   ABSCropCode,
	   SampleNr,
	   UtmostInlayDate = FORMAT(UtmostInlayDate, 'dd/MM/yyyy'), 
	   ExpectedReadyDate = FORMAT(ExpectedReadyDate, 'dd/MM/yyyy'),
	   PriorityCode,	
	   BatchNr,	
	   RepeatIndicator, 
	   Article,
	   Process,		
	   ProductStatus,	
	   Remarks, 
	   PlannedDate = FORMAT(PlannedDate, 'dd/MM/yyyy'),
	   IsPlanned,		
	   UsedFor,
	   CanEditPlanning = CanEdit,
	   IsLabPriority,
	   IsPacComplete,
	   IsInfoMissing,
	   VarietyNr,
	   NrOfPlates = CAST((M.NrOfSeeds / 92.0) AS DECIMAL(5,2))
    FROM @Result T
    JOIN Method M ON M.MethodCode = T.MethodCode
    ORDER BY T.ABSCropCode, T.MethodCode, T.PriorityCode, ExpectedReadyDate;

	--check if Variety is invalid
	SELECT 
		@InvalidIDs = COALESCE(@InvalidIDs + ',','') + CAST (DA.DetAssignmentID AS NVARCHAR(20))
	FROM @DeterminationAssignment DA
	LEFT JOIN Variety V ON V.VarietyNr = DA.VarietyNr
	WHERE V.VarietyNr IS NULL

	--check if Crop/Method is invalid
	SELECT 
		@InvalidIDs = COALESCE(@InvalidIDs + ',','') + CAST (DA.DetAssignmentID AS NVARCHAR(20))
	FROM @DeterminationAssignment DA
	LEFT JOIN
	(
		SELECT
			AC.ABSCropCode,
			PM.MethodCode,
			CM.UsedFor
		FROM CropMethod CM
		JOIN ABSCrop AC ON AC.ABSCropCode = CM.ABSCropCode
		JOIN Method PM ON PM.MethodID = CM.MethodID
		WHERE CM.PlatformID = @PlatformID
	) V1 ON V1.ABSCropCode = DA.ABSCropCode AND V1.MethodCode = DA.MethodCode
	WHERE V1.ABSCropCode IS NULL

	--Add descriptive message if invalid ID exists
	IF(ISNULL(@InvalidIDs,'') <> '')
		SET @InvalidIDs = 'Information mismatch for the following determination assignments.<br>' + @InvalidIDs;

END
GO


