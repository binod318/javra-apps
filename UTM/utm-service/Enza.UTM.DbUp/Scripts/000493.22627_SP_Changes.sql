
/*
Author					Date			Description
Krishna Gautam			2021/06/02		#22627:	Stored procedure created

===================================Example================================

-- EXEC PR_LFDISK_GetSlotsForBreeder 'ON', 'NLEN', 1, 200, 'Remark like ''%2%''',1
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
	PRINT @SQL;
    EXEC sp_executesql @SQL, N'@CropCode NVARCHAR(10), @BrStationCode NVARCHAR(50), @Offset INT, @PageSize INT', @CropCode, @BrStationCode, @Offset, @PageSize;

	
END


GO



/*
Author					Date			Description
Krishna Gautam			-				Stored procedure created
Krishna Gautam			2019-Nov-19		Update new requested value and approved value on different field that is used for furhter process (if denied only deny new request of approved slot).
Krishna Gautam			2020-Nov-23		#16325:Filter data from period name by providing year and export data to excel.
Krishna Gautam			2020-DEC-22		Changed query for performance (it was giving timeout).
Krishna Gautam			2021-JAN-29		18980: Display slot based on planned period.
Krishna Gautam			2021-Feb-11		19261: Display of available tests correction
Krishna Gautam			2021-Feb-11		#18921: provide test type to slot.
===================================Example================================

-- EXEC PR_PLAN_GetSlotsForBreeder 'To', 'NLEN', 'JAVRA\psindurakar', 1, 200, ''
-- EXEC PR_PLAN_GetSlotsForBreeder 'To', 'NLEN', 'JAVRA\psindurakar', 1, 200, 'PeriodName like ''%-13-20%'''
*/


