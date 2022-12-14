-- PR_SaveMarkerPerVarieties N'[{"MarkerPerVarID":2,"MarkerID":6,"VarietyNr":9008,"Action":"I"}]';
-- PR_SaveMarkerPerVarieties N'[]'
ALTER PROCEDURE [dbo].[PR_SaveMarkerPerVarieties]
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
    
    --New records
    INSERT MarkerPerVariety(MarkerID, VarietyNr, StatusCode)
    SELECT T.MarkerID, T.VarietyNr, 100
    FROM OPENJSON(@DataAsJson) WITH
    (
	   MarkerPerVarID  INT,
	   MarkerID	   INT,
	   VarietyNr	   INT,
	   [Action]	   CHAR(1)
    ) T
    LEFT JOIN MarkerPerVariety V ON V.MarkerPerVarID = T.MarkerPerVarID
    WHERE T.[Action] = 'I' AND V.MarkerPerVarID IS NULL;

    --Updates
    UPDATE V SET 
	   V.MarkerID = T.MarkerID,
	   V.VarietyNr = T.VarietyNr
    FROM MarkerPerVariety V
    JOIN OPENJSON(@DataAsJson) WITH
    (
	   MarkerPerVarID  INT,
	   MarkerID	   INT,
	   VarietyNr	   INT,
	   [Action]	   CHAR(1)
    ) T ON T.MarkerPerVarID = V.MarkerPerVarID
    WHERE T.[Action] = 'U';

    --Deletes
    UPDATE V SET 
	   V.StatusCode = 200
    FROM MarkerPerVariety V
    JOIN OPENJSON(@DataAsJson) WITH
    (
	   MarkerPerVarID  INT,
	   [Action]	   CHAR(1)
    ) T ON T.MarkerPerVarID = V.MarkerPerVarID
    WHERE T.[Action] = 'D';

     --Activate again
    UPDATE V SET 
	   V.StatusCode = 100
    FROM MarkerPerVariety V
    JOIN OPENJSON(@DataAsJson) WITH
    (
	   MarkerPerVarID  INT,
	   [Action]	   CHAR(1)
    ) T ON T.MarkerPerVarID = V.MarkerPerVarID
    WHERE T.[Action] = 'A';
END
GO

UPDATE [Status] SET StatusTable = 'DeterminationAssignment' WHERE StatusTable = 'Pac';
GO
UPDATE [Status] SET StatusName = 'Active' WHERE StatusID = 7;
GO
UPDATE [Status] SET StatusName = 'Inactive' WHERE StatusID = 8;
GO