
/*
Author					Date			Description
Binod Gurung			2021/06/03		Edit slot info and reserved capacity
===================================Example================================
DECLARE @Message NVARCHAR(MAX);
EXEC [PR_LFDISK_EditSlot] 10712,1100,'2021/07/07',0, @Message OUT
*/
ALTER PROCEDURE [dbo].[PR_LFDISK_EditSlot]
(
	@SlotID INT,
	@NrOfTests INT,
	@PlannedDate DATETIME NULL,
	@Forced BIT,
	@Message NVARCHAR(MAX) OUT
)
AS
BEGIN
	
	DECLARE @TotalTestsUsed INT, @ActualTests INT, @TotalAvailableTests INT, @TestProtocolID INT, @PeriodID INT, @ReservedTests INT,@NextPeriod INT,@NextPeriodEndDate DATETIME, @PeriodStartDate DATETIME, @Isolated BIT, @TesttypeID INT;
	DECLARE @Msg NVARCHAR(MAX),	@CurrentPeriodEndDate DATETIME, @ChangedPlannedPeriodID INT;
	DECLARE @InRange BIT =1, @NewNrOfTests INT, @SiteID INT;

	DECLARE @CurrentPlannedDate DATETIME, @CurrentExpectedDate DATETIME, @StartDate DATETIME, @EndDate DATETIME;

	--get period for provided slot. 
	SELECT @PeriodID = PeriodID, @Isolated = Isolated, @TesttypeID = TestTypeID, @SiteID = SiteID FROM Slot WHERE SlotID = @SlotID;

	SELECT 
		@StartDate = StartDate,
		@EndDate = EndDate
	FROM [Period] 
	WHERE PeriodID = @PeriodID

	IF(ISNULL(@PlannedDate,'') = '')
	BEGIN
		SELECT @PlannedDate = PlannedDate FROM Slot WHERE SlotID = @SlotID;
	END

	--get changed period ID
	SELECT @ChangedPlannedPeriodID = PeriodID FROM [Period] WHERE @PlannedDate BETWEEN StartDate AND EndDate;

	--Check if planned date is changed and test linked to this slot is already sent to lims
	IF EXISTS (SELECT St.SlotID FROM SlotTest ST
			JOIN Test T ON T.TestID = ST.TestID
			WHERE ST.SlotID = @SlotID AND T.StatusCode > 400)
	BEGIN				
		SELECT @CurrentPlannedDate = PlannedDate FROM Slot WHERE SlotID = @SlotID;
		IF(CAST(@CurrentPlannedDate AS DATETIME) <> CAST(@PlannedDate AS DATETIME))
		BEGIN
			EXEC PR_ThrowError 'Plateplan/Test linked with this slot is already sent to LIMS. Cannot change planned date.';
			RETURN;
		END
	END

	IF(@PeriodID = @ChangedPlannedPeriodID)
	BEGIN
		UPDATE Slot SET PlannedDate = @PlannedDate WHERE SlotID = @SlotID;
	END

	--if no period fould return error.
	IF(ISNULl(@PeriodID,0) = 0)
	BEGIN
		SET @Msg =N'Invalid slot.';
		EXEC PR_ThrowError @Msg;
	END

	IF(ISNULl(@PeriodID,0) = 0)
	BEGIN
		SET @Msg =N'Period not found for changed date.';
		EXEC PR_ThrowError @Msg;
	END

	--get current period end date to calculate whether slot updated is for current current period week + 1 week.
	SELECT TOP 1 @CurrentPeriodEndDate = EndDate
	FROM [Period]
	WHERE CAST(GETDATE() AS DATE) BETWEEN StartDate AND EndDate;

	SELECT TOP 1 @NextPeriod = PeriodID,
		@NextPeriodEndDate = EndDate
	FROM [Period]
	WHERE StartDate > @CurrentPeriodEndDate
	ORDER BY StartDate;
	
	--check if next period is available to get next period end date.
	IF(ISNULL(@NextPeriod,0)=0) BEGIN
		EXEC PR_ThrowError 'Next Period Not found';
		RETURN;
	END

	SELECT @PeriodStartDate = StartDate
	FROM [Period] WHERE PeriodID = @PeriodID
	
	SELECT @ActualTests = SUM(NrOfTests), @NewNrOfTests = SUM(NewNrOfTests) FROM ReservedCapacity WHERE SlotID = @SlotID

	--Week range warning display only if the number of tests is increased
	IF((@PeriodID <> @ChangedPlannedPeriodID AND @PlannedDate < @NextPeriodEndDate) OR (@PeriodStartDate < @NextPeriodEndDate AND (ISNULL(@NrOfTests,0) > @ActualTests)))
	BEGIN
		SET @InRange = 0;
		IF(ISNULL(@Forced,0) = 0)
		BEGIN
			SET @Message = 'Week range is too short to update value or Slot is moving to next week. You need lab approval to apply this change. Do you want continue?';
			RETURN;
		END
	END
	
	IF(ISNULL(@NewNrOftests,0) <> ISNULL(@ActualTests,0) OR ISNULL(@ActualTests,0) <> ISNULL(@NrOfTests,0) OR @PeriodID <> @ChangedPlannedPeriodID)
	BEGIN
		IF(@PeriodID <> @ChangedPlannedPeriodID)
		BEGIN
			IF EXISTS (SELECT * FROM SlotTest ST
			JOIN Test T ON T.TestID = ST.TestID
			WHERE ST.SlotID = @SlotID AND T.StatusCode > 400)
			BEGIN
				EXEC PR_ThrowError 'Plateplan/Test linked with this slot is already sent to LIMS. Cannot move slot to another week.';
				RETURN;
			END
			ELSE
			BEGIN
				IF EXISTS (SELECT * FROM SlotTest ST
				JOIN Test T ON T.TestID = ST.TestID
				WHERE ST.SlotID = @SlotID)
				BEGIN
					EXEC PR_ThrowError 'PlatePlan/Test already linked to this slot. Either unlink test from this slot or change planned/expected date of test linked with this slot.';
					RETURN;
				END
			END
		END

		--validation : this code will be needed in the future
		--Get total number of sample used
		SELECT
			@TotalTestsUsed = COUNT(STT.SampleTestID) 
		FROM Slot S
		JOIN SlotTest ST ON ST.SlotID = S.SlotID
		JOIN LD_SampleTest STT On STT.TestID = ST.TestID
		WHERE S.SlotID = @SlotID

		IF(ISNULL(@NrOfTests,0) < @TotalTestsUsed)
		BEGIN
			SET @Msg = +CAST(@TotalTestsUsed AS NVARCHAR(MAX)) + ' Sample(s) is already consumed by Test(s). Value cannot be less than already consumed.';
			EXEC PR_ThrowError @Msg;
			RETURN;
		END

		--IF Plate is null then this is marker protocol
		SELECT @TestProtocolID = TestProtocolID 
		FROM ReservedCapacity WHERE SlotID = @SlotID; 

		SELECT @TotalAvailableTests = MAX(NrOfTests) FROM AvailCapacity WHERE TestProtocolID = @TestProtocolID AND PeriodID = @ChangedPlannedPeriodID AND SiteID = @SiteID;

		IF(ISNULL(@TotalAvailableTests,0) = 0)
		BEGIN
			EXEC PR_ThrowError 'Capacity is not planned for selected week. Lab need to plan capacity first.'
			RETURN;
		END

		SELECT @ReservedTests = SUM(ISNULL(NrOfTests,0)) FROM ReservedCapacity RC
		JOIN Slot S ON S.SlotID = RC.SlotID 
		WHERE TestProtocolID = @TestProtocolID AND S.SlotID <> @SlotID AND S.SiteID = @SiteID
		AND (S.PlannedDate BETWEEN @StartDate AND @EndDate)
		AND (S.StatusCode = 200 OR (S.StatusCode = 100 AND ISNULL(RC.NewNrOfTests,0)>0));

		--can increase capacity if it is in range. 
		IF(@InRange = 1 
			AND ISNULL(@TotalAvailableTests,0) >= (ISNULL(@ReservedTests,0) + ISNULL(@NrOfTests,0)))
		BEGIN
			
			UPDATE ReservedCapacity SET NrOfTests = @NrOfTests, NewNrOfTests = 0  WHERE SlotID  = @SlotID		

			--update slot status to approved when it is in range and update other values accordingly.
			UPDATE Slot SET 
				PlannedDate = CASE WHEN ISNULL(@PlannedDate,'') = '' THEN PlannedDate ELSE @PlannedDate END,
				PeriodID = @ChangedPlannedPeriodID,
				AlreadyApproved = 1,
				StatusCode = 200
			WHERE SlotID = @SlotID
			
			RETURN;
		END

		--if capacity is not in range and forced bit if false then return error message.
		IF(ISNULL(@TotalAvailableTests,0) < (ISNULL(@ReservedTests,0) + ISNULL(@NrOfTests,0)))
		BEGIN
			SET @InRange = 0;
			IF(ISNULl(@Forced,0) = 0)
			BEGIN
				SET @Message = 'Lab capacity is full. You need lab approval to apply this change. Do you want to continue?';
				RETURN;
			END
		END

		IF(@Forced = 1 AND ISNULL(@InRange,0) = 0)
		BEGIN

			IF EXISTS (SELECT SlotID FROM Slot WHERE SlotID = @SlotID AND AlreadyApproved = 1)
			BEGIN
				--UPDATE RESERVE CAPACITY with new number of tests when approved once
				if(@ActualTests <> @NrOfTests)
					UPDATE ReservedCapacity SET NewNrOfTests = @NrOfTests WHERE SlotID  = @SlotID
			END
			ELSE
			BEGIN
				--UPDATE RESERVE CAPACITY with new number of tests when it is not approved before
				if(@ActualTests <> @NrOfTests)
					UPDATE ReservedCapacity SET NrOfTests = @NrOfTests WHERE SlotID  = @SlotID
			END
				
			--UPDATE SLOT	(update slot status to 100 which revert the status of slot back to requested when capacity is not within limit)
			UPDATE Slot SET 
				PlannedDate = CASE WHEN ISNULL(@PlannedDate,'') = '' THEN PlannedDate ELSE @PlannedDate END,
				PeriodID = @ChangedPlannedPeriodID,
				StatusCode = 100
			WHERE SlotID = @SlotID		
			RETURN;
			
		END
		ELSE
		BEGIN
			
			UPDATE ReservedCapacity SET NrOfTests = @NrOfTests, NewNrOfTests = 0  WHERE SlotID  = @SlotID
				
			--UPDATE SLOT				
			UPDATE Slot SET 
				PlannedDate = CASE WHEN ISNULL(@PlannedDate,'') = '' THEN PlannedDate ELSE @PlannedDate END,
				PeriodID = @ChangedPlannedPeriodID,
				AlreadyApproved = 1,
				StatusCode = 200
			WHERE SlotID = @SlotID

			RETURN;
		END
	END
