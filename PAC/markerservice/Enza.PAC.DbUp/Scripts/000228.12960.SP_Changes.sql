/****** Object:  StoredProcedure [dbo].[PR_ValidateCapacityPerFolder]    Script Date: 4/29/2020 3:43:37 PM ******/
DROP PROCEDURE IF EXISTS [dbo].[PR_ValidateCapacityPerFolder]
GO
/****** Object:  StoredProcedure [dbo].[PR_PlanAutoDeterminationAssignments]    Script Date: 4/29/2020 3:43:37 PM ******/
DROP PROCEDURE IF EXISTS [dbo].[PR_PlanAutoDeterminationAssignments]
GO
/****** Object:  StoredProcedure [dbo].[PR_GetTestInfoForLIMS]    Script Date: 4/29/2020 3:43:37 PM ******/
DROP PROCEDURE IF EXISTS [dbo].[PR_GetTestInfoForLIMS]
GO
/****** Object:  StoredProcedure [dbo].[PR_GetNrOFPlatesAndTests]    Script Date: 4/29/2020 3:43:37 PM ******/
DROP PROCEDURE IF EXISTS [dbo].[PR_GetNrOFPlatesAndTests]
GO
/****** Object:  StoredProcedure [dbo].[PR_GetFolderDetails]    Script Date: 4/29/2020 3:43:37 PM ******/
DROP PROCEDURE IF EXISTS [dbo].[PR_GetFolderDetails]
GO
/****** Object:  StoredProcedure [dbo].[PR_GetDeterminationAssignments]    Script Date: 4/29/2020 3:43:37 PM ******/
DROP PROCEDURE IF EXISTS [dbo].[PR_GetDeterminationAssignments]
GO
/****** Object:  StoredProcedure [dbo].[PR_GetDeterminationAssigmentOverview]    Script Date: 4/29/2020 3:43:37 PM ******/
DROP PROCEDURE IF EXISTS [dbo].[PR_GetDeterminationAssigmentOverview]
GO
/****** Object:  StoredProcedure [dbo].[PR_GetDeterminationAssigmentForSetABS]    Script Date: 4/29/2020 3:43:37 PM ******/
DROP PROCEDURE IF EXISTS [dbo].[PR_GetDeterminationAssigmentForSetABS]
GO
/****** Object:  StoredProcedure [dbo].[PR_GetBatch]    Script Date: 4/29/2020 3:43:37 PM ******/
DROP PROCEDURE IF EXISTS [dbo].[PR_GetBatch]
GO
/****** Object:  StoredProcedure [dbo].[PR_GenerateFolderDetails]    Script Date: 4/29/2020 3:43:37 PM ******/
DROP PROCEDURE IF EXISTS [dbo].[PR_GenerateFolderDetails]
GO
/****** Object:  StoredProcedure [dbo].[PR_FitPlatesToFolder]    Script Date: 4/29/2020 3:43:37 PM ******/
DROP PROCEDURE IF EXISTS [dbo].[PR_FitPlatesToFolder]
GO
/****** Object:  StoredProcedure [dbo].[PR_FitPlatesToFolder]    Script Date: 4/29/2020 3:43:37 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
Author					Date			Remarks
Krishna Gautam			2020/01/10		Created folder structcture based on lab priority and excelude already sent test while preparing folder structure
Binod Gurung			2020-jan-23		Transcation isolation level implemented to avoid record lock
										SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
============ExAMPLE===================
--EXEC PR_FitPlatesToFolder 4792
*/
CREATE PROCEDURE [dbo].[PR_FitPlatesToFolder]
(
	@PeriodID INT
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
		  DECLARE @StartDate DATE, @EndDate DATE, @PlateMaxLimit DECIMAL = 16.0, @loopCountGroup INT=1,@TotalTestRequired INT =0, @TotalCreatedTests INT =0,  @CropCode NVARCHAR(MAX), @MethodCode NVARCHAR(MAX), @PlatformName NVARCHAR(MAX), @TotalGroups INT, @TotalFolderRequired INT =0, @TestID INT =0, @groupLoopCount INT =0, @Offset INT=0, @NextRows INT =0;
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
					UsedFor = CASE WHEN [Type] = 'P' THEN 'Par' WHEN HybOp = 1 AND [Type] <> 'P' THEN 'Hyb' ELSE '' END
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
				groupRequired = CEILING((SUM(M.NrOfSeeds)/92.0) /16),
				MaxRecordPerPlate = CASE 
										WHEN  MAX(M.NrOfSeeds)/92.0 > 0 THEN FLOOR(16.0 / (MAX(M.NrOfSeeds)/92.0))
										ELSE 16 * (MAX(M.NrOfSeeds)/92.0)
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
					UsedFor = CASE WHEN [Type] = 'P' THEN 'Par' WHEN HybOp = 1 AND [Type] <> 'P' THEN 'Hyb' ELSE '' END
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
/****** Object:  StoredProcedure [dbo].[PR_GenerateFolderDetails]    Script Date: 4/29/2020 3:43:37 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
Author					Date			Description
Binod Gurung			2020-jan-23		Transcation isolation level implemented to avoid record lock
-- https://www.mssqltips.com/sqlservertip/4897/handling-transactions-in-nested-sql-server-stored-procedures/
*/
CREATE PROCEDURE [dbo].[PR_GenerateFolderDetails]
(
    @PeriodID INT,
    @IsLabPriority BIT
) AS BEGIN
    SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

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
			--handle if same method is used for hybrid and parent
			JOIN
			(
				SELECT 
					VarietyNr, 
					UsedFor = CASE WHEN [Type] = 'P' THEN 'Par' WHEN HybOp = 1 AND [Type] <> 'P' THEN 'Hyb' ELSE '' END
				FROM Variety
			) V ON V.VarietyNr = DA.VarietyNr AND V.UsedFor = CM.UsedFor
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
	   --handle if same method is used for hybrid and parent
	   JOIN
	   (
			SELECT 
				VarietyNr, 
				UsedFor = CASE WHEN [Type] = 'P' THEN 'Par' WHEN HybOp = 1 AND [Type] <> 'P' THEN 'Hyb' ELSE '' END
			FROM Variety
	   ) V ON V.VarietyNr = DA.VarietyNr AND V.UsedFor = CM.UsedFor
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
				--handle if same method is used for hybrid and parent
				JOIN
				(
					SELECT 
						VarietyNr, 
						UsedFor = CASE WHEN [Type] = 'P' THEN 'Par' WHEN HybOp = 1 AND [Type] <> 'P' THEN 'Hyb' ELSE '' END
					FROM Variety
				) V ON V.VarietyNr = DA.VarietyNr AND V.UsedFor = CM.UsedFor
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
/****** Object:  StoredProcedure [dbo].[PR_GetBatch]    Script Date: 4/29/2020 3:43:37 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
Author					Date			Remarks
Krishna Gautam			2020/01/16		Created Stored procedure to fetch data
Krishna Gautam			2020/01/21		Status description is sent instead of status code.
Krishna Gautam			2020/01/21		Column Label change.
Binod Gurung			2020-jan-23		Transcation isolation level implemented to avoid record lock
Dibya Mani Suvedi		2020-jan-27		Changed VarietyName from VarietyNr to ShortName
Dibya Mani Suvedi		2020-Feb-25		Applied sorting and default sorting for ValidatedOn DESC

=================EXAMPLE=============

exec PR_GetBatch @PageNr=1,@PageSize=50,@SortBy=N'',@SortOrder=N'',@ValidatedOn=N'28/01/2020'
*/
CREATE PROCEDURE [dbo].[PR_GetBatch]
(
	@PageNr INT,
	@PageSize INT,
	@CropCode NVARCHAR(10) =NULL,
	@PlatformDesc NVARCHAR(100) = NULL,
	@MethodCode NVARCHAR(50) = NULL, 
	@Plates NVARCHAR(100) = NULL, 
	@TestName NVARCHAR(100) = NULL,
	@StatusCode NVARCHAR(100) = NULL, 
	@ExpectedWeek NVARCHAR(100) = NULL,
	@SampleNr NVARCHAR(100) = NULL, 
	@BatchNr NVARCHAR(100) = NULL, 
	@DetAssignmentID  NVARCHAR(100) = NULL,
	@VarietyNr NVARCHAR(100) = NULL,
	@QualityClass NVARCHAR(10) = NULL,
	@ValidatedOn VARCHAR(20) = NULL,
	@SortBy	 NVARCHAR(100) = NULL,
	@SortOrder VARCHAR(20) = NULL
)
AS
BEGIN
	SET NOCOUNT ON;
	SET DATEFORMAT DMY;

	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

	IF(ISNULL(@SortBy, '') = '') BEGIN
	   SET @SortBy = 'ValidatedOn';
	END
	IF(ISNULL(@SortOrder, '') = '') BEGIN
	   SET @SortOrder = 'DESC';
	END

	DECLARE @Offset INT;
	DECLARE @Columns TABLE(ColumnID NVARCHAR(100), ColumnName NVARCHAR(100),IsVisible BIT, [Order] INT);
	DECLARE @SQL NVARCHAR(MAX), @Parameters NVARCHAR(MAX);

	SET @OffSet = @PageSize * (@pageNr -1);
	
	SET @SQL = N'
	DECLARE @Status TABLE(StatusCode INT, StatusName NVARCHAR(100));
	
	INSERT INTO @Status(StatusCode, StatusName)
	SELECT StatusCode,StatusName FROM [Status] WHERE StatusTable = ''DeterminationAssignment'';

	WITH CTE AS 
	(
		SELECT * FROM 
		(
			SELECT T.TestID, 
				C.CropCode,
				PlatformDesc = P.PlatformCode,
				M.MethodCode, 
				Plates = CAST(CAST((M.NrOfSeeds/92.0) as decimal(4,2)) AS NVARCHAR(10)), 
				T.TestName ,
				StatusCode = S.StatusName,
				[ExpectedWeek] = CONCAT(FORMAT(DATEPART(WEEK, DA.ExpectedReadyDate), ''00''), '' ('', FORMAT(DA.ExpectedReadyDate, ''yyyy''), '')''),
				SampleNr = CAST(DA.SampleNr AS NVARCHAR(50)), 
				BatchNr = CAST(DA.BatchNr AS NVARCHAR(50)), 
				DetAssignmentID = CAST(DA.DetAssignmentID AS NVARCHAR(50)) ,
				VarietyNr = V.ShortName,
				DA.QualityClass,
				ValidatedOn = FORMAT(ValidatedOn, ''dd/MM/yyyy'')
			FROM  Test T 
			JOIN TestDetAssignment TDA ON TDA.TestID = T.TestID
			JOIN DeterminationAssignment DA ON DA.DetAssignmentID = TDA.DetAssignmentID
			JOIN @Status S ON S.StatusCode = DA.StatusCode
			JOIN Method M ON M.MethodCode = DA.MethodCode
			JOIN CropMethod CM ON CM.MethodID = M.MethodID AND CM.ABSCropCode = DA.ABSCropCode
			JOIN
			(
				SELECT 
					VarietyNr, 
					Shortname,
					UsedFor = CASE WHEN [Type] = ''P'' THEN ''Par'' WHEN HybOp = 1 AND [Type] <> ''P'' THEN ''Hyb'' ELSE '''' END
				FROM Variety
			) V ON V.VarietyNr = DA.VarietyNr AND V.UsedFor = CM.UsedFor
			JOIN ABSCrop C ON C.ABSCropCode = CM.ABSCropCode
			JOIN [Platform] P ON P.PlatformID = CM.PlatformID
		) T
		WHERE 
		(ISNULL(@CropCode,'''') = '''' OR CropCode like ''%''+ @CropCode +''%'') AND
		(ISNULL(@PlatformDesc,'''') = '''' OR PlatformDesc like ''%''+ @PlatformDesc +''%'') AND
		(ISNULL(@MethodCode,'''') = '''' OR MethodCode like ''%''+ @MethodCode +''%'') AND
		(ISNULL(@Plates,'''') = '''' OR Plates like ''%''+ @Plates +''%'') AND
		(ISNULL(@TestName,'''') = '''' OR TestName like ''%''+ @TestName +''%'') AND
		(ISNULL(@StatusCode,'''') = '''' OR StatusCode like ''%''+ @StatusCode +''%'') AND
		(ISNULL(@ExpectedWeek,'''') = '''' OR ExpectedWeek like ''%''+ @ExpectedWeek +''%'') AND
		(ISNULL(@SampleNr,'''') = '''' OR SampleNr like ''%''+ @SampleNr +''%'') AND
		(ISNULL(@BatchNr,'''') = '''' OR BatchNr like ''%''+ @BatchNr +''%'') AND
		(ISNULL(@DetAssignmentID,'''') = '''' OR DetAssignmentID like ''%''+ @DetAssignmentID +''%'') AND
		(ISNULL(@VarietyNr,'''') = '''' OR VarietyNr like ''%''+ @VarietyNr +''%'') AND
		(ISNULL(@QualityClass,'''') = '''' OR QualityClass like ''%''+ @QualityClass +''%'') AND
		(ISNULL(@ValidatedOn,'''') = '''' OR ValidatedOn like ''%''+ @ValidatedOn +''%'')
	), Count_CTE AS (SELECT COUNT(TestID) AS [TotalRows] FROM CTE)
	SELECT 	
		CropCode,
		PlatformDesc,
		MethodCode, 
		Plates , 
		TestName ,
		StatusCode, 
		ExpectedWeek,
		SampleNr, 
		BatchNr, 
		DetAssignmentID ,
		VarietyNr,
		QualityClass,
		ValidatedOn,
		TotalRows
    FROM CTE,Count_CTE 
    ORDER BY ' + QUOTENAME(@SortBy) + ' ' + @SortOrder + N'   
    OFFSET @Offset ROWS
    FETCH NEXT @PageSize ROWS ONLY';

    SET @Parameters = N'@PageNr INT, @PageSize INT, @CropCode NVARCHAR(10), @PlatformDesc NVARCHAR(100), @MethodCode NVARCHAR(50), 
	@Plates NVARCHAR(100), @TestName NVARCHAR(100), @StatusCode NVARCHAR(100), @ExpectedWeek NVARCHAR(100), @SampleNr NVARCHAR(100), 
	@BatchNr NVARCHAR(100), @DetAssignmentID NVARCHAR(100), @VarietyNr NVARCHAR(100), @QualityClass NVARCHAR(10), @ValidatedOn NVARCHAR(20), @OffSet INT';

    EXEC sp_executesql @SQL, @Parameters, @PageNr, @PageSize, @CropCode, @PlatformDesc, @MethodCode, @Plates, @TestName,
	   @StatusCode, @ExpectedWeek, @SampleNr, @BatchNr, @DetAssignmentID, @VarietyNr, @QualityClass, @ValidatedOn, @OffSet;

	INSERT INTO @Columns(ColumnID,ColumnName,IsVisible,[Order])
	VALUES
	('CropCode','Crop',1, 1),
	('PlatformDesc','Platform',1,2),
	('MethodCode','Method',1,3),
	('Plates','#Plates',1,4),
	('TestName','Folder',1,5),
	('StatusCode','Status',1,6),	
	('ExpectedWeek','Exp. Wk',1,7),
	('ValidatedOn','Approved Date',1,8),
	('SampleNr','SampleNr',1,9),
	('BatchNr','BatchNr',1,10),
	('DetAssignmentID','Det. Assignment',1,11),
	('VarietyNr','Var. Name',1,12),
	('QualityClass','Qlty Class',1,13)

	SELECT * FROM @Columns order by [Order];
END
GO
/****** Object:  StoredProcedure [dbo].[PR_GetDeterminationAssigmentForSetABS]    Script Date: 4/29/2020 3:43:37 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
Author					Date			Remarks
Binod Gurung			2020-jan-23		Transcation isolation level implemented to avoid record lock

=================EXAMPLE=============

-- PR_GetDeterminationAssigmentForSetABS 4779
*/

CREATE PROCEDURE [dbo].[PR_GetDeterminationAssigmentForSetABS]
(
    @PeriodID INT
) 
AS 
BEGIN
    SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

	DECLARE @StartDate DATE, @EndDate DATE;
    DECLARE @PlatformID INT = (SELECT PlatformID FROM [Platform] WHERE PlatformCode = 'LS'); --light scanner   

    SELECT
	   @StartDate = StartDate,
	   @EndDate = EndDate
    FROM [Period]
    WHERE PeriodID = @PeriodID;

	SELECT 
		DetAssignmentID,
		2
	FROM DeterminationAssignment DA
	JOIN
    (
	   SELECT
		  AC.ABSCropCode,
		  PM.MethodCode,
		  CM.UsedFor
	   FROM CropMethod CM
	   JOIN ABSCrop AC ON AC.ABSCropCode = CM.ABSCropCode
	   JOIN Method PM ON PM.MethodID = CM.MethodID
	   WHERE CM.PlatformID = @PlatformID
    ) V1 ON V1.ABSCropCode = DA.ABSCropCode AND V1.MethodCode = DA.MethodCode
	--handle if same method is used for hybrid and parent
	JOIN
	(
		SELECT 
			VarietyNr, 
			UsedFor = CASE WHEN [Type] = 'P' THEN 'Par' WHEN HybOp = 1 AND [Type] <> 'P' THEN 'Hyb' ELSE '' END
		FROM Variety
	) V ON V.VarietyNr = DA.VarietyNr AND V.UsedFor = V1.UsedFor
	WHERE CAST(DA.PlannedDate AS DATE) BETWEEN @StartDate AND @EndDate AND DA.StatusCode IN (200,300)

END
GO
/****** Object:  StoredProcedure [dbo].[PR_GetDeterminationAssigmentOverview]    Script Date: 4/29/2020 3:43:37 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
Author					Date			Remarks
Binod Gurung			-				-
Krishna Gautam			2020-01-21		Where clause added.
Binod Gurung			2020-jan-23		Transcation isolation level implemented to avoid record lock
Krishna Gautam			2020-feb-28		(#11099) Pagination, sorting, filtering implemented and changed on logic to show all result without specific period (week).

=================EXAMPLE=============


	EXEC PR_GetDeterminationAssigmentOverview @PageNr = 1,
				@PageSize = 10,
				@SortBy = NULL,
				@SortOrder	= NULL,
				@DetAssignmentID = NULL,
				@SampleNr = NULL,
				@BatchNr = '19',
				@Shortname	 = NULL,
				@Status	 = NULL,
				@ExpectedReadyDate= NULL,
				@Folder		 = NULL,
				@QualityClass = NULL
*/
CREATE PROCEDURE [dbo].[PR_GetDeterminationAssigmentOverview]
(
    --@PeriodID INT
	@PageNr				INT,
	@PageSize			INT,
	@SortBy				NVARCHAR(100) = NULL,
	@SortOrder			NVARCHAR(20) = NULL,
	@DetAssignmentID	NVARCHAR(100) = NULL,
	@SampleNr			NVARCHAR(100) = NULL,
	@BatchNr			NVARCHAR(100) = NULL,
	@Shortname			NVARCHAR(100) = NULL,
	@Status				NVARCHAR(100) = NULL,
	@ExpectedReadyDate	NVARCHAR(100) = NULL,
	@Folder				NVARCHAR(100) = NULL,
	@QualityClass		NVARCHAR(100) = NULL,
	@Plates		     NVARCHAR(MAX) = NULL
) AS BEGIN
    SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
	
	DECLARE @TblColumn TABLE(ColumnLabel VARCHAR(100), ColumnID VARCHAR(100),[Order] INT,IsVisible BIT)
	DECLARE @PlatformID INT = (SELECT PlatformID FROM [Platform] WHERE PlatformCode = 'LS'); --light scanner ;
	DECLARE @Query NVARCHAR(MAX), @Offset INT,@Parameters NVARCHAR(MAX);;

	SET @OffSet = @PageSize * (@pageNr -1);

	INSERT INTO @TblColumn(ColumnLabel,ColumnID,[Order],IsVisible)
	VALUES
	('Det. Ass#','DetAssignmentID',1,1),
	('Sample#','SampleNr',2,1),
	('Batch#','BatchNr',3,1),
	('Article','Shortname',4,1),
	('Status','Status',5,1),
	('Exp Ready','ExpectedReadyDate',6,1),
	('Folder#','Folder',7,1),
	('Quality Class','QualityClass',8,1),
	('Plates','Plates',9,1);

    IF(ISNULL(@SortBy,'') ='')
	BEGIN
		SET @SortBy = 'ExpectedReadyDate'
		SET @SortOrder = 'DESC'
	END
	IF(ISNULL(@SortOrder,'') = '')
	BEGIN
		SET @SortOrder = 'DESC'
	END
	
	SET @Query = N'
	;WITH CTE AS
	(
		SELECT 
			*
		FROM
		(

			SELECT 
			   DA.DetAssignmentID,
			   DA.SampleNr,   
			   DA.BatchNr,
			   V.Shortname,
			   [Status] = COALESCE(S.StatusName, CAST(DA.StatusCode AS NVARCHAR(10))),
			   ExpectedReadyDate = FORMAT(DA.ExpectedReadyDate, ''dd/MM/yyyy''), 
			   V2.Folder,
			   DA.QualityClass,
			   Plates = STUFF 
			   (
				   (
					   SELECT DISTINCT '', '' + PlateName 
					   FROM Plate P 
					   JOIN Well W ON W.PlateID = P.PlateID 
					   WHERE P.TestID = T.TestID AND W.DetAssignmentID = DA.DetAssignmentID 
					   FOR  XML PATH('''')
				   ), 1, 2, ''''
			   )
			FROM DeterminationAssignment DA
			JOIN
			(
			   SELECT
				  AC.ABSCropCode,
				  PM.MethodCode,
				  CM.UsedFor
			   FROM CropMethod CM
			   JOIN ABSCrop AC ON AC.ABSCropCode = CM.ABSCropCode
			   JOIN Method PM ON PM.MethodID = CM.MethodID
			   WHERE CM.PlatformID = @PlatformID
			) V1 ON V1.ABSCropCode = DA.ABSCropCode AND V1.MethodCode = DA.MethodCode
			JOIN
			(
				SELECT 
					VarietyNr, 
					Shortname,
					UsedFor = CASE WHEN [Type] = ''P'' THEN ''Par'' WHEN HybOp = 1 AND [Type] <> ''P'' THEN ''Hyb'' ELSE '''' END
				FROM Variety
			) V ON V.VarietyNr = DA.VarietyNr AND V.UsedFor = V1.UsedFor
			JOIN
			(
				SELECT W.DetAssignmentID, MAX(T.TestName) AS Folder 
				FROM Test T
				JOIN Plate P ON P.TestID = T.TestID
				JOIN Well W ON W.PlateID = P.PlateID
				--WHERE T.StatusCode >= 500
				GROUP BY W.DetAssignmentID
			) V2 On V2.DetAssignmentID = DA.DetAssignmentID
			JOIN TestDetAssignment TDA ON TDA.DetAssignmentID = DA.DetAssignmentID
			JOIN Test T ON T.TestID = TDA.TestID
			JOIN [Status] S ON S.StatusCode = DA.StatusCode AND S.StatusTable = ''DeterminationAssignment''
			--WHERE DA.StatusCode IN (600,650)
		) T
		WHERE			
			(ISNULL(@DetAssignmentID,'''') = '''' OR DetAssignmentID like ''%''+ @DetAssignmentID +''%'') AND
			(ISNULL(@SampleNr,'''') = '''' OR SampleNr like ''%''+ @SampleNr +''%'') AND
			(ISNULL(@BatchNr,'''') = '''' OR BatchNr like ''%''+ @BatchNr +''%'') AND
			(ISNULL(@Shortname,'''') = '''' OR Shortname like ''%''+ @Shortname +''%'') AND
			(ISNULL(@Status,'''') = '''' OR Status like ''%''+ @Status +''%'') AND
			(ISNULL(@ExpectedReadyDate,'''') = '''' OR ExpectedReadyDate like ''%''+ @ExpectedReadyDate +''%'') AND
			(ISNULL(@Folder,'''') = '''' OR Folder like ''%''+ @Folder +''%'') AND
			(ISNULL(@QualityClass,'''') = '''' OR QualityClass like ''%''+ @QualityClass +''%'')
	), Count_CTE AS (SELECT COUNT(DetAssignmentID) AS [TotalRows] FROM CTE)
	SELECT 
		DetAssignmentID,
		SampleNr,
		BatchNr,
		Shortname,
		[Status],
		ExpectedReadyDate,
		Folder,
		QualityClass,
		Plates,
		TotalRows
	FROM CTE,Count_CTE 
	ORDER BY ' + QUOTENAME(@SortBy) + ' ' + @SortOrder + N'   
	OFFSET @Offset ROWS
    FETCH NEXT @PageSize ROWS ONLY'

	SET @Parameters = N'@PlatformID INT, @PageNr INT, @PageSize INT, @DetAssignmentID NVARCHAR(100), @SampleNr NVARCHAR(100), @BatchNr NVARCHAR(100), 
	@Shortname NVARCHAR(100), @Status NVARCHAR(100), @ExpectedReadyDate NVARCHAR(100), @Folder NVARCHAR(100), @QualityClass NVARCHAR(100), @OffSet INT';

	SELECT * FROM @TblColumn ORDER BY [Order]

	 EXEC sp_executesql @Query, @Parameters,@PlatformID, @PageNr, @PageSize, @DetAssignmentID, @SampleNr, @BatchNr, @Shortname, @Status,
	   @ExpectedReadyDate, @Folder, @QualityClass, @OffSet;

END
GO
/****** Object:  StoredProcedure [dbo].[PR_GetDeterminationAssignments]    Script Date: 4/29/2020 3:43:37 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
Author					Date			Description
Binod Gurung			2020-jan-23		Transcation isolation level implemented to avoid record lock
Dibya			    2020-Feb-19		Performance improvements on unplanned data
Dibya			    2020-Feb-25		Included NrOfPlates on response to calculate Plates on check changed event on client side.

===================================Example================================

    DECLARE @UnPlannedDataAsJson NVARCHAR(MAX) = N'[{"DetAssignmentID":1,"MethodCode":"PAC-01","ABSCropCode": "HP","VarietyNr":"21046"}]';
    EXEC PR_GetDeterminationAssignments 4780, @UnPlannedDataAsJson
*/

CREATE PROCEDURE [dbo].[PR_GetDeterminationAssignments]
(
    @PeriodID	INT,
    @DeterminationAssignment TVP_DeterminationAssignment READONLY
) 
AS 
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    DECLARE @StartDate DATE, @EndDate DATE;
    DECLARE @SQL NVARCHAR(MAX);
    DECLARE @PlatformID INT = (SELECT PlatformID FROM [Platform] WHERE PlatformCode = 'LS'); --light scanner   
    DECLARE @MaxSeqNr INT = 0;
    
    DECLARE @Groups TABLE
    (
	   SlotName	    NVARCHAR(100),
	   ABSCropCode	    NVARCHAR(20), 
	   MethodCode	    NVARCHAR(50), 
	   UsedFor	    NVARCHAR(10),
	   TotalPlates	    INT,
	   NrOfResPlates	    DECIMAL(5,2)
    ); 
    DECLARE @Capacity TABLE
    (
	   ABSCropCode	    NVARCHAR(20), 
	   MethodCode	    NVARCHAR(50), 
	   ResPlates   DECIMAL(5,2)
    );  
    --Prapare output of details records
    DECLARE @Result TABLE
    (
	   SeqNr			  INT,
	   DetAssignmentID    INT,
	   SampleNr		  INT,
	   PriorityCode	  INT,
	   MethodCode		  NVARCHAR(25),
	   ABSCropCode		  NVARCHAR(10),
	   Article		  NVARCHAR(100),
	   VarietyNr		  INT,
	   BatchNr		  INT,
	   RepeatIndicator    BIT,
	   Process		  NVARCHAR(100),
	   ProductStatus	  NVARCHAR(100),
	   Remarks			  NVARCHAR(MAX),
	   PlannedDate		  DATETIME,
	   UtmostInlayDate    DATETIME,
	   ExpectedReadyDate  DATETIME,
	   IsPlanned		  BIT,
	   UsedFor			NVARCHAR(10),
	   CanEdit			BIT,
	   IsLabPriority	BIT,
	   IsPacComplete	BIT	
    );

    SELECT
	   @StartDate = StartDate,
	   @EndDate = EndDate
    FROM [Period]
    WHERE PeriodID = @PeriodID;

    --Prepare capacities of planned records
    INSERT @Capacity(ABSCropCode, MethodCode, ResPlates)
    SELECT
	   T1.ABSCropCode,
	   T1.MethodCode,
	   NrOfPlates = SUM(T1.NrOfPlates)
    FROM
    (
		SELECT 
			V1.ABSCropCode,
			DA.MethodCode,
			NrOfPlates = CAST((V1.NrOfSeeds / 92.0) AS DECIMAL(5,2))
		FROM DeterminationAssignment DA
		JOIN
		(
			SELECT 
				PM.MethodCode,
				AC.ABSCropCode,
				PM.NrOfSeeds,
				pcm.UsedFor
			FROM Method PM
			JOIN CropMethod PCM ON PCM.MethodID = PM.MethodID
			JOIN ABSCrop AC ON AC.ABSCropCode = PCM.ABSCropCode
			WHERE PCM.PlatformID = @PlatformID
			AND PM.StatusCode = 100
		) V1 ON V1.ABSCropCode = DA.ABSCropCode AND V1.MethodCode = DA.MethodCode
		--handle if same method is used for hybrid and parent
		JOIN
		(
			SELECT 
				VarietyNr, 
				UsedFor = CASE WHEN [Type] = 'P' THEN 'Par' WHEN HybOp = 1 AND [Type] <> 'P' THEN 'Hyb' ELSE '' END
			FROM Variety
		) V ON V.VarietyNr = DA.VarietyNr AND V.UsedFor = V1.UsedFor
	   WHERE CAST(DA.PlannedDate AS DATE) BETWEEN @StartDate AND @EndDate
    ) T1 
    GROUP BY T1.ABSCropCode, T1.MethodCode;
    
    --Prepare Grops of planned records groups
    INSERT @Groups(SlotName, ABSCropCode, MethodCode, UsedFor, TotalPlates, NrOfResPlates)
    SELECT
	   V1.SlotName,
	   V1.ABSCropCode,
	   V1.MethodCode,
	   V1.UsedFor,
	   V1.TotalPlates,
	   ResPlates = ISNULL(V2.ResPlates, 0)
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
	   WHERE CM.PlatformID = @PlatformID AND PC.PeriodID = @PeriodID
	   GROUP BY PC.SlotName, AC.ABSCropCode, PM.MethodCode, CM.UsedFor
    ) V1
    JOIN @Capacity V2 ON V2.ABSCropCode = V1.ABSCropCode AND V2.MethodCode = V1.MethodCode;

    --Get details of planned determinations    
    INSERT @Result
    (
	   SeqNr,
	   DetAssignmentID,	 
	   MethodCode,		
	   ABSCropCode,
	   SampleNr,
	   UtmostInlayDate, 
	   ExpectedReadyDate,
	   PriorityCode,	
	   BatchNr,	
	   RepeatIndicator, 
	   Article,
	   VarietyNr,
	   Process,		
	   ProductStatus,	
	   Remarks, 
	   PlannedDate,	   
	   IsPlanned,		
	   UsedFor,
	   CanEdit,
	   IsLabPriority,
	   IsPacComplete
    )
    SELECT 
	   DA.SeqNr,
	   DA.DetAssignmentID,
	   DA.MethodCode,
	   DA.ABSCropCode,
	   DA.SampleNr,
	   DA.UtmostInlayDate,
	   DA.ExpectedReadyDate, 
	   DA.PriorityCode,	   
	   DA.BatchNr,
	   DA.RepeatIndicator,
	   V.Shortname,
	   V.VarietyNr,
	   DA.Process,
	   DA.ProductStatus,
	   DA.Remarks,
	   DA.PlannedDate,
	   IsPlanned = 1,
	   UsedFor = V.UsedFor,
	   --UsedFor = V1.UsedFor,
	   CASE WHEN DA.StatusCode < 200 THEN 1 ELSE 0 END,
	   ISNULL(DA.IsLabPriority, 0),
	   1 --Pac complete profile true for already planned DA
    FROM DeterminationAssignment DA
    JOIN
    (
	   SELECT
		  AC.ABSCropCode,
		  PM.MethodCode,
		  CM.UsedFor
	   FROM CropMethod CM
	   JOIN ABSCrop AC ON AC.ABSCropCode = CM.ABSCropCode
	   JOIN Method PM ON PM.MethodID = CM.MethodID
	   WHERE CM.PlatformID = @PlatformID
    ) V1 ON V1.ABSCropCode = DA.ABSCropCode AND V1.MethodCode = DA.MethodCode
	JOIN
	(
		SELECT 
			VarietyNr, 
			Shortname,
			UsedFor = CASE WHEN [Type] = 'P' THEN 'Par' WHEN HybOp = 1 AND [Type] <> 'P' THEN 'Hyb' ELSE '' END
		FROM Variety
	) V ON V.VarietyNr = DA.VarietyNr AND V.UsedFor = V1.UsedFor
    WHERE CAST(DA.PlannedDate AS DATE) BETWEEN @StartDate AND @EndDate

    --Process unplannded records    
    IF EXISTS (SELECT DetAssignmentID FROM @DeterminationAssignment) BEGIN
	   SELECT 
		  @MaxSeqNr = MAX(SeqNr) 
	   FROM @Result;
	   
	   --no need to process @Capacity, res plates is always 0 for unplanned records
	   --Prepare Grops of planned records groups
	   INSERT @Groups(SlotName, ABSCropCode, MethodCode, UsedFor, TotalPlates, NrOfResPlates)
	   SELECT
		  V1.SlotName,
		  V1.ABSCropCode,
		  V1.MethodCode,
		  V1.UsedFor,
		  V1.TotalPlates,
		  ResPlates = 0
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
		  WHERE CM.PlatformID = @PlatformID AND PC.PeriodID = @PeriodID
		  GROUP BY PC.SlotName, AC.ABSCropCode, PM.MethodCode, CM.UsedFor
	   ) V1
	   WHERE NOT EXISTS
	   (
		  SELECT ABSCropCode, MethodCode
		  FROM @Groups
		  WHERE ABSCropCode = V1.ABSCropCode AND MethodCode = V1.MethodCode
	   );

	   --Get details of unplanned determinations    
	   INSERT @Result
	   (
		  SeqNr,
		  DetAssignmentID,	 
		  MethodCode,		
		  ABSCropCode,
		  SampleNr,
		  UtmostInlayDate, 
		  ExpectedReadyDate,
		  PriorityCode,	
		  BatchNr,	
		  RepeatIndicator, 
		  Article,
		  VarietyNr,
		  Process,		
		  ProductStatus,	
		  Remarks, 
		  PlannedDate,	   
		  IsPlanned,		
		  UsedFor,
		  CanEdit,
		  IsLabPriority,
		  IsPacComplete
	   )
	   SELECT 
		  SeqNr = ROW_NUMBER() OVER(ORDER BY DetAssignmentID) + @MaxSeqNr,
		  DA.DetAssignmentID,
		  DA.MethodCode,
		  DA.ABSCropCode,
		  DA.SampleNr,
		  DA.UtmostInlayDate,
		  DA.ExpectedReadyDate, 
		  DA.PriorityCode,	   
		  DA.BatchNr,
		  DA.RepeatIndicator,
		  V.Shortname,
		  V.VarietyNr,
		  DA.Process,
		  DA.ProductStatus,
		  DA.Remarks,
		  DA.PlannedDate,
		  IsPlanned = 0,
		  UsedFor = V.UsedFor,
		  --UsedFor = V1.UsedFor,
		  CASE WHEN DA.PriorityCode IN(4, 7, 8) THEN 0 ELSE 1 END,
		  0,
		  dbo.FN_IsPacProfileComplete (DA.VarietyNr, @PlatformID, AC.CropCode) --#8068 Check PAC profile complete 
	   FROM @DeterminationAssignment DA
	   JOIN
	   (
		  SELECT
			 AC.ABSCropCode,
			 PM.MethodCode,
			 CM.UsedFor
		  FROM CropMethod CM
		  JOIN ABSCrop AC ON AC.ABSCropCode = CM.ABSCropCode
		  JOIN Method PM ON PM.MethodID = CM.MethodID
		  WHERE CM.PlatformID = @PlatformID
	   ) V1 ON V1.ABSCropCode = DA.ABSCropCode AND V1.MethodCode = DA.MethodCode
	   JOIN ABSCrop AC ON AC.ABSCropCode = DA.ABSCropCode
	   JOIN
	   (
			SELECT 
				VarietyNr, 
				Shortname,
				UsedFor = CASE WHEN [Type] = 'P' THEN 'Par' WHEN HybOp = 1 AND [Type] <> 'P' THEN 'Hyb' ELSE '' END
			FROM Variety
	   ) V ON V.VarietyNr = DA.VarietyNr AND V.UsedFor = V1.UsedFor
	   WHERE NOT EXISTS
	   (
		  SELECT DetAssignmentID 
		  FROM DeterminationAssignment
		  WHERE DetAssignmentID = DA.DetAssignmentID
	   );	   
    END  

    --return groups
    SELECT 
	   * 
    FROM @Groups G
    JOIN
    (
	   SELECT 
		  R.ABSCropCode,
		  R.MethodCode,
		  R.UsedFor,
		  TotalRows = COUNT( R.DetAssignmentID)
	   FROM @Result R
	   GROUP BY R.ABSCropCode, R.MethodCode, R.UsedFor
    ) V ON V.ABSCropCode = G.ABSCropCode AND V.MethodCode = G.MethodCode AND V.UsedFor = G.UsedFor
    WHERE V.TotalRows > 0;

    --return details
    SELECT 
	   DetAssignmentID,	 
	   T.MethodCode,		
	   ABSCropCode,
	   SampleNr,
	   UtmostInlayDate = FORMAT(UtmostInlayDate, 'dd/MM/yyyy'), 
	   ExpectedReadyDate = FORMAT(ExpectedReadyDate, 'dd/MM/yyyy'),
	   PriorityCode,	
	   BatchNr,	
	   RepeatIndicator, 
	   Article,
	   Process,		
	   ProductStatus,	
	   Remarks, 
	   PlannedDate = FORMAT(PlannedDate, 'dd/MM/yyyy'),
	   IsPlanned,		
	   UsedFor,
	   CanEditPlanning = CanEdit,
	   IsLabPriority,
	   IsPacComplete,
	   VarietyNr,
	   NrOfPlates = CAST((M.NrOfSeeds / 92.0) AS DECIMAL(5,2))
    FROM @Result T
    JOIN Method M ON M.MethodCode = T.MethodCode
    ORDER BY T.ABSCropCode, T.MethodCode, T.PriorityCode, ExpectedReadyDate;
END
GO
/****** Object:  StoredProcedure [dbo].[PR_GetFolderDetails]    Script Date: 4/29/2020 3:43:37 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


/*
Author					Date			Description
Binod Gurung			2020-jan-23		Transcation isolation level implemented to avoid record lock	
Krishna Gautam			2020/02/19		Calculation of nr of marker is done per plate on group level.
Dibya					2020/02/20		Made #plates as absolute number.
Krishna Gautam			2020/02/27		Added plates information on batches.
Binod Gurung			2020/03/10		#11471 Sorting added on Variety name 

===================================Example================================

    EXEC PR_GetFolderDetails 4792;
	
*/
CREATE PROCEDURE [dbo].[PR_GetFolderDetails]
(
    @PeriodID	 INT
) 
AS 
BEGIN
    SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    DECLARE @tbl TABLE
    (
		ID INT IDENTITY(1,1),
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
	   IsParent	    BIT,
	   TraitMarkers BIT,
	   Markers VARCHAR(MAX),
	   TempPlateID INT,
	   PlateNames NVARCHAR(MAX)
    );
	
    INSERT @tbl(DetAssignmentID, TestID, TestName, CropCode, MethodCode, PlatformName, NrOfPlates, NrOfMarkers, VarietyNr, VarietyName, SampleNr, IsLabPriority, IsParent, TraitMarkers,Markers,TempPlateID,PlateNames)
    SELECT 
	DetAssignmentID,
	TestID,
	TestName,
	CropCode,
	MethodCode, 
	PlatformDesc,
	NrOfPlates,
	NrOfMarkers,
	VarietyNr,
	Shortname,
	SampleNr,
	IsLabPriority,
	Prio,
	TraitMarkers,
	Markers = ISNULL(Markers,'') + ',' + ISNULL(Markers1,''),  --COALESCE( Markers1 +',', Markers),
	TempPlateID,
	Plates
	FROM 
	(
	
	SELECT 
	   DA.DetAssignmentID,	   
	   T.TestID,
	   T.TestName,
	   C.CropCode,
	   DA.MethodCode, 
	   P.PlatformDesc,
	   V2.NrOfPlates,
	   NrOfMarkers =  CASE WHEN NrOfPlates >=1 THEN V3.NrOfMarkers * NrOfPlates ELSE NrOfMarkers END,
	   V.VarietyNr,
	   V.Shortname,
	   DA.SampleNr,
	   IsLabPriority = ISNULL(DA.IsLabPriority, 0),
	   Prio = CASE WHEN V.[Type] = 'P' THEN 1 ELSE 0 END,
	   TraitMarkers = CAST (CASE WHEN ISNULL(V4.TraitMarker,0) = 0 THEN 0 ELSE 1 END As BIT),
	   Markers = STUFF((SELECT DISTINCT ',', + CAST(MTT.MarkerID AS NVARCHAR(50) )
							FROM
							MarkerToBeTested MTT
							WHERE MTT.DetAssignmentID =  DA.DetAssignmentID
							FOR XML PATH('')
						),1,1,''),
		Markers1 = STUFF((SELECT DISTINCT ',', + CAST(MTT.MarkerID AS NVARCHAR(50))
							FROM
							(
								SELECT DA.DetAssignmentID, MarkerID FROM MarkerPerVariety MPV
								JOIN Variety V ON V.VarietyNr = MPV.VarietyNr
								JOIN DeterminationAssignment DA ON DA.VarietyNr = V.VarietyNr
								WHERE MPV.StatusCode = 100

							)MTT
							WHERE MTT.DetAssignmentID =  DA.DetAssignmentID
							FOR XML PATH('')
						),1,1,''),
		TempPlateID = CEILING(SUM(ISNULL(NrOfPlates,0)) OVER (Partition by T.Testid Order by C.CropCode ASC, DA.MethodCode ASC, P.PlatformDesc ASC, ISNULL(DA.IsLabPriority, 0) DESC, CASE WHEN V.[Type] = 'P' THEN 1 ELSE 0 END DESC, DA.DetAssignmentID ASC) /1),
		Plates = STUFF((SELECT DISTINCT ', ' + PlateName 
							FROM 
							(
								SELECT 
									DA.DetAssignmentID,
									PlateName = MAX(P.PlateName) 
								FROM DeterminationAssignment DA
								JOIN Well W ON W.DetAssignmentID =DA.DetAssignmentID
								JOIN Plate p ON p.PlateID = W.PlateID
								--WHERE T.PeriodID = @PeriodID
								GROUP BY Da.DetAssignmentID, P.PlateID

							)P1
							
						WHERE P1.DetAssignmentID = DA.DetAssignmentID
						--GROUP BY P1.DetAssignmentID,P1.PlateName
					FOR XML PATH('')
					),1,1,'')
		
    FROM Test T
    JOIN TestDetAssignment TDA ON TDA.TestID = T.TestID
    JOIN DeterminationAssignment DA ON DA.DetAssignmentID = TDA.DetAssignmentID
    JOIN ABSCrop C ON C.ABSCropCode = DA.ABSCropCode
    JOIN Method M ON M.MethodCode = DA.MethodCode
    JOIN CropMethod CM ON CM.ABSCropCode = DA.ABSCropCode AND CM.MethodID = M.MethodID
    JOIN [Platform] P ON P.PlatformID = CM.PlatformID
	--handle if same method is used for hybrid and parent
	JOIN
	(
		SELECT 
			VarietyNr, 
			Shortname,
			[Type],
			UsedFor = CASE WHEN [Type] = 'P' THEN 'Par' WHEN HybOp = 1 AND [Type] <> 'P' THEN 'Hyb' ELSE '' END
		FROM Variety
	) V ON V.VarietyNr = DA.VarietyNr AND V.UsedFor = CM.UsedFor
    LEFT JOIN
    (
	   SELECT 
		  MethodID,
		  NrOfPlates = NrOfSeeds/92.0
	   FROM Method
    ) V2 ON V2.MethodID = M.MethodID
    LEFT JOIN 
    (
		SELECT DetAssignmentID, NrOfMarkers = COUNT(MarkerID) FROM
		(
			SELECT DetAssignmentID, MarkerID FROM
			MarkerToBeTested
			UNION
			(
				SELECT DA.DetAssignmentID, MPV.MarkerID FROM DeterminationAssignment DA
				JOIN Variety V ON V.VarietyNr = DA.VarietyNr
				JOIN MarkerPerVariety MPV ON MPV.VarietyNr = V.VarietyNr
				WHERE MPV.StatusCode = 100
			)
		) D
		GROUP BY DetAssignmentID
    ) V3 ON V3.DetAssignmentID = DA.DetAssignmentID
	LEFT JOIN 
	(
		SELECT DA.DetAssignmentID, TraitMarker = MAX(MPV.MarkerID) FROM DeterminationAssignment DA
		JOIN Variety V ON V.VarietyNr = DA.VarietyNr
		JOIN MarkerPerVariety MPV ON MPV.VarietyNr = V.VarietyNr
		WHERE MPV.StatusCode = 100
		GROUP BY DetAssignmentID
	) V4 ON V4.DetAssignmentID = DA.DetAssignmentID
	WHERE T.PeriodID = @PeriodID
	) T1
	ORDER BY T1.CropCode ASC, T1.MethodCode ASC, T1.PlatformDesc ASC, ISNULL(T1.IsLabPriority, 0) DESC, Prio DESC, T1.Shortname ASC

	

    --create groups
    SELECT 
	   V2.TestID,
	   TestName = COALESCE(V2.TestName, 'Folder ' + CAST(ROW_NUMBER() OVER(ORDER BY V2.CropCode, V2.MethodCode) AS VARCHAR)),
	   V2.CropCode,
	   V2.MethodCode,
	   V2.PlatformName,
	   NrOfPlates = CEILING(V2.NrOfPlates), --making absolute number for plates
	   NrOfMarkers = T1.TotalMarkers,
	   TraitMarkers,
	   IsLabPriority --CAST(0 AS BIT)
    FROM
    (
	   SELECT 
		  V.*,
		  T.TestName,
		  TraitMarkers = CAST (CASE WHEN ISNULL(V2.TraitMarker,0) = 0 THEN 0 ELSE 1 END As BIT)
	   FROM
	   (
		  SELECT
			 TestID,
			 CropCode,
			 MethodCode,
			 PlatformName,
			 NrOfPlates = SUM(NrOfPlates),
			 NrOfMarkers = SUM(NrOfMarkers),
			 IsLabPriority = CAST( MAX(IsLabPriority) AS BIT)
		  FROM @tbl
		  GROUP BY TestID, CropCode, MethodCode, PlatformName
	   ) V
	   JOIN Test T ON T.TestID = V.TestID
	   LEFT JOIN
	   (
			SELECT TD.TestID, TraitMarker = MAX(MPV.MarkerID) FROM TestDetAssignment TD
			JOIN DeterminationAssignment DA On DA.DetAssignmentID = TD.DetAssignmentID
			JOIN Variety V ON V.VarietyNr = DA.VarietyNr
			JOIN MarkerPerVariety MPV ON MPV.VarietyNr = V.VarietyNr
			WHERE MPV.StatusCode = 100
			GROUP BY TestID
	   ) V2 On V2.TestID = T.TestID
    ) V2
	JOIN 
	(
		SELECT TestID, TotalMarkers = SUM(TotalMarkers)
		FROM 
		(
			SELECT TestID,
				TotalMarkers = CASE 
									WHEN NrOfPlates >=1 THEN NrOfPlates * COUNT(DISTINCT [Value]) 
									ELSE COUNT(DISTINCT [Value]) END 
			FROM 
			(
				SELECT TempPlateID, TestID, NrOFPlates = MAX(NrOfPlates), TotalMarkers = ISNULL(STUFF(
										(SELECT DISTINCT  ',' + Markers
											FROM @tbl T1 WHERE  T1.TempPlateID = T2.TempPlateID AND T1.TestID = T2.TestID
											FOR XML PATH('')
										),1,1,''),'')
										FROM @tbl T2 
										GROUP BY TestID, TempPlateID
			)T
			OUTER APPLY 
			( 
				SELECT [Value] FROM string_split(TotalMarkers,',')
				WHERE ISNULL([Value],'') <> ''
			) T1
			GROUP BY T.TestID, T.TempPlateID,T.TotalMarkers,T.NrOFPlates
		) T1 GROUP BY TestID
	) T1
	ON T1.TestID = V2.TestID
	ORDER BY CropCode, MethodCode

    SELECT
	   T.TestID,
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
	   IsLabPriority = CAST(IsLabPriority AS BIT),
	   TraitMarkers,
	   PlateNames
    FROM @tbl T
	ORDER BY ID


    SELECT 
	   MIN(T2.StatusCode) AS StatusCode
    FROM @tbl T1
    JOIN Test T2 ON T2.TestID = T1.TestID;
END
GO
/****** Object:  StoredProcedure [dbo].[PR_GetNrOFPlatesAndTests]    Script Date: 4/29/2020 3:43:37 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
Author					Date			Description
Binod Gurung			2020-jan-23		Transcation isolation level implemented to avoid record lock	
Krishna Gautam			2020/02/19		Calculation of nr of marker is done per plate on group level.
Dibya			    2020/02/20		     Made #plates as absolute number.

===================================Example================================

    EXEC [PR_GetNrOFPlatesAndTests] 4796;
	
*/
CREATE PROCEDURE [dbo].[PR_GetNrOFPlatesAndTests]
(
    @PeriodID	 INT,
	@StatusCode	 INT = NULL
) 
AS 
BEGIN
    SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    DECLARE @tbl TABLE
    (
		ID INT IDENTITY(1,1),
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
		IsParent	    BIT,
		TraitMarkers BIT,
		Markers VARCHAR(MAX),
		TempPlateID INT
    );
	
    INSERT @tbl(DetAssignmentID, TestID, TestName, CropCode, MethodCode, PlatformName, NrOfPlates, NrOfMarkers, VarietyNr, VarietyName, SampleNr, IsLabPriority, IsParent, TraitMarkers,Markers,TempPlateID)
    SELECT 
	DetAssignmentID,
	TestID,
	TestName,
	CropCode,
	MethodCode, 
	PlatformDesc,
	NrOfPlates,
	NrOfMarkers,
	VarietyNr,
	Shortname,
	SampleNr,
	IsLabPriority,
	Prio,
	TraitMarkers,
	Markers = ISNULL(Markers,'') + ',' + ISNULL(Markers1,''),  --COALESCE( Markers1 +',', Markers),
	TempPlateID
	FROM 
	(
	
	SELECT 
	   DA.DetAssignmentID,	   
	   T.TestID,
	   T.TestName,
	   C.CropCode,
	   DA.MethodCode, 
	   P.PlatformDesc,
	   V2.NrOfPlates,
	   NrOfMarkers =  CASE WHEN NrOfPlates >=1 THEN V3.NrOfMarkers * NrOfPlates ELSE NrOfMarkers END,
	   V.VarietyNr,
	   V.Shortname,
	   DA.SampleNr,
	   IsLabPriority = ISNULL(DA.IsLabPriority, 0),
	   Prio = CASE WHEN V.[Type] = 'P' THEN 1 ELSE 0 END,
	   TraitMarkers = CAST (CASE WHEN ISNULL(V4.TraitMarker,0) = 0 THEN 0 ELSE 1 END As BIT),
	   Markers = STUFF((SELECT DISTINCT ',', + CAST(MTT.MarkerID AS NVARCHAR(50) )
							FROM
							MarkerToBeTested MTT
							WHERE MTT.DetAssignmentID =  DA.DetAssignmentID
							FOR XML PATH('')
						),1,1,''),
		Markers1 = STUFF((SELECT DISTINCT ',', + CAST(MTT.MarkerID AS NVARCHAR(50))
							FROM
							(
								SELECT DA.DetAssignmentID, MarkerID FROM MarkerPerVariety MPV
								JOIN Variety V ON V.VarietyNr = MPV.VarietyNr
								JOIN DeterminationAssignment DA ON DA.VarietyNr = V.VarietyNr
								WHERE MPV.StatusCode = 100

							)MTT
							WHERE MTT.DetAssignmentID =  DA.DetAssignmentID
							FOR XML PATH('')
						),1,1,''),
		TempPlateID = CEILING(SUM(ISNULL(NrOfPlates,0)) OVER (Partition by T.Testid Order by C.CropCode ASC, DA.MethodCode ASC, P.PlatformDesc ASC, ISNULL(DA.IsLabPriority, 0) DESC, CASE WHEN V.[Type] = 'P' THEN 1 ELSE 0 END DESC, DA.DetAssignmentID ASC) /1),
		Plates = STUFF((SELECT DISTINCT ', ' + PlateName 
							FROM 
							(
								SELECT 
									DA.DetAssignmentID,
									PlateName = MAX(P.PlateName) 
								FROM DeterminationAssignment DA
								JOIN Well W ON W.DetAssignmentID =DA.DetAssignmentID
								JOIN Plate p ON p.PlateID = W.PlateID
								--WHERE T.PeriodID = @PeriodID
								GROUP BY Da.DetAssignmentID, P.PlateID

							)P1
							
						WHERE P1.DetAssignmentID = DA.DetAssignmentID
						--GROUP BY P1.DetAssignmentID,P1.PlateName
					FOR XML PATH('')
					),1,1,'')
		
    FROM Test T
    JOIN TestDetAssignment TDA ON TDA.TestID = T.TestID
    JOIN DeterminationAssignment DA ON DA.DetAssignmentID = TDA.DetAssignmentID
    JOIN ABSCrop C ON C.ABSCropCode = DA.ABSCropCode
    JOIN Method M ON M.MethodCode = DA.MethodCode
    JOIN CropMethod CM ON CM.ABSCropCode = DA.ABSCropCode AND CM.MethodID = M.MethodID
    JOIN [Platform] P ON P.PlatformID = CM.PlatformID
	--handle if same method is used for hybrid and parent
    JOIN
	(
		SELECT 
			VarietyNr, 
			Shortname,
			[Type],
			UsedFor = CASE WHEN [Type] = 'P' THEN 'Par' WHEN HybOp = 1 AND [Type] <> 'P' THEN 'Hyb' ELSE '' END
		FROM Variety
	) V ON V.VarietyNr = DA.VarietyNr AND V.UsedFor = CM.UsedFor
    LEFT JOIN
    (
	   SELECT 
		  MethodID,
		  NrOfPlates = NrOfSeeds/92.0
	   FROM Method
    ) V2 ON V2.MethodID = M.MethodID
    LEFT JOIN 
    (
		SELECT DetAssignmentID, NrOfMarkers = COUNT(MarkerID) FROM
		(
			SELECT DetAssignmentID, MarkerID FROM
			MarkerToBeTested
			UNION
			(
				SELECT DA.DetAssignmentID, MPV.MarkerID FROM DeterminationAssignment DA
				JOIN Variety V ON V.VarietyNr = DA.VarietyNr
				JOIN MarkerPerVariety MPV ON MPV.VarietyNr = V.VarietyNr
				WHERE MPV.StatusCode = 100
			)
		) D
		GROUP BY DetAssignmentID
    ) V3 ON V3.DetAssignmentID = DA.DetAssignmentID
	LEFT JOIN 
	(
		SELECT DA.DetAssignmentID, TraitMarker = MAX(MPV.MarkerID) FROM DeterminationAssignment DA
		JOIN Variety V ON V.VarietyNr = DA.VarietyNr
		JOIN MarkerPerVariety MPV ON MPV.VarietyNr = V.VarietyNr
		WHERE MPV.StatusCode = 100
		GROUP BY DetAssignmentID
	) V4 ON V4.DetAssignmentID = DA.DetAssignmentID
	WHERE T.PeriodID = @PeriodID
	) T1
	ORDER BY T1.CropCode ASC, T1.MethodCode ASC, T1.PlatformDesc ASC, ISNULL(T1.IsLabPriority, 0) DESC, Prio DESC, T1.DetAssignmentID ASC
		
    --create groups
    SELECT 
	   V2.TestID,
	   NrOfPlates = CEILING(V2.NrOfPlates), --making absolute number for plates
	   NrOfMarkers = T1.TotalMarkers,
	   IsLabPriority
    FROM
    (
	   SELECT
			TestID,
			NrOfPlates = SUM(NrOfPlates),
			NrOfMarkers = SUM(NrOfMarkers),
			IsLabPriority = CAST( MAX(IsLabPriority) AS BIT)
		FROM @tbl
		GROUP BY TestID, CropCode, MethodCode, PlatformName   
    ) V2
	JOIN 
	(
		SELECT TestID, TotalMarkers = SUM(TotalMarkers)
		FROM 
		(
			SELECT TestID,
				TotalMarkers = CASE 
									WHEN NrOfPlates >=1 THEN NrOfPlates * COUNT(DISTINCT [Value]) 
									ELSE COUNT(DISTINCT [Value]) END 
			FROM 
			(
				SELECT TempPlateID, TestID, NrOFPlates = MAX(NrOfPlates), TotalMarkers = ISNULL(STUFF(
										(SELECT DISTINCT  ',' + Markers
											FROM @tbl T1 WHERE  T1.TempPlateID = T2.TempPlateID AND T1.TestID = T2.TestID
											FOR XML PATH('')
										),1,1,''),'')
										FROM @tbl T2 
										GROUP BY TestID, TempPlateID
			)T
			OUTER APPLY 
			( 
				SELECT [Value] FROM string_split(TotalMarkers,',')
				WHERE ISNULL([Value],'') <> ''
			) T1
			GROUP BY T.TestID, T.TempPlateID,T.TotalMarkers,T.NrOFPlates
		) T1 GROUP BY TestID
	) T1
	ON T1.TestID = V2.TestID
    
END
GO
/****** Object:  StoredProcedure [dbo].[PR_GetTestInfoForLIMS]    Script Date: 4/29/2020 3:43:37 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
Author					Date			Description
Binod Gurung			2019/10/22		Pull Test Information for input period for LIMS
Binod Gurung			2020-jan-23		Transcation isolation level implemented to avoid record lock

===================================Example================================

EXEC PR_GetTestInfoForLIMS 4805, 5, 2
*/
CREATE PROCEDURE [dbo].[PR_GetTestInfoForLIMS]
(
	@PeriodID INT
)
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

	DECLARE @TestPlates TABLE (TestID INT, NrOfPlates INT, NrOfMarkes INT, IsLabPrioity BIT);
	
	INSERT @TestPlates (TestID, NrOfPlates, NrOfMarkes, IsLabPrioity)
	EXEC PR_GetNrOFPlatesAndTests @PeriodID, 150;

	SELECT 
	   T1.ContainerType,
	   T1.CountryCode,
	   T1.CropCode,
	   ExpectedDate = FORMAT(T1.ExpectedDate, 'yyyy-MM-dd', 'en-US'),
	   ExpectedWeek = DATEPART(WEEK, T1.ExpectedDate),
	   ExpectedYear = YEAR(T1.ExpectedDate),
	   T1.Isolated,
	   T1.MaterialState,
	   T1.MaterialType,
	   PlannedDate = FORMAT(T1.PlannedDate, 'yyyy-MM-dd', 'en-US'),
	   PlannedWeek = DATEPART(WEEK, T1.PlannedDate),	
	   PlannedYear = YEAR(T1.PlannedDate),
	   T1.Remark,
	   T1.RequestID,
	   T1.RequestingSystem,
	   T1.SynchronisationCode,
	   T1.TotalNrOfPlates,
	   T1.TotalNrOfTests
	FROM
	(
	    SELECT 
		    'DPW' AS ContainerType,
		    'NL' AS CountryCode,
		    MAX(V0.CropCode) AS CropCode,
		    ExpectedDate = MAX(V0.ExpectedReadyDate),
		    'N' AS Isolated,	
		    'FRS' AS MaterialState,
		    'SDS' AS MaterialType,
		    PlannedDate =  MAX(V0.PlannedDate),
		    'PAC' AS Remark, 
		    T.TestID AS RequestID, 
		    'PAC' AS RequestingSystem,
		    'NL' AS SynchronisationCode,
			MAX(TP.NrOfPlates) AS TotalNrOfPlates,
			MAX(TP.NrOfMarkes) AS TotalNrOfTests		    
	    FROM
	    (	
		    SELECT 
			    TestID, 
			    DA.DetAssignmentID, 
			    AC.CropCode,
			    DA.PlannedDate,
			    DA.ExpectedReadyDate
		    FROM TestDetAssignment TDA
		    JOIN DeterminationAssignment DA ON DA.DetAssignmentID = TDA.DetAssignmentID
		    JOIN Method M ON M.MethodCode = DA.MethodCode
		    JOIN CropMethod CM ON CM.MethodID = M.MethodID AND CM.ABSCropCode = DA.ABSCropCode
			--handle if same method is used for hybrid and parent
			JOIN
			(
				SELECT 
					VarietyNr, 
					UsedFor = CASE WHEN [Type] = 'P' THEN 'Par' WHEN HybOp = 1 AND [Type] <> 'P' THEN 'Hyb' ELSE '' END
				FROM Variety
			) V ON V.VarietyNr = DA.VarietyNr AND V.UsedFor = CM.UsedFor
		    JOIN ABSCrop AC On AC.ABSCropCode = DA.ABSCropCode
	    ) V0 
	    JOIN Test T ON T.TestID = V0.TestID		
	    JOIN @TestPlates TP ON TP.TestID = T.TestID
	    WHERE T.PeriodID = @PeriodID AND T.StatusCode = 150
	    GROUP BY T.TestID
	) T1
END

GO
/****** Object:  StoredProcedure [dbo].[PR_PlanAutoDeterminationAssignments]    Script Date: 4/29/2020 3:43:37 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
Author					Date			Description
Binod Gurung			2020-jan-23		Transcation isolation level implemented to avoid record lock
Dibya			    2020-Feb-19		Performance improvements on unplanned data	
Dibya			    2020-MAR-4		Adjusted ExpectedReadyDate

===================================Example================================

    DECLARE @ABSDataAsJson NVARCHAR(MAX) =  N'[{"DetAssignmentID":1736406,"MethodCode":"PAC-01","ABSCropCode": "SP","VarietyNr":"21063","PriorityCode": 1}]';
    EXEC PR_PlanAutoDeterminationAssignments 4779, @ABSDataAsJson
*/
CREATE PROCEDURE [dbo].[PR_PlanAutoDeterminationAssignments]
(
    @PeriodID	 INT,
    @ExpWeekDifference	 INT,
    @ABSData	 TVP_DeterminationAssignment READONLY
) 
AS 
BEGIN
    SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    DECLARE @TransCount BIT = 0;

    DECLARE @ABSCropCode NVARCHAR(10);
    DECLARE @MethodCode	NVARCHAR(25);
    DECLARE @RequiredPlates INT;
    DECLARE @UsedFor NVARCHAR(10);
    DECLARE @PlatesPerMethod	  DECIMAL(5,2);
    DECLARE @RequiredDeterminations INT;
    DECLARE @StartDate DATE, @EndDate DATE;
    DECLARE @PlannedDate DATETIME, @ExpectedReadyDate DATETIME;
    DECLARE @IDX INT = 1;
    DECLARE @CNT INT = 0;
    
    SELECT
	   @StartDate = StartDate,
	   @EndDate = EndDate
    FROM [Period]
    WHERE PeriodID = @PeriodID;

    --This is the first Monday of the selected week
    SET @PlannedDate = dbo.FN_GetWeekStartDate(@StartDate);
    --Add number of week on start date and get the Friday of that week.
    SET @ExpectedReadyDate = DATEADD(WEEK, @ExpWeekDifference, @StartDate);
    --Get Monday of ExpectedReadyDate
    SET @ExpectedReadyDate = dbo.FN_GetWeekStartDate(@ExpectedReadyDate);
    --get the date of Friday of that expected ready date
    SET @ExpectedReadyDate = DATEADD(DAY, 4, @ExpectedReadyDate);

    DECLARE @PlatformID INT = (SELECT PlatformID FROM [Platform] WHERE PlatformCode = 'LS'); --light scanner   

    DECLARE @Capacity TABLE
    (
	   UsedFor	    VARCHAR(5), 
	   ABSCropCode	    NVARCHAR(10), 
	   MethodCode	    NVARCHAR(50), 
	   ReservePlates   DECIMAL(5,2)
    );

    DECLARE @Groups TABLE
    (
	   ID		    INT IDENTITY(1, 1),    
	   ABSCropCode	    NVARCHAR(10), 
	   MethodCode	    NVARCHAR(50), 
	   UsedFor	    VARCHAR(5), 
	   ReservePlates   DECIMAL(5,2),
	   TotalPlates	DECIMAL(5,2)
    );

    --handle unplanned records if exists
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
	   Process		    NVARCHAR(100),
	   ProductStatus	    NVARCHAR(100),
	   Remarks	    NVARCHAR(250),
	   PlannedDate		   DATE,
	   UtmostInlayDate	    DATE,
	   ExpectedReadyDate   DATE,
	   ReceiveDate		  DATETIME,
	   ReciprocalProd	  BIT,
	   BioIndicator		  BIT,
	   LogicalClassificationCode	NVARCHAR(20),
	   LocationCode					NVARCHAR(20),
	   UsedFor		    NVARCHAR(10)
    );

     BEGIN TRY
	   IF @@TRANCOUNT = 0 BEGIN
		  BEGIN TRANSACTION;
		  SET @TransCount = 1;
	   END

	   --clean already planned records before planning again
	   DELETE DA
	   FROM DeterminationAssignment DA
	   WHERE CAST(DA.PlannedDate AS DATE) BETWEEN @StartDate AND @EndDate
	   AND DA.StatusCode = 100;

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
			FROM DeterminationAssignment DA
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
				WHERE PCM.PlatformID = @PlatformID
				AND PM.StatusCode = 100
			) V1 ON V1.ABSCropCode = DA.ABSCropCode AND V1.MethodCode = DA.MethodCode
			--handle if same method is used for hybrid and parent
			JOIN
			(
				SELECT 
					VarietyNr, 
					UsedFor = CASE WHEN [Type] = 'P' THEN 'Par' WHEN HybOp = 1 AND [Type] <> 'P' THEN 'Hyb' ELSE '' END
				FROM Variety
			) V ON V.VarietyNr = DA.VarietyNr AND V.UsedFor = V1.UsedFor
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
		  WHERE CM.PlatformID = @PlatformID AND PC.PeriodID = @PeriodID
		  GROUP BY PC.SlotName, AC.ABSCropCode, PM.MethodCode, CM.UsedFor
	   ) V1
	   LEFT JOIN @Capacity V2 ON V2.ABSCropCode = V1.ABSCropCode AND V2.MethodCode = V1.MethodCode AND V2.UsedFor = V1.UsedFor;

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
		    Process, 
		    ProductStatus, 
		    Remarks, 
		    PlannedDate, 
		    UtmostInlayDate, 
		    ExpectedReadyDate,
		    ReceiveDate,
		    ReciprocalProd,
		    BioIndicator,
		    LogicalClassificationCode,
		    LocationCode,
		    UsedFor
	   )
	   SELECT 
		  T1.DetAssignmentID, 
		  T1.SampleNr, 
		  T1.PriorityCode, 
		  T1.MethodCode, 
		  T1.ABSCropCode, 
		  T1.VarietyNr, 
		  T1.BatchNr, 
		  T1.RepeatIndicator, 
		  T1.Process, 
		  T1.ProductStatus, 
		  T1.Remarks, 
		  @PlannedDate,
		  T1.UtmostInlayDate, 
		  @ExpectedReadyDate,
		  T1.ReceiveDate,
		  T1.ReciprocalProd,
		  T1.BioIndicator,
		  T1.LogicalClassificationCode,
		  T1.LocationCode,
		  UsedFor = CASE WHEN V.HybOp = 0 AND V.[Type] = 'P' THEN 'Par' ELSE 'Hyb' END
	   FROM @ABSData T1
	   JOIN ABSCrop C ON C.ABSCropCode = T1.ABSCropCode
	   JOIN Variety V ON V.VarietyNr = T1.VarietyNr
	   JOIN Method M ON M.MethodCode = T1.MethodCode
	   WHERE T1.PriorityCode NOT IN(4, 7, 8)
	   AND dbo.FN_IsPacProfileComplete (V.VarietyNr, @PlatformID, C.CropCode) = 1 -- #8068 Only plan if PAC profile complete is true
	   ORDER BY T1.PriorityCode;
    	  
	   SELECT @CNT = COUNT(ID) FROM @Groups;
	   WHILE(@IDX <= @CNT) BEGIN
		  SELECT 
			 @ABSCropCode =  G.ABSCropCode,
			 @MethodCode = G.MethodCode,
			 @RequiredPlates = G.TotalPlates - G.ReservePlates,
			 @UsedFor = G.UsedFor
		  FROM @Groups G
		  WHERE ID = @IDX;
    
		  IF(@RequiredPlates > 0) BEGIN	   
			 SELECT 
				@PlatesPerMethod = CAST((NrOfSeeds / 92.0) AS DECIMAL(5,2))
			 FROM Method 
			 WHERE MethodCode = @MethodCode;

			 SET @RequiredDeterminations = @RequiredPlates / @PlatesPerMethod;

			 --insert records into DeterminationAssignments and calculate required plates again
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
				LocationCode
			 )
			 SELECT TOP(@RequiredDeterminations) 
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
				D.PlannedDate,
				UtmostInlayDate, 
				ExpectedReadyDate,
				100,
				ReceiveDate,
				ReciprocalProd,
				BioIndicator,
				LogicalClassificationCode,
				LocationCode
			 FROM @DeterminationAssignment D
			 WHERE D.ABSCropCode = @ABSCropCode 
			 AND D.MethodCode = @MethodCode
			 AND D.UsedFor = @UsedFor
			 AND ISNULL(D.PriorityCode, 0) <> 0 
			 AND NOT EXISTS
			 (
				SELECT 
				    DetAssignmentID 
				FROM DeterminationAssignment
				WHERE DetAssignmentID = D.DetAssignmentID
			 )
			 ORDER BY D.PriorityCode;
			 --now check if plates are fulfilled already with priority	   
			 SET @RequiredPlates = @RequiredPlates - (@@ROWCOUNT * @PlatesPerMethod);
			 --if we still need determinations, get it based on expected ready date here
			 IF(@RequiredPlates > 0 AND @RequiredPlates > @PlatesPerMethod) BEGIN
				--PRINT 'we need more'
				--determine how many determinations required for required plates
				SET @RequiredDeterminations = @RequiredPlates / @PlatesPerMethod;

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
				    LocationCode
				)
				SELECT TOP(@RequiredDeterminations) 
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
				    @PlannedDate,
				    UtmostInlayDate, 
				    ExpectedReadyDate,
				    100,
				    ReceiveDate,
				    ReciprocalProd,
				    BioIndicator,
				    LogicalClassificationCode,
				    LocationCode
				FROM @DeterminationAssignment D
				WHERE D.ABSCropCode = @ABSCropCode 
				AND D.MethodCode = @MethodCode
				AND D.UsedFor = @UsedFor
				AND ISNULL(PriorityCode, 0) = 0 
				AND NOT EXISTS
				(
				    SELECT 
					   DetAssignmentID 
				    FROM DeterminationAssignment
				    WHERE DetAssignmentID = D.DetAssignmentID
				)
				ORDER BY D.ExpectedReadyDate;
			 END
		  END
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
/****** Object:  StoredProcedure [dbo].[PR_ValidateCapacityPerFolder]    Script Date: 4/29/2020 3:43:37 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
Author					Date			Description
Binod Gurung			2020-jan-23		Transcation isolation level implemented to avoid record lock
										
===================================Example================================
*/
CREATE PROCEDURE [dbo].[PR_ValidateCapacityPerFolder]
(
    @PeriodID	 INT,
    @DataAsJson NVARCHAR(MAX)
) AS BEGIN
    SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
    
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
	   UsedFor = CASE WHEN [Type] = 'P' THEN 'Par' WHEN HybOp = 1 AND [Type] <> 'P' THEN 'Hyb' ELSE '' END
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
	   [Action]	        CHAR(1)
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
			 --handle if same method is used for hybrid and parent
			 JOIN
			 (
				 SELECT 
				 	 VarietyNr, 
				 	 UsedFor = CASE WHEN [Type] = 'P' THEN 'Par' WHEN HybOp = 1 AND [Type] <> 'P' THEN 'Hyb' ELSE '' END
				 FROM Variety
			 ) V ON V.VarietyNr = DA2.VarietyNr AND V.UsedFor = PCM.UsedFor
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
			--handle if same method is used for hybrid and parent
			JOIN
			(
				SELECT 
					VarietyNr, 
					UsedFor = CASE WHEN [Type] = 'P' THEN 'Par' WHEN HybOp = 1 AND [Type] <> 'P' THEN 'Hyb' ELSE '' END
				FROM Variety
			) V ON V.VarietyNr = DA.VarietyNr AND V.UsedFor = CM.UsedFor
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
