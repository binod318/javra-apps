ALTER TABLE CalcCriteriaPerCrop
ADD MaterialTypeID INT

GO

ALTER TABLE CalcCriteriaPerCrop
ADD CONSTRAINT FK_MaterialTypeCalcCriteriaPerCrop
FOREIGN KEY (MaterialTypeID) REFERENCES MaterialType(MaterialTypeID)

GO

