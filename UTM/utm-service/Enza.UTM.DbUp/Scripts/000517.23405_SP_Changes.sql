--Create table
CREATE TABLE PeriodRemark
(
	PeriodRemarkID INT PRIMARY KEY IDENTITY(1,1),
	PeriodID INT,
	TestTypeID INT,
	SiteID INT,
	Remark NVARCHAR(MAX)
)
GO

--insert data
INSERT INTO PeriodRemark(PeriodID,Remark)
SELECT PeriodID,Remark FROM Period
WHERE ISNULL(Remark,'') <> '';
GO

--delete column remark from period
ALTER TABLE [Period]
DROP COLUMN Remark
GO


/*
EXEC PR_PLAN_GetCapacity 2018
*/
ALTER PROCEDURE [dbo].[PR_PLAN_GetCapacity]
(
	@Year INT = NULL
) AS
BEGIN	
	DECLARE @SQL NVARCHAR(MAX), @PeriodName NVARCHAR(MAX), @Where NVARCHAR(MAX) = '', @InnerSQL NVARCHAR(MAX) = dbo.FN_PLAN_GetAvailableCapacityByPeriodsQuery();
	IF(ISNULL(@Year,0)<>0) BEGIN
		SET @Where = 'WHERE Year(P.StartDate) = '+CAST(@Year AS NVARCHAR(MAX))+' OR Year(P.EndDate) = '+CAST(@Year AS NVARCHAR(MAX));
	END

	SET @PeriodName = 'Concat(P.PeriodName, ''('',Concat(FORMAT(P.StartDate,''MMM-d'',''en-US''),''-'',FORMAT(P.EndDate,''MMM-d'',''en-US'')),'')'') AS PeriodName';

	SET @InnerSQL = dbo.FN_PLAN_GetAvailableCapacityByPeriodsQuery();
	IF(ISNULL(@InnerSQL,'') = '') BEGIN
		EXEC PR_ThrowError 'No Protocol found for saving NoOfTest(Markers) or NoOfPlates';
		RETURN;
	END
	
	SET @SQL = N'SELECT '+@PeriodName+', PR.Remark,P.PeriodID, T.*
					FROM [Period] P
					LEFT JOIN PeriodRemark PR ON PR.PeriodID = P.PeriodID AND ISNULL(TestTypeID,0) = 0 AND ISNULL(SiteID,0) = 0
					LEFT JOIN
					(
					'+@InnerSQL+'
					 
					) T ON P.PeriodID = T.PID
					'+@Where+
					'ORDER BY P.PeriodID';
		
	EXEC sp_executesql @SQL;
	
	SELECT TestProtocolID = CAST(TestProtocolID AS NVARCHAR(10)),TestProtocolName
	FROM TestProtocol
	WHERE Isolated = 0
	AND TestTypeID IN (1,2); --2GB Marker test and DNA Isolation

END

GO

