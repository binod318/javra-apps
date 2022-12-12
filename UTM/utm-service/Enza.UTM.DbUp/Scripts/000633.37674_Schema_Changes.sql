IF NOT EXISTS (SELECT 1
               FROM   INFORMATION_SCHEMA.COLUMNS
               WHERE  TABLE_NAME = 'TestDeterminationFlowType'                      
                      AND TABLE_SCHEMA='DBO')
  BEGIN
      CREATE TABLE TestDeterminationFlowType
	(
		TestDetFlowID INT PRIMARY KEY IDENTITY(1,1),
		TestID INT,
		DeterminationID INT,
		TestFlowType INT,
		FOREIGN KEY (TestID) REFERENCES Test (TestID)
	)

	DROP INDEX IF EXISTS TestDeterminationFlowType.IDX_TestDeterminationFlowType_TestIDDetID;
	

	CREATE INDEX IDX_TestDeterminationFlowType_TestIDDetID ON TestDeterminationFlowType (TestID,DeterminationID);
	
  END
  
GO