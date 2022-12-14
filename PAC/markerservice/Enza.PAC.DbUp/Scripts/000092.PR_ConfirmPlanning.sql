-- https://www.mssqltips.com/sqlservertip/4897/handling-transactions-in-nested-sql-server-stored-procedures/
ALTER PROCEDURE [dbo].[PR_GenerateFolderDetails]
(
    @PeriodID INT,
    @IsLabPriority BIT
) AS BEGIN
    SET NOCOUNT ON;

    DECLARE @TransCount BIT = 0;
    DECLARE @PlateMaxLimit INT = 16;

    BEGIN TRY
	   IF @@TRANCOUNT = 0 BEGIN
		  BEGIN TRANSACTION;
		  SET @TransCount = 1;
	   END
    
	   DECLARE @StartDate DATE, @EndDate DATE;

	   SELECT 
		  @StartDate = StartDate,
		  @EndDate = EndDate
	   FROM [Period] 
	   WHERE PeriodID = @PeriodID;

	   DECLARE @tbl TABLE
	   (
		  ID			   INT IDENTITY(1,1), 
		  CropCode	   NVARCHAR(10),
		  MethodCode	   NVARCHAR(100),
		  PlatformName    NVARCHAR(100),
		  DetAssignmentID INT,
		  NrOfPlates	   DECIMAL(6,2)
	   );

	   --Make a groups based on Folder and other common attributes
	   DECLARE @groups TABLE
	   (
		  CropCode	   NVARCHAR(10),
		  MethodCode	   NVARCHAR(100),
		  PlatformName    NVARCHAR(100),
		  NrOfPlates	   DECIMAL(6,2),
		  NrOfPlateLimit  DECIMAL(6, 2)
	   );

	   WITH CTE (CropCode, MethodCode, PlatformName, NrOfPlates, NrOfPlateLimit) AS
	   (
		  SELECT 
			 C.CropCode,
			 DA.MethodCode, 
			 P.PlatformDesc,
			 V2.NrOfPlates,
			 NrOfPlateLimit = CASE 
							 WHEN @PlateMaxLimit % V2.NrOfPlates = 0 THEN 
								@PlateMaxLimit 
							 ELSE 
								@PlateMaxLimit - (@PlateMaxLimit % V2.NrOfPlates)
						   END
		  FROM DeterminationAssignment DA
		  JOIN ABSCrop C ON C.ABSCropCode = DA.ABSCropCode
		  JOIN TestDetAssignment TDA ON DA.DetAssignmentID = TDA.DetAssignmentID
		  JOIN Test T ON T.TestID = TDA.TestID
		  JOIN Method M ON M.MethodCode = DA.MethodCode
		  JOIN CropMethod CM ON CM.MethodID = M.MethodID AND CM.ABSCropCode = DA.ABSCropCode
		  JOIN [Platform] P ON P.PlatformID = CM.PlatformID
		  JOIN Variety V ON V.VarietyNr = DA.VarietyNr
		  JOIN
		  (
			 SELECT 
				MethodID,
				NrOfPlates = NrOfSeeds/92.0
			 FROM Method
		  ) V2 ON V2.MethodID = M.MethodID
		  WHERE T.PeriodID = @PeriodID
		  --AND ISNULL(DA.IsLabPriority, 0) = @IsLabPriority
	   )
	   INSERT @groups(CropCode, MethodCode, PlatformName, NrOfPlates, NrOfPlateLimit)		
	   SELECT
		  CropCode,
		  MethodCode,
		  PlatformName,    
		  NrOfPlates = SUM(NrOfPlates),
		  NrOfPlateLimit = MAX(NrOfPlateLimit)
	   FROM CTE
	   GROUP BY CropCode, MethodCode, PlatformName;

	   INSERT @tbl(CropCode, MethodCode, PlatformName, DetAssignmentID, NrOfPlates)
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
	   JOIN [Platform] P ON P.PlatformID = CM.PlatformID
	   WHERE CAST(DA.PlannedDate AS DATE) BETWEEN @StartDate AND @EndDate
	   --AND ISNULL(DA.IsLabPriority, 0) = @IsLabPriority
	   AND NOT EXISTS
	   (
		  SELECT 
			 TDA.DetAssignmentID 
		  FROM TestDetAssignment TDA
		  JOIN Test T ON T.TestID = TDA.TestID
		  WHERE TDA.DetAssignmentID = DA.DetAssignmentID AND T.PeriodID = @PeriodID
	   )
	   ORDER BY C.CropCode, DA.MethodCode, P.PlatformDesc;

	   DECLARE 
		  @CropCode			 NVARCHAR(10), 
		  @MethodCode			 NVARCHAR(100), 
		  @PlatformName		 NVARCHAR(100), 
		  @DetAssignmentID		 INT, 
		  @NrOfPlates			 DECIMAL(10, 2),
		  @TotalPlatesPerFolder   DECIMAL(10, 2),
		  @TestID				 INT,
		  @LastFolderSeqNr		 INT,
		  @NrOfPlateLimit		 DECIMAL(6, 2);

	   DECLARE @IDX INT = 1, @CNT INT;

	   SELECT @CNT = COUNT(ID) FROM @tbl;

	   WHILE @IDX <= @CNT BEGIN
		  SET @CropCode = NULL;
		  SET @MethodCode = NULL; 
		  SET @PlatformName = NULL;  
		  SET @DetAssignmentID = NULL; 
		  SET @NrOfPlates = NULL;

		  SET @TotalPlatesPerFolder = NULL;

		  SELECT
			 @CropCode = CropCode,
			 @MethodCode	 = MethodCode,
			 @PlatformName = PlatformName,
			 @DetAssignmentID = DetAssignmentID,
			 @NrOfPlates = NrOfPlates
		  FROM @tbl 
		  WHERE ID = @IDX;

		  SELECT 
			 @TotalPlatesPerFolder = NrOfPlates,
			 @NrOfPlateLimit = NrOfPlateLimit
		  FROM @groups
		  WHERE CropCode = @CropCode
		  AND MethodCode = @MethodCode
		  AND PlatformName = @PlatformName;

		  SET @TotalPlatesPerFolder = ISNULL(@TotalPlatesPerFolder, 0);
		  SET @NrOfPlateLimit = ISNULL(@NrOfPlateLimit, 0);
		  --PRINT '@MethodCode: ' + @MethodCode;
		  --PRINT '@TotalPlatesPerFolder: '
		  --PRINT @TotalPlatesPerFolder;
		  --PRINT '@MaxNrOfPlates: '
		  --PRINT @MaxNrOfPlates

		  --if there is no any such folder, create it
		  IF(@TotalPlatesPerFolder = 0) BEGIN
			 --Label
			 CREATE_NEW_FOLDER:
			 --get last number of existing folders in groups if there are any other created in a period
			 WITH CTE (SeqNr) AS
			 (
				SELECT 
				   CAST(TempName AS INT)
				FROM Test
				WHERE PeriodID = @PeriodID
			 )
			 SELECT @LastFolderSeqNr = ISNULL(MAX(SeqNr), 0) + 1 FROM CTE;
	   
			 INSERT Test(TempName, PeriodID, StatusCode, IsLabPriority)
			 VALUES(CAST(@LastFolderSeqNr AS VARCHAR(10)), @PeriodID, 100, @IsLabPriority);

			 SELECT @TestID = SCOPE_IDENTITY();
	   
			 --add information into temp groups
			 INSERT @groups(CropCode, MethodCode, PlatformName, NrOfPlates, NrOfPlateLimit)
			 VALUES
			 (
				@CropCode, @MethodCode, @PlatformName, @NrOfPlates, 
				CASE 
				    WHEN @PlateMaxLimit % @NrOfPlates = 0 THEN 
					   @PlateMaxLimit 
				    ELSE 
					   @PlateMaxLimit - (@PlateMaxLimit % @NrOfPlates)
				END
			 );
		  END
		  ELSE BEGIN
			 --Folder already available but check if it has already full 16 plates or not.
			 IF((@TotalPlatesPerFolder % @NrOfPlateLimit) = 0) BEGIN
			  -- need to create new folder for the group
				GOTO CREATE_NEW_FOLDER;
			 END
			 ELSE BEGIN
			 --if there is still room to store determinations, get last test id from group
				SELECT 
				    @TestID = MAX(T.TestID) 
				FROM Test T
				JOIN TestDetAssignment TDA ON TDA.TestID = T.TestID
				JOIN DeterminationAssignment DA ON DA.DetAssignmentID = TDA.DetAssignmentID
				JOIN ABSCrop C ON C.ABSCropCode = DA.ABSCropCode
				JOIN Method M ON M.MethodCode = DA.MethodCode
				JOIN CropMethod CM ON CM.ABSCropCode = DA.ABSCropCode AND CM.MethodID = M.MethodID
				JOIN [Platform] P ON P.PlatformID = CM.PlatformID
				WHERE T.PeriodID = @PeriodID
				AND C.CropCode = @CropCode
				AND DA.MethodCode = @MethodCode
				AND P.PlatformDesc = @PlatformName
				--AND ISNULL(DA.IsLabPriority, 0) = @IsLabPriority;	
				
				--update NrOfPlates in a groups
				UPDATE @groups 
				    SET NrOfPlates = NrOfPlates + @NrOfPlates
				WHERE CropCode = @CropCode
				AND MethodCode = @MethodCode
				AND PlatformName = @PlatformName;
			 END			
		  END
		  --Now map test with determination assignments
		  INSERT TestDetAssignment(TestID, DetAssignmentID)
		  VALUES(@TestID, @DetAssignmentID);

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

