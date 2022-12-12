DROP FUNCTION IF EXISTS [dbo].[FN_LFDISK_GetAvailableCapacityByPeriodsQuery]
GO


/*
	DECLARE @SQL NVARCHAR(MAX) = dbo.FN_LFDISK_GetAvailableCapacityByPeriodsQuery();
	PRINT @SQL
	EXEC sp_executesql @SQL;
	PRINT @SQL
*/
CREATE FUNCTION [dbo].[FN_LFDISK_GetAvailableCapacityByPeriodsQuery]
(
	@SiteID INT = NULL
)
RETURNS NVARCHAR(MAX)
AS BEGIN
	DECLARE @TCols1 NVARCHAR(MAX), @TCols2 NVARCHAR(MAX),@PCols1 NVARCHAR(MAX), @PCols2 NVARCHAR(MAX), @TestTypeID INT = 9; --fixed value 9 for test type LEaf Disk

	SELECT 
		@TCols1 = COALESCE(@TCols1 + ',', '') + QUOTENAME(TestProtocolID),
		@TCols2 = COALESCE(@TCols2 + ',', '') + QUOTENAME(TestProtocolID) + ' = ' + 'MAX(ISNULL(' + QUOTENAME(TestProtocolID) + ', 0))'
	FROM TestProtocol
	WHERE TestTypeID = @TestTypeID;

	IF (ISNULL(@TCols2,'')= '') BEGIN		
		RETURN '';
	END

	DECLARE @SQL NVARCHAR(MAX);
	SET @SQL = N'SELECT * FROM
	(
		SELECT PeriodID as PID, ' + @TCols2 + N' 
		FROM
		(
			SELECT * FROM
			(
				SELECT
					PeriodID,
					TestProtocolID = TestProtocolID ,
					TestProtocolID2 = TestProtocolID,
					NrOfTests
				FROM AvailCapacity
				WHERE SiteID = '+ CAST(COALESCE(@SiteID,0) AS NVARCHAR(MAX)) +'
			) V1
			PIVOT
			(
				MAX(NrOfTests)
				FOR TestProtocolID IN (' + @TCols1 + N')
			) AS V2
		) V5
		GROUP BY PeriodID
	) AS V';

	RETURN @SQL;
END 
GO




DROP FUNCTION IF EXISTS [dbo].[FN_LFDISK_GetReservedCapacityByPeriodsQuery]
GO


/*
	DECLARE @SQL NVARCHAR(MAX) = dbo.FN_PLAN_GetReservedCapacityByPeriodsQuery_New();
	EXEC sp_executesql @SQL;
	PRINT @SQL
*/
CREATE FUNCTION [dbo].[FN_LFDISK_GetReservedCapacityByPeriodsQuery]
(
	@SiteID INT
)
RETURNS NVARCHAR(MAX)
AS BEGIN
	DECLARE @TCols1 NVARCHAR(MAX), @TCols2 NVARCHAR(MAX);
	SELECT 
		@TCols1 = COALESCE(@TCols1 + ',', '') + QUOTENAME(TestProtocolID),
		@TCols2 = COALESCE(@TCols2 + ',', '') + QUOTENAME(TestProtocolID) + ' = ' + 'MAX(ISNULL(' + QUOTENAME(TestProtocolID) + ', 0))'
	FROM TestProtocol TP
	WHERE TP.TestTypeID = 9;

	IF(ISNULL(@TCols2,'')= '') BEGIN		
		RETURN '';
	END


	DECLARE @SQL NVARCHAR(MAX);
	SET @SQL = N'SELECT * FROM
	(
		SELECT PeriodID, ' + @TCols2 +  N' 
		FROM
		(
			SELECT * FROM
			(
				SELECT
					T2.PeriodID,
					T1.TestProtocolID,
					TestProtocolID2 = TestProtocolID,
					NrOfTests = SUM(T1.NrOfTests)
				FROM ReservedCapacity T1
				JOIN Slot T2 ON T2.SlotID = T1.SlotID 
				WHERE T2.StatusCode = 200
				AND T2.SiteID = ISNULL(@SiteID,0)
				GROUP BY T2.PeriodID, T1.TestProtocolID
			) V1
			PIVOT
			(
				MAX(NrOfTests)
				FOR TestProtocolID IN (' + @TCols1 + N')
			) AS V2			
		) V5
		GROUP BY PeriodID
	) AS V';

	
	RETURN @SQL;
END 
GO




DROP PROCEDURE IF EXISTS [dbo].[PR_LFDISK_GetPlanApprovalListBySlotForLAB]
GO

