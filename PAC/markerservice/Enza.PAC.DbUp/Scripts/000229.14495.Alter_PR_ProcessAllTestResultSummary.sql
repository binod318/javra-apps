DROP PROCEDURE IF EXISTS [dbo].[PR_ProcessAllTestResultSummary]
GO

-- EXEC PR_ProcessAllTestResultSummary 43, 30, 90
-- All input values are in percentage (1 - 100)
CREATE PROCEDURE [dbo].[PR_ProcessAllTestResultSummary]
(
	@MissingResultPercentage DECIMAL,
	@ThresholdA	DECIMAL,
	@ThresholdB DECIMAL
)
AS 
BEGIN
    SET NOCOUNT ON;
	    
	DECLARE @tbl TABLE(ID INT IDENTITY(1, 1), DetAssignmentID INT);

	DECLARE @Errors TABLE (DetAssignmentID INT, ErrorMessage NVARCHAR(MAX));
   
	INSERT @tbl(DetAssignmentID)
	SELECT 
		W.DetAssignmentID
	FROM TestResult TR
	JOIN Well W ON W.WellID = TR.WellID
	JOIN TestDetAssignment TDA ON TDA.DetAssignmentID = W.DetAssignmentID
	JOIN DeterminationAssignment DA ON DA.DetAssignmentID = TDA.DetAssignmentID
	WHERE ISNULL(W.DetAssignmentID, 0) <> 0
	AND DA.StatusCode = 500
	GROUP BY W.DetAssignmentID;

	DECLARE @DetAssignmentID INT, @ID INT = 1, @Count INT;
	SELECT @Count = COUNT(ID) FROM @tbl;
	WHILE(@ID <= @Count) BEGIN
			
		SELECT 
			@DetAssignmentID = DetAssignmentID 
		FROM @tbl
		WHERE ID = @ID;

		BEGIN TRY
		BEGIN TRANSACTION;
			
			--Background task 1
			EXEC PR_ProcessTestResultSummary @DetAssignmentID;

			--Background task 2, 3, 4
			EXEC PR_BG_Task_2_3_4 @DetAssignmentID, @MissingResultPercentage, @ThresholdA, @ThresholdB;

		COMMIT;
		END TRY
		BEGIN CATCH

			--Store exceptions
			INSERT @Errors(DetAssignmentID, ErrorMessage)
			SELECT @DetAssignmentID, ERROR_MESSAGE(); 

			IF @@TRANCOUNT > 0
				ROLLBACK;

		END CATCH

		SET @ID = @ID + 1;
	END   

	SELECT DetAssignmentID, ErrorMessage FROM @Errors;

END
GO


