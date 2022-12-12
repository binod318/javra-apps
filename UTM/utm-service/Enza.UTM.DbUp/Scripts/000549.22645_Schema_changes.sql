CREATE TABLE LD_TestResult
(

	LDTestResultID INT PRIMARY KEY IDENTITY(1,1),
	SampleTestID INT FOREIGN KEY REFERENCES LD_SampleTest(SampleTestID) ,
	DeterminationID INT FOREIGN KEY REFERENCES Determination(DeterminationID) ,
	Score NVARCHAR(MAX),
	StatusCode INT
)
GO
