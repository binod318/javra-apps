DROP PROCEDURE IF EXISTS PR_FitPlatesToFolder
GO
/*
Author					Date			Remarks
Krishna Gautam			2020/01/10		Created folder structcture based on lab priority and excelude already sent test while preparing folder structure

============ExAMPLE===================
--EXEC PR_FitPlatesToFolder 4792
*/
CREATE PROCEDURE [dbo].[PR_FitPlatesToFolder]
(
	@PeriodID INT
)
AS BEGIN

	SET NOCOUNT ON;
	 BEGIN TRY	   
		BEGIN TRANSACTION;

			DECLARE @StartDate DATE, @EndDate DATE, @PlateMaxLimit DECIMAL = 16.0, @loopCountGroup INT=1,@TotalTestRequired INT =0, @TotalCreatedTests INT =0,  @CropCode NVARCHAR(MAX), @MethodCode NVARCHAR(MAX), @PlatformName NVARCHAR(MAX), @TotalGroups INT, @TotalFolderRequired INT =0, @TestID INT =0, @groupLoopCount INT =0, @Offset INT=0, @NextRows INT =0;
			--declare table to insert data of determinatonAssignment
			DECLARE @tblDA TABLE(ID INT IDENTITY(1,1), CropCode NVARCHAR(10),MethodCode NVARCHAR(100),PlatformName NVARCHAR(100),DetAssignmentID INT,NrOfPlates DECIMAL(6,2),TestID INT);
			--this is group table which is required to calculate how many folders are required per method per crop per platform
			DECLARE @tblDAGroups TABLE(ID INT IDENTITY(1,1), CropCode NVARCHAR(10),MethodCode NVARCHAR(100),PlatformName NVARCHAR(100),groupReuired INT,MaxRowToSelect INT);
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
				JOIN [Platform] P ON P.PlatformID = CM.PlatformID				
				WHERE CAST(DA.PlannedDate AS DATE) BETWEEN @StartDate AND @EndDate	
				AND NOT EXISTS 
				( 
					SELECT TD.DetAssignmentID FROM  TestDetAssignment TD
					JOIN TEST T ON T.TestID = TD.TestID
					WHERE T.StatusCode >= 200 AND T.PeriodID = @PeriodID AND TD.DetAssignmentID = DA.DetAssignmentID
				)
				ORDER BY C.CropCode ASC, DA.MethodCode ASC, P.PlatformDesc ASC, ISNULL(DA.IsLabPriority, 0) DESC;


			INSERT INTO @tblDAGroups(CropCode,MethodCode,PlatformName,groupReuired, MaxRowToSelect)
				SELECT 
					C.CropCode,
					DA.MethodCode,
					P.PlatformDesc,
					groupReuired = CEILING((SUM(M.NrOfSeeds)/92.0) /16),
					MaxRecordPerPlate = CASE 
											WHEN  MAX(M.NrOfSeeds)/92.0 > 0 THEN FLOOR(16.0 / (MAX(M.NrOfSeeds)/92.0))
											ELSE 16 * (MAX(M.NrOfSeeds)/92.0)
										END
				FROM DeterminationAssignment DA
				JOIN ABSCrop C ON C.ABSCropCode = DA.ABSCropCode
				JOIN Method M ON M.MethodCode = DA.MethodCode
				JOIN CropMethod CM ON CM.MethodID = M.MethodID AND CM.ABSCropCode = DA.ABSCropCode
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

			SELECT @TotalTestRequired = SUM(groupReuired) FROM @tblDAGroups;
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
				SELECT @CropCode = CropCode, @MethodCode = MethodCode, @PlatformName = PlatformName, @TotalFolderRequired = groupReuired, @NextRows = MaxRowToSelect from @tblDAGroups Where ID = @loopCountGroup;
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

		COMMIT;
    END TRY
    BEGIN CATCH 
		  ROLLBACK;
	   THROW;
    END CATCH;

END