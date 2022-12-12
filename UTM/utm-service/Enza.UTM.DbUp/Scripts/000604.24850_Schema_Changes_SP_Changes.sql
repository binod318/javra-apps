DROP TABLE IF ExiSts SHTestResult
GO

CREATE TABLE SHTestResult(
	[RDTTestResultID] [int] IDENTITY(1,1) NOT NULL PRIMARY KEY,
	[TestID] [int] NOT NULL,
	[DeterminationID] [int] NOT NULL,
	[MaterialID] [int] NOT NULL,
	[Score] [nvarchar](100) NULL,
	[StatusCode] [int] Null
)
GO

CREATE INDEX IDX_SHTestResultTestID ON SHTestResult
(
	TestID DESC
)
GO


DROP PROCEDURE IF EXISTS [dbo].[PR_SH_GetTestToSendScore]
GO
/*
=========Changes====================
Changed By			DATE				Description

Krishna Gautam		2021-JAN-03			#24850: Created Stored Procedure	

========Example=============
EXEC PR_SH_GetTestToSendScore

*/


CREATE PROCEDURE [dbo].[PR_SH_GetTestToSendScore]
AS
BEGIN

	SELECT T.TestID,F.CropCode, T.BreedingStationCode,T.LabPlatePlanName, T.TestName FROM Test T 
	JOIN [File] F ON F.FileID = T.FileID 
	WHERE T.StatusCode = 600 AND T.TestTypeID = 10;
END

GO