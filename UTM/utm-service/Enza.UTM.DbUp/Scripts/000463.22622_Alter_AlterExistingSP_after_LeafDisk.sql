DROP FUNCTION IF EXISTS [dbo].[FN_PLAN_GetAvailableCapacityByPeriodsQuery]
GO

/*
	DECLARE @SQL NVARCHAR(MAX) = dbo.FN_PLAN_GetAvailableCapacityByPeriodsQuery();
	EXEC sp_executesql @SQL;
	PRINT @SQL
*/
CREATE FUNCTION [dbo].[FN_PLAN_GetAvailableCapacityByPeriodsQuery]()
RETURNS NVARCHAR(MAX)
AS BEGIN
	DECLARE @TCols1 NVARCHAR(MAX), @TCols2 NVARCHAR(MAX),@PCols1 NVARCHAR(MAX), @PCols2 NVARCHAR(MAX);
	SELECT 
		@TCols1 = COALESCE(@TCols1 + ',', '') + QUOTENAME(TestProtocolID),
		@TCols2 = COALESCE(@TCols2 + ',', '') + QUOTENAME(TestProtocolID) + ' = ' + 'MAX(ISNULL(' + QUOTENAME(TestProtocolID) + ', 0))'
	FROM TestProtocol TP
	JOIN TestType TT ON TT.TestTypeID = TP.TestTypeID 
	WHERE Isolated = 0 
	AND TT.DeterminationRequired = 1
	AND TP.TestTypeID IN (1,2); --2GB Marker test and DNA Isolation

	SELECT 
		@PCols1 = COALESCE(@PCols1 + ',', '') + QUOTENAME(TestProtocolID),
		@PCols2 = COALESCE(@PCols2 + ',', '') + QUOTENAME(TestProtocolID) + ' = ' + 'MAX(ISNULL(' + QUOTENAME(TestProtocolID) + ', 0))'
	FROM TestProtocol TP
	JOIN TestType TT ON TT.TestTypeID = TP.TestTypeID 
	WHERE Isolated = 0 
	AND TT.DeterminationRequired = 0
	AND TP.TestTypeID IN (1,2); --2GB Marker test and DNA Isolation

	IF(ISNULL(@PCols2,'')= '' OR ISNULL(@TCols2,'')= '') BEGIN		
		RETURN '';
	END

	DECLARE @SQL NVARCHAR(MAX);
	SET @SQL = N'SELECT * FROM
	(
		SELECT PeriodID AS PID, ' + @TCols2 + ',' +  @PCols2 + N' 
		FROM
		(
			SELECT * FROM
			(
				SELECT
					PeriodID,
					TestProtocolID = TestProtocolID ,
					TestProtocolID2 = TestProtocolID,
					NrOfTests,
					NrOfPlates
				FROM AvailCapacity
			) V1
			PIVOT
			(
				MAX(NrOfTests)
				FOR TestProtocolID IN (' + @TCols1 + N')
			) AS V2
			PIVOT
			(
				MAX(NrOfPlates)
				FOR TestProtocolID2 IN (' + @PCols1 + N')
			) AS V4
		) V5
		GROUP BY PeriodID
	) AS V';

	RETURN @SQL;
END 
GO


DROP PROCEDURE IF EXISTS [dbo].[PR_PLAN_GetCapacity]
GO


/*
EXEC PR_PLAN_GetCapacity 2018
*/
CREATE PROCEDURE [dbo].[PR_PLAN_GetCapacity]
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
	
	SET @SQL = N'SELECT '+@PeriodName+', P.Remark,P.PeriodID, T.*
					FROM [Period] P
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


DROP PROCEDURE IF EXISTS [dbo].[PR_PLAN_SaveCapacity]
GO


-- =============================================
-- Author:		Binod Gurung
-- Create date: 2018/03/12
-- Description:	Save Capacity
-- =============================================
CREATE PROCEDURE [dbo].[PR_PLAN_SaveCapacity]
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
		MERGE INTO Period T
		USING 
		(
			SELECT PeriodID, [Value] FROM @TVP_Capacity 
			WHERE PivotedColumn = 'remark'
		) S
		ON T.PeriodID = S.PeriodID
		WHEN MATCHED THEN
			UPDATE
			SET T.Remark = S.[Value] ;
		
		COMMIT;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK;
		THROW;
	END CATCH
    
END
GO


