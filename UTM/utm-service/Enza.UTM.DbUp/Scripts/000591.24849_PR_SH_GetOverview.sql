DROP PROCEdURE IF EXISTS PR_SH_GetOverview
GO

/*
Author					Date				Description
KRIAHNA GAUTAM			2021-11-23			SP created.

============Example===================
EXEC PR_SH_GetOverview 'ON',1,100,'',0,1
*/
CREATE PROCEDURE [dbo].[PR_SH_GetOverview]
(
	
	@Crops NVARCHAR(MAX),
	@PageNumber INT,
	@pageSize INT,
	@Filter NVARCHAR(MAX),
	@ExportToExcel BIT = NULL,
	@Active	BIT  = NULL
)
AS
BEGIN
	
	DECLARE @Query NVARCHAR(MAX), @Offset INT,@CropCodes NVARCHAR(MAX), @SelectColumns NVARCHAR(MAX);
	DECLARE @TblColumn TVP_ColumnDetail;
    CREATE TABLE #Status(StatusCode INT, StatusName NVARCHAR(50));
	
	--we need to send ColumnID in default case with first character a small.
	INSERT INTO @TblColumn(ColumnID, ColumnLabel, [Order], Visible, DataType, Editable, AllowFilter, AllowSort, Width)
	VALUES
	('testID','TestID', 0, 0, 'integer', 0, 0, 0, 0),
	('cropCode','Crop',1,1,'string',0,1,0,70),
	('breedingStationCode','Br.Station',2,1,'string',0,1,0,100),
	('testName','Test Name',3,1,'string',0,1,0,200),
	('siteName','Site',4,1,'string',0,1,0,200),
	('absTestNumber','ABS Test Number',5,1,'string',0,1,0,200),
	('resultSummary','Test Result',7,1,'string',0,1,0,200),
	('statusName','Status',8,1,'string',0,1,0,200),
	('statusCode','StatusCode',9,0,'string',0,1,0,100);

	IF(ISNULL(@ExportToExcel,0) = 0)
	BEGIN
		SELECT 
			@SelectColumns = COALESCE(@SelectColumns + ',','') + QUOTENAME(ColumnID) 
		FROM @TblColumn;
	END
	ELSE
	BEGIN
		SELECT 
			@SelectColumns = COALESCE(@SelectColumns + ',','') + QUOTENAME(ColumnID) +' AS ' + QUOTENAME(ColumnLabel)
		FROM @TblColumn
		WHERE ISNULL(Visible,0) = 1;
	END


    INSERT #Status(StatusCode, StatusName)
    SELECT StatusCode, StatusName
    FROM [Status]
    WHERE StatusTable = 'Test';
    IF(@Active IS NOT NULL AND @Active = 0) BEGIN
	   DELETE #Status WHERE StatusCode <> 700;
    END
    ELSE IF (@Active IS NOT NULL AND @Active = 1) BEGIN
	   DELETE #Status WHERE StatusCode = 700;	   
    END

    SELECT @CropCodes = COALESCE(@CropCodes + ',', '') + ''''+ T.[value] +'''' FROM 
	   string_split(@Crops,',') T

    SET @Offset = @PageSize * (@PageNumber -1);

    IF(ISNULL(@Filter,'')<> '') BEGIN
	   SET @Filter = 'WHERE '+@Filter
    END
    ELSE
	   SET @Filter = '';
	   
	SET @Query =	N';WITH CTE AS 
				(
					SELECT '+@SelectColumns+' FROM 
					(
						SELECT 
							T.TestID, 
							T.TestTypeID,							
							F.CropCode,							
							T.BreedingStationCode,							
							T.TestName,							
							T.LabPlatePlanName,						
							Stat.StatusName,
							ResultSummary = T.LDResultSummary,
							T.StatusCode,
							SL.SiteName,
							absTestNumber = T.LabPlatePlanID 
						FROM Test T
						JOIN [File] F ON F.FileID = T.FileID
						JOIN #Status Stat ON Stat.StatusCode = T.StatusCode
						JOIN SiteLocation SL ON SL.SiteID = T.SiteID						
						WHERE T.TestTypeID = 10 AND F.CropCode IN  ('+@CropCodes +') AND T.CreationDate >= DATEADD(YEAR,-1,GetDate())
					) T1 '+@Filter+'
				), COUNT_CTE AS (SELECT COUNT(CropCode) AS TotalRows FROM CTE)
				SELECT CTE.*,
				Count_CTE.[TotalRows] FROM CTE,COUNT_CTE
				ORDER BY CTE.TestID DESC
				OFFSET '+CAST(@offset AS varchar(MAX))+' ROWS
				FETCH NEXT '+CAST (@pageSize AS VARCHAR(MAX))+' ROWS ONLY';


	PRINT @Query;

	EXEC sp_executesql @Query;

	SELECT * FROM @TblColumn ORDER BY [Order];

	DROP TABLE #Status

END
