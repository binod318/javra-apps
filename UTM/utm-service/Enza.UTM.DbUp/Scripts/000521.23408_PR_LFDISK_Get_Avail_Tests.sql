
/*
Authror					Date				Description
Krishna Gautam			2021/06/08			#22627: Stored procedure created
Krishna Gautam			2021/06/22			#22408: Added site location.

==========================Example============================


*/

ALTER PROCEDURE [dbo].[PR_LFDISK_Get_Avail_Tests]
(
	@TestProtocolID INT,
	@PlannedDate DateTime,
	@SiteID INT,
	@DisplayPlannedWeek NVARCHAR(20) OUT,	
	@AvailSample INT OUT
)
AS
BEGIN

	SET NOCOUNT ON;

	DECLARE @PeriodID INT, @TotalTests INT, @ReservedTests INT;
	DECLARE @StartDate DATETIME, @EndDate DATETIME;
		
	IF NOT EXISTS (SELECT * FROM TestProtocol WHERE TestProtocolID = ISNULL(@TestProtocolID,0))
	BEGIN
		EXEC PR_ThrowError 'No valid test protocol found.';
		RETURN;
	END
	
	IF NOT EXISTS (SELECT * FROM SiteLocation WHERE SiteID = ISNULL(@SiteID,0))
	BEGIN
		EXEC PR_ThrowError 'No valid Site location found.';
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
	WHERE PeriodID = @PeriodID
	AND TestProtocolID = @TestProtocolID
	AND SiteID = ISNULL(@SiteID,0)

	--Reserved tests per period
	SELECT 
		@ReservedTests = SUM(ISNULL(RC.NrOfTests,0))
	FROM ReservedCapacity RC
	JOIN Slot S ON S.SlotID = RC.SlotID
	WHERE S.PeriodID = @PeriodID 
	AND S.TestTypeID = 9  --test type is leafdisk
	AND RC.TestProtocolID = @TestProtocolID
	AND S.SiteID = ISNULL(@siteID,0)
	AND (S.StatusCode = 200 OR (S.StatusCode = 100  AND S.AlreadyApproved = 1))

	
	SET @AvailSample = ISNULL(@TotalTests, 0) - ISNULL(@ReservedTests, 0);

	IF(@AvailSample < 0)
	BEGIN
		SET @AvailSample = 0;
	END
END
