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
	   ORDER BY C.CropCode, DA.MethodCode, P.PlatformDesc, ISNULL(DA.IsLabPriority, 0) DESC;

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