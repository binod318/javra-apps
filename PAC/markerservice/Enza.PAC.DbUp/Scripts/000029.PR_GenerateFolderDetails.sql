DROP PROCEDURE IF EXISTS PR_GenerateFolderDetails
GO

CREATE PROCEDURE PR_GenerateFolderDetails
(
    @PeriodID INT = 4780 --4785;
) AS BEGIN
    SET NOCOUNT ON;

    BEGIN TRANSACTION;

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

    COMMIT;
END
GO

DROP PROCEDURE IF EXISTS [dbo].[PR_GetFolderDetails]
GO

-- EXEC PR_GetFolderDetails 4785
CREATE PROCEDURE [dbo].[PR_GetFolderDetails]
(
    @PeriodID	 INT
) AS BEGIN
    SET NOCOUNT ON;

    DECLARE @tbl TABLE
    (
	   DetAssignmentID INT,
	   TestID		    INT,
	   TestName	    NVARCHAR(200),
	   ABSCropCode	    NVARCHAR(10),
	   MethodCode	    NVARCHAR(100),
	   PlatformName    NVARCHAR(100),
	   NrOfPlates	    DECIMAL(6,2),
	   NrOfMarkers	    DECIMAL(6,2),
	   TraitMarkers    BIT,
	   VarietyName	    NVARCHAR(200),
	   SampleNr	    INT
    );

    INSERT @tbl(DetAssignmentID, TestID, TestName, ABSCropCode, MethodCode, PlatformName, NrOfPlates, NrOfMarkers, TraitMarkers, VarietyName, SampleNr)
    SELECT 
	   DA.DetAssignmentID,	   
	   T.TestID,
	   COALESCE(T.TestName, T.TempName),
	   DA.ABSCropCode,
	   DA.MethodCode, 
	   P.PlatformDesc,
	   V2.NrOfPlates,
	   V3.NrOfMarkers,
	   0,
	   V.Shortname,
	   DA.SampleNr
    FROM Test T
    JOIN TestDetAssignment TDA ON TDA.TestID = T.TestID
    JOIN DeterminationAssignment DA ON DA.DetAssignmentID = TDA.DetAssignmentID
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
	   TestID,
	   TestName,
	   ABSCropCode,
	   MethodCode,
	   PlatformName,
	   NrOfPlates = SUM(NrOfPlates),
	   NrOfMarkers = SUM(NrOfMarkers),
	   TraitMarkers
    FROM @tbl
    GROUP BY TestID, TestName, ABSCropCode, MethodCode, PlatformName, TraitMarkers
    ORDER BY TestName;

    SELECT
	   TestID,
	   TestName,
	   ABSCropCode,
	   MethodCode,
	   PlatformName,
	   TraitMarkers,
	   DetAssignmentID,
	   NrOfPlates,
	   NrOfMarkers,
	   VarietyName,
	   SampleNr
    FROM @tbl;
END
GO