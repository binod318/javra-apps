DROP PROCEDURE IF EXISTS PR_ProcessAllTestResultSummary
GO

-- EXEC PR_ProcessAllTestResultSummary
CREATE PROCEDURE PR_ProcessAllTestResultSummary
AS BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
	   BEGIN TRANSACTION;
    
	   DECLARE @tbl TABLE(ID INT IDENTITY(1, 1), DetAssignmentID INT);
    
	   INSERT @tbl(DetAssignmentID)
	   SELECT 
		  W.DetAssignmentID
	   FROM TestResult TR
	   JOIN Well W ON W.WellID = TR.WellID
	   JOIN TestDetAssignment TDA ON TDA.DetAssignmentID = W.DetAssignmentID
	   JOIN Test T ON T.TestID = TDA.TestID
	   WHERE ISNULL(W.DetAssignmentID, 0) <> 0
	   AND T.StatusCode = 500
	   GROUP BY W.DetAssignmentID;

	   DECLARE @DetAssignmentID INT, @ID INT = 1, @Count INT;
	   SELECT @Count = COUNT(ID) FROM @tbl;
	   WHILE(@ID <= @Count) BEGIN
		  SELECT 
			 @DetAssignmentID = DetAssignmentID 
		  FROM @tbl
		  WHERE ID = @ID;

		  EXEC PR_ProcessTestResultSummary @DetAssignmentID;

		  SET @ID = @ID + 1;
	   END

	   COMMIT;
    END TRY
    BEGIN CATCH
	   IF @@TRANCOUNT = 0
		  ROLLBACK;
	   THROW;
    END CATCH
END
GO