/*
=============================================
Author:					Date				Remark
Binod Gurung			2021/06/02			Lab capacity screen for Leaf disk
=========================================================================

EXEC PR_LFDISK_GetCapacity 2021,0
*/
ALTER PROCEDURE [dbo].[PR_LFDISK_GetCapacity]
(
	@Year INT = NULL,
	@SiteLocation INT = NULL
) AS
BEGIN	
	DECLARE @SQL NVARCHAR(MAX), @PeriodName NVARCHAR(MAX), @Where NVARCHAR(MAX) = '', @InnerSQL NVARCHAR(MAX), @TestTypeID INT = 9; -- testtypeid 9 for Leaf disk
	DECLARE @ColumnTable TABLE(ColumnID NVARCHAR(MAX), Label NVARCHAR(MAX),[Order] INT, IsVisible BIT,Editable BIT, DataType NVARCHAR(MAX));

	IF(ISNULL(@Year,0)<>0) BEGIN
		--SET @Where = 'WHERE Year(P.StartDate) = '+CAST(@Year AS NVARCHAR(MAX))+' OR Year(P.EndDate) = '+CAST(@Year AS NVARCHAR(MAX));
		SET @Where = 'WHERE '+ CAST(@Year AS NVARCHAR(MAX))+ ' BETWEEN YEAR(P.StartDate) AND YEAR(P.ENdDate) '
	END

	SET @PeriodName = 'Concat(P.PeriodName, ''('',Concat(FORMAT(P.StartDate,''MMM-d'',''en-US''),''-'',FORMAT(P.EndDate,''MMM-d'',''en-US'')),'')'') AS PeriodName';

	SET @InnerSQL = dbo.FN_LFDISK_GetAvailableCapacityByPeriodsQuery(@SiteLocation);

	IF(ISNULL(@InnerSQL,'') = '') BEGIN
		EXEC PR_ThrowError 'No Protocol found for saving NoOfTest(Samples)';
		RETURN;
	END
	
	SET @SQL = N'SELECT '+@PeriodName+', PR.Remark, T.* ,P.PeriodID
					FROM [Period] P
					LEFT JOIN PeriodRemark PR ON PR.PeriodID = P.PeriodID AND ISNULL(TestTypeID,0) = 9 AND ISNULL(SiteID,0) = ' +CAST( @SiteLocation  AS NVARCHAR(MAX))+' 
					LEFT JOIN
					(
					'+@InnerSQL+'
					 
					) T ON P.PeriodID = T.PID
					'+@Where+
					'ORDER BY P.PeriodID';

	PRINT @SQL;
		
	EXEC sp_executesql @SQL;

	INSERT INTO @ColumnTable(ColumnID,Label,[Order],IsVisible,Editable, DataType)
	SELECT TestProtocolID = CAST(TestProtocolID AS NVARCHAR(10)),TestProtocolName,TestProtocolID + 1,1,1, 'Number'
	FROM TestProtocol
	WHERE TestTypeID = @TestTypeID

	DECLARE @maxOrder INT;
	SELECT @maxOrder = MAX([order]) FROM @ColumnTable

	INSERT INTO @ColumnTable(ColumnID, Label, [Order], IsVisible, Editable, DataType)
	VALUES('PeriodID','PeriodID',0,0,0,'Number')
	,('PeriodName','PeriodName',1,1,0,'String')
	,('Remark','Remark',@maxOrder +1,1,1, 'String');

	SELECT * FROM @ColumnTable order by [order]

END
GO

--EXEC PR_PLAN_GetCurrentPeriod
ALTER PROCEDURE [dbo].[PR_PLAN_GetCurrentPeriod]
(
	@DetailAlso BIT = 0
)
AS BEGIN
	SET NOCOUNT ON;
	DECLARE @PeriodID INT;
	--DECLARE @today DATE = GETUTCDATE();
	DECLARE @today DATE = GETDATE();
	SELECT 
		@PeriodID = [PeriodID]
	FROM [Period] 
	WHERE @today BETWEEN StartDate AND EndDate;

	IF(ISNULL(@PeriodID, 0) = 0) BEGIN
		EXEC PR_ThrowError N'Couldn''t find period information in database.';
		RETURN 0;
	END

	IF (@DetailAlso = 1) BEGIN
		SELECT 
			[PeriodID], [PeriodName], [StartDate], [EndDate]
		FROM [Period] 
		WHERE @today BETWEEN StartDate AND EndDate;
	END
	RETURN @PeriodID;
END

GO



