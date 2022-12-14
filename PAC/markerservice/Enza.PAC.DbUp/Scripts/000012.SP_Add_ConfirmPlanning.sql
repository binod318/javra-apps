DROP PROCEDURE IF EXISTS [dbo].[PR_ConfirmPlanning]
GO

/*
Author					Date			Description
Binod Gurung			2019-Sept-04	Service to confirm planning

===================================Example================================

EXEC PR_ConfirmPlanning '1,2,3,733310';
*/
CREATE PROCEDURE [dbo].[PR_ConfirmPlanning]
(
	@IDs NVARCHAR(MAX)
)
AS 
BEGIN
	 SET NOCOUNT ON;
	 BEGIN TRY
		BEGIN TRANSACTION;

			UPDATE DA
			SET DA.StatusCode = '200'
			FROM DeterminationAssignment DA
			WHERE DA.DetAssignmentID IN (SELECT value FROM STRING_SPLIT(@IDs, ','))

		COMMIT;
	END TRY
	BEGIN CATCH
		ROLLBACK;
		THROW;
	END CATCH
END
GO


