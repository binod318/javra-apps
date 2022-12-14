IF NOT EXISTS(SELECT 1 FROM sys.columns 
          WHERE Name = N'SusceptibilityPercent'
          AND Object_ID = Object_ID(N'RDTTestResult'))
BEGIN

	ALTER TABLE RDTTestResult
	ADD SusceptibilityPercent DECIMAL(5,2)

END
GO

IF NOT EXISTS(SELECT 1 FROM sys.columns 
          WHERE Name = N'ValueColumn'
          AND Object_ID = Object_ID(N'RDTTestResult'))
BEGIN

	ALTER TABLE RDTTestResult
	ADD ValueColumn DECIMAL(5,2)

END
GO

IF NOT EXISTS(SELECT 1 FROM sys.columns 
          WHERE Name = N'Source'
          AND Object_ID = Object_ID(N'Determination'))
BEGIN

	ALTER TABLE Determination
	ADD [Source] NVARCHAR(50)

END
GO


IF NOT EXISTS(SELECT 1 FROM sys.columns 
          WHERE Name = N'OriginID'
          AND Object_ID = Object_ID(N'Determination'))
BEGIN

	ALTER TABLE Determination
	ADD OriginID INT

END

DROP PROCEDURE IF EXISTS [dbo].[PR_RDT_ReceiveResults]
GO

DROP TYPE IF EXISTS [dbo].[TVP_RDTScore]
GO

CREATE TYPE [dbo].[TVP_RDTScore] AS TABLE(
	[OriginID] [int] NULL,
	[MaterialID] [int] NULL,
	[Score] [nvarchar](255) NULL,
	[SusceptibilityPercent] [decimal](5,2) NULL,
	[ValueColumn] [nvarchar](100) NULL
)
GO


CREATE PROCEDURE [dbo].[PR_RDT_ReceiveResults]
(
	@TestID INT,
	@TestFlowType INT,
	@TVP_RDTScore TVP_RDTScore READONLY
) AS

BEGIN
SET NOCOUNT ON;
	BEGIN TRY
		BEGIN TRANSACTION;
					
			INSERT INTO RDTTestResult(TestID, DeterminationID, MaterialID, Score, ResultStatus, SusceptibilityPercent, ValueColumn)
			SELECT @TestID, T1.OriginID, T1.MaterialID, T1.Score, 100, SusceptibilityPercent, ValueColumn	
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

GO