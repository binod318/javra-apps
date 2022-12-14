CREATE INDEX idx_MTBT_DetAssignmentID_MarkerID 
ON MarkerToBeTested (DetAssignmentID, MarkerID)

GO

CREATE INDEX idx_MPV_VarietyNr_MarkerID 
ON MarkerPerVariety (VarietyNr, MarkerID)

GO

CREATE INDEX idx_MVPV_VarietyNr_MarkerID 
ON MarkerValuePerVariety (VarietyNr, MarkerID)
INCLUDE (AlleleScore)

GO
