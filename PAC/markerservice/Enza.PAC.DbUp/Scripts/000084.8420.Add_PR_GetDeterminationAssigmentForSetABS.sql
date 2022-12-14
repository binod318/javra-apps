DROP PROCEDURE IF EXISTS [dbo].[PR_GetDeterminationAssigmentForSetABS]
GO

-- PR_GetDeterminationAssigmentForSetABS 4779
CREATE PROCEDURE [dbo].[PR_GetDeterminationAssigmentForSetABS]
(
    @PeriodID INT
) 
AS 
BEGIN
    SET NOCOUNT ON;

	DECLARE @StartDate DATE, @EndDate DATE;
    DECLARE @PlatformID INT = (SELECT PlatformID FROM [Platform] WHERE PlatformCode = 'LS'); --light scanner   

    SELECT
	   @StartDate = StartDate,
	   @EndDate = EndDate
    FROM [Period]
    WHERE PeriodID = @PeriodID;

	SELECT 
		DetAssignmentID,
		2
	FROM DeterminationAssignment DA
	JOIN
    (
	   SELECT
		  AC.ABSCropCode,
		  PM.MethodCode
	   FROM CropMethod CM
	   JOIN ABSCrop AC ON AC.ABSCropCode = CM.ABSCropCode
	   JOIN Method PM ON PM.MethodID = CM.MethodID
	   WHERE CM.PlatformID = @PlatformID
    ) V1 ON V1.ABSCropCode = DA.ABSCropCode AND V1.MethodCode = DA.MethodCode
    JOIN Variety V ON V.VarietyNr = DA.VarietyNr
	WHERE CAST(DA.PlannedDate AS DATE) BETWEEN @StartDate AND @EndDate AND DA.StatusCode IN (200,300)

END
GO


