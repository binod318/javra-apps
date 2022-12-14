CREATE FUNCTION [dbo].[FN_GetWeekStartDate]
(
    @dt DATETIME
) RETURNS DATETIME
AS BEGIN
    -- get DATEFIRST setting
    DECLARE @ds INT = @@DATEFIRST;
    -- get week day number under current DATEFIRST setting
    DECLARE @dow INT = DATEPART(DW, @dt); 
    DECLARE @wd  INT =  1 + (((@dow + @ds) % 7) + 5) % 7;  -- this is always return Mon as 1,Tue as 2 ... Sun as 7 
    RETURN DATEADD(dd, 1 - @wd, @dt);
END
GO


/*
Author					Date			Description
Binod Gurung			2020-jan-23		Transcation isolation level implemented to avoid record lock
Dibya			    2020-Feb-19		Performance improvements on unplanned data	
Dibya			    2020-MAR-4		Adjusted ExpectedReadyDate

===================================Example================================

    DECLARE @ABSDataAsJson NVARCHAR(MAX) =  N'[{"DetAssignmentID":1736406,"MethodCode":"PAC-01","ABSCropCode": "SP","VarietyNr":"21063","PriorityCode": 1}]';
    EXEC PR_PlanAutoDeterminationAssignments 4779, @ABSDataAsJson
*/
ALTER PROCEDURE [dbo].[PR_PlanAutoDeterminationAssignments]
(
    @PeriodID	 INT,
    @ExpWeekDifference	 INT,
    @ABSData	 TVP_DeterminationAssignment READONLY
) 
AS 
BEGIN
    SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    DECLARE @TransCount BIT = 0;

    DECLARE @ABSCropCode NVARCHAR(10);
    DECLARE @MethodCode	NVARCHAR(25);
    DECLARE @RequiredPlates INT;
    DECLARE @UsedFor NVARCHAR(10);
    DECLARE @PlatesPerMethod	  DECIMAL(5,2);
    DECLARE @RequiredDeterminations INT;
    DECLARE @StartDate DATE, @EndDate DATE;
    DECLARE @ExpectedReadyDate DATETIME;
    DECLARE @IDX INT = 1;
    DECLARE @CNT INT = 0;
    
    SELECT
	   @StartDate = StartDate,
	   @EndDate = EndDate
    FROM [Period]
    WHERE PeriodID = @PeriodID;

    --first get first date from the monday of the week
    SET @ExpectedReadyDate = dbo.FN_GetWeekStartDate(@StartDate);
    --Add nr of weeks on weekstart date which is coming from settings
    SET @ExpectedReadyDate = DATEADD(WEEK, @ExpWeekDifference, @ExpectedReadyDate);

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
	   LogicalClassificationCode	NVARCHAR(20),
	   LocationCode					NVARCHAR(20),
	   UsedFor		    NVARCHAR(10)
    );

     BEGIN TRY
	   IF @@TRANCOUNT = 0 BEGIN
		  BEGIN TRANSACTION;
		  SET @TransCount = 1;
	   END

	   --clean already planned records before planning again
	   DELETE DA
	   FROM DeterminationAssignment DA
	   WHERE CAST(DA.PlannedDate AS DATE) BETWEEN @StartDate AND @EndDate
	   AND DA.StatusCode = 100;

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
		  T1.DetAssignmentID, 
		  T1.SampleNr, 
		  T1.PriorityCode, 
		  T1.MethodCode, 
		  T1.ABSCropCode, 
		  T1.VarietyNr, 
		  T1.BatchNr, 
		  T1.RepeatIndicator, 
		  T1.Process, 
		  T1.ProductStatus, 
		  T1.Remarks, 
		  T1.PlannedDate, 
		  T1.UtmostInlayDate, 
		  --T1.ExpectedReadyDate,
		  @ExpectedReadyDate,
		  T1.ReceiveDate,
		  T1.ReciprocalProd,
		  T1.BioIndicator,
		  T1.LogicalClassificationCode,
		  T1.LocationCode,
		  UsedFor = CASE WHEN V.HybOp = 0 AND V.[Type] = 'P' THEN 'Par' ELSE 'Hyb' END
	   FROM @ABSData T1
	   JOIN ABSCrop C ON C.ABSCropCode = T1.ABSCropCode
	   JOIN Variety V ON V.VarietyNr = T1.VarietyNr
	   JOIN Method M ON M.MethodCode = T1.MethodCode
	   WHERE T1.PriorityCode NOT IN(4, 7, 8)
	   AND dbo.FN_IsPacProfileComplete (V.VarietyNr, @PlatformID, C.CropCode) = 1 -- #8068 Only plan if PAC profile complete is true
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
				    --CASE WHEN CAST(D.PlannedDate AS DATE) BETWEEN @StartDate AND @EndDate THEN D.PlannedDate ELSE @EndDate END,
				    @EndDate,
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

