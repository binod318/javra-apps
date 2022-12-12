/*
Author					Date			Description
Krishna Gautam			2021/06/02		#22627:	Stored procedure created

===================================Example================================

-- EXEC PR_LFDISK_GetSlotsForBreeder 'ON', 'NLEN', 1, 200, '',0
-- EXEC PR_PLAN_GetSlotsForBreeder 'To', 'NLEN', 1, 200, 'PeriodName like ''%-13-20%'''
*/


ALTER PROCEDURE [dbo].[PR_LFDISK_GetSlotsForBreeder]
(
	@CropCode		NVARCHAR(10),
	@BrStationCode	NVARCHAR(50),
	@Page			INT,
	@PageSize		INT,
	@Filter			NVARCHAR(MAX) = NULL,
	@ExportToExcel  BIT = NULL
)
AS BEGIN
    SET NOCOUNT ON;
    DECLARE @SQL NVARCHAR(MAX), @SelectColumns NVARCHAR(MAX), @SelectColumns1 NVARCHAR(MAX);
    DECLARE @Offset INT;
	--DECLARE @ColumnTable TABLE(ColumnID NVARCHAR(MAX), Label NVARCHAR(MAX),[Order] INT, Visible BIT, Editable BIT, DataType NVARCHAR(MAX));

    SET @Offset = @PageSize * (@Page -1);
	SET @SelectColumns = '*'
	IF(ISNULL(@ExportToExcel,0) =1)
	BEGIN
		SET @SelectColumns = '	SlotID, 
								PeriodID,
								CropCode AS [Crop], 
								SlotName As [Slot Name] ,
								BreedingStationCode AS [Br.Station],
								PeriodName AS [Period Name],
								SiteName AS [Lab Location],
								MaterialTypeCode AS [Material Type],
								TestProtocolName AS [Method],
								NrOfTests AS [Total Sample],
								AvailableSample AS [Available Sample],
								RequestUser AS [Requestor],
								StatusName AS Status,
								Remark'
	END

    SET @SQL = N'
				;WITH CTE AS
				(
					SELECT '+@SelectColumns+' FROM 
					(
						SELECT * FROM 
						(
							SELECT 
								S.SlotID,
								SlotName,
								PeriodName = P.PeriodName2,
								SL.SiteName,
								S.SiteID,
								S.CropCode,
								S.BreedingStationCode,
								MT.MaterialTypeCode,
								S.PeriodID,
								S.RequestDate,
								S.PlannedDate,
								S.StatusCode,
								STA.StatusName,			
								RC.NrOfTests,	
								AvailableSample = (RC.NrOfTests - ISNULL(T1.UsedSamples,0)),			
								S.RequestUser,
								S.Remark,
								S.TestTypeID,
								RC.TestProtocolID,
								TP.TestProtocolName
							FROM Slot S
							JOIN SiteLocation SL ON SL.SiteID = S.SiteID
							JOIN ReservedCapacity RC ON RC.SlotID = S.SlotID --only one record exists for leafdisk
							JOIN TestProtocol TP ON TP.TestProtocolID = RC.TestProtocolID
							JOIN VW_Period P ON P.PeriodID = S.PeriodID
							JOIN MaterialType MT ON MT.MaterialTypeID = S.MaterialTypeID
							JOIN [Status] STA ON STA.StatusCode = S.StatusCode AND STA.StatusTable = ''Slot''
							LEFT JOIN 
							(
								SELECT UsedSamples = COUNT(ST.SampleID), Slt.slotid FROM  LD_Sample S
								JOIN LD_SampleTest ST ON ST.SampleID = S.SampleID
								JOIN SlotTest Slt on slt.testid = st.testid
								GROUP BY slt.slotid
							) T1 ON T1.SlotID = S.SlotID
							
						) T1
						'+ CASE WHEN ISNULL(@Filter,'') <> '' THEN ' WHERE TestTypeID = 9 AND CropCode = @CropCode AND BreedingStationCode = @BrStationCode  AND ' + @Filter ELSE ' WHERE TestTypeID = 9 AND CropCode = @CropCode AND BreedingStationCode = @BrStationCode ' END +N' 
					)
					T
				), CTE_COUNT AS (SELECT COUNT(SlotID) AS [TotalRows] FROM CTE
				)

				SELECT CTE.*, CTE_COUNT.TotalRows FROM CTE,CTE_COUNT
					ORDER BY PeriodID DESC
					OFFSET @Offset ROWS
					FETCH NEXT @PageSize ROWS ONLY
					OPTION (RECOMPILE)';

    EXEC sp_executesql @SQL, N'@CropCode NVARCHAR(10), @BrStationCode NVARCHAR(50), @Offset INT, @PageSize INT', @CropCode, @BrStationCode, @Offset, @PageSize;

	
END

GO


/*
Author					Date				Description
KRIAHNA GAUTAM			2021-06-27			#22645:SP created.

============Example===================
EXEC PR_LFDISK_GETOVERVIEW 'ON',1,100,'',0,1
*/

ALTER PROCEDURE [dbo].[PR_LFDISK_GETOVERVIEW]
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
	('SiteName','Site',4,1,'string',0,1,0),
	('SlotName','Slot Name',5,1,'string',0,1,0),
	('PlannedDate','PlannedDate',6,1,'string',0,1,0),
	('UsedSamples','Used Sample',7,1,'string',0,1,0),
	('ResultSummary','Test Result',8,1,'string',0,1,0),
	('StatusName','Status',9,1,'string',0,1,0),
	('StatusCode','StatusCode',10,0,'string',0,1,0)

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
							T.PlannedDate,							
							Stat.StatusName,
							T1.UsedSamples,
							ResultSummary = T.LDResultSummary,
							T.StatusCode,
							SL.SiteName,
							T2.SlotName
						FROM Test T
						JOIN [File] F ON F.FileID = T.FileID
						JOIN #Status Stat ON Stat.StatusCode = T.StatusCode
						JOIN SiteLocation SL ON SL.SiteID = T.SiteID
						LEFT JOIN
						(
							SELECT UsedSamples = COUNT(ST.SampleID), ST.TestID FROM  LD_Sample S
							JOIN LD_SampleTest ST ON ST.SampleID = S.SampleID
							GROUP BY ST.TestID										
						) T1 ON T.TestID = T1.TestID
						LEFT JOIN 
						(
							SELECT S.SlotName, T.TestID FROM Test T
							JOIN SlotTest ST ON ST.TestID = T.TestID
							JOIN Slot S ON S.SlotID = ST.SlotID
						) T2 ON T2.TestID = T.TestID
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