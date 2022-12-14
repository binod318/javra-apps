DROP PROCEDURE IF EXISTS [dbo].[PR_GetPeriod]
GO



--EXEC PR_GetPeriod 2022
CREATE PROCEDURE [dbo].[PR_GetPeriod]
(
	@Year INT
	
)
AS
BEGIN

	DECLARE @SelectedDate DATETIME;

	--Default display week is current week + 1
	SET @SelectedDate = DATEADD(WEEK, 1, GETDATE());

	SELECT 
		P.PeriodID, 
		PeriodName = CONCAT(P.PeriodName, FORMAT(P.StartDate, ' (MMM-dd-yy - ', 'en-US' ), FORMAT(P.EndDate, 'MMM-dd-yy)', 'en-US' )),
		[Current] = CAST(CASE WHEN @SelectedDate BETWEEN P.StartDate AND P.EndDate THEN 1 ELSE 0 END AS BIT),
		P.StartDate,
		P.EndDate
	FROM [Period] P
	WHERE @Year BETWEEN YEAR(P.StartDate) AND YEAR(P.EndDate)

END
GO


