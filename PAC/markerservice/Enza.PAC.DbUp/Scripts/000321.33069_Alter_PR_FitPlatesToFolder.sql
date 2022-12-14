DROP PROCEDURE IF EXISTS [dbo].[PR_FitPlatesToFolder]
GO


/*
Author					Date			Remarks
Krishna Gautam			2020/01/10		Created folder structcture based on lab priority and excelude already sent test while preparing folder structure
Binod Gurung			2020-jan-23		Transcation isolation level implemented to avoid record lock
										SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
Binod Gurung			2021-dec-07		Make maximum numbers of plate in one fodler configurable #29482
Binod Gurung			2022-feb-23		Number of Folders required calculation corrected for method that has seeds more than 92 #33069

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
				groupRequired = CASE
									WHEN  MAX(M.NrOfSeeds)/92.0 > (@MaxPlatesInFolder / 2) THEN COUNT(DA.DetAssignmentID)--when only one batch is possible in a folder (7-12 plates used by batch)
									WHEN  MAX(M.NrOfSeeds)/92.0 > (@MaxPlatesInFolder / 3) THEN COUNT(DA.DetAssignmentID) / 2 --when maximum of 2 batches are possible in a folder (5-6 plates used by batch)
									ELSE CEILING((SUM(M.NrOfSeeds)/92.0) / @MaxPlatesInFolder)				
								END,
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