===================================Example================================

EXEC PR_ConfirmPlanning 4780, N'[{"DetAssignmentID":733313,"MethodCode":"PAC-01","ABSCropCode":"HP","SampleNr":1223714,"UtmostInlayDate":"11/03/2016","ExpectedReadyDate":"08/03/2016",
"PriorityCode":1,"BatchNr":0,"RepeatIndicator":false,"VarietyNr":20993,"ProcessNr":"0","ProductStatus":"5","Remarks":null,"PlannedDate":"08/01/2016","IsPlanned":false,"UsedFor":"Hyb",
"CanEditPlanning":true,"can":true,"init":false,"flag":true,"change":true,"Action":"i"}]';
*/
ALTER PROCEDURE [dbo].[PR_ConfirmPlanning]
(
    @PeriodID	 INT,
    @DataAsJson NVARCHAR(MAX)
)
AS 
BEGIN
    SET NOCOUNT ON;

    DECLARE @TransCount BIT = 0;
    DECLARE @StartDate DATE, @EndDate DATE;   
    DECLARE @PlatformID INT = (SELECT PlatformID FROM [Platform] WHERE PlatformCode = 'LS'); --light scanner   

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
	   EXEC PR_GenerateFolderDetails @PeriodID, 0; --Process for Non IsLabPriority determination assignments first
	   
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
    EXEC PR_GetFolderDetails 4792;
