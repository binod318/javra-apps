DROP PROCEDURE IF EXISTS [dbo].[PR_LFDISK_GetSlotsForBreeder]
GO


/*
Author					Date			Description
Krishna Gautam			2021/06/02		#22627:	Stored procedure created

===================================Example================================

-- EXEC PR_LFDISK_GetSlotsForBreeder 'ON', 'NLEN', 1, 200, ''
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
			S.TestTypeID,
			RC.TestProtocolID,
			TP.TestProtocolName
		FROM Slot S
		JOIN ReservedCapacity RC ON RC.SlotID = S.SlotID --only one record exists for leafdisk
		JOIN TestProtocol TP ON TP.TestProtocolID = RC.TestProtocolID
		JOIN VW_Period P ON P.PeriodID = S.PeriodID
		JOIN MaterialType MT ON MT.MaterialTypeID = S.MaterialTypeID
		JOIN [Status] STA ON STA.StatusCode = S.StatusCode AND STA.StatusTable = ''Slot''
		'+ CASE WHEN ISNULL(@Filter,'') <> '' THEN ' WHERE S.TestTypeID = 9 AND S.CropCode = @CropCode AND S.BreedingStationCode = @BrStationCode  AND ' + @Filter ELSE ' WHERE S.TestTypeID = 9 AND S.CropCode = @CropCode AND S.BreedingStationCode = @BrStationCode ' END +N' 
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
GO


DROP PROCEDURE IF EXISTS [dbo].[PR_LFDISK_GetReserveCapacityLookUp]
GO


/*
=============================================
Author:					Date				Remark
Krishna Gautam			2021/06/02			Capacity planning screen data lookup.
=========================================================================

EXEC PR_LFDISK_GetReserveCapacityLookUp 'TO,ON'
*/
CREATE PROCEDURE [dbo].[PR_LFDISK_GetReserveCapacityLookUp]
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
	('Period','Period Name',5,1,0,'string'),
	('MaterialTypeCode','Material Type',6,1,0,'string'),
	('MaterialTypeID','MaterialTypeID',7,0,0,'int'), --not visible
	('TestProtocolName','Method',8,1,0,'string'),
	('TestProtocolID','TestProtocolID',9,0,0,'int'), --not visible
	('Sample','Sample',10,1,0,'string'),
	('Remark','Remark',11,1,0,'string');

	SELECT * FROM @ColumnTable;

	SELECT C.CropCode, C.CropName FROM CropRD C
	JOIN string_split(@Crops,',') S ON C.CropCode = S.[value]
END


GO


DROP PROCEDURE IF EXISTS [dbo].[PR_LFDISK_EditSlot]
GO


/*
Author					Date			Description
Binod Gurung			2021/06/03		Edit slot info and reserved capacity
===================================Example================================
DECLARE @Message NVARCHAR(MAX);
EXEC [PR_LFDISK_EditSlot] 101,100,'2021/05/23','2021/06/13',0, @Message OUT
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
	DECLARE @InRange BIT =1, @AutomaticApprove BIT = 0, @NewNrOfTests INT;

	DECLARE @CurrentPlannedDate DATETIME, @CurrentExpectedDate DATETIME, @PeriodIDForTest INT, @StartDate DATETIME, @EndDate DATETIME;

	--get period for provided slot. 
	SELECT @PeriodID = PeriodID, @Isolated = Isolated, @TesttypeID = TestTypeID FROM Slot WHERE SlotID = @SlotID;

	SELECT 
		@StartDate = StartDate,
		@EndDate = EndDate
	FROM [Period] 
	WHERE PeriodID = @PeriodID

	--TesttypeId = 2 for DNA Isolation : Automatic approve for DNA Isolation and Isolated
	IF(ISNULL(@TestTypeID,0) = 2 AND ISNULL(@Isolated,0) = 1)
		SET @AutomaticApprove = 1;

	IF(ISNULL(@PlannedDate,'') = '')
	BEGIN
		SELECT @PlannedDate = PlannedDate FROM Slot WHERE SlotID = @SlotID;
	END

	--get changed period ID
	SELECT @ChangedPlannedPeriodID = PeriodID FROM [Period] WHERE @PlannedDate BETWEEN StartDate AND EndDate;
	
	--SELECT @ChangedExpectedPeriodID = PeriodID FROM [Period] WHERE @ExpectedDate BETWEEN StartDate AND EndDate;

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
		IF(ISNULL(@Forced,0) = 0 AND @AutomaticApprove = 0)
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

		
		--This section should be updated once database design with Sample is done
		--SELECT @TotalTestsUsed = ISNULL(COUNT(V2.DeterminationID),0)
		--FROM
		--(
		--	SELECT V.DeterminationID, V.PlateID
		--	FROM
		--	(
		--		SELECT P.PlateID, TMDW.MaterialID, TMD.DeterminationID FROM TestMaterialDetermination TMD 
		--		JOIN TestMaterialDeterminationWell TMDW ON TMDW.MaterialID = TMD.MaterialID
		--		JOIN Well W ON W.WellID = TMDW.WellID
		--		JOIN Plate P ON P.PlateID = W.PlateID AND P.TestID = TMD.TestID
		--		JOIN SlotTest ST ON ST.TestID = P.TestID
		--		WHERE ST.SlotID = @SlotID
		
		--	) V
		--	GROUP BY V.DeterminationID, V.PlateID
		--) V2 ;

		IF(ISNULL(@NrOfTests,0) < @TotalTestsUsed)
		BEGIN
			SET @Msg = +CAST(@TotalTestsUsed AS NVARCHAR(MAX)) + ' Sample(s) is already consumed by Test(s). Value cannot be less than already consumed.';
			EXEC PR_ThrowError @Msg;
			RETURN;
		END

		--IF Plate is null then this is marker protocol
		SELECT @TestProtocolID = TestProtocolID 
		FROM ReservedCapacity WHERE SlotID = @SlotID; 

		SELECT @TotalAvailableTests = MAX(NrOfTests) FROM AvailCapacity WHERE TestProtocolID = @TestProtocolID AND PeriodID = @PeriodIDForTest;

		SELECT @ReservedTests = SUM(ISNULL(NrOfTests,0)) FROM ReservedCapacity RC
		JOIN Slot S ON S.SlotID = RC.SlotID 
		WHERE TestProtocolID = @TestProtocolID AND S.SlotID <> @SlotID
		AND (S.ExpectedDate BETWEEN @StartDate AND @EndDate)
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
			IF(ISNULl(@Forced,0) = 0 AND @AutomaticApprove = 0)
			BEGIN
				SET @Message = 'Lab capacity is full. You need lab approval to apply this change. Do you want to continue?';
				RETURN;
			END
		END

		IF(@Forced = 1 AND ISNULL(@InRange,0) = 0 AND @AutomaticApprove = 0)
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


