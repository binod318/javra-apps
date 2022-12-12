/*
=========Changes====================
Changed By			Date				Description

										#15150: Created Stored Procedure	
Krishna Gautam		2021-03-17			Stored procedure changes.
Krishna Gautam		2021-04-16			Stored procedure changes.

========Example=============
EXEC PR_RDT_GetScore 10628

*/
ALTER PROCEDURE [dbo].[PR_RDT_ReceiveResults]
(
	@TestID INT,
	@TestFlowType INT,
	@TVP_RDTScore TVP_RDTScore READONLY
) AS

BEGIN
SET NOCOUNT ON;
	BEGIN TRY
		BEGIN TRANSACTION;
					
			INSERT INTO RDTTestResult(TestID, DeterminationID, MaterialID, Score, ResultStatus, SusceptibilityPercent, MappingColumn)
			SELECT @TestID, DeterminationID = MAX(D.DeterminationID), T1.MaterialID, T1.Score, 100, SusceptibilityPercent, ValueColumn	
			FROM @TVP_RDTScore T1
			JOIN Determination D ON D.OriginID = T1.OriginID AND D.Source = 'StarLims'
			JOIN TestMaterialDetermination TMD ON TMD.DeterminationID = D.DeterminationID AND TMD.MaterialID = T1.MaterialID
			WHERE TMD.TestID = @TestID
			GROUP BY T1.OriginID, T1.MaterialID, T1.Score, T1.SusceptibilityPercent, T1.ValueColumn;

			UPDATE Test 
				SET StatusCode = 550, --Partially Received
					TestFlowType = @TestFlowType
			WHERE TestID = @TestID;
			
		COMMIT;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
            ROLLBACK;
		THROW;
	END CATCH
END

