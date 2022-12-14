DROP PROCEDURE IF EXISTS [dbo].[PR_SaveMarkerPerVarieties]
GO

-- PR_SaveMarkerPerVarieties N'[{"MarkerPerVarID":2,"MarkerID":6,"VarietyNr":9008,"Action":"I"}]';
-- PR_SaveMarkerPerVarieties N'[{"MarkerPerVarID":11,"MarkerID":0,"VarietyNr":0,"Action":"a"}]'
CREATE PROCEDURE [dbo].[PR_SaveMarkerPerVarieties]
(
    @DataAsJson NVARCHAR(MAX)
)AS BEGIN
    SET NOCOUNT ON;
    --duplicate validation while adding new and updating existing
    IF EXISTS
    (
	   SELECT T.MarkerID, T.VarietyNr
	   FROM OPENJSON(@DataAsJson) WITH
	   (
		  MarkerPerVarID  INT,
		  MarkerID	   INT,
		  VarietyNr	   INT,
		  [Action]	   CHAR(1)
	   ) T
	   JOIN MarkerPerVariety V ON V.MarkerID = T.MarkerID AND V.VarietyNr = T.VarietyNr
	   WHERE T.[Action] = 'I' OR (T.[Action] = 'U' AND V.MarkerPerVarID <> T.MarkerPerVarID)
    ) BEGIN
	   EXEC PR_ThrowError N'Same record already exits.';
	   RETURN;
    END
    
	MERGE INTO MarkerPerVariety T
	USING
	(
		SELECT T1.MarkerID,T1.MarkerPerVarID,T1.VarietyNr,T1.ExpectedResult,T1.Remarks,T1.[Action] FROM OPENJSON(@DataAsJson) WITH
		(
			MarkerPerVarID	INT,
			MarkerID			INT,
	   		VarietyNr		INT,
			ExpectedResult	NVARCHAR(20),
			Remarks			NVARCHAR(MAX),
			[Action]			CHAR(1)
		) T1

	) S ON T.MarkerPerVarID = S.MarkerPerVarID
	WHEN NOT MATCHED AND S.[Action] = 'I' THEN --Insert data
		INSERT (MarkerID, VarietyNr, StatusCode, ExpectedResult, Remarks)
		VALUES (S.MarkerID, S.VarietyNr, 100, S.ExpectedResult, S.Remarks)
	WHEN MATCHED THEN
		UPDATE SET
			StatusCode = (CASE 
								WHEN S.[Action] = 'A' THEN 100 
								WHEN S.[ACTION] = 'D' THEN 200
								ELSE T.StatusCode END
						),
			T.MarkerID = (CASE 
							WHEN S.[Action] = 'U' THEN S.MarkerID 
							ELSE T.MarkerID END
						),
			T.VarietyNr = (CASE 
							WHEN S.[Action] = 'U' THEN S.VarietyNr 
							ELSE T.VarietyNr END
						),
			T.ExpectedResult = (CASE 
							WHEN S.[Action] = 'U' THEN S.ExpectedResult 
							ELSE T.ExpectedResult END
						),
			T.Remarks = (CASE 
				WHEN S.[Action] = 'U' THEN S.Remarks 
				ELSE T.Remarks END
			);
END
GO


