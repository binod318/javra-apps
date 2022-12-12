/*
=============================================
Author:					Date				Remark
Krishna Gautam			2021/06/02			Capacity planning screen data lookup.
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
	('MaterialTypeCode','Material Type',6,1,0,'string'),
	('MaterialTypeID','MaterialTypeID',7,0,0,'int'), --not visible
	('TestProtocolName','Method',8,1,0,'string'),
	('TestProtocolID','TestProtocolID',9,0,0,'int'), --not visible
	('NrOfTests','Total Sample',10,1,0,'string'),
	('AvailableSample','Available Sample',11,1,0,'string'),
	('Remark','Remark',12,1,0,'string');

	SELECT * FROM @ColumnTable;

	SELECT C.CropCode, C.CropName FROM CropRD C
	JOIN string_split(@Crops,',') S ON C.CropCode = S.[value]
END



Go




/*
Author					Date			Description
Krishna Gautam			2021/06/02		#22627:	Stored procedure created

===================================Example================================

-- EXEC PR_LFDISK_GetSlotsForBreeder 'ON', 'NLEN', 1, 200, '',1
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
								MaterialTypeCode AS [Material Type],
								TestProtocolName AS [Method],
								NrOfTests AS [Total Sample],
								UsedSample AS [Available Sample],
								Remark'
	END

    SET @SQL = N'
				;WITH CTE AS
				(
					SELECT '+@SelectColumns+' FROM 
					(
						SELECT 
							S.SlotID,
							SlotName,
							PeriodName = P.PeriodName2,
							S.CropCode,
							S.BreedingStationCode,
							MT.MaterialTypeCode,
							S.PeriodID,
							S.RequestDate,
							S.PlannedDate,
							S.StatusCode,
							STA.StatusName,			
							RC.NrOfTests,	
							AvailableSample = 0,			
							S.RequestUser,
							S.Remark,
							S.TestTypeID,
							RC.TestProtocolID,
							TP.TestProtocolName
						FROM Slot S
						JOIN ReservedCapacity RC ON RC.SlotID = S.SlotID --only one record exists for leafdisk
						JOIN TestProtocol TP ON TP.TestProtocolID = RC.TestProtocolID
						JOIN VW_Period P ON P.PeriodID = S.PeriodID
						JOIN MaterialType MT ON MT.MaterialTypeID = S.MaterialTypeID
						JOIN [Status] STA ON STA.StatusCode = S.StatusCode AND STA.StatusTable = ''Slot''
						'+ CASE WHEN ISNULL(@Filter,'') <> '' THEN ' WHERE S.TestTypeID = 9 AND S.CropCode = @CropCode AND S.BreedingStationCode = @BrStationCode  AND ' + @Filter ELSE ' WHERE S.TestTypeID = 9 AND S.CropCode = @CropCode AND S.BreedingStationCode = @BrStationCode ' END +N' 
					)
					T
				), CTE_COUNT AS (SELECT COUNT(SlotID) AS [TotalRows] FROM CTE
				)

				SELECT CTE.*, CTE_COUNT.TotalRows FROM CTE,CTE_COUNT
					ORDER BY PeriodID DESC
					OFFSET @Offset ROWS
					FETCH NEXT @PageSize ROWS ONLY
					OPTION (RECOMPILE)';
	PRINT @SQL;
    EXEC sp_executesql @SQL, N'@CropCode NVARCHAR(10), @BrStationCode NVARCHAR(50), @Offset INT, @PageSize INT', @CropCode, @BrStationCode, @Offset, @PageSize;

	
END

GO