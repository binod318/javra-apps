DROP PROCEDURE IF EXISTS [dbo].[PR_LFDISK_Reserve_Capacity]
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

CREATE PROCEDURE [dbo].[PR_LFDISK_Reserve_Capacity]
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


