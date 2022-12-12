DROP PROCEDURE IF EXISTS PR_SH_SaveTraitDeterminationResult
GO

DROP PROCEDURE IF EXISTS PR_SH_Get_TraitDeterminationResult
GO


DROP TABLE IF EXISTS SHTraitDetResult
GO


CREATE TABLE [dbo].[SHTraitDetResult](
	[SHTraitDetResultID] [int] IDENTITY(1,1) NOT NULL PRIMARY KEY,
	[RelationID] [int] NOT NULL,
	[SampleType] [nvarchar](100) NULL,
	[MappingCol] [nvarchar](100) NULL
)
GO

DROP INDEX IF EXISTS IDX_SHTDRRelationIDSampleType ON SHTraitDetResult
GO

CREATE INDEX IDX_SHTDRRelationIDSampleType 
ON SHTraitDetResult (RelationID,SampleType,MappingCol)
GO


DROP TYPE IF EXISTS TVP_SHTraitDeterminationResult
GO

CREATE TYPE TVP_SHTraitDeterminationResult AS TABLE(
	[SHTraitDetResultID] [int] NULL,
	[RelationID] [int] NULL,
	[SampleType] [nvarchar](1000) NULL,
	[MappingCol] [nvarchar](1000) NULL,
	[Action] [nvarchar](10) NULL
)
GO