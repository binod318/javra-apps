DROP PROCEDURE IF EXISTS [dbo].[PR_LFDISK_GetPlannedOverview]
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

CREATE PROCEDURE [dbo].[PR_LFDISK_GetPlannedOverview]
(
	@Year			INT,
	@PeriodID		INT				= NULL,
	@Filter			NVARCHAR(MAX)   = NULL,
	@SiteID			INT=NULL,
	@ExportToExcel	BIT
) AS BEGIN
SET NOCOUNT ON;

	DECLARE @Query NVARCHAR(MAX), @TestTypeID INT = 9; --TesttypeId always 9 for LeafDisk
	DECLARE @TblColumn TABLE(ColumnLabel VARCHAR(100), ColumnID VARCHAR(100),[Order] INT,IsVisible BIT);
	DECLARE @SelectColumns NVARCHAR(MAX);


	INSERT INTO @TblColumn(ColumnLabel,ColumnID,[Order],IsVisible)
	VALUES
	('Week','PeriodName',1,1),
	('Slot name','SlotName',2,1),
	('Breeding station','BreedingStationCode',3,1),
	('Crop','CropName',4,1),
	('Site','SiteName',5,1),
	('Requester','RequestUser',6,1),
	('#Samples','Samples',7,1),
	('Method','TestProtocolName',8,1),
	('Status','StatusName',9,1),
	('PeriodID','PeriodID',10,0),
	('SlotID','SlotID',11,0),
	('PlanneDate','PlanneDate',12,0),
	('ExpectedDate','ExpectedDate',13,0),
	('CropCode','CropCode',14,0),
	('UpdatePeriod','UpdatePeriod',15,0);

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


DROP PROCEDURE IF EXISTS [dbo].[PR_LFDISK_GetSlotsForBreeder]
GO



/*
Author					Date			Description
Krishna Gautam			2021/06/02		#22627:	Stored procedure created

===================================Example================================

-- EXEC PR_LFDISK_GetSlotsForBreeder 'ON', 'NLEN', 1, 200, '',0
-- EXEC PR_PLAN_GetSlotsForBreeder 'To', 'NLEN', 1, 200, 'PeriodName like ''%-13-20%'''
*/


CREATE PROCEDURE [dbo].[PR_LFDISK_GetSlotsForBreeder]
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
								S.CropCode,
								S.BreedingStationCode,
								MT.MaterialTypeCode,
								S.PeriodID,
								S.RequestDate,
								S.PlannedDate,
								S.StatusCode,
								STA.StatusName,			
								RC.NrOfTests,	
								AvailableSample = RC.NrOfTests,			
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


DROP PROCEDURE IF EXISTS [dbo].[PR_LFDISK_GetReserveCapacityLookUp]
GO


/*
=============================================
Author:					Date				Remark
Krishna Gautam			2021/06/02			Capacity planning screen data lookup.
Krishna Gautam			2021/06/22			#22408: Added site location.
=========================================================================

EXEC PR_LFDISK_GetReserveCapacityLookUp 'TO,ON'
*/
CREATE PROCEDURE [dbo].[PR_LFDISK_GetReserveCapacityLookUp]
(
	@Crops NVARCHAR(MAX)
)

AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @ColumnTable TABLE(ColumnID NVARCHAR(MAX), Label NVARCHAR(MAX),[Order] INT, Visible BIT, Editable BIT, DataType NVARCHAR(MAX));
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
	INSERT INTO @ColumnTable(ColumnID,Label,[Order],Visible,Editable,DataType)
	VALUES
	('CropCode','Crop',1,1,0,'string'),
	('BreedingStationCode','Br.Station',2,1,0,'string'),
	('SlotID','SlotID',3,0,0,'int'), --not visible
	('SlotName','Slot Name',4,1,0,'string'),
	('PeriodName','Period Name',5,1,0,'string'),
	('SiteName','Lab Location',6,1,0,'string'),
	('MaterialTypeCode','Material Type',7,1,0,'string'),
	('MaterialTypeID','MaterialTypeID',8,0,0,'int'), --not visible
	('TestProtocolName','Method',9,1,0,'string'),
	('TestProtocolID','TestProtocolID',10,0,0,'int'), --not visible
	('NrOfTests','Total Sample',11,1,0,'string'),
	('AvailableSample','Available Sample',12,1,0,'string'),
	('RequestUser','Requestor',13,1,0,'string'),	
	('Remark','Remark',14,1,0,'string'),
	('StatusName','Status',15,1,0,'string');

	SELECT * FROM @ColumnTable;

	SELECT C.CropCode, C.CropName FROM CropRD C
	JOIN string_split(@Crops,',') S ON C.CropCode = S.[value];

	SELECT SiteID, SiteName FROM SiteLocation
END


GO


