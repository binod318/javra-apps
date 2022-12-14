-- https://www.mssqltips.com/sqlservertip/4897/handling-transactions-in-nested-sql-server-stored-procedures/
ALTER PROCEDURE [dbo].[PR_GenerateFolderDetails]
(
    @PeriodID INT = 4780 --4785;
) AS BEGIN
    SET NOCOUNT ON;

    DECLARE @TransCount BIT = 0;

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
		  ID INT IDENTITY(1,1), 
		  ABSCropCode	NVARCHAR(10),
		  MethodCode		NVARCHAR(100),
		  PlatformName    NVARCHAR(100),
		  TraitMarkers    BIT,
		  DetAssignmentID INT,
		  NrOfPlates		DECIMAL(6,2)
	   );

	   --Make a groups based on Folder and other common attributes
	   DECLARE @groups TABLE
	   (
		  ABSCropCode	   NVARCHAR(10),
		  MethodCode	   NVARCHAR(100),
		  PlatformName    NVARCHAR(100),
		  TraitMarkers    BIT,
		  NrOfPlates	   DECIMAL(6,2),
		  MaxNrOfPlates   DECIMAL(6, 2)
	   );

	   WITH CTE (ABSCropCode, MethodCode, PlatformName, TraitMarkers, NrOfPlates, MaxNrOfPlates) AS
	   (
		  SELECT 
			 DA.ABSCropCode,
			 DA.MethodCode, 
			 P.PlatformDesc,
			 0,
			 V2.NrOfPlates,
			 MaxNrOfPlates = CASE WHEN 16 % V2.NrOfPlates = 0 THEN 16 ELSE 12 END
		  FROM Test T
		  JOIN TestDetAssignment TDA ON TDA.TestID = T.TestID
		  JOIN DeterminationAssignment DA ON DA.DetAssignmentID = TDA.DetAssignmentID
		  JOIN Method M ON M.MethodCode = DA.MethodCode
		  JOIN CropMethod CM ON CM.ABSCropCode = DA.ABSCropCode AND CM.MethodID = M.MethodID
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
	   )
	   INSERT @groups(ABSCropCode, MethodCode, PlatformName, TraitMarkers, NrOfPlates, MaxNrOfPlates)	   
	   SELECT
		  ABSCropCode,
		  MethodCode,
		  PlatformName,    
		  TraitMarkers,
		  NrOfPlates = SUM(NrOfPlates),
		  MAX(MaxNrOfPlates)
	   FROM CTE
	   GROUP BY ABSCropCode, MethodCode, PlatformName, TraitMarkers;

	   INSERT @tbl(ABSCropCode, MethodCode, PlatformName, TraitMarkers, DetAssignmentID, NrOfPlates)
	   SELECT 
		  DA.ABSCropCode,
		  DA.MethodCode,
		  P.PlatformDesc,
		  0,
		  DA.DetAssignmentID,
		  M.NrOfSeeds / 92.0
	   FROM DeterminationAssignment DA
	   JOIN Method M ON M.MethodCode = DA.MethodCode
	   JOIN CropMethod CM ON CM.MethodID = M.MethodID AND CM.ABSCropCode = DA.ABSCropCode
	   JOIN [Platform] P ON P.PlatformID = CM.PlatformID
	   WHERE CAST(DA.PlannedDate AS DATE) BETWEEN @StartDate AND @EndDate
	   AND NOT EXISTS
	   (
		  SELECT 
			 TDA.DetAssignmentID 
		  FROM TestDetAssignment TDA
		  JOIN Test T ON T.TestID = TDA.TestID
		  WHERE TDA.DetAssignmentID = DA.DetAssignmentID
		  AND T.PeriodID = @PeriodID
	   )
	   ORDER BY DA.ABSCropCode, DA.MethodCode, P.PlatformDesc;

	   DECLARE 
		  @ABSCropCode	    NVARCHAR(10), 
		  @MethodCode	    NVARCHAR(100), 
		  @PlatformName	    NVARCHAR(100), 
		  @TraitMarkers	    BIT, 
		  @DetAssignmentID    INT, 
		  @NrOfPlates	    DECIMAL(10, 2),
		  @TotalPlatesPerFolder   DECIMAL(10, 2),
		  @TestID		    INT,
		  @LastFolderSeqNr    INT,
		  @MaxNrOfPlates  DECIMAL(6, 2);

	   DECLARE @IDX INT = 1, @CNT INT;

	   SELECT @CNT = COUNT(ID) FROM @tbl;

	   WHILE @IDX <= @CNT BEGIN
		  SET @ABSCropCode = NULL;
		  SET @MethodCode = NULL; 
		  SET @PlatformName = NULL;  
		  SET @TraitMarkers = NULL;  
		  SET @DetAssignmentID = NULL; 
		  SET @NrOfPlates = NULL;

		  SET @TotalPlatesPerFolder = NULL;

		  SELECT
			 @ABSCropCode = ABSCropCode,
			 @MethodCode	 = MethodCode,
			 @PlatformName = PlatformName,
			 @TraitMarkers = TraitMarkers,
			 @DetAssignmentID = DetAssignmentID,
			 @NrOfPlates = NrOfPlates
		  FROM @tbl 
		  WHERE ID = @IDX;

		  SELECT 
			 @TotalPlatesPerFolder = NrOfPlates,
			 @MaxNrOfPlates = MaxNrOfPlates
		  FROM @groups
		  WHERE ABSCropCode = @ABSCropCode
		  AND MethodCode = @MethodCode
		  AND PlatformName = @PlatformName
		  AND TraitMarkers = @TraitMarkers;

		  SET @TotalPlatesPerFolder = ISNULL(@TotalPlatesPerFolder, 0);

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
				   CAST(RIGHT(TempName, PATINDEX('%[^0-9]%', REVERSE(TempName)) - 1) AS INT)
				FROM Test
				WHERE PeriodID = @PeriodID
			 )
			 SELECT @LastFolderSeqNr = ISNULL(MAX(SeqNr), 0) + 1 FROM CTE;
	   
			 INSERT Test(TempName, PeriodID, StatusCode)
			 VALUES('Folder ' + CAST(@LastFolderSeqNr AS VARCHAR(10)), @PeriodID, 100);

			 SELECT @TestID = SCOPE_IDENTITY();
	   
			 --add information into temp groups
			 INSERT @groups(ABSCropCode, MethodCode, PlatformName, TraitMarkers, NrOfPlates, MaxNrOfPlates)
			 VALUES(@ABSCropCode, @MethodCode, @PlatformName, @TraitMarkers, @NrOfPlates, CASE WHEN 16 % @NrOfPlates = 0 THEN 16 ELSE 12 END);
		  END
		  ELSE BEGIN
			 --Folder already available but check if it has already full 16 plates or not.
			 IF((@TotalPlatesPerFolder % @MaxNrOfPlates) = 0) BEGIN
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
				JOIN Method M ON M.MethodCode = DA.MethodCode
				JOIN CropMethod CM ON CM.ABSCropCode = DA.ABSCropCode AND CM.MethodID = M.MethodID
				JOIN [Platform] P ON P.PlatformID = CM.PlatformID
				WHERE T.PeriodID = @PeriodID
				GROUP BY DA.ABSCropCode, DA.MethodCode, P.PlatformDesc;	
				
				--update NrOfPlates in a groups
				UPDATE @groups 
				    SET NrOfPlates = NrOfPlates + @NrOfPlates
				WHERE ABSCropCode = @ABSCropCode
				AND MethodCode = @MethodCode
				AND PlatformName = @PlatformName
				AND TraitMarkers = @TraitMarkers;
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

