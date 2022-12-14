ALTER TABLE CalcCriteriaPerCrop
DROP CONSTRAINT FK_MaterialTypeCalcCriteriaPerCrop

GO

DROP TABLE IF EXISTS [dbo].[MaterialType]
GO


CREATE TABLE [dbo].[MaterialType](
	[MaterialTypeID] [int] PRIMARY KEY NOT NULL,
	[MaterialTypeCode] [varchar](8) NOT NULL,
	[MaterialTypeDescription] [varchar](20) NULL
)
GO



ALTER TABLE CalcCriteriaPerCrop
ADD CONSTRAINT FK_MaterialTypeCalcCriteriaPerCrop
FOREIGN KEY (MaterialTypeID) REFERENCES MaterialType(MaterialTypeID)

GO



