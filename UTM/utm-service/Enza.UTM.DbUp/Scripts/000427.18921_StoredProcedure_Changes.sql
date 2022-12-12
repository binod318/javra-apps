/*
Authror					Date				Description
KRIAHNA GAUTAM								SP Created
KRIAHNA GAUTAM			2020-Mar-24			#11242: Change request to add remark.
KRIAHNA GAUTAM			2020-Nov-11			#16340: Date is taking timezone
KRIAHNA GAUTAM			2020-Nov-11			#18921: Add testtype in slot.

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
		DECLARE @ReservedPlates INT =0, @ReservedTests INT=0, @CapacityPlates INT =0, @CapacityTests INT=0;
		DECLARE @MaxSlotID INT, @SlotName NVARCHAR(100);
		
		IF(ISNULL(@Isolated,0) = 0) BEGIN
			SELECT TOP 1 @DNATypeTestProtocolID = TestProtocolID 
			FROM MaterialTypeTestProtocol
			WHERE MaterialTypeID = @MaterialTypeID AND CropCode = @CropCode;
		END
		ELSE BEGIN
			SELECT TOP 1 @DNATypeTestProtocolID = TestProtocolID 
			FROM TestProtocol
			WHERE Isolated = 1;
		END


		IF EXISTS(SELECT TOP 1 TestTypeID FROM TestType WHERE TestTypeID = @TestTypeID AND DeterminationRequired = 1) BEGIN
			SELECT TOP 1 @MarkerTypeTestProtocolID = TestProtocolID 
			FROM TestProtocol
			WHERE TestTypeID = @TestTypeID;
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

		IF(@PlannedDate  <= @NextPeriodEndDate) BEGIN			
			SET @InRange = 0;
			SET @IsSuccess = 0;
			SET @Message = 'Reservation time is too short. Do you want to request for reservation anyway?';
			IF(@Forced = 0)
				RETURN;
		END

		--get reserved tests if selected testtype is marker tests
		SELECT 
			@ReservedTests = SUM(RC.NrOfTests)
		FROM ReservedCapacity RC 
		JOIN Slot S ON S.SlotID = RC.SlotID
		JOIN [Period] P ON S.ExpectedDate BETWEEN P.StartDate AND P.EndDate
		WHERE P.PeriodID = @PeriodIDForTest AND TestProtocolID = @MarkerTypeTestProtocolID AND (S.StatusCode = 200 OR (S.StatusCode = 100  AND ISNULL(RC.NewNrOfTests,0) >0));

		SET @ReservedTests = ISNULL(@ReservedTests,0);
		
		--WHERE S.PeriodID = @PeriodID AND S.StatusCode = 200 AND TestProtocolID IS NULL

		--get reserved plates for selected material type and crop
		SELECT 
			@ReservedPlates = SUM(RC.NrOfPlates)
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
				INSERT INTO Slot(SlotName, PeriodID, StatusCode, CropCode, MaterialTypeID, MaterialStateID, RequestUser, RequestDate, PlannedDate, ExpectedDate,BreedingStationCode,Isolated, Remark,TestTypeId)
				VALUES(@SlotName,@PeriodID,'200',@CropCode,@MaterialTypeID,@MaterialStateID,@User,GETDATE(),@PlannedDate,@ExpectedDate,@BreedingStationCode,@Isolated, @Remark,@TestTypeID);

				SELECT @SlotID = SCOPE_IDENTITY();

				SET @IsSuccess = 1;
				SET @Message = 'Reservation for '+ @SlotName + ' is completed.';				
			END
			ELSE IF(@Forced = 1 AND @InRange = 0) BEGIN				
				--create logic here....				
				INSERT INTO Slot(SlotName, PeriodID, StatusCode, CropCode, MaterialTypeID, MaterialStateID, RequestUser, RequestDate, PlannedDate, ExpectedDate,BreedingStationCode,Isolated,Remark,TestTypeID)
				VALUES(@SlotName, @PeriodID, '100', @CropCode, @MaterialTypeID, @MaterialStateID, @User, GETDATE(), @PlannedDate, @ExpectedDate, @BreedingStationCode, @Isolated, @Remark, @TestTypeID);

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

GO



/*
Author					Date			Remarks
-------------------------------------------------------------------------------
Dibya Suvedi			2020-Apr-02		#11245: Sp Created
Krishna Gautam			2020-Apr-03		#11245: Change request for showing only crops that user have access and date greater than today
Krishna Gautam			2020-Feb-11		#18921: add test type to slot.

==================================Example======================================
--EXEC PR_PLAN_GetApprovedSlots 'JAVRA\dsuvedi', '57','TO'

*/


ALTER PROCEDURE [dbo].[PR_PLAN_GetApprovedSlots]
(
    @UserName	 NVARCHAR(100) = NULL,
    @SlotName	 NVARCHAR(200) = NULL,
	@Crops		 NVARCHAR(MAX)
) AS BEGIN
    SET NOCOUNT ON;

    SELECT TOP 200
	   S.SlotID,
	   S.SlotName,
	   S.CropCode,
	   S.PlannedDate,
	   S.ExpectedDate,
	   S.MaterialTypeID,
	   S.MaterialStateID,
	   S.Isolated,
	   S.BreedingStationCode,
	   S.TestTypeID
    FROM Slot S
	JOIN string_split(@Crops,',') T ON T.[value] = S.CropCode
    WHERE S.StatusCode = 200
    AND (ISNULL(@UserName, '') = '' OR S.RequestUser = @UserName)
    AND (ISNULL(@SlotName, '') = '' OR S.SlotName LIKE CONCAT('%', @SlotName, '%'))
	AND S.PlannedDate > GETUTCDATE()
    ORDER BY S.PlannedDate DESC;
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
				NrOfTests = MAX(ISNULL(RC.NrOfTests,0)),
				NrOfPlates = MAX(ISNULL(RC.NrOfPlates,0)) 
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