DROP PROCEDURE IF EXISTS PR_ValidateCapacityPerFolder
GO

CREATE PROCEDURE PR_ValidateCapacityPerFolder
(
    @PeriodID	 INT,
    @DataAsJson NVARCHAR(MAX)
) AS BEGIN
    SET NOCOUNT ON;
    
    DECLARE @PlatformID INT;
    DECLARE @StartDate DATE, @EndDate DATE;
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
	   UsedFor		   NVARCHAR(10)
    );
    DECLARE @Capacity TABLE
    (
	   UsedFor	    VARCHAR(5), 
	   ABSCropCode	    NVARCHAR(10), 
	   MethodCode	    NVARCHAR(50), 
	   ReservePlates   DECIMAL(5,2)
    );
    DECLARE @Groups TABLE
    (
	   ABSCropCode	    NVARCHAR(10), 
	   MethodCode	    NVARCHAR(50), 
	   UsedFor	    VARCHAR(5), 
	   ReservePlates   DECIMAL(5,2),
	   TotalPlates	DECIMAL(5,2)
    );

    SELECT 
	   @StartDate = P.StartDate,
	   @EndDate = P.EndDate
    FROM [Period] P 
    WHERE P.PeriodID = @PeriodID;

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
	   S.DetAssignmentID, 
	   S.SampleNr, 
	   S.PriorityCode, 
	   S.MethodCode, 
	   S.ABSCropCode, 
	   S.VarietyNr, 
	   S.BatchNr, 
	   S.RepeatIndicator, 
	   S.ProcessNr, 
	   S.ProductStatus, 
	   S.BatchOutputDesc, 
	   CASE WHEN CAST(S.PlannedDate AS DATE) BETWEEN @StartDate AND @EndDate THEN S.PlannedDate ELSE @EndDate END,
	   S.UtmostInlayDate, 
	   S.ExpectedReadyDate,
	   UsedFor = CASE WHEN V.HybOp = 0 AND V.[Type] = 'P' THEN 'Par' ELSE 'Hyb' END	   
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
	   ProcessNr		   NVARCHAR(100),
	   ProductStatus	   NVARCHAR(100),
	   BatchOutputDesc	   NVARCHAR(250),
	   PlannedDate		   DATETIME,
	   UtmostInlayDate	   DATETIME,
	   ExpectedReadyDate   DATETIME,
	   [Action]	   CHAR(1)
    ) S
    JOIN Variety V ON V.VarietyNr = S.VarietyNr
    LEFT JOIN DeterminationAssignment DA ON DA.DetAssignmentID = S.DetAssignmentID	   
    WHERE S.[Action] = 'I'
    AND S.PriorityCode NOT IN(4, 7, 8)
    AND DA.DetAssignmentID IS NULL;

    IF @@ROWCOUNT > 0 BEGIN
	   --check validation
	   SELECT 
		  @PlatformID = PlatformID 
	   FROM [Platform] WHERE PlatformCode = 'LS'; --light scanner 

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
		  FROM
		  (
			 SELECT 
				ABSCropCode,
				MethodCode,
				PlannedDate
			 FROM DeterminationAssignment
			 UNION ALL
			 SELECT 
				ABSCropCode,
				MethodCode,
				PlannedDate 
			 FROM @DeterminationAssignment
		  ) DA
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
			 JOIN @DeterminationAssignment DA2 ON DA2.ABSCropCode = PCM.ABSCropCode AND DA2.MethodCode = PM.MethodCode
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
		  JOIN @DeterminationAssignment DA ON DA.ABSCropCode = CM.ABSCropCode AND DA.MethodCode = PM.MethodCode
		  WHERE CM.PlatformID = @PlatformID AND PC.PeriodID = @PeriodID
		  GROUP BY PC.SlotName, AC.ABSCropCode, PM.MethodCode, CM.UsedFor
	   ) V1
	   LEFT JOIN @Capacity V2 ON V2.ABSCropCode = V1.ABSCropCode AND V2.MethodCode = V1.MethodCode AND V2.UsedFor = V1.UsedFor;
		  
	   SELECT 
		  ABSCropCode, 
		  MethodCode, 
		  UsedFor,
		  ReservePlates,
		  TotalPlates
	   FROM @Groups
	   WHERE ReservePlates > TotalPlates;
    END	
END
GO