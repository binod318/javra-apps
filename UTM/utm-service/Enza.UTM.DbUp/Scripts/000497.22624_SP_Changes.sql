DROP PROCEDURE IF EXISTS [dbo].[PR_PLAN_GetPlannedOverview]
GO

/*
-- =============================================
Author:					Date				Remark
Krishna Gautam								SP Created
Krishna Gautam			2020/03/26			#7848: Show cancelled and denied slot also.. Earlier only slot with status code 200 (Approved was shown).
Binod Gurung			2021/05/12			#22262: Made dynmaic query to implement filter query
=========================================================================

--EXEC PR_PLAN_GetPlannedOverview 2021, NULL, 'PeriodName LIKE ''%10%'''
--EXEC PR_PLAN_GetPlannedOverview 2021, NULL, 'CropCode LIKE ''%ON%'''
*/

CREATE PROCEDURE [dbo].[PR_PLAN_GetPlannedOverview]
(
	@Year			INT,
	@PeriodID		INT				= NULL,
	@Filter			NVARCHAR(MAX)   = NULL
) AS BEGIN
SET NOCOUNT ON;

	DECLARE @MarkerTestProtocolID INT, @Query NVARCHAR(MAX);
	SELECT 
		@MarkerTestProtocolID = TestProtocolID 
	FROM TestProtocol TP
	JOIN TestType TT On TT.TestTypeID = TP.TestTypeID
	WHERE TT.DeterminationRequired = 1 AND TT.TestTypeID IN (1,2); --TestypeId 1 for 2GB Marker, 2 for DNA Isolatuon

	SET @Query = N'
					SELECT
						PeriodName,
						SlotName,
						BreedingStationCode,
						CropName,
						RequestUser,
						Remark,
						Markers,
						Plates,
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
							SELECT T1.SlotID, MAX(ISNULL([Markers], 0)) As [Markers] , MAX(ISNULL([Plates], 0)) AS [Plates],Max(PlannedDate) AS PlanneDate,Max(ExpectedDate) AS ExpectedDate, StatusName = MAX(StatusName)
							FROM 
							(
								SELECT SlotID, [Markers], [Plates],PlannedDate,ExpectedDate,StatusName
								FROM
								(
									SELECT 
										S.SlotID, 
										NrOfTests, 
										NrOfPlates,
										Protocol1 = CASE WHEN RC.TestProtocolID = @MarkerTestProtocolID THEN ''Markers'' ELSE ''Plates'' END,
										Protocol2 = CASE WHEN RC.TestProtocolID = @MarkerTestProtocolID THEN ''Markers'' ELSE ''Plates'' END,
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
								PIVOT 
								(
									SUM(NrOfPlates)
									FOR Protocol2 IN ([Plates])
								) AS V3
							) T1
							GROUP BY T1.SlotID
						) T1
						JOIN Slot T3 ON T3.SlotID = T1.SlotID AND ISNULL(T3.TestTypeID,1) BETWEEN 1 AND 8
						LEFT JOIN
						(
							SELECT 
								RC.SlotID, 
								TP.TestProtocolID, 
								TP.TestProtocolName			 
							FROM ReservedCapacity RC 
							JOIN TestProtocol TP ON RC.TestProtocolID = TP.TestProtocolID
							WHERE RC.TestProtocolID <> @MarkerTestProtocolID
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

	EXEC sp_executesql @Query, N'@MarkerTestProtocolID INT, @Year INT, @PeriodID INT', @MarkerTestProtocolID, @Year, @PeriodID;

END
GO


DROP PROCEDURE IF EXISTS [dbo].[PR_LFDISK_ChangeSlot]
GO


/*
	Author					Date			Description
-------------------------------------------------------------------
	Binod Gurung			2021/06/03		Change slot info and reserved capacity Leaf disk
-------------------------------------------------------------------
EXEC [PR_LFDISK_ChangeSlot] 69 
*/

CREATE PROC [dbo].[PR_LFDISK_ChangeSlot]
(
	@SlotID INT,
	@PlannedDate DATETIME
) 
AS BEGIN
SET NOCOUNT ON;
	BEGIN TRY
		DECLARE @CurrentPlannedDate DATETIME, @CurrentPeriodName NVARCHAR(100);
		DECLARE @ChangedPeriod INT;
		DECLARE @InRange INT;
		DECLARE @SlotLinkedToTest INT;
		
		IF NOT EXISTS (SELECT SlotID FROM Slot WHERE SlotID = @SlotID) BEGIN	
			EXEC PR_ThrowError 'Invalid slot';
			RETURN;
		END

		SELECT @SlotLinkedToTest = Count(TestID) FROM SlotTest WHERE SlotID = @SlotID;

		--IF EXISTS(SELECT SlotID FROM SlotTest WHERE SlotID = @SlotID) BEGIN
		--	EXEC PR_ThrowError 'Slot is already assigned to some tests. Cannot move this slot to new planned date.';
		--	RETURN;
		--END

		--First we have to select before we update data for this stored procedure
		SELECT 
			@CurrentPeriodName = PeriodName, 
			@CurrentPlannedDate = PlannedDate		
		FROM Slot S
		JOIN [Period] P ON P.PeriodID = S.PeriodID WHERE S.SlotID = @SlotID;


		IF(@PlannedDate <> @CurrentPlannedDate  AND ISNULL(@SlotLinkedToTest,0) <> 0)
		BEGIN
			EXEC PR_ThrowError 'Slot is already assigned to some tests. Cannot move this slot to new planned date.';
			RETURN;
		END
				
		SELECT @ChangedPeriod = PeriodID
		FROM Period WHERE @PlannedDate BETWEEN StartDate AND EndDate;

		DECLARE @ReturnValue INT, @AdditionalMarker INT, @AdditionalPlates INT;

		--begin transaction here
		BEGIN TRAN
		
			--#10396
			--EXEC PR_Validate_Capacity_Period_Protocol @SlotID, @PlannedDate, @AdditionalMarker OUT,  @AdditionalPlates OUT;
			--#10396 END

			--Update slot status to 200
			UPDATE Slot 
				SET PlannedDate = CAST(@PlannedDate AS DATE),
				PeriodID = @ChangedPeriod,
				StatusCode = 200,
				AlreadyApproved = 1
			WHERE SlotID = @SlotID;
			
			 --update reservedCapacity if slot is pending due to edited value.
			 UPDATE ReservedCapacity SET 
				NrOfTests = NewNrOfTests,
				NewNrOfTests = 0
			 WHERE SlotID = @SlotID AND ISNULL(NewNrOfTests,0) > 0
		COMMIT TRAN;

		SELECT 
			ReservationNumber = RIGHT('0000' + CAST(SlotID AS NVARCHAR(5)),5), 
			SlotName, 
			PeriodName = @CurrentPeriodName, 
			ChangedPeriodname = PeriodName, 
			PlannedDate = @CurrentPlannedDate,
			ChangedPlannedDate = PlannedDate,
			RequestUser
		FROM Slot S
		JOIN [Period] P ON P.PeriodID = S.PeriodID WHERE S.SlotID = @SlotID;
		
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK;
		THROW;
	END CATCH
END
GO


