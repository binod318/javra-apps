DROP PROCEDURE IF EXISTS [dbo].[PR_GetMinTestStatusPerPeriod]
GO

-- PR_GetMinTestStatusPerPeriod 4779
CREATE PROCEDURE [dbo].[PR_GetMinTestStatusPerPeriod]
(
	@PeriodID INT
) 
AS 
BEGIN
    SET NOCOUNT ON;

    DECLARE @Status INT;

	SELECT MIN(StatusCode) AS StatusCode FROM Test WHERE PeriodID = @PeriodID;

END
GO


