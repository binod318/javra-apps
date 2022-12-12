DROP FUNCTION IF EXISTS [dbo].[FN_LFDISK_GetAvailableCapacityByPeriodsQuery]
GO

/*
	DECLARE @SQL NVARCHAR(MAX) = dbo.FN_LFDISK_GetAvailableCapacityByPeriodsQuery();
	EXEC sp_executesql @SQL;
	PRINT @SQL
*/
CREATE FUNCTION [dbo].[FN_LFDISK_GetAvailableCapacityByPeriodsQuery]()
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
		SELECT PeriodID, ' + @TCols2 + N' 
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


DROP PROCEDURE IF EXISTS [dbo].[PR_LFDISK_GetCapacity]
GO

/*
=============================================
Author:					Date				Remark
Binod Gurung			2021/06/02			Lab capacity screen for Leaf disk
=========================================================================

EXEC PR_LFDISK_GetCapacity 2021
*/
CREATE PROCEDURE [dbo].[PR_LFDISK_GetCapacity]
(
	@Year INT = NULL
) AS
BEGIN	
	DECLARE @SQL NVARCHAR(MAX), @PeriodName NVARCHAR(MAX), @Where NVARCHAR(MAX) = '', @InnerSQL NVARCHAR(MAX), @TestTypeID INT = 9; -- testtypeid 9 for Leaf disk
	DECLARE @ColumnTable TABLE(ColumnID NVARCHAR(MAX), Label NVARCHAR(MAX),[Order] INT, IsVisible BIT,Editable BIT);

	IF(ISNULL(@Year,0)<>0) BEGIN
		SET @Where = 'WHERE Year(P.StartDate) = '+CAST(@Year AS NVARCHAR(MAX))+' OR Year(P.EndDate) = '+CAST(@Year AS NVARCHAR(MAX));
	END

	SET @PeriodName = 'Concat(P.PeriodName, ''('',Concat(FORMAT(P.StartDate,''MMM-d'',''en-US''),''-'',FORMAT(P.EndDate,''MMM-d'',''en-US'')),'')'') AS PeriodName';

	SET @InnerSQL = dbo.FN_LFDISK_GetAvailableCapacityByPeriodsQuery();

	IF(ISNULL(@InnerSQL,'') = '') BEGIN
		EXEC PR_ThrowError 'No Protocol found for saving NoOfTest(Samples)';
		RETURN;
	END
	
	SET @SQL = N'SELECT '+@PeriodName+', P.Remark, T.*
					FROM [Period] P
					LEFT JOIN
					(
					'+@InnerSQL+'
					 
					) T ON P.PeriodID = T.PeriodID
					'+@Where+
					'ORDER BY P.PeriodID';
		
	EXEC sp_executesql @SQL;

	INSERT INTO @ColumnTable(ColumnID,Label,[Order],IsVisible,Editable)
	SELECT TestProtocolID = CAST(TestProtocolID AS NVARCHAR(10)),TestProtocolName,TestProtocolID + 1,1,1
	FROM TestProtocol
	WHERE TestTypeID = @TestTypeID

	DECLARE @maxOrder INT;
	SELECT @maxOrder = MAX([order]) FROM @ColumnTable

	INSERT INTO @ColumnTable(ColumnID,Label,[Order],IsVisible,Editable)
	VALUES('PeriodID','PeriodID',0,0,0)
	,('PeriodName','PeriodName',1,1,0)
	,('Remarks','Remarks',@maxOrder +1,1,1);

	SELECT * FROM @ColumnTable order by [order]

END
GO


DROP PROCEDURE IF EXISTS [dbo].[PR_LFDISK_SaveCapacity]
GO

/*
=============================================
Author:					Date				Remark
Binod Gurung			2021/06/02			Save Lab capacity for Leaf disk
=========================================================================
DECLARE @Table [TVP_PLAN_Capacity];

INSERT @Table(PeriodID, PivotedColumn, Value)
VALUES (4848,'1009', '2100')

EXEC PR_LFDISK_SaveCapacity @Table;
*/
CREATE PROCEDURE [dbo].[PR_LFDISK_SaveCapacity]
(
	@TVP_Capacity TVP_PLAN_Capacity READONLY
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
			SELECT * FROM @TVP_Capacity 
			WHERE ISNUMERIC(PivotedColumn) = 1
		) S
		ON T.PeriodID = S.PeriodID AND T.TestProtocolID = CAST(S.PivotedColumn AS INT)
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