/*
Authror					Date				Description
Krishna Gautam			
Krishna Gautam			2021/06/22			#22626: Added site location.

==================================Example============================
	DECLARE @PeriodID INT;
	DECLARE @Periods TVP_PLAN_Period;

	--EXEC @PeriodID = PR_PLAN_GetCurrentPeriod;
	SET @PeriodID =4874
	INSERT INTO @Periods(PeriodID)
	SELECT TOP 5 
		PeriodID
	FROM [Period] 
	WHERE PeriodID < @PeriodID
	ORDER BY PeriodID DESC;

	INSERT INTO @Periods(PeriodID) 
	SELECT TOP 13 
		PeriodID
	FROM [Period] 
	WHERE PeriodID >= @PeriodID
	ORDER BY PeriodID;
	EXEC PR_LFDISK_GetPlanApprovalListBySlotForLAB 3, @Periods
*/

CREATE PROCEDURE [dbo].[PR_LFDISK_GetPlanApprovalListBySlotForLAB]
(
	@SiteID INT,
	@Periods TVP_PLAN_Period READONLY
) AS BEGIN
	SET NOCOUNT ON;
	DECLARE @SQL NVARCHAR(MAX);

	DECLARE @TCols1 NVARCHAR(MAX), @TCols2 NVARCHAR(MAX);
	SELECT 
		@TCols1 = COALESCE(@TCols1 + ',', '') + QUOTENAME(TestProtocolID),
		@TCols2 = COALESCE(@TCols2 + ',', '') + QUOTENAME(TestProtocolID) + ' = ' + 'MAX(ISNULL(' + QUOTENAME(TestProtocolID) + ', 0))'
	FROM TestProtocol TP
	JOIN TestType TT ON TT.TestTypeID = TP.TestTypeID 
	--WHERE Isolated = 0 
	--AND TT.DeterminationRequired = 1
	WHERE TT.TestTypeID = 9;

	--get current period
	DECLARE @CurrentPeriodID INT, @CurrentPeriodEndDate DATETIME;
	EXEC @CurrentPeriodID = PR_PLAN_GetCurrentPeriod;
	--get end date of current period
	SELECT @CurrentPeriodEndDate = EndDate FROM [Period] WHERE PeriodID = @CurrentPeriodID;

	DECLARE @TblReservedCapicity TVP_ReservedCapacity;
	INSERT @TblReservedCapicity(SlotID, PeriodID, TestProtocolID, NrOfTests, StatusCode)
	SELECT
	   T2.SlotID,
	   T2.PeriodID,
	   T1.TestProtocolID,
	   NrOfTests = COALESCE( NULLIF(T1.NewNrOfTests, 0), T1.NrOfTests, 0),
	   T2.StatusCode
    FROM ReservedCapacity T1
    JOIN Slot T2 ON T2.SlotID = T1.SlotID 
    JOIN @Periods P ON P.PeriodID = T2.PeriodID
	WHERE T1.TestProtocolID in (SELECT TestProtocolID FROM TestProtocol WHERE TestTypeID = 9)
	AND T2.SiteID = ISNULL(@SiteID,0);

	SET @SQL = N'	
	DECLARE @TBLPeriod TABLE(PeriodID INT, TestProtocolID INT);
	INSERT INTO @TBLPeriod (PeriodID, TestProtocolID)
	SELECT DISTINCT PeriodID, TestProtocolID 
	FROM @Periods P 
	CROSS JOIN TestProtocol TP
	WHERE TP.TestTypeID = 9;	

	DECLARE @ReservedCapacity TABLE(PeriodID INT, TestProtocolID INT, NrOfTests INT)
	DECLARE @NonReservedCapacity TABLE(SlotID INT, PeriodID INT, TestProtocolID INT, NrOfTests INT)
	DECLARE @MarkerTestProtocolID INT = 0;

	--calculate slot wise detailed records
	--SELECT 
	--	@MarkerTestProtocolID = TestProtocolID 
	--FROM TestProtocol TP
	--JOIN TestType TT On TT.TestTypeID = TP.TestTypeID
	--WHERE TT.TestTypeID = 9;

	--SET @MarkerTestProtocol = 0;
	
	--Calculate sum of reserved capacity period and protocol wise
	INSERT INTO @ReservedCapacity(PeriodID, TestProtocolID, NrOfTests)
	SELECT 
		P.PeriodID, 
		TP.TestProtocolID,  
		ISNULL(NrOfTests ,0)
	FROM TestProtocol TP
	JOIN @TBLPeriod P ON P.TestProtocolID = TP.TestProtocolID
	LEFT JOIN
	(
	   SELECT
		  T1.PeriodID,
		  T1.TestProtocolID,
		  NrOfTests = SUM(T1.NrOfTests)
	   FROM @TblReservedCapicity T1
	   WHERE T1.StatusCode = 200
	   GROUP BY T1.PeriodID, T1.TestProtocolID
	) T2 ON T2.TestProtocolID = TP.TestProtocolID AND P.PeriodID = T2.PeriodID
	WHERE TP.Isolated = 0;

	--Calculate sum of non reserved but requested capacity slot, period and protocol wise
	;WITH CTE AS 
	(
	   SELECT 
		  T1.PeriodID,
		  T1.SlotID,
		  T1.TestProtocolID,
		  NrOfTests = SUM(T1.NrOfTests)
	   FROM @TblReservedCapicity T1
	   WHERE T1.StatusCode = 100
	   GROUP BY T1.PeriodID, T1.SlotID, T1.TestProtocolID
	)
	INSERT INTO @NonReservedCapacity(PeriodID, SlotID, TestProtocolID, NrOfTests)
	SELECT 
		T1.PeriodID, 
		T1.SlotID, 
		T1.TestProtocolID, 
		SUM(T2.NrOfTests)
	FROM CTE T1
	JOIN CTE T2 ON T1.SlotID >= T2.SlotID AND T1.TestProtocolID = T2.TestProtocolID AND T1.PeriodID = T2.PeriodID
	GROUP BY T1.PeriodID, T1.SlotID, T1.TestProtocolID;

	--calculate and transpose slot test protocol wise

	;WITH CTE2 AS
	(
		 SELECT 
			T1.PeriodID,
			T1.SlotID, 
			T1.TestProtocolID, 
			TestProtocolID2 = T1.TestProtocolID, 
			NrOfTests = T1.NrOfTests + T2.NrOfTests
		 FROM @NonReservedCapacity T1
		 JOIN @ReservedCapacity T2 ON T2.PeriodID = T1.PeriodID AND T2.TestProtocolID = T1.TestProtocolID
	)
	SELECT 
		T4.PeriodID,
		Samples = CASE 
				    WHEN ISNULL(T1.Markers, 0) <> ISNULL(RC.NrOfTests, 0) THEN 
					   CAST(RC.NrOfTests AS VARCHAR(10)) + '' ( '' + CAST((T1.Markers - RC.NrOfTests) AS VARCHAR(10)) + '' )'' 
				    ELSE 
					   CAST(T1.Markers AS VARCHAR(10)) 
				END, 
		T1.SlotID,
		' + @TCols1 + N',
		T4.BreedingStationCode, 
		T4.CropCode, 
		T4.SlotName, 
		T4.RequestUser, 
		T3.TestProtocolName, 
		T4.PlannedDate,
		T4.SiteID,
	    TotalWeeks = 
	    (
		    SELECT 
			    COUNT(PP.PeriodID) 
		    FROM [Period] PP
		    WHERE PP.StartDate >  @CurrentPeriodEndDate
		    AND PP.EndDate <= 
		    (
			    SELECT TOP 1
				    PPP.EndDate 
			    FROM [Period] PPP
			    WHERE T4.PlannedDate BETWEEN PPP.StartDate AND PPP.EndDate
		    )
	    )
	FROM 
	(
		SELECT T1.SlotID, MAX(ISNULL([Markers], 0)) As [Markers] 
		FROM 
		(
			SELECT SlotID, [Markers]
			FROM
			(
				SELECT
				    T1.SlotID, 
					T1.NrOfTests,
					Protocol1 = CASE WHEN T1.TestProtocolID = @MarkerTestProtocolID THEN ''Markers'' ELSE ''Plates'' END
				FROM @TblReservedCapicity T1
				WHERE T1.StatusCode = 100 
			) AS V1
			PIVOT 
			(
				SUM(NrOfTests)
				FOR Protocol1 IN ([Markers])
			) AS V2			
		) T1
		GROUP BY T1.SlotID
	) T1
	JOIN Slot T4 ON T4.SlotID = T1.SlotID AND T4.SiteID = ISNULL(@SiteID,0)
	JOIN 
	(
	   SELECT 
		  SlotID,
		  NrOfTests = SUM(T1.NrOfTests)
	   FROM ReservedCapacity T1
	   GROUP BY T1.SlotID
    ) RC ON RC.SlotID = T1.SlotID
    LEFT JOIN
	(
		SELECT 
			RC.SlotID, 
			TP.TestProtocolID, 
			TP.TestProtocolName			 
		FROM ReservedCapacity RC 
		JOIN TestProtocol TP ON RC.TestProtocolID = TP.TestProtocolID
		WHERE RC.TestProtocolID <> @MarkerTestProtocolID
	) T3 ON T3.SlotID = T1.SlotID
	LEFT JOIN
	(
		 SELECT SlotID, ' + @TCols2 + N' 
		 FROM
		 (
			  SELECT 
				   SlotID,
				  ' + @TCols1 + N'
			  FROM CTE2 T1
			  PIVOT
			  (
				   MAX(NrOfTests)
				   FOR TestProtocolID IN (' + @TCols1 + N')
			  ) AS T2			  
		 ) V1
		 GROUP BY SlotID
	) T2 ON T2.SlotID = T1.SlotID
    ORDER BY T4.PeriodID, T1.SlotID'

	--SELECT @SQL;

	EXEC sp_executesql @SQL, N'@CurrentPeriodEndDate DATETIME, @Periods TVP_PLAN_Period READONLY, @TblReservedCapicity TVP_ReservedCapacity READONLY, @SiteID INT', @CurrentPeriodEndDate, @Periods, @TblReservedCapicity, @SiteID;

