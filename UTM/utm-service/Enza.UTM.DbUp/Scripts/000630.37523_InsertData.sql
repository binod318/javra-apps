MERGE INTO testTypedetermination T 
USING 
(
    SELECT determinationID, testTypeid = 1 FROM determination WHERE determinationName in ('slm0149559','slm0149560','slm0149561','slm0149562') 
) S on T.TestTypeid = S.testTypeid and T.determinationID = S.determinationID
WHEN NOT MATCHED THEN
INSERT (DeterminationID, TestTypeID)
VALUES (S.determinationID, S.TesttypeID);