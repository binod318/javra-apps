/*
Author					Date			Description
Binod Gurung			2021/06/08		Save Plots to sample
Krishna Gautam			2021/06/29		Change service to prevent giving duplicate sample name for atleast same test.
===================================Example================================
EXEC [PR_LFDISK_SaveSampleTest] 12701, 'PSample',5
*/
ALTER PROCEDURE [dbo].[PR_LFDISK_SaveSampleTest]
(
	@TestID INT,
	@SampleName NVARCHAR(150),
	@NrOfSamples INT,
	@SampleID INT = NULL,
	@Action NVARCHAR(MAX) = NULL
)
AS
BEGIN
	
	SET NOCOUNT ON;
	DECLARE @Sample TABLE(ID INT);
	DECLARE @ExistingSample TABLE(SampleID INT, SampleName NVARCHAR(MAX));
	DECLARE @SampleToCreate TABLE(SampleName NVARCHAR(MAX));
	DECLARE @CustName NVARCHAR(50), @Counter INT = 1, @StatusCode INT;
	DECLARE @DuplicateNameFound BIT;
	
	IF NOT EXISTS (SELECT TestID FROM Test WHERE TestID = @TestID )
	BEGIN
		EXEC PR_ThrowError N'Invalid Test.';
		RETURN;
	END

	SELECT @StatusCode = StatusCode FROM Test WHERE TestID = @TestID;

	IF(ISNULL(@StatusCode,0) >=500)
	BEGIN
		EXEC PR_ThrowError 'Cannot save sample for test which is sent to LIMS.';
		RETURN;
	END
	--get name for number of samples
	IF(ISNULL(@SampleID,0) = 0 AND ISNULL(@Action,'') <> 'remove')
	BEGIN
		--get already existing samples
		INSERT INTO @ExistingSample(SampleID, SampleName)
		SELECT 
			S.SampleID,
			S.SampleName 
		FROM LD_Sample S
		JOIN LD_SampleTest ST ON S.SampleID = ST.SampleID
		WHERE ST.TestID  = @TestID

		IF(@NrOfSamples <=1)
		BEGIN
			
			SET @CustName = @SampleName;
			SELECT @DuplicateNameFound = CASE WHEN ISNULL(COUNT(SampleID),0) > 0 THEN 1 ELSE 0 END  FROM @ExistingSample WHERE SampleName = @CustName;
			WHILE(ISNULL(@DuplicateNameFound,0) <> 0)
			BEGIN
			
				IF(@NrOfSamples >=1000)
					RETURN;
				IF(@NrOfSamples >= 100)
					SET @CustName = @SampleName + '-' + RIGHT('000'+CAST(@Counter AS NVARCHAR(10)),3);
				ELSE IF(@NrOfSamples >= 10)
					SET @CustName = @SampleName + '-' + RIGHT('00'+CAST(@Counter AS NVARCHAR(10)),2);
				ELSE
					SET @CustName = @SampleName + '-' + CAST(@Counter AS NVARCHAR(10));
				--get name with counter value
				SELECT @DuplicateNameFound = CASE WHEN ISNULL(COUNT(SampleID),0) > 0 THEN 1 ELSE 0 END  FROM @ExistingSample WHERE SampleName = @CustName;
				--increase counter after that.
				SET @Counter = @Counter + 1;
			END
			INSERT INTO @SampleToCreate(SampleName)
			Values(@CustName);

		END
		--When more than 1 material required
		ELSE
		BEGIN
			--this loop is necessary for avoiding same name
			WHILE ( @Counter <= @NrOfSamples)
			BEGIN	
				SET @DuplicateNameFound = 1;
				WHILE(ISNULL(@DuplicateNameFound,0) <> 0)
				BEGIN
					IF(@Counter >=1000)
						RETURN;

					SET @CustName = @SampleName + '-' + CAST(@Counter AS NVARCHAR(10));

					--Check if same name exists if exists then increase the sample name
				
					SELECT @DuplicateNameFound = CASE WHEN ISNULL(COUNT(SampleID),0) > 0 THEN 1 ELSE 0 END  FROM @ExistingSample WHERE SampleName = @CustName;
					IF(ISNULL(@DuplicateNameFound,0) <> 0)
					BEGIN
						--increase both counter to get new name
						SET @Counter  = @Counter  + 1
						SET @NrOfSamples = @NrOfSamples +1;
					END
				END

				INSERT INTO @SampleToCreate(SampleName)
				Values(@CustName);
				SET @Counter  = @Counter  + 1
			END
		END
		INSERT INTO LD_Sample(SampleName)
		OUTPUT inserted.SampleID INTO @Sample
		SELECT SampleName FROM @SampleToCreate;

		INSERT INTO LD_SampleTest(SampleID,TestID)
		SELECT ID, @TestID FROM @Sample;

	END
	--rename sample name
	ELSE
	BEGIN
		
		--delete sample from sample test
		DELETE ST FROM LD_SampleTest ST
		JOIN LD_Sample S ON S.SampleID = ST.SampleID
		WHERE S.SampleID = @SampleID;

		--delete sample
		DELETE LD_Sample WHERE SampleID = @SampleID;
	END

END

GO


DROP PROCEDURE IF EXISTS PR_LFDISK_EditSlot
GO
/*
Author					Date			Description
Binod Gurung			2021/06/03		Edit slot info and reserved capacity
===================================Example================================
DECLARE @Message NVARCHAR(MAX);
EXEC [PR_LFDISK_EditSlot] 10712,1100,'2021/07/07',0, @Message OUT
*/
CREATE PROCEDURE [dbo].[PR_LFDISK_EditSlot]
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

		SELECT @TotalAvailableTests = MAX(NrOfTests) FROM AvailCapacity WHERE TestProtocolID = @TestProtocolID AND PeriodID = @PeriodID AND SiteID = @SiteID;

		SELECT @ReservedTests = SUM(ISNULL(NrOfTests,0)) FROM ReservedCapacity RC
		JOIN Slot S ON S.SlotID = RC.SlotID 
		WHERE TestProtocolID = @TestProtocolID AND S.SlotID <> @SlotID AND S.SiteID = @SiteID
		AND (S.PlannedDate BETWEEN @StartDate AND @EndDate)
		AND (S.StatusCode = 200 OR (S.StatusCode = 100 AND ISNULL(RC.NewNrOfTests,0)>0));

		PRINT '@TotalAvailableTests';
		PRINT @TotalAvailableTests;
		PRINT @ReservedTests;
		PRINT @NrOfTests;
		RETURN;

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