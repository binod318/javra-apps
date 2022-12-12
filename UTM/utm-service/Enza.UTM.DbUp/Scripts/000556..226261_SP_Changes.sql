/*
	Author					Date			Description
-------------------------------------------------------------------
	Binod Gurung			2021/06/03		Change slot info and reserved capacity Leaf disk
-------------------------------------------------------------------
EXEC [PR_LFDISK_ChangeSlot] 69 
*/

ALTER PROC [dbo].[PR_LFDISK_ChangeSlot]
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
			RequestUser,
			S.TestTypeID,
			SL.SiteName
		FROM Slot S
		JOIN [Period] P ON P.PeriodID = S.PeriodID
		LEFT JOIN [SiteLocation] SL ON SL.SiteID = S.SiteID
		WHERE S.SlotID = @SlotID;
		
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK;
		THROW;
	END CATCH
END

GO

/*
Author					Date			Description
Krishna Gautam							Stored procedure created
Krishna Gautam			2020-Nov-23		#16323: When slot is denied/Rejected (then check if test is linked, if linked then reject for new requested marker and plates and											approve already approved slots.
Krishna Gautam			2021-02-16		#19474: Upate already approved value in slot.

===================================Example================================

EXEC PR_PLAN_RejectSlot 8
*/

ALTER PROC [dbo].[PR_PLAN_RejectSlot]
(
	@SlotID INT
) 
AS BEGIN
SET NOCOUNT ON;
	BEGIN TRY
		DECLARE @TestID INT;
		DECLARE @NrOftests INT, @NrOfPlates INT;
		BEGIN TRAN
			IF NOT EXISTS (SELECT SlotID FROM Slot WHERE SlotID = @SlotID) BEGIN	
				EXEC PR_ThrowError 'Invalid slot';
				RETURN;
			END

			--IF EXISTS(SELECT SlotID FROM SlotTest WHERE SlotID = @SlotID) 
			--BEGIN
			--	EXEC PR_ThrowError 'Slot is already assigned to some tests. Cannot reject this slot.';
			--	RETURN;
			--END

			----EXEC PR_PLAN_UpdateCapacitySlot @SlotID,300;
			--SELECT 
			--	@NrOftests = SUM(ISNULL(NewNrOfTests,0)),
			--	@NrOfPlates = SUM(ISNULL(NewNrOfPlates,0))
			--FROM ReservedCapacity RC
			--WHERE SLotID = @SlotID

			--IF(ISNULL(@NrOfTests,0) > 0 OR ISNULL(@NrOfPlates,0) > 0)
			--BEGIN
			--	UPDATE ReservedCapacity	SET 
			--		NewNrOfPlates = 0,
			--		NewNrOfTests = 0
			--	WHERE SlotID = @SlotID;
				
			--	UPDATE Slot SET StatusCode = 200 WHERE SlotID = @SlotID;
			--END
			--ELSE
			--BEGIN
			--	EXEC PR_PLAN_UpdateCapacitySlot @SlotID,300;
			--END

			
			SELECT 
				@NrOftests = SUM(ISNULL(NewNrOfTests,0)),
				@NrOfPlates = SUM(ISNULL(NewNrOfPlates,0))
			FROM ReservedCapacity RC
			WHERE SLotID = @SlotID

			IF(ISNULL(@NrOfTests,0) > 0 OR ISNULL(@NrOfPlates,0) > 0)
			BEGIN
				UPDATE ReservedCapacity	SET 
					NewNrOfPlates = 0,
					NewNrOfTests = 0
				WHERE SlotID = @SlotID;
				--check if slot is already approved one or not
				--IF EXISTS (SELECT TOP 1 * FROM SlotTest WHERE SlotID = @SlotID)
				IF EXISTS (SELECT * FROM Slot WHERE SlotID = @SlotID AND ISNULL(AlreadyApproved,0) = 1)
				BEGIN
					UPDATE Slot SET StatusCode = 200 WHERE SlotID = @SlotID;
				END				
				ELSE
				BEGIN
					UPDATE Slot SET StatusCode = 300 WHERE SlotID = @SlotID;
				END
			END
			--else simply deny slot.
			ELSE
			BEGIN
				UPDATE Slot SET StatusCode = 300 WHERE SlotID = @SlotID;
			END

		COMMIT TRAN;

		SELECT 
			ReservationNumber = RIGHT('0000' + CAST(SlotID AS NVARCHAR(5)),5), 
			SlotName, 
			PeriodName, 
			ChangedPeriodname = PeriodName, 
			PlannedDate,
			ChangedPlannedDate = PlannedDate, 
			RequestUser, 
			ExpectedDate, 
			ChangedExpectedDate = ExpectedDate,
			TestType = S.TestTypeID,
			SL.SiteName
		FROM Slot S
		JOIN [Period] P ON P.PeriodID = S.PeriodID 
		LEFT JOIN [SiteLocation] SL ON SL.SiteID = S.SiteID
		WHERE S.SlotID = @SlotID;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK;
		THROW;
	END CATCH
END


GO

/*
	Author					Date			Description
-------------------------------------------------------------------
	Krishna Gautam			-				SP Created
	Krishna Gautam			2020-03-12		-
	Krishna Gautam			2021-02-16		#19474: Upate already approved value in slot.
-------------------------------------------------------------------
*/
ALTER PROC [dbo].[PR_PLAN_ApproveSlot]
(
	@SlotID INT
) 
AS BEGIN
SET NOCOUNT ON;
	--DECLARE @PlannedDate DATETIME,@AdditionalMarker INT,@AdditionalPlates INT;
	BEGIN TRY
		BEGIN TRAN
			
			IF NOT EXISTS (SELECT SlotID FROM Slot WHERE SlotID = @SlotID) BEGIN	
				EXEC PR_ThrowError 'Invalid slot';
				RETURN;
			END
			--SELECT @PlannedDate = PlannedDate from Slot WHERE SlotID = @SlotID;
			
			--EXEC PR_Validate_Capacity_Period_Protocol @SlotID,@PlannedDate,@AdditionalMarker OUT,@AdditionalPlates OUT;

			--EXEC PR_PLAN_UpdateCapacitySlot @SlotID,200;	
			UPDATE Slot SET 
				StatusCode = 200,
				AlreadyApproved = 1
				WHERE SlotID = @SlotID;
			
			UPDATE ReservedCapacity SET
				NrOfPlates = CASE WHEN ISNULL(NewNrOfPlates,0) > 0 THEN NewNrOfPlates ELSE NrOfPlates END,
				NrOfTests = CASE WHEN ISNULL(NewNrOfTests,0) > 0 THEN NewNrOfTests ELSE NrOfTests END,
				NewNrOfTests = 0,
				NewNrOfPlates = 0
			 WHERE SlotID = @SlotID;

		COMMIT TRAN;
		SELECT
			ReservationNumber = RIGHT('0000' + CAST(SlotID AS NVARCHAR(5)),5), 
			SlotName, 
			PeriodName, 
			ChangedPeriodname = PeriodName, 
			PlannedDate,
			ChangedPlannedDate = PlannedDate, 
			RequestUser, 
			ExpectedDate, 
			ChangedExpectedDate = ExpectedDate,
			TestType = S.TestTypeID,
			SL.SiteName
		FROM Slot S
		JOIN [Period] P ON P.PeriodID = S.PeriodID 
		LEFT JOIN [SiteLocation] SL ON SL.SiteID = S.SiteID
		WHERE S.SlotID = @SlotID;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK;
		THROW;
	END CATCH
END
GO