END

GO



/*
Authror					Date				Description
Krishna Gautam			2021/06/02			#22627: Stored procedure created
Krishna Gautam			2021/06/22			#22408: Added site location.

DECLARE @IsSuccess BIT,@Message NVARCHAR(MAX);
EXEC PR_PR_LFDISK_Reserve_Capacity 'AUNA','LT',9,15,1,'2021-06-13 12:07:25.090',1007,100,'KATHMANDU\Krishna',0,'tt',@IsSuccess OUT,@Message OUT
PRINT @IsSuccess;
PRINT @Message;
*/

ALTER PROCEDURE [dbo].[PR_LFDISK_Reserve_Capacity]
(
	@BreedingStationCode NVARCHAR(10),
	@CropCode NVARCHAR(10),
	@TestTypeID INT,
	@MaterialTypeID INT,
	@PlannedDate DateTime,
	@TestProtocolID INT,
	@NrOfSample INT,
	@User NVARCHAR(200),
	@Forced BIT,
	@Remark NVARCHAR(MAX),
	@SiteID INT,
	@IsSuccess BIT OUT,
	@Message NVARCHAR(MAX) OUT
)
AS
BEGIN
	--SELECT * FROM TEST
	SET NOCOUNT ON;
	BEGIN TRY
		DECLARE @PeriodID INT,@InRange BIT = 1, @SlotID INT, @NextPeriod INT, @CurrentPeriodEndDate DATETIME,@NextPeriodEndDate DATETIME;
		DECLARE @ReservedSamples INT=0, @CapacitySamples INT=0;
		DECLARE @MaxSlotID INT, @SlotName NVARCHAR(100);

			
		SELECT TOP 1 @CurrentPeriodEndDate = EndDate
		FROM [Period]
		WHERE CAST(GETDATE() AS DATE) BETWEEN StartDate AND EndDate

		SELECT TOP 1 @PeriodID = PeriodID
		FROM [Period]
		WHERE @PlannedDate BETWEEN StartDate AND EndDate
		
		--check test protocol
		IF NOT EXISTS (SELECT * FROM TestProtocol WHERE TestProtocolID = ISNULL(@TestProtocolID,0))
		BEGIN
			EXEC PR_ThrowError 'Invalid test protocolID';
			RETURN;
		END

		--check test typeID
		IF NOT EXISTS (SELECT * FROM TestType WHERE TestTypeID = ISNULL(@TestTypeID,0))
		BEGIN
			EXEC PR_ThrowError 'Invalid test type';
			RETURN;
		END

		--check period
		IF(ISNULL(@PeriodID,0)=0) BEGIN
			EXEC PR_ThrowError 'No period found for selected date';
			RETURN;
		END
		
		--check siteID
		IF NOT EXISTS (SELECT * FROM SiteLocation WHERE SiteID = ISNULL(@SiteID,0))
		BEGIN
			EXEC PR_ThrowError 'Invalid site location';
			RETURN;
		END

		SELECT TOP 1 @NextPeriod = PeriodID,
		@NextPeriodEndDate = EndDate
		FROM [Period]
		WHERE StartDate > @CurrentPeriodEndDate
		ORDER BY StartDate;

		IF(ISNULL(@NextPeriod,0)=0) BEGIN
			EXEC PR_ThrowError 'No Next period found for selected date';
			RETURN;
		END

		IF(@PlannedDate  <= @NextPeriodEndDate) BEGIN			
			SET @InRange = 0;
			SET @IsSuccess = 0;
			SET @Message = 'Reservation time is too short. Do you want to request for reservation anyway?';
			IF(@Forced = 0)
				RETURN;
		END

		--get already reserved samples for selected Period
		SELECT 
			@ReservedSamples = ISNULL(SUM(ISNULL(RC.NrOfTests,0)),0)
		FROM ReservedCapacity RC 
		JOIN Slot S ON S.SlotID = RC.SlotID
		WHERE S.PeriodID = @PeriodID 
		AND S.TestTypeID = 9 --Leafdisk
		AND TestProtocolID = @TestProtocolID 
		AND S.SiteID = ISNULL(@SiteID,0)
		AND (S.StatusCode = 200 OR (S.StatusCode = 100  AND ISNULL(S.AlreadyApproved,0) = 1));
				
		--get total capacity samples defined in lab.
		SELECT 
			@CapacitySamples = ISNULL(NrOfTests,0)
		FROM AvailCapacity
		WHERE PeriodID = @PeriodID 
		AND SiteID = ISNULL(@SiteID,0)
		AND TestProtocolID = @TestProtocolID;

		IF(ISNULL(@CapacitySamples,0) = 0)
		BEGIN
			EXEC PR_ThrowError 'Capacity is not planned for selected week. Lab need to plan capacity first.'
			RETURN;
		END

		--check with capacity
		IF((@ReservedSamples + ISNULL(@NrOfSample,0)) > @CapacitySamples)
		BEGIN
			--this means limit exceed.
			SET @InRange = 0;
		END

		--do not create data if not in range and forced bit is false.
		IF(@Forced = 0 AND @InRange = 0) BEGIN
			SET @IsSuccess = 0;
			SET @Message = 'Reservation quota is already occupied. Do you want to reserve this capacity anyway?';
			RETURN;
		END

		BEGIN TRANSACTION;
			SELECT @MaxSlotID = ISNULL(IDENT_CURRENT('Slot'),0) + 1
			FROM Slot;

			IF(ISNULL(@MaxSlotID,0) = 0) BEGIN
				SET @MaxSlotID = 1;
			END

			SET @SlotName = @BreedingStationCode + '-' + @CropCode + '-' + RIGHT('00000'+CAST(@MaxSlotID AS NVARCHAR(10)),5);
			--on this case create slot and reserved capacity data			
			IF(@InRange = 1) BEGIN
				INSERT INTO Slot(SlotName, PeriodID, StatusCode, CropCode, MaterialTypeID, RequestUser, RequestDate, PlannedDate, BreedingStationCode, Remark,TestTypeId,AlreadyApproved,MaterialStateID,SiteID)
				VALUES(@SlotName,@PeriodID,200,@CropCode,@MaterialTypeID,@User,GETDATE(),@PlannedDate,@BreedingStationCode, @Remark,@TestTypeID,1,2,@SiteID);

				SELECT @SlotID = SCOPE_IDENTITY();

				SET @IsSuccess = 1;
				SET @Message = 'Reservation for '+ @SlotName + ' is completed.';				
			END
			ELSE IF(@Forced = 1 AND @InRange = 0) BEGIN				
				--create logic here....				
				INSERT INTO Slot(SlotName, PeriodID, StatusCode, CropCode, MaterialTypeID,  RequestUser, RequestDate, PlannedDate, BreedingStationCode,Remark,TestTypeID,MaterialStateID,SiteID)
				VALUES(@SlotName, @PeriodID, 100, @CropCode, @MaterialTypeID,  @User, GETDATE(), @PlannedDate,  @BreedingStationCode,  @Remark, @TestTypeID,2,@SiteID);

				SELECT @SlotID = SCOPE_IDENTITY();	

				SET @IsSuccess = 1;
				SET @Message = 'Your request for '+ @SlotName + ' is pending. You will get notification after action from LAB.';		
			END

			--create reserve capacity here
			INSERT INTO ReservedCapacity(SlotID, TestProtocolID, NrOfTests)
			VALUES(@SlotID,@TestProtocolID, @NrOfSample);

		COMMIT;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK;
		THROW;
	END CATCH

END

GO
