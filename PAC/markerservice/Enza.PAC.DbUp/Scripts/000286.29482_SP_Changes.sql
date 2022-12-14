DROP PROCEDURE IF EXISTS [dbo].[PR_GenerateFolderDetails]
GO

DROP PROCEDURE IF EXISTS [dbo].[PR_FitPlatesToFolder]
GO



/*
Author					Date			Remarks
Krishna Gautam			2020/01/10		Created folder structcture based on lab priority and excelude already sent test while preparing folder structure
Binod Gurung			2020-jan-23		Transcation isolation level implemented to avoid record lock
										SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
Binod Gurung			2021-dec-07		Make maximum numbers of plate in one fodler configurable #29482
============ExAMPLE===================
--EXEC PR_FitPlatesToFolder 4792
*/
CREATE PROCEDURE [dbo].[PR_FitPlatesToFolder]
(
	@PeriodID INT,
	@MaxPlatesInFolder DECIMAL
)
AS BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

	DECLARE @TransCount BIT = 0;
	 
    BEGIN TRY	  
	   IF @@TRANCOUNT = 0 BEGIN
		  BEGIN TRANSACTION;
		  SET @TransCount = 1;
	   END
		  DECLARE @StartDate DATE, @EndDate DATE, @loopCountGroup INT=1,@TotalTestRequired INT =0, @TotalCreatedTests INT =0,  @CropCode NVARCHAR(MAX), @MethodCode NVARCHAR(MAX), @PlatformName NVARCHAR(MAX), @TotalGroups INT, @TotalFolderRequired INT =0, @TestID INT =0, @groupLoopCount INT =0, @Offset INT=0, @NextRows INT =0;
		  --declare table to insert data of determinatonAssignment
		  DECLARE @tblDA TABLE(ID INT IDENTITY(1,1), CropCode NVARCHAR(10),MethodCode NVARCHAR(100),PlatformName NVARCHAR(100),DetAssignmentID INT,NrOfPlates DECIMAL(6,2),TestID INT);
		  --this is group table which is required to calculate how many folders are required per method per crop per platform
		  DECLARE @tblDAGroups TABLE(ID INT IDENTITY(1,1), CropCode NVARCHAR(10),MethodCode NVARCHAR(100),PlatformName NVARCHAR(100),groupRequired INT,MaxRowToSelect INT);
		  --declare Temp test table
		  DECLARE @tblTempTest TABLE(ID INT IDENTITY(1,1), CropCode NVARCHAR(10),MethodCode NVARCHAR(100),PlatformName NVARCHAR(100), TestID INT);
		  --declare test table to get sequential test ID
		  DECLARE @tblSeqTest TABLE(ID INT IDENTITY(1,1), TestID INT);
			
			
		  --get date range of current period
		  SELECT 
			 @StartDate = StartDate,
			 @EndDate = EndDate
		  FROM [Period] 
		  WHERE PeriodID = @PeriodID;

		  --for now do not insert testID this should be updated or inserted later depending upon condition
		  INSERT INTO @tblDA(CropCode,MethodCode,PlatformName,DetAssignmentID,NrOfPlates)
			SELECT 
				C.CropCode,
				DA.MethodCode,
				P.PlatformDesc,
				DA.DetAssignmentID,
				M.NrOfSeeds/92.0
			FROM DeterminationAssignment DA
			JOIN ABSCrop C ON C.ABSCropCode = DA.ABSCropCode
			JOIN Method M ON M.MethodCode = DA.MethodCode
			JOIN CropMethod CM ON CM.MethodID = M.MethodID AND CM.ABSCropCode = DA.ABSCropCode
			--handle if same method is used for hybrid and parent
			JOIN
			(
				SELECT 
					VarietyNr, 
					UsedFor = CASE WHEN HybOp = 1 AND [Type] <> 'P' THEN 'Hyb' ELSE 'Par' END
				FROM Variety
			) V ON V.VarietyNr = DA.VarietyNr AND V.UsedFor = CM.UsedFor
			JOIN [Platform] P ON P.PlatformID = CM.PlatformID				
			WHERE CAST(DA.PlannedDate AS DATE) BETWEEN @StartDate AND @EndDate	
			AND NOT EXISTS 
			( 
				SELECT TD.DetAssignmentID FROM  TestDetAssignment TD
				JOIN TEST T ON T.TestID = TD.TestID
				WHERE T.StatusCode >= 200 AND T.PeriodID = @PeriodID AND TD.DetAssignmentID = DA.DetAssignmentID
			)
			ORDER BY C.CropCode ASC, DA.MethodCode ASC, P.PlatformDesc ASC, ISNULL(DA.IsLabPriority, 0) DESC, DA.DetAssignmentID ASC;


		  INSERT INTO @tblDAGroups(CropCode,MethodCode,PlatformName,groupRequired, MaxRowToSelect)
			SELECT 
				C.CropCode,
				DA.MethodCode,
				P.PlatformDesc,
				groupRequired = CEILING((SUM(M.NrOfSeeds)/92.0) / @MaxPlatesInFolder),
				MaxRecordPerPlate = CASE 
										WHEN  MAX(M.NrOfSeeds)/92.0 > 0 THEN FLOOR(@MaxPlatesInFolder / (MAX(M.NrOfSeeds)/92.0))
										ELSE @MaxPlatesInFolder * (MAX(M.NrOfSeeds)/92.0)
									END
			FROM DeterminationAssignment DA
			JOIN ABSCrop C ON C.ABSCropCode = DA.ABSCropCode
			JOIN Method M ON M.MethodCode = DA.MethodCode
			JOIN CropMethod CM ON CM.MethodID = M.MethodID AND CM.ABSCropCode = DA.ABSCropCode
			--handle if same method is used for hybrid and parent
			JOIN
			(
				SELECT 
					VarietyNr, 
					UsedFor = CASE WHEN HybOp = 1 AND [Type] <> 'P' THEN 'Hyb' ELSE 'Par' END
				FROM Variety
			) V ON V.VarietyNr = DA.VarietyNr AND V.UsedFor = CM.UsedFor
			JOIN [Platform] P ON P.PlatformID = CM.PlatformID							
			WHERE CAST(DA.PlannedDate AS DATE) BETWEEN @StartDate AND @EndDate
			AND NOT EXISTS 
			( 
				SELECT TD.DetAssignmentID FROM  TestDetAssignment TD
				JOIN TEST T ON T.TestID = TD.TestID
				WHERE T.StatusCode >= 200 AND T.PeriodID = @PeriodID AND TD.DetAssignmentID = DA.DetAssignmentID
			)
			GROUP BY C.CropCode, DA.MethodCode, P.PlatformDesc
			ORDER BY C.CropCode, DA.MethodCode, P.PlatformDesc;

		  SELECT @TotalTestRequired = SUM(groupRequired) FROM @tblDAGroups;
		  SELECT @TotalCreatedTests = COUNT(TestID) FROM Test WHERE PeriodID = @PeriodID AND StatusCode < 200;

		  WHILE(@TotalCreatedTests < @TotalTestRequired)
		  BEGIN
			 INSERT INTO Test(PeriodID,StatusCode)
			 VALUES(@PeriodID,100);
			 SET @TotalCreatedTests = @TotalCreatedTests + 1;
		  END

		  INSERT INTO @tblSeqTest(TestID)
		  SELECT TestID FROM Test  WHERE PeriodID = @PeriodID AND StatusCode < 200 order by TestID;

		  --SELECT * FROM @tblSeqTest;
		  --SELECT * FROM @tblDAGroups;

		  SELECT @TotalGroups = COUNT(ID) FROM @tblDAGroups
		  SET @loopCountGroup = 1;
		  SET @groupLoopCount= 1;

		  WHILE(@loopCountGroup <= @TotalGroups)
		  BEGIN
			 SELECT @CropCode = CropCode, @MethodCode = MethodCode, @PlatformName = PlatformName, @TotalFolderRequired = groupRequired, @NextRows = MaxRowToSelect from @tblDAGroups Where ID = @loopCountGroup;
			 SET @Offset = 0;
			 WHILE(@TotalFolderRequired > 0)
			 BEGIN
				    SELECT @TestID = TestID FROM @tblSeqTest WHERE ID = @groupLoopCount;
					
				    --SELECT * FROM @tblDA WHERE CropCode = @CropCode AND MethodCode = @MethodCode AND PlatformName = @PlatformName ORDER BY ID OFFSET @Offset ROWS FETCH NEXT @NextRows ROWS ONLY

				    MERGE INTO @TblDA T
				    USING
				    (
					   SELECT * FROM @tblDA WHERE CropCode = @CropCode AND MethodCode = @MethodCode AND PlatformName = @PlatformName ORDER BY ID OFFSET @Offset ROWS FETCH NEXT @NextRows ROWS ONLY
				    ) S ON S.ID = T.ID
				    WHEN MATCHED THEN 
				    UPDATE SET T.TestID = @TestID;

				    SET @groupLoopCount = @groupLoopCount + 1;
				    SET @Offset = @Offset + @NextRows ;
				    SET @TotalFolderRequired = @TotalFolderRequired -1;
			 END

			 SET @loopCountGroup = @loopCountGroup + 1;				
		  END
			
		  MERGE INTO TestDetAssignment T
		  USING @TblDA S
		  ON S.DetAssignmentID = T.DetAssignmentID
		  WHEN MATCHED AND T.TestID <> S.TestID THEN UPDATE
		  SET T.TestID = S.TestID
		  WHEN NOT MATCHED THEN
		  INSERT(DetAssignmentID, TestID)
		  VALUES(S.DetAssignmentID, S.TestID);

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

	RETURN;

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


