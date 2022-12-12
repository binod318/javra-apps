ALTER TABLE AvailCapacity
ADD SiteID INT
GO

ALTER TABLE AvailCapacity
ADD FOREIGN KEY (SiteID) REFERENCES SiteLocation(SiteID)
GO

ALTER TABLE Slot
ADD SiteID INT 
GO

ALTER TABLE Slot
ADD FOREIGN KEY (SiteID) REFERENCES SiteLocation(SiteID)
GO



/*
	DECLARE @SQL NVARCHAR(MAX) = dbo.FN_LFDISK_GetAvailableCapacityByPeriodsQuery();
	PRINT @SQL
	EXEC sp_executesql @SQL;
	PRINT @SQL
*/
ALTER FUNCTION [dbo].[FN_LFDISK_GetAvailableCapacityByPeriodsQuery]
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
	
	SET @SQL = N'SELECT '+@PeriodName+', P.Remark, T.* ,P.PeriodID
					FROM [Period] P
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
	VALUES('PeriodID','PeriodID',0,0,0,'intiger')
	,('PeriodName','PeriodName',1,1,0,'String')
	,('Remark','Remark',@maxOrder +1,1,1, 'String');

	SELECT * FROM @ColumnTable order by [order]

END

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
		MERGE INTO [Period] T
		USING 
		(
			SELECT PeriodID, [Value] = MAX([Value]) FROM @TVP_Capacity 
			WHERE PivotedColumn = 'remark'
			GROUP BY PeriodID
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