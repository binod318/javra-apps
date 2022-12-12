DROP PROCEDURE IF EXISTS [dbo].[PR_GetDeterminationAssignments]
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
				UsedFor = CASE WHEN HybOp = 1 THEN 'Hyb' ELSE 'Par' END
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
			UsedFor = CASE WHEN HybOp = 1 THEN 'Hyb' ELSE 'Par' END
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
				UsedFor = CASE WHEN HybOp = 1 THEN 'Hyb' ELSE 'Par' END
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
		  UsedFor = CASE WHEN R.UsedFor = 'Par' THEN 'OP/Par' ELSE R.UsedFor END,
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





DROP PROCEDURE IF EXISTS [dbo].[PR_GetPlanningCapacitySO_LS]
GO


/*
Author					Date			Description
Krishna Gautam			2019-Jul-08		Service created to get capacity planning for SO for Lightscanner
Dibya			    2020-Feb-19		Adjusted week name. made shorter name
Dibya			    2020-Feb-27		Adjusted the sorting columns

===================================Example================================

EXEC PR_GetPlanningCapacitySO_LS 4744
*/

CREATE PROCEDURE [dbo].[PR_GetPlanningCapacitySO_LS]
(
	@PeriodID INT
)
AS 
BEGIN
	DECLARE @Query NVARCHAR(MAX),@Query1 NVARCHAR(MAX),@Columns NVARCHAR(MAX), @MinPeriodID INT,@PlatformID INT;
	DECLARE @Period TABLE(PeriodID INT,PeriodName NVARCHAR(MAX));
	DECLARE @ColumnTable TABLE(ColumnID NVARCHAR(MAX), Label NVARCHAR(MAX),[Order] INT, IsVisible BIT,Editable BIT);

	SELECT @PlatformID = PlatformID 
	FROM [Platform] WHERE PlatformCode = 'LS' --Lightscanner;

	IF(ISNULL(@PlatformID,0)=0)
	BEGIN
		EXEC PR_ThrowError 'Invalid Platform';
		RETURN
	END
	
	IF NOT EXISTS (SELECT PeriodID FROM [Period] WHERE PeriodID = @PeriodID)
	BEGIN
		EXEC PR_ThrowError 'Invalid Period (Week)';
		RETURN
	END

	INSERT INTO @Period(PeriodID, PeriodName)
	SELECT 
		P.PeriodID,
		Concat('Wk' + RIGHT(P.PeriodName, 2),Concat(FORMAT(P.StartDate,'MMMdd','en-US'),'-',FORMAT(P.EndDate,'MMMdd','en-US'))) AS PeriodName
	FROM [Period] P 
	WHERE PeriodID BETWEEN @PeriodID - 4 AND @PeriodID +5

	SELECT 
		@Columns = COALESCE(@Columns +',','') + QUOTENAME(PeriodID)
	FROM @Period ORDER BY PeriodID;

	SELECT TOP 1 @MinPeriodID =  PeriodID FROM @Period ORDER BY PeriodID


	IF(ISNULL(@Columns,'') = '')
	BEGIN
		EXEC PR_ThrowError 'No Period (week) found';
		RETURN
	END

	SET @Query = N'SELECT T1.CropMethodID, C.ABSCropCode, T1.MethodCode, UsedFor, '+ @Columns+'
				FROM 
				(
					SELECT 
					   CropMethodID, 
					   PM.MethodID, 
					   MethodCode,
					   ABSCropCode,
					   UsedFor,
					   DisplayOrder
					FROM CropMethod CM
					JOIN Method PM ON PM.MethodID = CM.MethodID
				) 
				T1 				
				JOIN ABSCrop C ON C.ABSCropCode = T1.ABSCropCode
				LEFT JOIN
				(
					SELECT CropMethodID,'+@Columns+'
					FROM 
					(
						SELECT CropMethodID,PeriodID, NrOfPlates = MAX(NrOfPlates) 
						FROM ReservedCapacity						
						GROUP BY CropMethodID,PeriodID
					) 
					SRC
					PIVOT 
					(
						MAX(NrOfPlates)
						FOR PeriodID IN ('+@Columns+')
					)
					PIV

				) T2 ON T2.CropMethodID = T1.CropMethodID	
				Order BY T1.UsedFor, T1.ABSCropCode, T1.MethodCode';

	

	EXEC SP_ExecuteSQL @Query ,N'@PlatformID INT', @PlatformID;


	INSERT INTO @ColumnTable(ColumnID,Label,[Order],IsVisible,Editable)
	VALUES
	('CropMethodID','CropMethodID',0,0,0),
	('ABSCropCode','ABS Crop',1,1,0),
	('MethodCode','Method',2,1,0),
	('UsedFor','UsedFor',3,0,0);
	

	INSERT INTO @ColumnTable(ColumnID,Label,[Order],IsVisible,Editable)
	SELECT PeriodID, PeriodName, PeriodID - @MinPeriodID + 4, 1,1 FROM @Period ORDER BY PeriodID

	SELECT * FROM @ColumnTable
	

    DECLARE @tbl RCAggrTableType;
    
    INSERT @tbl (Method, PeriodID, NrOfPlates, DisplayOrder)
    SELECT 'Hybrid Plates' AS Method, PeriodID, NrOfPlates = SUM(NrOfPlates), 1
    FROM ReservedCapacity RC
    JOIN CropMethod PC ON PC.CropMethodID = RC.CropMethodID 
    WHERE PC.UsedFor = 'HYB'
    GROUP BY PeriodID;
    IF(@@ROWCOUNT = 0) BEGIN
	   INSERT @tbl(Method) VALUES('Hybrid Plates');
    END

    INSERT @tbl (Method, PeriodID, NrOfPlates, DisplayOrder)
    SELECT 'OP/Parentline Plates' AS Method, PeriodID, NrOfPlates = SUM(NrOfPlates), 2
    FROM ReservedCapacity RC
    JOIN CropMethod PC ON PC.CropMethodID = RC.CropMethodID 
    WHERE PC.UsedFor = 'par'
    GROUP BY PeriodID;
    IF(@@ROWCOUNT = 0) BEGIN
	   INSERT @tbl(Method) VALUES('OP/Parentline Plates');
    END

    INSERT @tbl (Method, PeriodID, NrOfPlates, DisplayOrder)
    SELECT 'Total Plates' AS Method, PeriodID, NrOfPlates = SUM(NrOfPlates), 3
    FROM ReservedCapacity
    GROUP BY PeriodID
    IF(@@ROWCOUNT = 0) BEGIN
	   INSERT @tbl(Method) VALUES('Total Plates');
    END
    
    INSERT @tbl (Method, PeriodID, NrOfPlates, DisplayOrder)
    SELECT 'Plates Budget' AS Method, PeriodID, NrOfPlates, 4
    FROM Capacity
    WHERE PlatformID = @PlatformID
    IF(@@ROWCOUNT = 0) BEGIN
	   INSERT @tbl(Method) VALUES('Plates Budget');
    END

    SET @Query1 = N'SELECT Method, ' + @Columns + N' 
    FROM
    (
	   SELECT Method, DisplayOrder, ' + @Columns + N' 
	   FROM @tbl SRC
	   PIVOT 
	   (
		  MAX(NrOfPlates)
		  FOR PeriodID IN (' + @Columns + N')
	   ) PIV 
    ) V1 
    ORDER BY DisplayOrder';
    EXEC SP_ExecuteSQL @Query1 , N'@tbl RCAggrTableType READONLY, @PlatformID INT', @tbl, @PlatformID
END
GO


