
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
	
	--we need to send ColumnID in default case with first character a small.
	INSERT INTO @TblColumn(ColumnID,ColumnLabel,[Order],Visible,DataType,Editable,AllowFilter,AllowSort,Width)
	VALUES
	('testID','TestID',0,0,'integer',0,0,0,0),
	('cropCode','Crop',1,1,'string',0,1,0,70),
	('breedingStationCode','Br.Station',2,1,'string',0,1,0,100),
	('testName','Test Name',3,1,'string',0,1,0,200),
	('siteName','Site',4,1,'string',0,1,0,200),
	('slotName','Slot Name',5,1,'string',0,1,0,200),
	('plannedDate','PlannedDate',6,1,'string',0,1,0,120),
	('usedSamples','Used Sample',7,1,'string',0,1,0,120),
	('resultSummary','Test Result',8,1,'string',0,1,0,200),
	('statusName','Status',9,1,'string',0,1,0,200),
	('statusCode','StatusCode',10,0,'string',0,1,0,100);

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

/*
=============================================
Author:					Date				Remark
Krishna Gautam			2021/06/02			Capacity planning screen data lookup.
Krishna Gautam			2021/06/22			#22408: Added site location.
=========================================================================

EXEC PR_LFDISK_GetReserveCapacityLookUp 'TO,ON'
*/
ALTER PROCEDURE [dbo].[PR_LFDISK_GetReserveCapacityLookUp]
(
	@Crops NVARCHAR(MAX)
)

AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @ColumnTable TABLE(ColumnID NVARCHAR(MAX), Label NVARCHAR(MAX),[Order] INT, Visible BIT, Editable BIT, DataType NVARCHAR(MAX), Width INT);

	--BreedingStation
	SELECT BreedingStationCode, BreedingStationName FROM BreedingStation;
	--TestType
	SELECT TestTypeID, TestTypeCode, TestTypeName, DeterminationRequired FROM TestType WHERE TestTypeID = 9;
	--MaterialType
	SELECT MaterialTypeID, MaterialTypeCode, MaterialTypeDescription FROM MaterialType;
	--TestProtocol
	SELECT * FROM TestProtocol WHERE TestTypeID = 9
	--CurrentPeriod
	EXEC PR_PLAN_GetCurrentPeriod 1
	
	--Grid Columns
	INSERT INTO @ColumnTable(ColumnID,Label,[Order],Visible,Editable,DataType,Width)
	VALUES
	('cropCode','Crop',1,1,0,'string',70),
	('breedingStationCode','Br.Station',2,1,0,'string',100),
	('SlotID','SlotID',3,0,0,'int',0), --not visible
	('SlotName','Slot Name',4,1,0,'string',150),
	('PeriodName','Period Name',5,1,0,'string',250),
	('SiteName','Lab Location',6,1,0,'string',150),
	('MaterialTypeCode','Material Type',7,1,0,'string', 100),
	('MaterialTypeID','MaterialTypeID',8,0,0,'int',0), --not visible
	('TestProtocolName','Method',9,1,0,'string', 150),
	('TestProtocolID','TestProtocolID',10,0,0,'int',0), --not visible
	('NrOfTests','Total Sample',11,1,0,'string', 100),
	('AvailableSample','Available Sample',12,1,0,'string', 100),
	('RequestUser','Requestor',13,1,0,'string', 150),	
	('Remark','Remark',14,1,0,'string',200),
	('StatusName','Status',15,1,0,'string',70);

	SELECT * FROM @ColumnTable;

	SELECT C.CropCode, C.CropName FROM CropRD C
	JOIN string_split(@Crops,',') S ON C.CropCode = S.[value];

	SELECT SiteID, SiteName FROM SiteLocation
END


GO


/*
-- =============================================
Author:					Date				Remark
Binod Gurung			2021/06/02			Lab overview for Leaf disk
Krishna Gautam			2021/06/21			#22407: Add site location
=========================================================================

EXEC PR_LFDISK_GetPlannedOverview 2021, NULL, 'PeriodName LIKE ''%10%'''
EXEC PR_LFDISK_GetPlannedOverview 2021,NULL,NULL,NULL,1
*/