ALTER PROCEDURE [dbo].[PR_PLAN_GetPlanPeriods]
(
	@Year INT = NULL,
	@TestTypeID INT = NULL,
	@SiteID INT = NULL
)
AS BEGIN
	SET NOCOUNT ON;

	SELECT P.[PeriodID]
        ,PeriodName = CONCAT(PeriodName, FORMAT(StartDate, ' (MMM-dd-yy - ', 'en-US' ), FORMAT(EndDate, 'MMM-dd-yy)', 'en-US' ))
        ,[StartDate]
        ,[EndDate]
        ,PR.[Remark]
    FROM [Period] P
	LEFT JOIN PeriodRemark PR ON PR.PeriodID = P.PeriodID AND ISNULL(PR.TestTypeID,0) = ISNULL(@TestTypeID,0) AND ISNULL(PR.SiteID,0) = ISNULL(@SiteID,0)
	WHERE ISNULL(@Year, 0) = 0 
	OR @Year BETWEEN DATEPART(YEAR, StartDate) AND DATEPART(YEAR, EndDate);
END
GO


ALTER PROCEDURE [dbo].[PR_PLAN_GetCurrentPeriod]
(
	@DetailAlso BIT = 0,
	@TestTypeID INT = NULL,
	@SiteID INT = NULL
)
AS BEGIN
	SET NOCOUNT ON;
	DECLARE @PeriodID INT;
	--DECLARE @today DATE = GETUTCDATE();
	DECLARE @today DATE = GETDATE();
	SELECT 
		@PeriodID = [PeriodID]
	FROM [Period] 
	WHERE @today BETWEEN StartDate AND EndDate;

	IF(ISNULL(@PeriodID, 0) = 0) BEGIN
		EXEC PR_ThrowError N'Couldn''t find period information in database.';
		RETURN 0;
	END

	IF (@DetailAlso = 1) BEGIN
		SELECT 
			P.[PeriodID], [PeriodName], [StartDate], [EndDate],PR.Remark
		FROM [Period] P
		LEFT JOIN PeriodRemark PR ON PR.PeriodID = P.PeriodID AND ISNULL(PR.TestTypeID,0) = ISNULL(@TestTypeID,0) AND ISNULL(PR.SiteID,0) = ISNULL(@SiteID,0)
		WHERE @today BETWEEN StartDate AND EndDate;
	END
	RETURN @PeriodID;
END
GO