ALTER PROCEDURE [dbo].[PR_PLAN_GetSlotsForBreeder]
(
	@CropCode		NVARCHAR(10),
	@BrStationCode	NVARCHAR(50),
	@RequestUser	NVARCHAR(100),
	@Page			INT,
	@PageSize		INT,
	@Filter			NVARCHAR(MAX) = NULL
)
AS BEGIN
    SET NOCOUNT ON;
    DECLARE @SQL NVARCHAR(MAX);
    DECLARE @Offset INT;
    DECLARE @WellType INT;

    SELECT @WellType = WelltypeID FROM WellType WHERE WellTypeName = 'D';

    SET @Offset = @PageSize * (@Page -1);
	
    SET @SQL = N';WITH CTE AS
    (
		SELECT * FROM 
		(
		SELECT 
			SlotID = S.SlotID,
			SlotName = MAX(S.SlotName),
			PeriodName = MAX(P.PeriodName2),
			CropCode = MAX(S.CropCode),
			BreedingStationCode = MAX(S.BreedingStationCode),
			MaterialTypeCode = MAX(MT.MaterialTypeCode),
			MaterialStateCode = MAX(MS.MaterialStateCode),
			PeriodID = MAX(S.PeriodID),
			RequestDate = MAX(S.RequestDate),
			PlannedDate = MAX(S.PlannedDate),
			ExpectedDate = MAX(S.ExpectedDate),
			Isolated = S.Isolated,
			StatusCode = MAX(S.StatusCode),
			StatusName = MAX(STA.StatusName),			
			[TotalPlates] =SUM(ISNULL(RC.NrOfPlates,0)),
			[TotalTests] =SUM(ISNULL(RC.NrOfTests,0)),
			[AvailablePlates] =SUM(ISNULL(RC.NrOfPlates,0)) - SUM(ISNULL(UsedPlates,0)),
			[AvailableTests] = SUM(ISNULL(RC.NrOfTests,0)) - SUM(ISNULL(UsedMarker,0)),
			UsedPlates = SUM(ISNULL(UsedPlates,0)),
			UsedMarker = SUM(ISNULL(UsedMarker,0)),
			RequestUser = MAX(S.RequestUser),
			Remark = MAX(S.Remark),
			TestTypeID = MAX(S.TestTypeID)
		FROM Slot S
		JOIN VW_Period P ON P.PeriodID = S.PeriodID
		JOIN MaterialType MT ON MT.MaterialTypeID = S.MaterialTypeID
		JOIN MaterialState MS ON MS.MaterialStateID = S.MaterialStateID
		JOIN [Status] STA ON STA.StatusCode = S.StatusCode AND STA.StatusTable = ''Slot''
		LEFT JOIN
		(
			SELECT 
				SlotID,
				NrOfTests = CASE WHEN MAX(ISNULL(RC.NewNrOfTests,0)) > 0 THEN MAX(ISNULL(RC.NewNrOfTests,0)) ELSE MAX(ISNULL(RC.NrOfTests,0)) END,
				NrOfPlates = CASE WHEN MAX(ISNULL(RC.NewNrOfPlates,0)) > 0 THEN MAX(ISNULL(RC.NewNrOfPlates,0)) ELSE MAX(ISNULL(RC.NrOfPlates,0)) END
			FROM ReservedCapacity RC
			GROUP BY SlotID		
		) RC ON RC.SlotID = S.SlotID
		LEFT JOIN 
		(

			SELECT 
				SlotID, 
				COUNT(DISTINCT P.PlateID) AS UsedPlates
			FROM SlotTest ST 
			JOIN Test T ON T.TestID = ST.TestID
			JOIN Plate P ON P.TestID = T.TestID
			GROUP BY SlotID
		) T1 ON T1.SlotID = S.SlotID
		LEFT JOIN 
		(
			SELECT 
				SlotID, 
				COUNT(DeterminationID) AS UsedMarker  
			FROM 
			(
				SELECT 
					S.SlotID,
					T.TestID,
					P.PlateID,
					TMD.DeterminationID				
				FROM Slot S 
				JOIN SlotTest ST ON ST.SlotID = S.SlotID 
				JOIN Test T ON T.TestID = ST.TestID
				JOIN Plate P ON P.TestID = T.TestID
				JOIN Well W ON W.PlateID = P.PlateID
				JOIN TestMaterialDeterminationWell TMDW ON TMDW.WellID = W.WellID			
				JOIN TestMaterialDetermination TMD on TMD.TestID = T.TestID	AND TMD.MaterialID = TMDW.MaterialID	
				GROUP BY S.SlotID,T.TestID,P.PlateID,DeterminationID
			) V 
			GROUP BY SlotID
		  ) T2 ON T2.SlotID = S.SlotID
		  WHERE S.CropCode = @CropCode
		  AND S.BreedingStationCode = @BrStationCode
		  AND ISNULL(S.TestTypeID,1) BETWEEN (1 AND 8)
	   GROUP BY S.SlotID, Isolated
	   )T3 '+CASE WHEN ISNULL(@Filter,'') <> '' THEN ' WHERE ' + @Filter ELSE '' END + N'), CTE_COUNT AS (SELECT COUNT(SlotID) AS [TotalRows] FROM CTE
    )	
    SELECT 
	   CTE.SlotID, 
	   CTE.SlotName,
	   CTE.PeriodName,
	   CTE.CropCode,
	   CTE.BreedingStationCode,
	   CTE.MaterialTypeCode,
	   CTE.MaterialStateCode,
	   CTE.RequestDate,
	   CTE.PlannedDate,
	   CTE.ExpectedDate,
	   CTE.Isolated,
	   CTE.StatusCode,
	   CTE.StatusName,
	   CTE.[TotalPlates],
	   CTE.[TotalTests],
	   CTE.[AvailablePlates],
	   CTE.[AvailableTests],
	   CTE.UsedPlates,
	   CTE.UsedMarker,
	   CTE.RequestUser,
	   CTE.Remark,
	   CTE.TestTypeID,
	   CTE_COUNT.TotalRows 
    FROM CTE, CTE_Count
    ORDER BY PeriodID DESC
    OFFSET @Offset ROWS
    FETCH NEXT @PageSize ROWS ONLY
	OPTION (RECOMPILE)';

    EXEC sp_executesql @SQL, N'@CropCode NVARCHAR(10), @BrStationCode NVARCHAR(50), @Offset INT, @PageSize INT, @WellType INT', @CropCode, @BrStationCode, @Offset, @PageSize, @WellType;

	
END
GO