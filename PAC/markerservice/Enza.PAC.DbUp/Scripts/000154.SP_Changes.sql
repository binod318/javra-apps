DROP PROCEDURE IF EXISTS [dbo].[PR_ApproveDetermination]
GO

/*
Author					Date			Remarks
Krishna Gautam			2020/01/10		Created service to approve determinationAssignment to approved.
Krishna Gautam			2020/01/24		Validation added to allow to change data for status 600 only.

============ExAMPLE===================
--EXEC PR_ApproveDetermination 125487
*/
CREATE PROCEDURE [dbo].[PR_ApproveDetermination]
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
		EXEC PR_ThrowError 'Cannot Approve determination assignment.';
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


DROP PROCEDURE IF EXISTS [dbo].[PR_GetInfoForUpdateDA]
GO

/*
Author					Date			Remarks
Binod Gurung			2020-jan-21		Get information for UpdateDA
Binod Gurung			2020-jan-23		Transcation isolation level implemented to avoid record lock

=================EXAMPLE=============
EXEC PR_GetInfoForUpdateDA 1568336
*/
CREATE PROCEDURE [dbo].[PR_GetInfoForUpdateDA]
(
	@DetAssignmentID INT
)
AS
BEGIN
	
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

	DECLARE @StatusCode INT, @TestID INT;

	SELECT @StatusCode = StatusCode FROM DeterminationAssignment WHERE DetAssignmentID = @DetAssignmentID;
	IF(ISNULL(@DetAssignmentID,0) = 0)
	BEGIN
		EXEC PR_ThrowError 'Invalid ID.';
		RETURN
	END

	IF(@StatusCode <> 600)
	BEGIN
		EXEC PR_ThrowError 'Invalid determination assignment status.';
		RETURN
	END

	SELECT
		DetAssignmentID = Max(DA.DetAssignmentID),
		ValidatedOn		= FORMAT(MAX(ValidatedOn), 'yyyy-MM-dd', 'en-US'),
		Result			= CAST ((MAX(DA.ActualSamples) * 100 / SUM(P.NrOfSamples)) AS DECIMAL),
		QualityClass	= MAX(QualityClass),
		ValidatedBy		= MAX(ValidatedBy)
	FROM DeterminationAssignment DA
	LEFT JOIN Pattern P On P.DetAssignmentID = DA.DetAssignmentID 
	WHERE DA.DetAssignmentID = @DetAssignmentID
	GROUP BY DA.DetAssignmentID
	
END

GO


