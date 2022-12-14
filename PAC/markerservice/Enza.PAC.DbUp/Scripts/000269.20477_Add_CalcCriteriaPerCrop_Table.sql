CREATE TABLE CalcCriteriaPerCrop
(
	CropCode CHAR(2) NOT NULL UNIQUE,
	ThresholdA DECIMAL(5,2),
	ThresholdB DECIMAL(5,2),
	CalcExternalAppl BIT,
    FOREIGN KEY (CropCode) REFERENCES CropRD(CropCode)
)

GO