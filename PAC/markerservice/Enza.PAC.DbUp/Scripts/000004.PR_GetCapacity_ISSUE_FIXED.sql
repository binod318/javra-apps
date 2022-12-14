/*
	EXEC PR_GetCapacity 2019

*/
CREATE OR ALTER PROCEDURE [dbo].[PR_GetCapacity]
(
	@Year INT = NULL
) AS
BEGIN	
	DECLARE @SQL NVARCHAR(MAX), @PeriodName NVARCHAR(MAX), @Where NVARCHAR(MAX) = '', @ColumnsIDs NVARCHAR(MAX), @ColumnsIDs2 NVARCHAR(MAX);

	DECLARE @ColumnTable TABLE(ColumnID NVARCHAR(MAX), Label NVARCHAR(MAX),[Order] INT, IsVisible BIT,Editable BIT);

	IF(ISNULL(@Year,0)<>0) BEGIN
		SET @Where = 'WHERE Year(P.StartDate) = '+CAST(@Year AS NVARCHAR(MAX))+' OR Year(P.EndDate) = '+CAST(@Year AS NVARCHAR(MAX));
	END

	ELSE
	BEGIN
		SET @Where = '';
	END

	SELECT 
		@ColumnsIDs = COALESCE(@ColumnsIDS+',','') + QUOTENAME(PlatformID),
		@ColumnsIDs2 = COALESCE(@ColumnsIDS2+',','') + 'MAX(' + QUOTENAME(PlatformID) + ') AS ' + QUOTENAME(PlatformID)
	FROM [Platform]
	WHERE StatusCode = 100

	IF(ISNULL(@ColumnsIDs,'') = '') BEGIN
		EXEC PR_ThrowError 'No Platform found.';
		RETURN;
	END


	SET @SQL = N'	
				SELECT P.PeriodID, PeriodName2 AS PeriodName, ' +@ColumnsIDs+ ', T1.Remarks FROM [VW_Period] P
				LEFT JOIN 
				(
					SELECT PeriodID,MAX(Remarks) AS Remarks,'+@ColumnsIDs2+'
					FROM 
					(
						SELECT PlatFormID,Remarks,PeriodID,NrOfPlates FROM Capacity
					)
					SRC
					PIVOT
					(
						MAX(NrOfPlates)
						FOR PlatformID IN ('+@ColumnsIDs+')
					)
					PT
					GROUP BY PeriodID
				) T1
				ON T1.PeriodID = P.PeriodID '
				+@Where +
				' ORDER BY P.PeriodID';
		
	--PRINT @SQL;
	EXEC sp_executesql @SQL;

	INSERT INTO @ColumnTable(ColumnID,Label,[Order],IsVisible,Editable)
	SELECT PlatformID,PlatformDesc,PlatformID + 1,1,1
	FROM [Platform]
	WHERE StatusCode = 100;

	DECLARE @maxOrder INT;
	SELECT @maxOrder = MAX([order]) FROM @ColumnTable

	INSERT INTO @ColumnTable(ColumnID,Label,[Order],IsVisible,Editable)
	VALUES('PeriodID','PeriodID',0,0,0)
	,('PeriodName','PeriodName',1,1,0)
	,('Remarks','Remarks',@maxOrder +1,1,1);

	SELECT * FROM @ColumnTable order by [order]
	
END
GO