--EXEC PR_PLAN_GetPlanApprovalListForLAB 4844
ALTER PROCEDURE [dbo].[PR_PLAN_GetPlanApprovalListForLAB]
(
	@PeriodID	INT = NULL
) AS BEGIN
	SET NOCOUNT ON;
	
	DECLARE @ARGS		NVARCHAR(MAX);
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
	END

	--Get standard values 
	SET @SQL = N'SELECT 
		PeriodName = CONCAT(PeriodName, FORMAT(StartDate, '' (MMM-dd - '', ''en-US'' ), FORMAT(EndDate, ''MMM-dd)'', ''en-US'' )), 
		PR.Remark, T1.PeriodID, T2.*
	FROM [Period] T1
	LEFT JOIN PeriodRemark PR ON PR.PeriodID = T1.PeriodID AND ISNULL(PR.TestTypeID,0) = 0 AND ISNULL(PR.SiteID,0) = 0
	LEFT JOIN
	(' +
		dbo.FN_PLAN_GetAvailableCapacityByPeriodsQuery()			
	+ N') T2 ON T2.PID = T1.PeriodID
	WHERE T1.PeriodID IN (SELECT PeriodID FROM @Periods)
	ORDER BY T1.PeriodID;'

	EXEC sp_executesql @SQL, N'@Periods TVP_PLAN_Period READONLY', @Periods;
	
	----get current values
	--SET @SQL = dbo.FN_PLAN_GetReservedCapacityByPeriodsQuery() + 
	--	N' WHERE PeriodID IN (SELECT PeriodID FROM @Periods);'
	
	--EXEC sp_executesql @SQL, N'@Periods TVP_PLAN_Period READONLY', @Periods;

	--get current values
	SET @SQL = dbo.FN_PLAN_GetReservedCapacityByPeriodsQuery();

	EXEC sp_executesql @SQL, N'@Periods TVP_PLAN_Period READONLY', @Periods;

	--get columns list
	SELECT TestProtocolID, TestProtocolName,CalculationFor
	FROM
	(
		SELECT
			0 AS DisplayOrder, 
			TestProtocolID = CAST(TestProtocolID AS VARCHAR(10)), 
			TestProtocolName,
			CalculationFor = 'ExpectedPeriod'
		FROM TestProtocol TP
		JOIN TestType TT ON TT.TestTypeID = TP.TestTypeID 
		WHERE TP.Isolated = 0
		AND TT.DeterminationRequired = 1
		AND TT.TestTypeID IN (1,2)
		UNION
		SELECT 
			1 AS DisplayOrder, 
			TestProtocolID = CAST(TestProtocolID AS VARCHAR(10)), 
			TestProtocolName,
			CalculationFor = 'PlannedPeriod'
		FROM TestProtocol TP
		JOIN TestType TT ON TT.TestTypeID = TP.TestTypeID 
		WHERE TP.Isolated = 0
		AND TT.DeterminationRequired = 0
		AND TT.TestTypeID in (1,2)
	) V
	ORDER BY DisplayOrder;

	--Get summary period and slot wise
	DELETE FROM @Periods;

	INSERT INTO @Periods(PeriodID) 
		SELECT TOP 4 
			PeriodID
		FROM [Period] 
		WHERE PeriodID < @PeriodID
		ORDER BY PeriodID DESC;

	INSERT INTO @Periods(PeriodID) 
		SELECT TOP 11 
			PeriodID
		FROM [Period] 
		WHERE PeriodID >= @PeriodID
		ORDER BY PeriodID;

	EXEC PR_PLAN_GetPlanApprovalListBySlotForLAB @Periods
END
GO

-- =============================================
-- Author:		Binod Gurung
-- Create date: 2018/03/12
-- Description:	Save Capacity
-- =============================================
ALTER PROCEDURE [dbo].[PR_PLAN_SaveCapacity]
(
	@TVP_Capacity TVP_PLAN_Capacity READONLY
)
AS
BEGIN
	
	SET NOCOUNT ON;

	DECLARE @MarkerTypeTestProtocolID INT = 0;

	BEGIN TRY
		BEGIN TRANSACTION;
		
		--Find TestProtocolID for Marker Test
		SELECT 
			@MarkerTypeTestProtocolID = TP.TestProtocolID 
		FROM TestProtocol TP
		JOIN TestType TT ON TT.TestTypeID = TP.TestTypeID
		WHERE TT.DeterminationRequired = 1
		AND TP.TestTypeID IN (1,2); --2GB Marker test and DNA Isolation
						
		-- Insert / Update NrOfTests (For Marker Test)
		MERGE INTO AvailCapacity T
		USING 
		(
			SELECT * FROM @TVP_Capacity 
			WHERE ISNUMERIC(PivotedColumn) = 1 AND PivotedColumn = @MarkerTypeTestProtocolID
		) S
		ON T.PeriodID = S.PeriodID AND T.TestProtocolID = @MarkerTypeTestProtocolID
		WHEN NOT MATCHED THEN
			INSERT 
			(
				PeriodID, 
				TestProtocolID,
				NrOfTests
			)
			VALUES 
			(
				S.PeriodID, 
				CAST(PivotedColumn AS INT),
				CAST([Value] AS INT )
			)

		WHEN MATCHED THEN
			UPDATE
			SET T.NrOfTests  = CAST([Value] AS INT ) ;

		--Insert / Update NrOfPlates (For DNA Isolation)
		MERGE INTO AvailCapacity T
		USING 
		(
			SELECT * FROM @TVP_Capacity 
			WHERE ISNUMERIC(PivotedColumn) = 1 AND PivotedColumn <> @MarkerTypeTestProtocolID
		) S
		ON T.PeriodID = S.PeriodID AND T.TestProtocolID = CAST(S.PivotedColumn AS INT)
		WHEN NOT MATCHED THEN
			INSERT 
			(
				PeriodID, 
				TestProtocolID, 
				NrOfPlates
			)
			VALUES 
			(
				S.PeriodID, 
				CAST(PivotedColumn AS INT),
				CAST([Value] AS INT )
			)

		WHEN MATCHED THEN
			UPDATE
			SET T.NrOfPlates = CAST([Value] AS INT ) ;

		--Update Remark
		MERGE INTO PeriodRemark T
		USING 
		(
			SELECT PeriodID, [Value] FROM @TVP_Capacity 
			WHERE PivotedColumn = 'remark'
		) S
		ON T.PeriodID = S.PeriodID AND ISNULL(T.TestTypeID,0) = 0 AND ISNULL(T.SiteID,0) = 0
		WHEN MATCHED THEN
			UPDATE
			SET T.Remark = S.[Value] 
		WHEN NOT MATCHED THEN
			INSERT(PeriodID,Remark)
			VALUES(S.PeriodID,S.[Value]);

		COMMIT;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK;
		THROW;
	END CATCH
    
END
GO


DROP VIEW IF EXISTS [dbo].[VW_Period]
GO


CREATE VIEW [dbo].[VW_Period] AS
SELECT 
	P.PeriodID,
	P.PeriodName,
	PeriodName2 = CONCAT(P.PeriodName, FORMAT(P.StartDate, ' (MMM-dd-yy - ', 'en-US' ), FORMAT(P.EndDate, 'MMM-dd-yy)', 'en-US' )),
	P.StartDate,
	P.EndDate
FROM [Period] P
GO

/*
=============================================
Author:					Date				Remark
Binod Gurung			2021/06/02			Save Lab capacity for Leaf disk
=========================================================================
DECLARE @Table [TVP_PLAN_Capacity];

INSERT @Table(PeriodID, PivotedColumn, Value)
VALUES (4848,1009, 2100)

EXEC PR_LFDISK_SaveCapacity  @Table, 1;
*/
ALTER PROCEDURE [dbo].[PR_LFDISK_SaveCapacity]
(
	@TVP_Capacity TVP_PLAN_Capacity READONLY,
	@SiteID INT
)
AS
BEGIN
	
	SET NOCOUNT ON;

	BEGIN TRY
		BEGIN TRANSACTION;	
		
		-- Insert / Update NrOfTests (Samples) : if PivotedColumn is numeric else Remark
		MERGE INTO AvailCapacity T
		USING 
		(
			SELECT PeriodID, PivotedColumn, [Value] = MAX([Value]) FROM @TVP_Capacity
			WHERE ISNUMERIC(PivotedColumn) = 1
			GROUP BY PeriodID, PivotedColumn
			
		) S
		ON T.PeriodID = S.PeriodID AND T.TestProtocolID = CAST(S.PivotedColumn AS INT) AND ISNULL(@SiteID,0) = ISNULL(T.SiteID,0)
		WHEN NOT MATCHED THEN
			INSERT 
			(
				PeriodID, 
				TestProtocolID,
				NrOfTests,
				SiteID
			)
			VALUES 
			(
				S.PeriodID, 
				CAST(PivotedColumn AS INT),
				CAST([Value] AS INT ),
				@SiteID
			)

		WHEN MATCHED THEN
			UPDATE
			SET T.NrOfTests  = CAST([Value] AS INT) ;

		--Update Remark
		MERGE INTO PeriodRemark T
		USING 
		(
			SELECT PeriodID, [Value] = MAX([Value]) FROM @TVP_Capacity 
			WHERE PivotedColumn = 'remark'
			GROUP BY PeriodID
		) S
		ON T.PeriodID = S.PeriodID AND T.TestTypeID = 9 AND T.SiteID = @SiteID
		WHEN MATCHED THEN
			UPDATE
			SET T.Remark = S.[Value]
		WHEN NOT MATCHED THEN
		INSERT(PeriodID,TestTypeID,SiteID,Remark)
		VALUES(S.PeriodID,9,@siteID,S.[Value]);
		
		COMMIT;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK;
		THROW;
	END CATCH
    
END
GO