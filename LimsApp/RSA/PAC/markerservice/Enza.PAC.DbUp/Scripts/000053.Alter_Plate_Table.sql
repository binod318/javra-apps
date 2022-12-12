ALTER TABLE Plate
ADD TestID INT;

GO

ALTER TABLE Plate
ADD FOREIGN KEY (TestID) REFERENCES Test(TestID);

GO

DROP TYPE IF EXISTS [dbo].[TVP_Plates]
GO

CREATE TYPE [dbo].[TVP_Plates] AS TABLE(
	[LIMSPlateID] [int] NULL,
	[LIMSPlateName] [nvarchar](100) NULL
)
GO


