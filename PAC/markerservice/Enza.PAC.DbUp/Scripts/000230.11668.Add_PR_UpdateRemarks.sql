DROP PROCEDURE IF EXISTS [dbo].[PR_UpdateRemarks]
GO

/*
Author					Date			Remarks
Binod Gurung			2020/08/14		Update remarks of determination assignment

============ExAMPLE===================
--EXEC PR_UpdateRemarks 837822, 'TestRemarks'
*/
CREATE PROCEDURE [dbo].[PR_UpdateRemarks]
(
	@DetAssignmentID INT,
	@Remarks		 NVARCHAR(MAX)
)
AS 
BEGIN

	IF NOT EXISTS (SELECT * FROM DeterminationAssignment WHERE DetAssignmentID = @DetAssignmentID)
	BEGIN
		EXEC PR_ThrowError 'Invalid determination assignment id.';
		RETURN
	END

	IF NOT EXISTS (SELECT * FROM DeterminationAssignment WHERE DetAssignmentID = @DetAssignmentID AND StatusCode IN (500,600,650))
	BEGIN
		EXEC PR_ThrowError 'Invalid determination assignment status.';
		RETURN
	END

	UPDATE DeterminationAssignment 
		SET Remarks = @Remarks
	WHERE DetAssignmentID = @DetAssignmentID;

END

GO


