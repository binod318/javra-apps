DROP PROCEDURE IF EXISTS [dbo].[PR_UpdateTestStatus]
GO

-- PR_UpdateTestStatus '11,22', 200
CREATE PROCEDURE [dbo].[PR_UpdateTestStatus]
(
	@TestIDs	NVARCHAR(100),
    @StatusCode INT
) 
AS 
BEGIN
    SET NOCOUNT ON;

    UPDATE Test
	SET StatusCode = @StatusCode
	WHERE TestID IN (SELECT [value] FROM STRING_SPLIT(@TestIDs, ','))

END
GO


