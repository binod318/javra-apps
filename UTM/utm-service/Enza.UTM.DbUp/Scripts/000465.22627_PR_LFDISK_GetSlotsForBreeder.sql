DROP PROCEDURE IF EXISTS PR_LFDISK_GetSlotsForBreeder
GO
/*
Author					Date			Description
Krishna Gautam			2021/06/02		#22627:	Stored procedure created

===================================Example================================

-- EXEC PR_LFDISK_GetSlotsForBreeder 'To', 'NLEN', 1, 200, ''
-- EXEC PR_PLAN_GetSlotsForBreeder 'To', 'NLEN', 1, 200, 'PeriodName like ''%-13-20%'''
*/


CREATE PROCEDURE [dbo].[PR_LFDISK_GetSlotsForBreeder]
(
	@CropCode		NVARCHAR(10),
	@BrStationCode	NVARCHAR(50),
	@Page			INT,
	@PageSize		INT,
	@Filter			NVARCHAR(MAX) = NULL
)
AS BEGIN
    SET NOCOUNT ON;
    DECLARE @SQL NVARCHAR(MAX);
    DECLARE @Offset INT;
    DECLARE @WellType INT;

    SET @Offset = @PageSize * (@Page -1);
	
    SET @SQL = N'
;WITH CTE AS
(
	SELECT * FROM 
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
			S.ExpectedDate,
			S.StatusCode,
			STA.StatusName,			
			[TotalSample] = RC.NrOfTests,
			[AvailablePlates] = 0,			
			UsedSample = 0,			
			S.RequestUser,
			S.Remark,
			S.TestTypeID
		FROM Slot S
		JOIN ReservedCapacity RC ON RC.SlotID = S.SlotID --only one record exists for leafdisk
		JOIN VW_Period P ON P.PeriodID = S.PeriodID
		JOIN MaterialType MT ON MT.MaterialTypeID = S.MaterialTypeID
		JOIN [Status] STA ON STA.StatusCode = S.StatusCode AND STA.StatusTable = ''Slot''
		'+ CASE WHEN ISNULL(@Filter,'') <> '' THEN ' WHERE S.TestTypeID = 9 AND ' + @Filter ELSE ' WHERE S.TestTypeID = 9 ' END +N' 
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
