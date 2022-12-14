/*
Author					Date			Description
Binod Gurung			2019-Sept-04	Service to confirm planning

===================================Example================================

EXEC PR_ConfirmPlanning 4780, N'[{"DetAssignmentID":733313,"MethodCode":"PAC-01","ABSCropCode":"HP","SampleNr":1223714,"UtmostInlayDate":"11/03/2016","ExpectedReadyDate":"08/03/2016",
"PriorityCode":1,"BatchNr":0,"RepeatIndicator":false,"VarietyNr":20993,"ProcessNr":"0","ProductStatus":"5","BatchOutputDesc":null,"PlannedDate":"08/01/2016","IsPlanned":false,"UsedFor":"Hyb",
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
		  ProcessNr, 
		  ProductStatus, 
		  BatchOutputDesc, 
		  PlannedDate, 
		  UtmostInlayDate, 
		  ExpectedReadyDate,
		  StatusCode
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
		  200   
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
		  M.NrOfSeeds/92.0
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
		  SET @MaxNrOfPlates = ISNULL(@MaxNrOfPlates, 0);
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
				AND DA.ABSCropCode = @ABSCropCode
				AND DA.MethodCode = @MethodCode
				AND P.PlatformDesc = @PlatformName
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