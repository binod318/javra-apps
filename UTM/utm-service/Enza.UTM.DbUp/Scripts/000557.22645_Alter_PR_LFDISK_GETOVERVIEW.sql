DROP PROCEDURE IF EXISTS [dbo].[PR_LFDISK_GETOVERVIEW]
GO



/*
Author					Date				Description
KRIAHNA GAUTAM			2021-06-27			#22645:SP created.

============Example===================
EXEC PR_LFDISK_GETOVERVIEW 'ON',1,100,'',0,1
*/

CREATE PROCEDURE [dbo].[PR_LFDISK_GETOVERVIEW]
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

	INSERT INTO @TblColumn(ColumnID,ColumnLabel,[Order],Visible,DataType,Editable,AllowFilter,AllowSort)
	VALUES
	('TestID','TestID',0,0,'integer',0,0,0),
	('CropCode','Crop',1,1,'string',0,1,0),
	('BreedingStationCode','Br.Station',2,1,'string',0,1,0),
	('TestName','Test Name',3,1,'string',0,1,0),
	('LabPlatePlanName','Folder',4,1,'string',0,1,0),
	('PlannedDate','PlannedDate',5,1,'string',0,1,0),
	('StatusName','Status',6,1,'string',0,1,0),
	('UsedSamples','Used Sample',7,1,'string',0,1,0),
	('StatusCode','StatusCode',8,1,'string',0,1,0),
	('SiteName','Site',9,1,'string',0,1,0)

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
							--Crop = F.CropCode, 
							F.CropCode,
							--[BreedingStation] = T.BreedingStationCode , 
							T.BreedingStationCode,
							--[Test] = T.TestName,
							T.TestName,
							--[Folder] = T.LabPlatePlanName, 
							T.LabPlatePlanName, 
							T.PlannedDate, 
							--[Status] = Stat.StatusName, 
							Stat.StatusName,
							T1.UsedSamples,
							T.StatusCode,
							SL.SiteName
						FROM Test T
						JOIN [File] F ON F.FileID = T.FileID
						JOIN #Status Stat ON Stat.StatusCode = T.StatusCode
						JOIN SiteLocation SL ON SL.SiteID = T.SiteID
						LEFT JOIN
						(
							SELECT UsedSamples = COUNT(ST.SampleID), ST.TestID FROM  LD_Sample S
							JOIN LD_SampleTest ST ON ST.SampleID = S.SampleID
							JOIN LD_SampleTestMaterial STM ON STM.SampleTestID = ST.SampleTestID
							GROUP BY ST.TestID	--ST.SampleID												
						) T1 ON T.TestID = T1.TestID
						WHERE T.TestTypeID = 9 AND F.CropCode IN  ('+@CropCodes +') AND T.CreationDate >= DATEADD(YEAR,-1,GetDate())
					) T1 '+@Filter+'
				), COUNT_CTE AS (SELECT COUNT(CropCode) AS TotalRows FROM CTE)
				SELECT CTE.*,
				Count_CTE.[TotalRows] FROM CTE,COUNT_CTE
				ORDER BY CTE.PlannedDate DESC
				OFFSET '+CAST(@offset AS varchar(MAX))+' ROWS
				FETCH NEXT '+CAST (@pageSize AS VARCHAR(MAX))+' ROWS ONLY'

	EXEC sp_executesql @Query;

	SELECT * FROM @TblColumn ORDER BY [Order];

	DROP TABLE #Status

END
GO


