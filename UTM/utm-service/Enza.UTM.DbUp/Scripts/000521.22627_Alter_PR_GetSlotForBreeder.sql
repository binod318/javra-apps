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


