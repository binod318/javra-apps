DROP PROCEDURE IF EXISTS [dbo].[PR_LFDISK_GetPlannedOverview]
GO



/*
-- =============================================
Author:					Date				Remark
Binod Gurung			2021/06/02			Lab overview for Leaf disk
=========================================================================

--EXEC PR_LFDISK_GetPlannedOverview 2021, NULL, 'PeriodName LIKE ''%10%'''
--EXEC PR_LFDISK_GetPlannedOverview 2021, NULL, 'CropCode LIKE ''%ON%'''
*/

CREATE PROCEDURE [dbo].[PR_LFDISK_GetPlannedOverview]
(
	@Year			INT,
	@PeriodID		INT				= NULL,
	@Filter			NVARCHAR(MAX)   = NULL
) AS BEGIN
SET NOCOUNT ON;

	DECLARE @Query NVARCHAR(MAX), @TestTypeID INT = 9; --TesttypeId always 9 for LeafDisk
	DECLARE @TblColumn TABLE(ColumnLabel VARCHAR(100), ColumnID VARCHAR(100),[Order] INT,IsVisible BIT)

	INSERT INTO @TblColumn(ColumnLabel,ColumnID,[Order],IsVisible)
	VALUES
	('Week','PeriodName',1,1),
	('Slot name','SlotName',2,1),
	('Breeding station','BreedingStationCode',3,1),
	('Crop','CropName',4,1),
	('Requester','RequestUser',5,1),
	('#Samples','Samples',6,1),
	('Method','TestProtocolName',7,1),
	('Status','StatusName',8,1),
	('PeriodID','PeriodID',9,0),
	('SlotID','SlotID',10,0),
	('PlanneDate','PlanneDate',11,0),
	('ExpectedDate','ExpectedDate',12,0),
	('CropCode','CropCode',13,0),
	('UpdatePeriod','UpdatePeriod',14,0);
	
	SET @Query = N'
					SELECT
						PeriodName,
						SlotName,
						BreedingStationCode,
						CropName,
						RequestUser,
						Remark,
						Samples,
						TestProtocolName,
						StatusName,
						PeriodID,
						SlotID,
						PlanneDate,
						ExpectedDate,
						CropCode,
						UpdatePeriod
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
							UpdatePeriod = CAST(CASE WHEN ISNULL(T4.SlotID,0) = 0 THEN 1 ELSE 0 END AS BIT)
						FROM
						(
							SELECT T1.SlotID, MAX(ISNULL([Markers], 0)) As [Samples], Max(PlannedDate) AS PlanneDate,Max(ExpectedDate) AS ExpectedDate, StatusName = MAX(StatusName)
							FROM 
							(
								SELECT SlotID, [Markers], PlannedDate,ExpectedDate,StatusName
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
								) AS V1
								PIVOT 
								(
									SUM(NrOfTests)
									FOR Protocol1 IN ([Markers])
								) AS V2
							) T1
							GROUP BY T1.SlotID
						) T1
						JOIN Slot T3 ON T3.SlotID = T1.SlotID
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

	EXEC sp_executesql @Query, N'@TestTypeID INT, @Year INT, @PeriodID INT', @TestTypeID, @Year, @PeriodID;

	SELECT * FROM @TblColumn ORDER BY [Order]

END
GO


