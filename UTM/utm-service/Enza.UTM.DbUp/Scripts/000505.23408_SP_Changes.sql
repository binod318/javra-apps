/*
=============================================
Author:					Date				Remark
Krishna Gautam			2021/06/02			Capacity planning screen data lookup.
Krishna Gautam			2021/06/22			#22408: Added site location.
=========================================================================

EXEC PR_LFDISK_GetReserveCapacityLookUp 'TO,ON'
*/
ALTER PROCEDURE [dbo].[PR_LFDISK_GetReserveCapacityLookUp]
(
	@Crops NVARCHAR(MAX)
)

AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @ColumnTable TABLE(ColumnID NVARCHAR(MAX), Label NVARCHAR(MAX),[Order] INT, Visible BIT, Editable BIT, DataType NVARCHAR(MAX));
	--BreedingStation
	SELECT BreedingStationCode, BreedingStationName FROM BreedingStation;
	--TestType
	SELECT TestTypeID, TestTypeCode, TestTypeName, DeterminationRequired FROM TestType WHERE TestTypeID = 9;
	--MaterialType
	SELECT MaterialTypeID, MaterialTypeCode, MaterialTypeDescription FROM MaterialType;
	--TestProtocol
	SELECT * FROM TestProtocol WHERE TestTypeID = 9
	--CurrentPeriod
	EXEC PR_PLAN_GetCurrentPeriod 1
	
	--Grid Columns
	INSERT INTO @ColumnTable(ColumnID,Label,[Order],Visible,Editable,DataType)
	VALUES
	('CropCode','Crop',1,1,0,'string'),
	('BreedingStationCode','Br.Station',2,1,0,'string'),
	('SlotID','SlotID',3,0,0,'int'), --not visible
	('SlotName','Slot Name',4,1,0,'string'),
	('PeriodName','Period Name',5,1,0,'string'),
	('MaterialTypeCode','Material Type',6,1,0,'string'),
	('MaterialTypeID','MaterialTypeID',7,0,0,'int'), --not visible
	('TestProtocolName','Method',8,1,0,'string'),
	('TestProtocolID','TestProtocolID',9,0,0,'int'), --not visible
	('NrOfTests','Total Sample',10,1,0,'string'),
	('AvailableSample','Available Sample',11,1,0,'string'),
	('RequestUser','Requestor',12,1,0,'string'),	
	('Remark','Remark',13,1,0,'string'),
	('StatusName','Status',14,1,0,'string');

	SELECT * FROM @ColumnTable;

	SELECT C.CropCode, C.CropName FROM CropRD C
	JOIN string_split(@Crops,',') S ON C.CropCode = S.[value];

	SELECT SiteID, SiteName FROM SiteLocation
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
		DECLARE @ReservedTests INT=0, @CapacityTests INT=0;
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

		--Testtype = 2 for DNA Isolation
		IF(@PlannedDate  <= @NextPeriodEndDate) BEGIN			
			SET @InRange = 0;
			SET @IsSuccess = 0;
			SET @Message = 'Reservation time is too short. Do you want to request for reservation anyway?';
			IF(@Forced = 0)
				RETURN;
		END

		--get reserved tests if selected testtype is marker tests
		SELECT 
			@ReservedTests = ISNULL(SUM(RC.NrOfTests),0)
		FROM ReservedCapacity RC 
		JOIN Slot S ON S.SlotID = RC.SlotID
		JOIN [Period] P ON S.ExpectedDate BETWEEN P.StartDate AND P.EndDate
		WHERE P.PeriodID = @PeriodID 
		AND TestProtocolID = @TestProtocolID 
		AND S.SiteID = ISNULL(@SiteID,0)
		AND (S.StatusCode = 200 OR (S.StatusCode = 100  AND ISNULL(S.AlreadyApproved,0) = 1));

		
		--get total capacity of lab.
		SELECT 
			@CapacityTests = ISNULL(NrOfTests,0)
		FROM AvailCapacity
		WHERE PeriodID = @PeriodID 
		AND SiteID = ISNULL(@SiteID,0)
		AND TestProtocolID = @TestProtocolID;

		--check with capacity
		IF(ISNULL(@ReservedTests,0) + ISNULL(@NrOfSample,0) > @CapacityTests)
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
		DECLARE @ReservedTests INT=0, @CapacityTests INT=0;
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

		--Testtype = 2 for DNA Isolation
		IF(@PlannedDate  <= @NextPeriodEndDate) BEGIN			
			SET @InRange = 0;
			SET @IsSuccess = 0;
			SET @Message = 'Reservation time is too short. Do you want to request for reservation anyway?';
			IF(@Forced = 0)
				RETURN;
		END

		--get reserved tests if selected testtype is marker tests
		SELECT 
			@ReservedTests = ISNULL(SUM(RC.NrOfTests),0)
		FROM ReservedCapacity RC 
		JOIN Slot S ON S.SlotID = RC.SlotID
		JOIN [Period] P ON S.ExpectedDate BETWEEN P.StartDate AND P.EndDate
		WHERE P.PeriodID = @PeriodID 
		AND TestProtocolID = @TestProtocolID 
		AND S.SiteID = ISNULL(@SiteID,0)
		AND (S.StatusCode = 200 OR (S.StatusCode = 100  AND ISNULL(S.AlreadyApproved,0) = 1));

		
		--get total capacity of lab.
		SELECT 
			@CapacityTests = ISNULL(NrOfTests,0)
		FROM AvailCapacity
		WHERE PeriodID = @PeriodID 
		AND SiteID = ISNULL(@SiteID,0)
		AND TestProtocolID = @TestProtocolID;

		--check with capacity
		IF(ISNULL(@ReservedTests,0) + ISNULL(@NrOfSample,0) > @CapacityTests)
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