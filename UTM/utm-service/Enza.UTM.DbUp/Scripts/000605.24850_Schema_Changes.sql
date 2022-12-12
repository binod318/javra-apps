DROP TABLE IF EXISTS [dbo].[SHTestResult]
GO


CREATE TABLE [dbo].[SHTestResult](
	[SHTestResultID] [int] PRIMARY KEY IDENTITY(1,1) NOT NULL,
	[SampleTestID] [int] NOT NULL,
	[DeterminationID] [int] NOT NULL,
	[Score] [nvarchar](100) NULL,
	[MappingColumn] [nvarchar](50) NULL,
	[StatusCode] [int] NULL

)
GO

ALTER TABLE SHTestResult
ADD CONSTRAINT FK_SHTestResultSampleTest
FOREIGN KEY (SampleTestID) REFERENCES LD_SampleTest(SampleTestID);

GO

ALTER TABLE SHTestResult
ADD CONSTRAINT FK_SHTestResultDetermination
FOREIGN KEY (DeterminationID) REFERENCES Determination(DeterminationID);

GO

--Update Meail group
UPDATE EmailConfig
SET ConfigGroup = REPLACE(ConfigGroup,'LD_','')
WHERE ConfigGroup LIKE 'LD_TEST_COMPLETE%'

GO