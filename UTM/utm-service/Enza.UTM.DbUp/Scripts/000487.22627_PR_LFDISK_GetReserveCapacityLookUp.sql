/*
=============================================
Author:					Date				Remark
Krishna Gautam			2021/06/02			Capacity planning screen data lookup.
=========================================================================

EXEC PR_LFDISK_GetReserveCapacityLookUp
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
	('Period','Period Name',5,1,0,'string'),
	('MaterialTypeCode','Material Type',6,1,0,'string'),
	('MaterialTypeID','MaterialTypeID',7,0,0,'int'), --not visible
	('Sample','Sample',8,1,0,'string'),
	('Remark','Remark',9,1,0,'string');

	SELECT * FROM @ColumnTable;

	SELECT C.CropCode, C.CropName FROM CropRD C
	JOIN string_split(@Crops,',') S ON C.CropCode = S.[value]
END