ALTER PROCEDURE [dbo].[PR_LFDISK_GetPlannedOverview]
(
	@Year			INT,
	@PeriodID		INT				= NULL,
	@Filter			NVARCHAR(MAX)   = NULL,
	@SiteID			INT=NULL,
	@ExportToExcel	BIT
) AS BEGIN
SET NOCOUNT ON;

	DECLARE @Query NVARCHAR(MAX), @TestTypeID INT = 9; --TesttypeId always 9 for LeafDisk
	DECLARE @TblColumn TABLE(ColumnLabel VARCHAR(100), ColumnID VARCHAR(100),[Order] INT,IsVisible BIT,Width INT);
	DECLARE @SelectColumns NVARCHAR(MAX);


	INSERT INTO @TblColumn(ColumnLabel,ColumnID,[Order],IsVisible,Width)
	VALUES
	('Week','periodName',1,1,250),
	('Slot Name','slotName',2,1,150),
	('Br.Station','breedingStationCode',3,1,100),
	('Crop','cropName',4,1,100),
	('Site','siteName',5,1,150),
	('Requester','requestUser',6,1,150),
	('#Samples','samples',7,1,100),
	('Method','testProtocolName',8,1,100),
	('Status','StatusName',9,1,100),
	('PeriodID','periodID',10,0,0),
	('SlotID','slotID',11,0,0),
	('PlanneDate','PlanneDate',12,0,0),
	('ExpectedDate','ExpectedDate',13,0,0),
	('CropCode','CropCode',14,0,0),
	('UpdatePeriod','UpdatePeriod',15,0,0);

	IF(ISNULL(@ExportToExcel,0) = 0)
	BEGIN
		SELECT 
			@SelectColumns = COALESCE(@SelectColumns + ',','') + QUOTENAME(ColumnID) 
		FROM @TblColumn;
	END
	ELSE
	BEGIN
		SELECT 
			@SelectColumns = COALESCE(@SelectColumns + ',','') + QUOTENAME(ColumnID) +'AS ' + QUOTENAME(ColumnLabel)
		FROM @TblColumn
		WHERE ISNULL(IsVisible,0) = 1;
	END
	
	SET @Query = N'
					SELECT
						' + @SelectColumns + '
					FROM
					(
						SELECT 
							P.PeriodID, 
							PeriodName = CONCAT(P.PeriodName, FORMAT(P.StartDate, '' (MMM-dd-yy - '', ''en-US'' ), FORMAT(P.EndDate, ''MMM-dd-yy)'', ''en-US'' )),
							T1.*, 
							T2.TestProtocolName, 
							T3.BreedingStationCode, 
							T3.CropCode, 
							T3.RequestUser,
							T3.SlotName,
							T3.Remark,
							CRD.CropName,
							SL.SiteName,
							UpdatePeriod = CAST(CASE WHEN ISNULL(T4.SlotID,0) = 0 THEN 1 ELSE 0 END AS BIT)
						FROM
						(
							SELECT T1.SlotID, MAX(ISNULL([Samples], 0)) As [Samples], Max(PlannedDate) AS PlanneDate,Max(ExpectedDate) AS ExpectedDate, StatusName = MAX(StatusName)
							FROM 
							(
								SELECT SlotID, [Samples], PlannedDate,ExpectedDate,StatusName
								FROM
								(
									SELECT 
										S.SlotID, 
										NrOfTests, 
										Protocol1 = CASE WHEN NrOfTests IS NOT NULL THEN ''Samples'' ELSE '''' END,
										S.PlannedDate,
										S.ExpectedDate,
										STA.StatusName
									FROM SLOT S
									JOIN ReservedCapacity RC ON RC.SlotID = S.SlotID
									JOIN TestProtocol TP On TP.TestProtocolID = RC.TestProtocolID
									JOIN [Period] P ON P.PeriodID = S.PeriodID
									JOIN [Status] STA ON STA.StatusCode = S.StatusCode AND STA.StatusTable = ''Slot''
									WHERE S.StatusCode >=200
									AND @Year BETWEEN DATEPART(YEAR, P.StartDate) AND DATEPART(YEAR, P.EndDate)
									AND (ISNULL(@PeriodID, 0) = 0 OR S.PeriodID = @PeriodID)
									AND (ISNULL(@SiteID,0) = 0 OR S.SiteID = @SiteID)
								) AS V1
								PIVOT 
								(
									SUM(NrOfTests)
									FOR Protocol1 IN ([Samples])
								) AS V2
							) T1
							GROUP BY T1.SlotID
						) T1
						JOIN Slot T3 ON T3.SlotID = T1.SlotID AND T3.TestTypeID = 9 --Leafdisk
						JOIN SiteLocation SL ON T3.SiteID = SL.SiteID
						LEFT JOIN
						(
							SELECT 
								RC.SlotID, 
								TP.TestProtocolID, 
								TP.TestProtocolName			 
							FROM ReservedCapacity RC 
							JOIN TestProtocol TP ON RC.TestProtocolID = TP.TestProtocolID
							WHERE TP.TestTypeID = @TestTypeID
						) T2 ON T2.SlotID = T1.SlotID	
						LEFT JOIN
						(
							SELECT SlotID FROM SlotTest
							GROUP BY SlotID
						) T4 ON T4.SlotID = T1.SlotID
						JOIN [Period] P ON P.PeriodID = T3.PeriodID
						JOIN CropRD CRD ON CRD.CropCode = T3.CropCode
					) V
					' + CASE WHEN ISNULL(@Filter,'') <> '' THEN 'WHERE ' + @Filter ELSE '' END + N'
					ORDER BY PeriodID, BreedingStationCode, CropCode;'

	EXEC sp_executesql @Query, N'@TestTypeID INT, @Year INT, @PeriodID INT, @SiteID INT', @TestTypeID, @Year, @PeriodID, @SiteID;
	
	SELECT * FROM @TblColumn ORDER BY [Order]

END

GO