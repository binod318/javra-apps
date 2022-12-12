CREATE TABLE [dbo].[History](
	[HistoryID] [bigint] PRIMARY KEY IDENTITY(1,1) NOT NULL,
	[PlateIDBarcode] [nvarchar](50) NOT NULL,
	[SampleNrBarcode] [nvarchar](50) NOT NULL,
	[User] [nvarchar](255) NULL,
	[CreatedDate] [datetime] NULL,
	[IsMatched] [bit] NULL,
)

GO


