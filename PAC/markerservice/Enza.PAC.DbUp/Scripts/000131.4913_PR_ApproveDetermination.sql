/*
Author					Date			Remarks
Krishna Gautam			2020/01/10		Created service to approve determinationAssignment to approved.

============ExAMPLE===================
--EXEC PR_ApproveDetermination 125487
*/
ALTER PROCEDURE [dbo].[PR_ApproveDetermination]
(
	@ID INT,
	@User NVARCHAR(MAX) = NULL
)
AS 
BEGIN

	IF NOT EXISTS (SELECT DetAssignmentID FROM DeterminationAssignment WHERE DetAssignmentID = @ID)
	BEGIN
		EXEC PR_ThrowError 'Invalid ID.';
		RETURN
	END

	DECLARE @TestID INT;

	SELECT TOP 1 @TestID = TestID FROM TestDetAssignment WHERE DetAssignmentID = @ID;

	UPDATE DeterminationAssignment 
		SET 
		StatusCode = 700,
		ValidatedBy = @User,
		ValidatedOn = GETUTCDATE()		
	WHERE DetAssignmentID = @ID;

	IF NOT EXISTS(SELECT * FROM TestDetAssignment TDA JOIN DeterminationAssignment DA ON DA.DetAssignmentID = TDA.TestDetAssignmentID
	WHERE TDA.TestID = @TestID AND DA.StatusCode NOT IN (700,999))
	BEGIN
		UPDATE Test SET StatusCode = 600 WHERE TestID = @TestID;
	END
	
END
