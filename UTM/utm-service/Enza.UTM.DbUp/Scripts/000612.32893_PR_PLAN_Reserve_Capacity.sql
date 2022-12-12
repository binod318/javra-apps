/*
Authror					Date				Description
KRIAHNA GAUTAM								SP Created
KRIAHNA GAUTAM			2020-Mar-24			#11242: Change request to add remark.
KRIAHNA GAUTAM			2020-Nov-11			#16340: Date is taking timezone
KRIAHNA GAUTAM			2020-Nov-11			#18921: Add testtype in slot.
KRIAHNA GAUTAM			2021-Feb-16			# :Added already approved in slot.
BINOD GURUNG			2021-May-06			#21340 : Automatic approve reserve slots for DNA isolation and isolated always
KRISHNA GAUTAM			2022-Feb-15			#32473 : Block reservation of slot when no capacity is planned for selected week.

DECLARE @IsSuccess BIT,@Message NVARCHAR(MAX);
EXEC PR_PLAN_Reserve_Capacity 'AUNA','LT',1,1,1,0,'2018-04-16 12:07:25.090','2018-05-15 12:07:25.090',20,20,'KATHMANDU\Krishna',0,'tt',@IsSuccess OUT,@Message OUT
PRINT @IsSuccess;
PRINT @Message;
*/

