DROP TABLE IF EXiSTS MaterialLot
GO

CREATE TABLE [dbo].[MaterialLot](
	[MaterialLotID] [int] IDENTITY(1,1) NOT NULL,
	[MaterialType] [nvarchar](20) NOT NULL,
	[MaterialKey] [nvarchar](50) NOT NULL,
	[CropCode] [nvarchar](2) NOT NULL,
	[StatusCode] [int] NULL,
	[Originrowid] [int] NULL,
	[RefExternal] [nvarchar](100) NULL,
	[BreedingStationCode] [nvarchar](10) NULL,
 CONSTRAINT [PK_MaterialLot] PRIMARY KEY CLUSTERED 
(
	[MaterialLotID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO


CREATE INDEX IDX_MateriallotMaterialKey
on MaterialLot 
(Materialkey DESC)
GO





ALTER TABLE LD_SampleTestMaterial
ADD MaterialLotID INT

GO