
/*
=============================================
Author:					Date				Remark
Binod Gurung			2021/06/02			Lab capacity screen for Leaf disk
=========================================================================

EXEC PR_LFDISK_GetCapacity 2021
*/
ALTER PROCEDURE [dbo].[PR_LFDISK_GetCapacity]
(
	@Year INT = NULL
) AS
BEGIN	
	DECLARE @SQL NVARCHAR(MAX), @PeriodName NVARCHAR(MAX), @Where NVARCHAR(MAX) = '', @InnerSQL NVARCHAR(MAX), @TestTypeID INT = 9; -- testtypeid 9 for Leaf disk
	DECLARE @ColumnTable TABLE(ColumnID NVARCHAR(MAX), Label NVARCHAR(MAX),[Order] INT, IsVisible BIT,Editable BIT, DataType NVARCHAR(MAX));

	IF(ISNULL(@Year,0)<>0) BEGIN
		SET @Where = 'WHERE Year(P.StartDate) = '+CAST(@Year AS NVARCHAR(MAX))+' OR Year(P.EndDate) = '+CAST(@Year AS NVARCHAR(MAX));
	END

	SET @PeriodName = 'Concat(P.PeriodName, ''('',Concat(FORMAT(P.StartDate,''MMM-d'',''en-US''),''-'',FORMAT(P.EndDate,''MMM-d'',''en-US'')),'')'') AS PeriodName';

	SET @InnerSQL = dbo.FN_LFDISK_GetAvailableCapacityByPeriodsQuery();

	IF(ISNULL(@InnerSQL,'') = '') BEGIN
		EXEC PR_ThrowError 'No Protocol found for saving NoOfTest(Samples)';
		RETURN;
	END
	
	SET @SQL = N'SELECT '+@PeriodName+', P.Remark, T.*, P.PeriodID
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
	VALUES('PeriodID','PeriodID',0,0,0,'Number')
	,('PeriodName','PeriodName',1,1,0,'String')
	,('Remark','Remark',@maxOrder +1,1,1, 'String');

	SELECT * FROM @ColumnTable order by [order]

END


