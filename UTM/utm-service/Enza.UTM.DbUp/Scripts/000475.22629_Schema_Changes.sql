DROP TABLE IF EXISTS [dbo].[LD_SampleTestMaterial]
GO

DROP TABLE IF EXISTS [dbo].[LD_SampleTestDetermination]
GO

DROP TABLE IF EXISTS [dbo].[LD_SampleTest]
GO

DROP TABLE IF EXISTS [dbo].[LD_MaterialPlant]
GO

DROP TABLE IF EXISTS [dbo].[LD_Sample]
GO




CREATE TABLE [dbo].[LD_Sample](
	[SampleID] [int] IDENTITY(1,1) NOT NULL,
	[SampleName] [nvarchar](150) NOT NULL,
	[ReferenceCode] [nvarchar](150) NULL,
	PRIMARY KEY (SampleID)
)
GO

CREATE TABLE [dbo].[LD_SampleTest](
	[SampleTestID] [int] IDENTITY(1,1) NOT NULL,
	[TestID] [int] NOT NULL,
	[SampleID] [int] NOT NULL,
	PRIMARY KEY (SampleTestID),
    FOREIGN KEY (TestID) REFERENCES Test(TestID),
    FOREIGN KEY (SampleID) REFERENCES [LD_Sample](SampleID)

) 
GO


CREATE TABLE [LD_SampleTestMaterial](
	[SampleTestMatID] [int] IDENTITY(1,1) NOT NULL,
	[SampleTestID] [int] NOT NULL,
	[NrOfPlants] [int] NULL,
	[MaterialPlantID] [int] NULL,
	PRIMARY KEY (SampleTestMatID),
    FOREIGN KEY (SampleTestID) REFERENCES LD_SampleTest(SampleTestID)
) 
GO

CREATE TABLE [dbo].[LD_MaterialPlant](
	[MaterialPlantID] [int] IDENTITY(1,1) NOT NULL,
	[MaterialID] [int] NOT NULL,
	[Name] [nvarchar](150) NULL,
	PRIMARY KEY (MaterialPlantID),
    FOREIGN KEY (MaterialID) REFERENCES Material(MaterialID),

) 
GO

CREATE TABLE [dbo].[LD_SampleTestDetermination](
	[SampleTestDetID] [int] IDENTITY(1,1) NOT NULL,
	[SampleTestID] [int] NOT NULL,
	[DeterminationID] [int] NOT NULL,
	[StatusCode] [int] NOT NULL,
	PRIMARY KEY (SampleTestDetID),
    FOREIGN KEY (SampleTestID) REFERENCES LD_SampleTest(SampleTestID),
	FOREIGN KEY (DeterminationID) REFERENCES Determination(DeterminationID)
) 
GO


IF NOT EXISTS (SELECT StatusID FROM [Status] WHERE StatusTable = 'LD_SampleTestDetermination')
BEGIN
	INSERT [STATUS](StatusID, StatusTable, StatusCode, StatusName, StatusDescription)
	VALUES  (49, 'LD_SampleTestDetermination', 100, 'Assigned', 'Assigned'),
			(50, 'LD_SampleTestDetermination', 200, 'Cancelled', 'Cancelled in UTM'),
			(51, 'LD_SampleTestDetermination', 300, 'Updated', 'Updated'),
			(52, 'LD_SampleTestDetermination', 400, 'Synced', 'Synced')

END

GO