END
GO


DROP PROCEDURE IF EXISTS [dbo].[PR_LFDISK_GetPlanApprovalListForLAB]
GO

/*
Authror					Date				Description
Krishna Gautam			
Krishna Gautam			2021/06/22			#22626: Added site location.

============Example==================
EXEC PR_LFDISK_GetPlanApprovalListForLAB 1, 4844
*/


CREATE PROCEDURE [dbo].[PR_LFDISK_GetPlanApprovalListForLAB]
(
	@SiteID INT,
	@PeriodID	INT = NULL
) AS BEGIN
	SET NOCOUNT ON;
		
	DECLARE @SQL		NVARCHAR(MAX);

	--Prepare 8 periods to display
	DECLARE @Periods TVP_PLAN_Period;
	
	IF(ISNULL(@PeriodID, 0) <> 0) BEGIN
		INSERT INTO @Periods(PeriodID) 
		SELECT TOP 8 
			PeriodID
		FROM [Period] 
		WHERE PeriodID >= @PeriodID
		ORDER BY PeriodID;
	END

	
	
	ELSE BEGIN
		--get current period
		EXEC @PeriodID = PR_PLAN_GetCurrentPeriod;
		
		INSERT INTO @Periods(PeriodID) 
		SELECT TOP 8 
			PeriodID
		FROM [Period] 
		WHERE PeriodID >= @PeriodID
		ORDER BY PeriodID;

		SELECT * FROM @Periods;
	END

	--Get standard values 
	SET @SQL = N'SELECT 
		PeriodName = CONCAT(PeriodName, FORMAT(StartDate, '' (MMM-dd - '', ''en-US'' ), FORMAT(EndDate, ''MMM-dd)'', ''en-US'' )), 
		PR.Remark, T1.PeriodID, T2.*
	FROM [Period] T1
	LEFT JOIN PeriodRemark PR ON PR.PeriodID = T1.PeriodID AND ISNULL(PR.TestTypeID,0) = 9 AND ISNULL(PR.SiteID,0) = @SiteID
	LEFT JOIN
	(' +
		dbo.FN_LFDISK_GetAvailableCapacityByPeriodsQuery(@SiteID)			
	+ N') T2 ON T2.PID = T1.PeriodID
	WHERE T1.PeriodID IN (SELECT PeriodID FROM @Periods)
	ORDER BY T1.PeriodID;'

	--PRINT @SQL;

	EXEC sp_executesql @SQL, N'@Periods TVP_PLAN_Period READONLY, @SiteID INT', @Periods,@SiteID;
	
	--get current values
	SET @SQL = dbo.FN_LFDISK_GetReservedCapacityByPeriodsQuery(@SiteID);

	
	EXEC sp_executesql @SQL, N'@Periods TVP_PLAN_Period READONLY, @SiteID INT', @Periods, @SiteID;

	--get columns list
	SELECT TestProtocolID = CAST(TestProtocolID AS VARCHAR(10)), 
			TestProtocolName
	FROM TestProtocol TP
	WHERE TP.TestTypeID = 9

	--Get summary period and slot wise
	EXEC PR_LFDISK_GetPlanApprovalListBySlotForLAB @SiteID, @Periods;
END

GO


