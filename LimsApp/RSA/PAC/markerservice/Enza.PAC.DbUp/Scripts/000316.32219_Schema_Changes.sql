
DROP INDEX IF EXISTS MarkerToBeTested.idx_DetAssignmentID

GO

CREATE INDEX idx_MTBT_MarkerID
ON MarkerToBeTested (MarkerID)

GO
