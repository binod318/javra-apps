DROP PROCEDURE IF EXISTS PR_LFDISK_Get_Avail_Tests
GO
/*
Authror					Date				Description
Krishna Gautam			2021/06/08			#22627: Stored procedure created

==========================   Example    ============================
*/

CREATE PROCEDURE [dbo].[PR_LFDISK_Get_Avail_Tests]
(
	@TestProtocolID INT,
	@PlannedDate DateTime,
	@DisplayPlannedWeek NVARCHAR(20) OUT,	
	@AvailSample INT OUT
)
AS
BEGIN

	SET NOCOUNT ON;

	DECLARE @PeriodID INT, @TotalTests INT, @ReservedTests INT;
	DECLARE @StartDate DATETIME, @EndDate DATETIME;
		
	IF(ISNULL(@TestProtocolID,0)=0) BEGIN
		EXEC PR_ThrowError 'No valid protocol found for selected material type and crop';
		RETURN;
	END
	
	SELECT 
		@PeriodID = PeriodID,
		@DisplayPlannedWeek = PeriodName + ' - ' + CAST(YEAR(@PlannedDate) AS NVARCHAR(10))
	FROM [Period] 
	WHERE @PlannedDate BETWEEN StartDate AND EndDate;

	IF(ISNULL(@PeriodID,0)=0) BEGIN
		EXEC PR_ThrowError 'No period found for selected planned date';
		RETURN;
	END

	--Total number of tests avail per period
	SELECT DISTINCT
		@TotalTests = NrOfTests
	FROM AvailCapacity
	WHERE PeriodID = @PeriodID --AND NrOfTests IS NOT NULL

	--Reserved tests per period
	SELECT 
		@ReservedTests = SUM(ISNULL(RC.NrOfTests,0))
	FROM ReservedCapacity RC
	JOIN Slot S ON S.SlotID = RC.SlotID
	WHERE 
		S.PeriodID = @PeriodID 
		AND S.TestTypeID = 9  --test type is leafdisk
		AND (S.StatusCode = 200 OR (S.StatusCode = 100  AND S.AlreadyApproved = 1))

	
	SET @AvailSample = ISNULL(@TotalTests, 0) - ISNULL(@ReservedTests, 0);

	IF(@AvailSample < 0)
	BEGIN
		SET @AvailSample = 0;
	END
END

GO


