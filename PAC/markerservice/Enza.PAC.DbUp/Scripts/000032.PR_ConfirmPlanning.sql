DROP PROCEDURE IF EXISTS PR_GenerateFolderDetails
GO
-- https://www.mssqltips.com/sqlservertip/4897/handling-transactions-in-nested-sql-server-stored-procedures/
CREATE PROCEDURE [dbo].[PR_GenerateFolderDetails]
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
		  ABSCropCode	NVARCHAR(10),
		  MethodCode		NVARCHAR(100),
		  PlatformName    NVARCHAR(100),
		  TraitMarkers    BIT,
		  NrOfPlates		DECIMAL(6,2)
	   );

	   WITH CTE (ABSCropCode, MethodCode, PlatformName, TraitMarkers, NrOfPlates) AS
	   (
		  SELECT 
			 DA.ABSCropCode,
			 DA.MethodCode, 
			 P.PlatformDesc,
			 0,
			 V2.NrOfPlates
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
	   INSERT @groups(ABSCropCode, MethodCode, PlatformName, TraitMarkers, NrOfPlates)
	   SELECT
		  ABSCropCode,
		  MethodCode,
		  PlatformName,    
		  TraitMarkers,
		  NrOfPlates = SUM(NrOfPlates)
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
		  @LastFolderSeqNr    INT;

	   DECLARE @IDX INT = 1, @CNT INT;

	   SELECT @CNT = COUNT(ID) FROM @tbl;

	   WHILE @IDX <= @CNT BEGIN
		  SET @TotalPlatesPerFolder = NULL;
		  SET @TestID = NULL;

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
			 @TotalPlatesPerFolder = NrOfPlates
		  FROM @groups
		  WHERE ABSCropCode = @ABSCropCode
		  AND MethodCode = @MethodCode
		  AND PlatformName = @PlatformName
		  AND TraitMarkers = @TraitMarkers;

		  --if there is no any such folder, create it
		  IF(ISNULL(@TotalPlatesPerFolder, 0) = 0) BEGIN
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
			 INSERT @groups(ABSCropCode, MethodCode, PlatformName, TraitMarkers, NrOfPlates)
			 VALUES(@ABSCropCode, @MethodCode, @PlatformName, @TraitMarkers, @NrOfPlates);
		  END
		  ELSE BEGIN
			 --PRINT 'Folder already exists';
			 --Folder already available but check if it has already full 16 plates or not.
			 IF @TotalPlatesPerFolder % 16 <> 0 BEGIN
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
			 END
			 ELSE 
			 -- need to create new folder for the group
				GOTO CREATE_NEW_FOLDER
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

DROP PROCEDURE IF EXISTS PR_ConfirmPlanning
GO

/*
Author					Date			Description
Binod Gurung			2019-Sept-04	Service to confirm planning

===================================Example================================

EXEC PR_ConfirmPlanning 4676, N'[{"DetAssignmentID":1,"Action":"U"},{"DetAssignmentID":2,"Action":"D"}]';
*/
CREATE PROCEDURE [dbo].[PR_ConfirmPlanning]
(
    @PeriodID	 INT,
    @DataAsJson NVARCHAR(MAX)
)
AS 
BEGIN
	 SET NOCOUNT ON;

	 DECLARE @StartDate DATE, @EndDate DATE;

	 SELECT 
	   @StartDate = P.StartDate,
	   @EndDate = P.EndDate
	 FROM [Period] P 
	 WHERE P.PeriodID = @PeriodID;

	 BEGIN TRY
	   BEGIN TRANSACTION;
	   
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
		  @EndDate,
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
	   LEFT JOIN DeterminationAssignment DA ON DA.DetAssignmentID = S.DetAssignmentID	   
	   WHERE S.[Action] = 'I'
	   AND S.PriorityCode NOT IN(4, 7, 8)
	   AND DA.DetAssignmentID IS NULL;

	   --Generate folder structure based on confirmed data
	   EXEC PR_GenerateFolderDetails @PeriodID;
	   
	   IF @@TRANCOUNT > 0 
		  COMMIT;
	END TRY
	BEGIN CATCH
	   IF @@TRANCOUNT > 0 
		ROLLBACK;
	   THROW;
	END CATCH
END
GO