*/
ALTER PROCEDURE [dbo].[PR_GetFolderDetails]
(
    @PeriodID	 INT
) AS BEGIN
    SET NOCOUNT ON;

    DECLARE @tbl TABLE
    (
	   DetAssignmentID INT,
	   TestID		    INT,
	   TestName	    NVARCHAR(200),
	   CropCode	    NVARCHAR(10),
	   MethodCode	    NVARCHAR(100),
	   PlatformName    NVARCHAR(100),
	   NrOfPlates	    DECIMAL(6,2),
	   NrOfMarkers	    DECIMAL(6,2),
	   VarietyNr	    INT,
	   VarietyName	    NVARCHAR(200),
	   SampleNr	    INT,
	   IsLabPriority   INT,
	   IsParent	    BIT
    );

    INSERT @tbl(DetAssignmentID, TestID, TestName, CropCode, MethodCode, PlatformName, NrOfPlates, NrOfMarkers, VarietyNr, VarietyName, SampleNr, IsLabPriority, IsParent)
    SELECT 
	   DA.DetAssignmentID,	   
	   T.TestID,
	   T.TestName,
	   C.CropCode,
	   DA.MethodCode, 
	   P.PlatformDesc,
	   V2.NrOfPlates,
	   V3.NrOfMarkers,
	   V.VarietyNr,
	   V.Shortname,
	   DA.SampleNr,
	   ISNULL(T.IsLabPriority, 0), --labpriority for folder only
	   CASE WHEN V.HybOp = 0 AND V.[Type] = 'P' THEN 1 ELSE 0 END
    FROM Test T
    JOIN TestDetAssignment TDA ON TDA.TestID = T.TestID
    JOIN DeterminationAssignment DA ON DA.DetAssignmentID = TDA.DetAssignmentID
    JOIN ABSCrop C ON C.ABSCropCode = DA.ABSCropCode
    JOIN Method M ON M.MethodCode = DA.MethodCode
    JOIN CropMethod CM ON CM.ABSCropCode = DA.ABSCropCode AND CM.MethodID = M.MethodID
    JOIN [Platform] P ON P.PlatformID = CM.PlatformID
    JOIN Variety V ON V.VarietyNr = DA.VarietyNr
    LEFT JOIN
    (
	   SELECT 
		  MethodID,
		  NrOfPlates = NrOfSeeds/92.0
	   FROM Method
    ) V2 ON V2.MethodID = M.MethodID
    LEFT JOIN 
    (
	   SELECT 
		   DetAssignmentID,
		   NrOfMarkers = COUNT(MarkerID)
	   FROM MarkerToBeTested
	   GROUP BY DetAssignmentID
    ) V3 ON V3.DetAssignmentID = DA.DetAssignmentID
    WHERE T.PeriodID = @PeriodID;

    --create groups
    SELECT 
	   V2.TestID,
	   TestName = COALESCE(V2.TestName, 'Folder ' + CAST(ROW_NUMBER() OVER(ORDER BY V2.CropCode, V2.MethodCode) AS VARCHAR)),
	   V2.CropCode,
	   V2.MethodCode,
	   V2.PlatformName,
	   V2.NrOfPlates,
	   V2.NrOfMarkers,
	   IsLabPriority = CAST(V2.IsLabPriority AS BIT)
    FROM
    (
	   SELECT 
		  V.*,
		  T.TestName
	   FROM
	   (
		  SELECT
			 TestID,
			 CropCode,
			 MethodCode,
			 PlatformName,
			 NrOfPlates = SUM(NrOfPlates),
			 NrOfMarkers = SUM(NrOfMarkers),
			 IsLabPriority = MAX(IsLabPriority)
		  FROM @tbl
		  GROUP BY TestID, CropCode, MethodCode, PlatformName
	   ) V
	   JOIN Test T ON T.TestID = V.TestID
    ) V2
    ORDER BY V2.CropCode, V2.MethodCode;

    SELECT
	   TestID,
	   TestName = NULL,--just to manage column list in client side.
	   CropCode,
	   MethodCode,
	   PlatformName,
	   DetAssignmentID,
	   NrOfPlates,
	   NrOfMarkers,
	   VarietyName,
	   SampleNr,
	   IsParent = CAST(CASE WHEN DetAssignmentID % 2 = 0 THEN 1 ELSE 0 END AS BIT),
	   IsLabPriority = CAST(ISNULL(IsLabPriority, 0) AS BIT)
    FROM @tbl T

    SELECT 
	   MIN(T2.StatusCode) AS StatusCode
    FROM @tbl T1
    JOIN Test T2 ON T2.TestID = T1.TestID;
END
GO