/*Schema changes */

DROP TABLE IF EXISTS TestDeterminationFlowType
GO

CREATE TABLE TestDeterminationFlowType
(
	TestDetFlowID INT PRIMARY KEY IDENTITY(1,1),
	TestID INT,
	DeterminationID INT,
	TestFlowType INT,
	FOREIGN KEY (TestID) REFERENCES Test (TestID)
)
GO

DROP INDEX IF EXISTS TestDeterminationFlowType.IDX_TestDeterminationFlowType_TestIDDetID;
GO

CREATE INDEX IDX_TestDeterminationFlowType_TestIDDetID ON TestDeterminationFlowType (TestID,DeterminationID)
GO

/*Insert existing data to new table for test flow type */

MERGE INTO TestDeterminationFlowType T
USING
(
	SELECT TR.TestID,TR.DeterminationID, FlowType = MAX(T.TestFlowType) FROM Test T
	JOIN RDTTestResult TR ON TR.TestID = T.TestID
	WHERE T.TestTypeID = 8
	GROUP BY TR.TestID, TR.DeterminationID
) S ON S.TestID = T.TestID AND S.DeterminationID = T.DeterminationID
WHEN NOT MATCHED THEN 
INSERT(TestID, DeterminationID, TestFlowType)
VALUES(S.TestID, S.DeterminationID, S.FlowType);

GO

IF EXISTS (SELECT 1
               FROM   INFORMATION_SCHEMA.COLUMNS
               WHERE  TABLE_NAME = 'Test'
                      AND COLUMN_NAME = 'TestFlowType'
                      AND TABLE_SCHEMA='DBO')
  BEGIN
      ALTER TABLE Test
        DROP COLUMN TestFlowType
  END
GO