-- =============================================
-- Author:		Binod Gurung
-- Create date: 2018/03/15
-- Description:	Get available plates tests
/*
DECLARE @DisplayPlannedWeek NVARCHAR(20),@ExpectedDate DateTime ,@DisplayExpectedWeek NVARCHAR(20),@AvailPlates INT,@AvailTests INT;

EXEC PR_PLAN_Get_Avail_Plates_Tests 2,'LT',0,'2021-01-26',NULL,@DisplayPlannedWeek OUT,@ExpectedDate OUT, @DisplayExpectedWeek OUT, @AvailPlates OUT, @AvailTests OUT;
PRINT @DisplayPlannedWeek;
PRINT @ExpectedDate;
PRINT @DisplayExpectedWeek;
PRINT @AvailPlates;
PRINT @AvailTests;

*/
-- =============================================
ALTER PROCEDURE [dbo].[PR_PLAN_Get_Avail_Plates_Tests]
(
	@MaterialTypeID INT,
	@CropCode NVARCHAR(10),
	@Isolated BIT,
	@PlannedDate DateTime,
	@ExpectedDateIn DateTime = NULL,
	@DisplayPlannedWeek NVARCHAR(20) OUT,
	@ExpectedDate DateTime OUT,
	@DisplayExpectedWeek NVARCHAR(20) OUT,
	@AvailPlates INT OUT,
	@AvailTests INT OUT
)
AS
BEGIN

	SET NOCOUNT ON;

	DECLARE @PeriodID INT, @TotalPlates INT, @ReservedPlates INT, @TotalTests INT, @ReservedTests INT, @TestProtocolID INT, @PeriodIDForTest INT;
	DECLARE @StartDate DATETIME, @EndDate DATETIME;

	IF (ISNULL(@ExpectedDateIn,'') = '')
		--Default Expected Week is 2 Weeks later than Planned Week
		SET @ExpectedDate = DATEADD(week, 2, @PlannedDate);
	ELSE
		SET @ExpectedDate = @ExpectedDateIn;

	--get TestProtocolID (used only for plates - DNA) for selected Material type and crop
	SELECT @TestProtocolID = MTP.TestProtocolID 
		FROM MaterialTypeTestProtocol MTP
	JOIN TestProtocol TP ON TP.TestProtocolID = MTP.TestProtocolID
	WHERE MaterialTypeID = @MaterialTypeID AND CropCode = @CropCode AND TP.TestTypeID = 2; --hard code value 2 for DNA type

	IF(ISNULL(@TestProtocolID,0)=0) BEGIN
		EXEC PR_ThrowError 'No valid protocol found for selected material type and crop';
		RETURN;
	END
	
	SELECT 
		@PeriodID = PeriodID 
	FROM [Period] 
	WHERE @PlannedDate BETWEEN StartDate AND EndDate;

	SELECT 
		@StartDate = StartDate,
		@EndDate = EndDate,
		@PeriodIDForTest = PeriodID 
	FROM [Period] 
	WHERE @ExpectedDate BETWEEN StartDate AND EndDate;

	IF(ISNULL(@PeriodID,0)=0) BEGIN
		EXEC PR_ThrowError 'No period found for selected planned date';
		RETURN;
	END

	--Total number of plates avail per period per method
	SELECT 
		@TotalPlates = NrOfPlates
	FROM AvailCapacity
	WHERE PeriodID = @PeriodID AND TestProtocolID = @TestProtocolID

	--Total number of tests avail per period
	SELECT DISTINCT
		@TotalTests = NrOfTests
	FROM AvailCapacity
	WHERE PeriodID = @PeriodIDForTest --AND NrOfTests IS NOT NULL

	--Reserved plates per period per method
	SELECT 
		@ReservedPlates = SUM(ISNULL(RC.NrOfPlates,0))
	FROM ReservedCapacity RC
	JOIN Slot S ON S.SlotID = RC.SlotID
	WHERE S.PeriodID = @PeriodID AND RC.TestProtocolID = @TestProtocolID AND (S.StatusCode = 200 OR (S.StatusCode = 100  AND S.AlreadyApproved = 1));	

	--Reserved tests per period
	SELECT 
		@ReservedTests = SUM(ISNULL(RC.NrOfTests,0))
	FROM ReservedCapacity RC	
	JOIN Slot S ON S.SlotID = RC.SlotID
	WHERE 
		(S.ExpectedDate BETWEEN @StartDate AND @EndDate) 
		AND ISNULL(S.TestTypeID,1) = 1 --2GB uses both plates and test but dna isolation (testtype 2) only uses plates not tests.
		AND (S.StatusCode = 200 OR (S.StatusCode = 100  AND S.AlreadyApproved = 1))

	--Get display period for Planned date
	SELECT 
		@DisplayPlannedWeek = PeriodName + ' - ' + CAST(YEAR(@PlannedDate) AS NVARCHAR(10))
	FROM [Period] 
	WHERE @PlannedDate BETWEEN StartDate AND EndDate;

	--Get display period for Expected date
	SELECT 
		@DisplayExpectedWeek = PeriodName + ' - ' + CAST(YEAR(@ExpectedDate) AS NVARCHAR(10))
	FROM [Period] 
	WHERE @ExpectedDate BETWEEN StartDate AND EndDate;

	IF(@Isolated = 1) BEGIN
		SELECT  @AvailPlates = NULL,
				--@AvailTests = NULL;
				 @AvailTests = ISNULL(@TotalTests, 0) - ISNULL(@ReservedTests, 0);

		--Do not display negative value
		IF(@AvailTests < 0)
			SET @AvailTests = 0;
	END
	ELSE BEGIN
		SELECT @AvailPlates = ISNULL(@TotalPlates, 0) - ISNULL(@ReservedPlates, 0),
			   @AvailTests = ISNULL(@TotalTests, 0) - ISNULL(@ReservedTests, 0);

		--Do not display negative value
		IF(@AvailPlates < 0)
			SET @AvailPlates = 0;

		--Do not display negative value
		IF(@AvailTests < 0)
			SET @AvailTests = 0;
	END
END

GO