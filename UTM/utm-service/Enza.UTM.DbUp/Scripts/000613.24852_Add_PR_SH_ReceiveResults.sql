DROP PROCEDURE IF EXISTS [dbo].[PR_SH_ReceiveResults]
GO


/*
=========Changes====================
Changed By			Date				Description	
Binod Gurung		2022-02-17			Receive result for seedhealth

========Example=============
DECLARE @Json NVARCHAR(MAX) = N'[{"SampleTestID":2774,"DeterminationID":12133,"Key":"result","Value":"1"},{"SampleTestID":2774,"DeterminationID":12133,"Key":"abstestnumber","Value":"21"},{"SampleTestID":2774,"DeterminationID":12134,"Key":"result","Value":"3"},{"SampleTestID":2774,"DeterminationID":12134,"Key":"abstestnumber","Value":"23"}]'
EXEC PR_SH_ReceiveResults @Json

*/
CREATE PROCEDURE [dbo].[PR_SH_ReceiveResults]
(
	@Json NVARCHAR(MAX) 
) AS

BEGIN
SET NOCOUNT ON;

	DECLARE @TblScore TABLE (SampleTestID INT, DeterminationID INT, [Key] NVARCHAR(50), [Value] NVARCHAR(50));
	DECLARE @TestID INT;
	
	INSERT @TblScore(SampleTestID, DeterminationID, [Key], [Value])
	SELECT SampleTestID, DeterminationID, [Key], [Value]
		FROM OPENJSON(@Json) WITH
		(
			SampleTestID	INT '$.SampleTestID',
			DeterminationID	NVARCHAR(MAX) '$.DeterminationID',
			[Key]			NVARCHAR(50) '$.Key',
			[Value]			NVARCHAR(50) '$.Value'
		)
	
	--get TestID
	SELECT @TestID = TestID FROM LD_SampleTest WHERE SampleTestID = (SELECT TOP 1 SampleTestID FROM @TblScore)
	
	--validate test
	IF NOT EXISTS (SELECT TestID FROM Test WHERE TestID = @TestID)
	BEGIN
		EXEC PR_ThrowError N'Invalid test.';
		RETURN;
	END

	--validate testtype
	IF NOT EXISTS (SELECT TestID FROM Test WHERE TestID = @TestID AND TestTypeID = 9)
	BEGIN
		EXEC PR_ThrowError N'Invalid test type.';
		RETURN;
	END

	--validate test status
	IF NOT EXISTS (SELECT TestID FROM Test WHERE TestID = @TestID AND StatusCode >= 500)
	BEGIN
		EXEC PR_ThrowError N'Invalid test status.';
		RETURN;
	END

	BEGIN TRY
		BEGIN TRANSACTION;
					
			MERGE INTO SHTestResult T
			USING @TblScore S ON S.SampleTestID = T.SampleTestID AND S.DeterminationID = T.DeterminationID
			WHEN NOT MATCHED THEN
			INSERT (SampleTestID, DeterminationID, MappingColumn, Score, StatusCode)
			VALUES(S.SampleTestID, S.DeterminationID, S.[Key], S.[Value], 100) ;
			
			UPDATE Test 
				SET StatusCode = 600 --Received
			WHERE TestID = @TestID;

		COMMIT;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
            ROLLBACK;
		THROW;
	END CATCH
END

GO


