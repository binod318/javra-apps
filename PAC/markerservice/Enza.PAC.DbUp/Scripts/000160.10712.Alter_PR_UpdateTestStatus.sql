DROP PROCEDURE IF EXISTS [dbo].[PR_UpdateTestStatus]
GO

-- PR_UpdateTestStatus '11,22', 200, 0
CREATE PROCEDURE [dbo].[PR_UpdateTestStatus]
(
	@TestIDs	NVARCHAR(100),
    @StatusCode INT,
	@DAStatusCode INT = NULL
) 
AS 
BEGIN
    SET NOCOUNT ON;

    UPDATE Test
	SET StatusCode = @StatusCode
	WHERE TestID IN (SELECT [value] FROM STRING_SPLIT(@TestIDs, ','))
	
	--Update status of determination assignment
	IF(ISNULL(@DAStatusCode,0) > 0)
	BEGIN
		UPDATE DA
		SET DA.StatusCode = @DAStatusCode
		FROM DeterminationAssignment DA
		JOIN TestDetAssignment TDA On TDA.DetAssignmentID = DA.DetAssignmentID
		WHERE TDA.TestID IN (SELECT [value] FROM STRING_SPLIT(@TestIDs, ','))
	END

END
GO


