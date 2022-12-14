

/*
Author					Date			Remarks
Krishna Gautam			2020/01/10		Created service to approve determinationAssignment to re-test.
Krishna Gautam			2020/01/24		Validation added to allow to change data for status 600 only.
Krishna Gautam			2020/01/24		Delete pattern and pattern result of selected Det. ID.

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

	--delete result
	DELETE TR FROM TestResult TR
	JOIN Well W ON W.WellID = TR.WellID
	WHERE W.DetAssignmentID = @ID;

	--delete parrtenResult
	DELETE PR FROM PatternResult PR
	JOIN Pattern P ON P.PatternID = PR.PatternID
	JOIN DeterminationAssignment DA ON DA.DetAssignmentID = P.DetAssignmentID
	WHERE DA.DetAssignmentID = @ID;

	--delete pattern
	DELETE P FROM Pattern P
	JOIN DeterminationAssignment DA ON DA.DetAssignmentID = P.DetAssignmentID
	WHERE DA.DetAssignmentID = @ID;

	--update status from 600 to 650
	UPDATE DeterminationAssignment SET StatusCode = 650
	WHERE DetAssignmentID = @ID;
END

GO

UPDATE [Status] SET StatusName = 'Re-test', StatusDescription = 'Re-test' WHERE StatusTable = 'DeterminationAssignment' AND StatusCode = 650
GO