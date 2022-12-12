DROP TABLE IF EXISTS [dbo].[MaterialType]
GO


CREATE TABLE [dbo].[MaterialType](
	[MaterialTypeID] [int] PRIMARY KEY IDENTITY(1,1) NOT NULL,
	[MaterialTypeCode] [varchar](8) NOT NULL,
	[MaterialTypeDescription] [varchar](20) NULL
)
GO