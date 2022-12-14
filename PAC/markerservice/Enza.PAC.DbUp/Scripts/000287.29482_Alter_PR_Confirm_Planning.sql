DROP PROCEDURE IF EXISTS [dbo].[PR_ConfirmPlanning]
GO


/*
Author					Date			Description
Binod Gurung			2019-Sept-04	Service to confirm planning
Krishna Gautam			2020-jan-09		Changes to made to add extra folder or extra variety on plate filling after confirming with high lab priority even if plates is already requested on LIMS.
Binod Gurung			2020-jan-23		Transcation isolation level implemented to avoid record lock
										SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
Dibya					2020-MAR-4		Adjusted ExpectedReadyDate
Binod Gurung			2021-dec-07		Make maximum numbers of plate in one fodler configurable #29482
===================================Example================================

EXEC PR_ConfirmPlanning 4780,5,2,12, N'[{"DetAssignmentID":733313,"MethodCode":"PAC-01","ABSCropCode":"HP","SampleNr":1223714,"UtmostInlayDate":"11/03/2016","ExpectedReadyDate":"08/03/2016",
"PriorityCode":1,"BatchNr":0,"RepeatIndicator":false,"VarietyNr":20993,"ProcessNr":"0","ProductStatus":"5","Remarks":null,"PlannedDate":"08/01/2016","IsPlanned":false,"UsedFor":"Hyb",
"CanEditPlanning":true,"can":true,"init":false,"flag":true,"change":true,"Action":"i"}]';
*/
CREATE PROCEDURE [dbo].[PR_ConfirmPlanning]
(
    @PeriodID	 INT,
    @ExpWeekDifference	 INT,
    @ExpWeekDifferenceLab   INT,
	@MaxPlatesInFolder DECIMAL,
    @DataAsJson NVARCHAR(MAX)
)
AS 
BEGIN
    SET NOCOUNT ON;

	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    DECLARE @TransCount BIT = 0;
    DECLARE @StartDate DATE, @EndDate DATE, @PlannedDate DATETIME, @ExpectedReadyDate1 DATETIME, @ExpectedReadyDate2 DATETIME;   
    DECLARE @PlatformID INT = (SELECT PlatformID FROM [Platform] WHERE PlatformCode = 'LS'); --light scanner   

    SELECT 
	   @StartDate = P.StartDate,
	   @EndDate = P.EndDate
    FROM [Period] P 
    WHERE P.PeriodID = @PeriodID;

    --This is the first Monday of the selected week
    SET @PlannedDate = dbo.FN_GetWeekStartDate(@StartDate);
    --Add number of week on start date and get the Friday of that week.
    SET @ExpectedReadyDate1 = DATEADD(WEEK, @ExpWeekDifference, @StartDate);
    --Get Monday of ExpectedReadyDate
    SET @ExpectedReadyDate1 = dbo.FN_GetWeekStartDate(@ExpectedReadyDate1);
    --get the date of Friday of that expected ready date
    SET @ExpectedReadyDate1 = DATEADD(DAY, 4, @ExpectedReadyDate1);

    --Add number of week on start date and get the Friday of that week.
    SET @ExpectedReadyDate2 = DATEADD(WEEK, @ExpWeekDifferenceLab, @StartDate);
    --Get Monday of ExpectedReadyDate
    SET @ExpectedReadyDate2 = dbo.FN_GetWeekStartDate(@ExpectedReadyDate2);
    --get the date of Friday of that expected ready date
    SET @ExpectedReadyDate2 = DATEADD(DAY, 4, @ExpectedReadyDate2);

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
			@PlannedDate,
			S.UtmostInlayDate, 
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
	   EXEC PR_FitPlatesToFolder @PeriodID, @MaxPlatesInFolder;
	   
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


