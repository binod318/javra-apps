DROP PROCEDURE IF EXISTS PR_ConfirmPlanning
GO

/*
Author					Date			Description
Binod Gurung			2019-Sept-04	Service to confirm planning

===================================Example================================

EXEC PR_ConfirmPlanning 4676, N'[{"DetAssignmentID":1,"Action":"U"},{"DetAssignmentID":2,"Action":"D"}]';
*/
CREATE PROCEDURE [dbo].[PR_ConfirmPlanning]
(
    @PeriodID	 INT,
    @DataAsJson NVARCHAR(MAX)
)
AS 
BEGIN
	 SET NOCOUNT ON;

	 DECLARE @StartDate DATE, @EndDate DATE;

	 SELECT 
	   @StartDate = P.StartDate,
	   @EndDate = P.EndDate
	 FROM [Period] P 
	 WHERE P.PeriodID = @PeriodID;

	 BEGIN TRY
	   BEGIN TRANSACTION;
	   
	   DELETE DA
	   FROM DeterminationAssignment DA
	   JOIN OPENJSON(@DataAsJson) WITH
	   (
		  DetAssignmentID INT,
		  [Action]	   CHAR(1)
	   ) S ON S.DetAssignmentID = DA.DetAssignmentID
	   WHERE S.[Action] = 'D'
	   AND CAST(DA.PlannedDate AS DATE) BETWEEN @StartDate AND @EndDate;

	   --Change status to 200 of those records which falls under that period
	   UPDATE DA
	   SET DA.StatusCode = 200
	   FROM DeterminationAssignment DA
	   JOIN OPENJSON(@DataAsJson) WITH
	   (
		  DetAssignmentID INT,
		  [Action]	   CHAR(1)
	   ) S ON S.DetAssignmentID = DA.DetAssignmentID
	   WHERE S.[Action] = 'U'
	   AND CAST(DA.PlannedDate AS DATE) BETWEEN @StartDate AND @EndDate;

	   --update status of all records of that particular week if there are no any data comes in json
	   UPDATE DA
		  SET DA.StatusCode = 200
	   FROM DeterminationAssignment DA
	   WHERE DA.StatusCode = 100 
	   AND CAST(DA.PlannedDate AS DATE) BETWEEN @StartDate AND @EndDate;  
	   
	   --insert new records if it is not in automatic plan but user has checked it up
	   INSERT INTO DeterminationAssignment
	   (
		  DetAssignmentID, 
		  SampleNr, 
		  PriorityCode, 
		  MethodCode, 
		  ABSCropCode, 
		  VarietyNr, 
		  BatchNr, 
		  RepeatIndicator, 
		  ProcessNr, 
		  ProductStatus, 
		  BatchOutputDesc, 
		  PlannedDate, 
		  UtmostInlayDate, 
		  ExpectedReadyDate,
		  StatusCode
	   )
	   SELECT 
		  S.DetAssignmentID, 
		  S.SampleNr, 
		  S.PriorityCode, 
		  S.MethodCode, 
		  S.ABSCropCode, 
		  S.VarietyNr, 
		  S.BatchNr, 
		  S.RepeatIndicator, 
		  S.ProcessNr, 
		  S.ProductStatus, 
		  S.BatchOutputDesc, 
		  S.PlannedDate, 
		  S.UtmostInlayDate, 
		  S.ExpectedReadyDate,
		  200	   
	   FROM OPENJSON(@DataAsJson) WITH
	   (
		  DetAssignmentID	   INT,
		  SampleNr		   INT,
		  PriorityCode	   INT,
		  MethodCode		   NVARCHAR(25),
		  ABSCropCode		   NVARCHAR(10),
		  VarietyNr		   INT,
		  BatchNr		   INT,
		  RepeatIndicator	   BIT,
		  ProcessNr		   NVARCHAR(100),
		  ProductStatus	   NVARCHAR(100),
		  BatchOutputDesc	   NVARCHAR(250),
		  PlannedDate		   DATETIME,
		  UtmostInlayDate	   DATETIME,
		  ExpectedReadyDate   DATETIME,
		  [Action]	   CHAR(1)
	   ) S
	   LEFT JOIN DeterminationAssignment DA ON DA.DetAssignmentID = S.DetAssignmentID	   
	   WHERE S.[Action] = 'I'
	   AND CAST(S.PlannedDate AS DATE) BETWEEN @StartDate AND @EndDate
	   AND DA.DetAssignmentID IS NULL;

	   COMMIT;
	END TRY
	BEGIN CATCH
	   IF @@TRANCOUNT > 0 
		ROLLBACK;
	   THROW;
	END CATCH
END
GO