ALTER PROCEDURE [dbo].[PR_PLAN_Reserve_Capacity]
(
	@BreedingStationCode NVARCHAR(10),
	@CropCode NVARCHAR(10),
	@TestTypeID INT,
	@MaterialTypeID INT,
	@MaterialStateID INT,
	@Isolated BIT,
	@PlannedDate DateTime,
	@ExpectedDate DateTime,
	@NrOfPlates INT,
	@NrOfTests INT,
	@User NVARCHAR(200),
	@Forced BIT,
	@Remark NVARCHAR(MAX),
	@IsSuccess BIT OUT,
	@Message NVARCHAR(MAX) OUT
)
AS
BEGIN
	--SELECT * FROM TEST
	SET NOCOUNT ON;
	BEGIN TRY
		DECLARE @MarkerTypeTestProtocolID INT =0, @DNATypeTestProtocolID INT =0, @PeriodID INT,@InRange BIT = 1, @SlotID INT, @NextPeriod INT, @CurrentPeriodEndDate DATETIME,@NextPeriodEndDate DATETIME,@PeriodIDForTest INT;
		DECLARE @ReservedPlates INT =0, @ReservedTests INT=0, @CapacityPlates INT =0, @CapacityTests INT=0,@AutomaticApprove BIT = 0;
		DECLARE @MaxSlotID INT, @SlotName NVARCHAR(100);

		--TesttypeId = 2 for DNA Isolation : Automatic approve for DNA Isolation and Isolated
		IF(ISNULL(@TestTypeID,0) = 2 AND ISNULL(@Isolated,0) = 1)
			SET @AutomaticApprove = 1;
	
		--@DNATypeTestProtocolID is for Plates
		IF(ISNULL(@Isolated,0) = 0) BEGIN
			SELECT @DNATypeTestProtocolID = MTP.TestProtocolID 
			FROM MaterialTypeTestProtocol MTP
			JOIN TestProtocol TP ON TP.TestProtocolID = MTP.TestProtocolID
			WHERE MaterialTypeID = @MaterialTypeID AND CropCode = @CropCode AND TP.TestTypeID = 2; --hard code value 2 for DNA type
		END
		ELSE BEGIN
			SELECT TOP 1 @DNATypeTestProtocolID = TestProtocolID 
			FROM TestProtocol
			WHERE Isolated = 1 AND TestTypeID = 2; --hard code value 2 for DNA type
		END

		--@MarkerTypeTestProtocolID is for Tests
		IF EXISTS(SELECT TOP 1 TestTypeID FROM TestType WHERE TestTypeID = @TestTypeID AND DeterminationRequired = 1) BEGIN
			SELECT TOP 1 @MarkerTypeTestProtocolID = TestProtocolID 
			FROM TestProtocol
			WHERE TestTypeID = 1; --hard code value 1 for 2GB Markers
		END
		
			
		SELECT TOP 1 @CurrentPeriodEndDate = EndDate
		FROM [Period]
		--WHERE CAST(GETUTCDATE() AS DATE) BETWEEN StartDate AND EndDate
		WHERE CAST(GETDATE() AS DATE) BETWEEN StartDate AND EndDate

		SELECT TOP 1 @PeriodID = PeriodID
		FROM [Period]
		WHERE @PlannedDate BETWEEN StartDate AND EndDate

		SELECT TOP 1 @PeriodIDForTest = PeriodID
		FROM [Period]
		WHERE @ExpectedDate BETWEEN StartDate AND EndDate

		IF(ISNULL(@DNATypeTestProtocolID,0)=0) BEGIN
			EXEC PR_ThrowError 'No valid protocol found for selected material type and crop';
			RETURN;
		END

		IF(ISNULL(@PeriodID,0)=0) BEGIN
			EXEC PR_ThrowError 'No period found for selected date';
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

		--Testtype = 2 for DNA Isolation
		IF(@PlannedDate  <= @NextPeriodEndDate AND @AutomaticApprove = 0) BEGIN			
			SET @InRange = 0;
			SET @IsSuccess = 0;
			SET @Message = 'Reservation time is too short. Do you want to request for reservation anyway?';
			IF(@Forced = 0)
				RETURN;
		END

		--get reserved tests if selected testtype is marker tests
		SELECT 
			@ReservedTests = SUM(ISNULL(RC.NrOfTests,0))
		FROM ReservedCapacity RC 
		JOIN Slot S ON S.SlotID = RC.SlotID
		JOIN [Period] P ON S.ExpectedDate BETWEEN P.StartDate AND P.EndDate
		WHERE P.PeriodID = @PeriodIDForTest AND TestProtocolID = @MarkerTypeTestProtocolID AND (S.StatusCode = 200 OR (S.StatusCode = 100  AND ISNULL(RC.NewNrOfTests,0) >0));

		SET @ReservedTests = ISNULL(@ReservedTests,0);
		
		--WHERE S.PeriodID = @PeriodID AND S.StatusCode = 200 AND TestProtocolID IS NULL

		--get reserved plates for selected material type and crop
		SELECT 
			@ReservedPlates = SUM(ISNULL(RC.NrOfPlates,0))
		FROM ReservedCapacity RC 
		JOIN Slot S ON S.SlotID = RC.SlotID
		WHERE S.PeriodID = @PeriodID AND TestProtocolID = @DNATypeTestProtocolID AND (S.StatusCode = 200 OR (S.StatusCode = 100  AND ISNULL(RC.NewNrOfPlates,0) >0))

		SET @ReservedPlates = ISNULL(@ReservedPlates,0);
		

		--get total capacity (Test/Marker) per period only but to become to have data on db we added method.
		SELECT 
			@CapacityTests = NrOfTests
		FROM AvailCapacity
		WHERE PeriodID = @PeriodIDForTest AND TestProtocolID = @MarkerTypeTestProtocolID;

		

		SET @CapacityTests = ISNULL(@CapacityTests,0);

		--Get Total capacity( plates) PER period PER Method.
		SELECT 
			@CapacityPlates = NrOfPlates
		FROM AvailCapacity
		WHERE PeriodID = @PeriodID AND TestProtocolID = @DNATypeTestProtocolID;

		SET @CapacityPlates = ISNULL(@CapacityPlates,0);

		--for isolated check no of test(markers) and ignore no of plates.
		IF((ISNULL(@CapacityTests,0) = 0 AND ISNULL(@MarkerTypeTestProtocolID,0) <> 0)  OR (ISNULL(@Isolated,0) = 0 AND ISNULL(@CapacityPlates,0) = 0))
		BEGIN
			EXEC PR_ThrowError 'Capacity is not planned for selected week. Lab need to plan capacity first.'
			RETURN;
		END

		--for isolated check no of test(markers) and ignore no of plates.
		IF(ISNULL(@Isolated,0) =1) BEGIN
			IF((@ReservedTests + @NrOfTests) > @CapacityTests) BEGIN
				SET @InRange = 0;
			END
		END
		--for marker test type protocol we have to check both no of plates and no of tests(markers)
		ELSE IF(ISNULL(@MarkerTypeTestProtocolID,0) <> 0) BEGIN			
			IF(((@ReservedTests + @NrOfTests) > @CapacityTests) OR ( (@ReservedPlates + @NrOfPlates) > @CapacityPlates)) BEGIN
				SET @InRange = 0;
			END
		END
		--for dna  test type protocol we have to check only no plates not no of tests(markers)		
		ELSE BEGIN			
			IF(@ReservedPlates + @NrOfPlates > @CapacityPlates) BEGIN
				SET @InRange = 0;
			END
		END

		--do not create data if not in range and forced bit is false.
		IF(@Forced = 0 AND @InRange = 0 AND @AutomaticApprove = 0) BEGIN
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
				INSERT INTO Slot(SlotName, PeriodID, StatusCode, CropCode, MaterialTypeID, MaterialStateID, RequestUser, RequestDate, PlannedDate, ExpectedDate,BreedingStationCode,Isolated, Remark,TestTypeId,AlreadyApproved)
				VALUES(@SlotName,@PeriodID,200,@CropCode,@MaterialTypeID,@MaterialStateID,@User,GETDATE(),@PlannedDate,@ExpectedDate,@BreedingStationCode,@Isolated, @Remark,@TestTypeID,1);

				SELECT @SlotID = SCOPE_IDENTITY();

				SET @IsSuccess = 1;
				SET @Message = 'Reservation for '+ @SlotName + ' is completed.';				
			END
			ELSE IF(@Forced = 1 AND @InRange = 0) BEGIN				
				--create logic here....				
				INSERT INTO Slot(SlotName, PeriodID, StatusCode, CropCode, MaterialTypeID, MaterialStateID, RequestUser, RequestDate, PlannedDate, ExpectedDate,BreedingStationCode,Isolated,Remark,TestTypeID)
				VALUES(@SlotName, @PeriodID, 100, @CropCode, @MaterialTypeID, @MaterialStateID, @User, GETDATE(), @PlannedDate, @ExpectedDate, @BreedingStationCode, @Isolated, @Remark, @TestTypeID);

				SELECT @SlotID = SCOPE_IDENTITY();	

				SET @IsSuccess = 1;
				SET @Message = 'Your request for '+ @SlotName + ' is pending. You will get notification after action from LAB.';		
			END

			--create reserve capacity here based on two protocols
			IF(ISNULL(@MarkerTypeTestProtocolID,0) <> 0) BEGIN
				INSERT INTO ReservedCapacity(SlotID, TestProtocolID, NrOfTests)
				VALUES(@SlotID,@MarkerTypeTestProtocolID,@NrOfTests);
			END
			INSERT INTO ReservedCapacity(SlotID, TestProtocolID, NrOfPlates)
			VALUES(@SlotID,@DNATypeTestProtocolID,@NrOfPlates);
						

		COMMIT;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK;
		THROW;
	END CATCH

END
