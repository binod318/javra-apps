DROP TABLE IF EXISTS ABS_Determination_assignments

GO

DROP TABLE IF EXISTS ABS_Determination_assignmentsTemp

GO

DROP TABLE IF EXISTS ABS_Process_lots

GO

DROP TABLE IF EXISTS ABS_Process_lotsTemp

GO

DROP INDEX IF EXISTS idx_MarkerValuePerVariety_VarietyNr
ON MarkerValuePerVariety;

GO

DROP INDEX IF EXISTS idx_MVPV_VarietyNr_MarkerID
ON MarkerValuePerVariety;

GO

DROP INDEX IF EXISTS idx_MPV_VarietyNr_MarkerID
ON MarkerPerVariety;

GO

DROP INDEX IF EXISTS idx_MTBT_DetAssignmentID_MarkerID
ON MarkerToBeTested;

GO

CREATE INDEX idx_Capacity_PeriodID_PlatformID
ON Capacity (PeriodID, PlatformID)

GO

CREATE INDEX idx_CropMethod_MethodID_ABSCrop_PlatformID
ON CropMethod (MethodID, ABSCropCode, PlatformID)

GO

CREATE INDEX idx_DA_MethodCode
ON DeterminationAssignment (MethodCode)

GO

CREATE INDEX idx_DA_VarietyNr
ON DeterminationAssignment (VarietyNr)

GO

CREATE INDEX idx_DA_StatusCode
ON DeterminationAssignment (StatusCode)

GO

CREATE INDEX idx_MCP_PlatformID_MarkerID
ON MarkerCropPlatform (PlatformID,MarkerID)

GO

CREATE INDEX idx_MCP_VarietyNr_MarkerID
ON MarkerPerVariety (VarietyNr, MarkerID)

GO

CREATE INDEX idx_MTBT_DetAssignmentID
ON MarkerToBeTested (DetAssignmentID)

GO

CREATE INDEX idx_MVPV_VarietyNr
ON MarkerValuePerVariety (VarietyNr)

GO

CREATE INDEX idx_MVPV_VarietyNr_MarkerID
ON MarkerValuePerVariety (VarietyNr, MarkerID)

GO

CREATE INDEX idx_MVP_PlatformID_VarietyNr
ON MarkerVarietyPlatform (PlatformID, VarietyNr)

GO

CREATE INDEX idx_Pattern_DetAssignmentID
ON Pattern (DetAssignmentID)

GO

CREATE INDEX idx_PatternResult_PatternID_MarkerID_Score
ON PatternResult (PatternID, MarkerID)
INCLUDE (Score)

GO

CREATE INDEX idx_Plate_TestID
ON Plate (TestID)

GO

CREATE INDEX idx_Plate_LabPlateID
ON Plate (LabPlateID)

GO

CREATE INDEX idx_ReservedCapacity_PeriodID_CropMethodID
ON ReservedCapacity (PeriodID, CropMethodID)

GO


CREATE INDEX idx_Status_StTable_StCode
ON [Status] (StatusTable, StatusCode)

GO


CREATE INDEX idx_Test_PeriodID
ON Test (PeriodID)

GO

CREATE INDEX idx_Test_StatusCode
ON Test (StatusCode)

GO

CREATE INDEX idx_TDA_TestID
ON TestDetAssignment (TestID)

GO

CREATE INDEX idx_TDA_DetAssignmentID
ON TestDetAssignment (DetAssignmentID)

GO

CREATE INDEX idx_TestResult_WellID_MarkerID_Score
ON TestResult (WellID, MarkerID)
INCLUDE (Score)

GO

CREATE INDEX idx_Variety_CropCode_PacComp
ON Variety (CroPCode, PacComp)

GO

CREATE INDEX idx_Well_Position
ON Well (Position)

GO

CREATE INDEX idx_Well_PlateID
ON Well (PlateID)

GO

CREATE INDEX idx_Well_DetAssignmetnID
ON Well (DetAssignmentID)

GO

