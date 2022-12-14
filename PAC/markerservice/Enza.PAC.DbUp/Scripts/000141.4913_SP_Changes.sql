
/*
Author					Date			Remarks
Krishna Gautam			2020/01/10		Created service to approve determinationAssignment to re-test.
Krishna Gautam			2020/01/24		Validation added to allow to change data for status 600 only.

============ExAMPLE===================
--EXEC PR_ReTestDetermination 125487
*/
ALTER PROCEDURE [dbo].[PR_ReTestDetermination]
(
	@ID INT
)
AS 
BEGIN

	DECLARE @DetAssignmentID INT, @StatusCode INT, @TestID INT;

	SELECT @DetAssignmentID = DetAssignmentID, @StatusCode = StatusCode FROM DeterminationAssignment WHERE DetAssignmentID = @ID;

	IF(ISNULL(@DetAssignmentID,0) = 0)
	BEGIN
		EXEC PR_ThrowError 'Invalid ID.';
		RETURN
	END

	IF(@StatusCode <> 600)
	BEGIN
		EXEC PR_ThrowError 'Cannot assign determination to re-test.';
		RETURN
	END

	DELETE TR FROM TestResult TR
	JOIN Well W ON W.WellID = TR.WellID
	WHERE W.DetAssignmentID = @ID;


	UPDATE DeterminationAssignment SET StatusCode = 650
	WHERE DetAssignmentID = @ID;
END

GO

/*
Author					Date			Remarks
Krishna Gautam			2020/01/10		Created service to approve determinationAssignment to approved.
Krishna Gautam			2020/01/24		Validation added to allow to change data for status 600 only.

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
	
	DECLARE @DetAssignmentID INT, @StatusCode INT, @TestID INT;

	SELECT @DetAssignmentID = DetAssignmentID, @StatusCode = StatusCode FROM DeterminationAssignment WHERE DetAssignmentID = @ID;
	IF(ISNULL(@DetAssignmentID,0) = 0)
	BEGIN
		EXEC PR_ThrowError 'Invalid ID.';
		RETURN
	END

	IF(@StatusCode <> 600)
	BEGIN
		EXEC PR_ThrowError 'Cannot Approve determination.';
		RETURN
	END

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

GO