/*
Author					Date			Description
Binod Gurung			2019-Sept-04	Service to confirm planning
Krishna Gautam			2020-jan-09		Changes to made to add extra folder or extra variety on plate filling after confirming with high lab priority even if plates is already requested on LIMS.
Binod Gurung			2020-jan-23		Transcation isolation level implemented to avoid record lock
										SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
Dibya			    2020-MAR-4		Adjusted ExpectedReadyDate

===================================Example================================

EXEC PR_ConfirmPlanning 4780, N'[{"DetAssignmentID":733313,"MethodCode":"PAC-01","ABSCropCode":"HP","SampleNr":1223714,"UtmostInlayDate":"11/03/2016","ExpectedReadyDate":"08/03/2016",
"PriorityCode":1,"BatchNr":0,"RepeatIndicator":false,"VarietyNr":20993,"ProcessNr":"0","ProductStatus":"5","Remarks":null,"PlannedDate":"08/01/2016","IsPlanned":false,"UsedFor":"Hyb",
"CanEditPlanning":true,"can":true,"init":false,"flag":true,"change":true,"Action":"i"}]';
*/
ALTER PROCEDURE [dbo].[PR_ConfirmPlanning]
(
    @PeriodID	 INT,
    @ExpWeekDifference	 INT,
    @ExpWeekDifferenceLab   INT,
    @DataAsJson NVARCHAR(MAX)
)
AS 
BEGIN
    SET NOCOUNT ON;

	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    DECLARE @TransCount BIT = 0;
    DECLARE @StartDate DATE, @EndDate DATE, @WeekStartDate DATETIME, @ExpectedReadyDate1 DATETIME, @ExpectedReadyDate2 DATETIME;   
    DECLARE @PlatformID INT = (SELECT PlatformID FROM [Platform] WHERE PlatformCode = 'LS'); --light scanner   

    SELECT 
	   @StartDate = P.StartDate,
	   @EndDate = P.EndDate
    FROM [Period] P 
    WHERE P.PeriodID = @PeriodID;

     --first get first date from the monday of the week
    SET @WeekStartDate = dbo.FN_GetWeekStartDate(@StartDate);
    --Add nr of weeks on weekstart date which is coming from settings
    SET @ExpectedReadyDate1 = DATEADD(WEEK, @ExpWeekDifference, @WeekStartDate);
    SET @ExpectedReadyDate2 = DATEADD(WEEK, @ExpWeekDifferenceLab, @WeekStartDate);

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
		  DA.IsLabPriority = S.IsLabPriority,
		  DA.ExpectedReadyDate = CASE S.IsLabPriority 
								WHEN 0 THEN @ExpectedReadyDate1
								ELSE @ExpectedReadyDate2
							 END
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
			--S.ExpectedReadyDate,
			CASE S.IsLabPriority 
				WHEN 0 THEN @ExpectedReadyDate1
				ELSE @ExpectedReadyDate2
			END,
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
			LogicalClassificationCode	NVARCHAR(20),
			LocationCode				NVARCHAR(20)
	   ) S
	   JOIN ABSCrop C ON C.ABSCropCode = S.ABSCropCode
	   JOIN Variety V ON V.VarietyNr = S.VarietyNr
	   LEFT JOIN DeterminationAssignment DA ON DA.DetAssignmentID = S.DetAssignmentID
	   WHERE S.[Action] = 'I'
	   AND S.PriorityCode NOT IN(4, 7, 8)
	   AND DA.DetAssignmentID IS NULL
	   AND dbo.FN_IsPacProfileComplete (V.VarietyNr, @PlatformID, C.CropCode) = 1 -- #8068 Only plan if PAC profile complete is true
	   
	   --Generate folder structure based on confirmed data
	   --EXEC PR_GenerateFolderDetails @PeriodID, 0; --Process for Non IsLabPriority determination assignments first
	   EXEC PR_FitPlatesToFolder @PeriodID;
	   
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

/*
Author					Date			Description
Binod Gurung			2020-jan-23		Transcation isolation level implemented to avoid record lock
Dibya			    2020-Feb-19		Performance improvements on unplanned data
Dibya			    2020-Feb-25		Included NrOfPlates on response to calculate Plates on check changed event on client side.

===================================Example================================

    DECLARE @UnPlannedDataAsJson NVARCHAR(MAX) = N'[{"DetAssignmentID":1,"MethodCode":"PAC-01","ABSCropCode": "HP","VarietyNr":"21046"}]';
    EXEC PR_GetDeterminationAssignments 4780, @UnPlannedDataAsJson
*/

ALTER PROCEDURE [dbo].[PR_GetDeterminationAssignments]
(
    @PeriodID	INT,
    @DeterminationAssignment TVP_DeterminationAssignment READONLY
) 
AS 
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    DECLARE @StartDate DATE, @EndDate DATE;
    DECLARE @SQL NVARCHAR(MAX);
    DECLARE @PlatformID INT = (SELECT PlatformID FROM [Platform] WHERE PlatformCode = 'LS'); --light scanner   
    DECLARE @MaxSeqNr INT = 0;
    
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
	   IsPacComplete	BIT	
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
	   --UsedFor = CASE WHEN V.HybOp = 0 AND V.[Type] = 'P' THEN 'Par' ELSE 'Hyb' END,
	   UsedFor = V1.UsedFor,
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
    JOIN Variety V ON V.VarietyNr = DA.VarietyNr
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
		  --UsedFor = CASE WHEN V.HybOp = 0 AND V.[Type] = 'P' THEN 'Par' ELSE 'Hyb' END,
		  UsedFor = V1.UsedFor,
		  CASE WHEN DA.PriorityCode IN(4, 7, 8) THEN 0 ELSE 1 END,
		  0,
		  dbo.FN_IsPacProfileComplete (DA.VarietyNr, @PlatformID, AC.CropCode) --#8068 Check PAC profile complete 
	   FROM @DeterminationAssignment DA
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
	   JOIN ABSCrop AC ON AC.ABSCropCode = DA.ABSCropCode
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
	   VarietyNr,
	   NrOfPlates = CAST((M.NrOfSeeds / 92.0) AS DECIMAL(5,2))
    FROM @Result T
    JOIN Method M ON M.MethodCode = T.MethodCode
    ORDER BY T.ABSCropCode, T.MethodCode, T.PriorityCode, ExpectedReadyDate;
END
GO