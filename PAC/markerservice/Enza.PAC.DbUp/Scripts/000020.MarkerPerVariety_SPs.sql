DROP PROCEDURE IF EXISTS PR_GetMarkers
GO

-- PR_GetMarkers '024'
CREATE PROCEDURE PR_GetMarkers
(
    @MarkerName NVARCHAR(100) = ''
) AS BEGIN
    SET NOCOUNT ON;

    SELECT 
	   M.MarkerID,
	   M.MarkerName
    FROM Marker M
    WHERE M.StatusCode = 100 
    AND M.MarkerName LIKE '%' + @MarkerName + '%';
END
GO


DROP PROCEDURE IF EXISTS PR_GetVarieties
GO

-- PR_GetVarieties 'EK'
CREATE PROCEDURE PR_GetVarieties
(
    @VarietyName NVARCHAR(100) = ''
) AS BEGIN
    SET NOCOUNT ON;

    SELECT 
	   V.VarietyNr,
	   VarietyName = V.Shortname
    FROM Variety V
    WHERE --V.[Status] = '100' AND 
    V.Shortname LIKE '%' + @VarietyName + '%';
END
GO

DROP PROCEDURE IF EXISTS PR_GetMarkerPerVarieties
GO

-- PR_GetMarkerPerVarieties
CREATE PROCEDURE PR_GetMarkerPerVarieties
AS BEGIN
    SET NOCOUNT ON;

    SELECT 
	   MPV.MarkerPerVarID,
	   MPV.MarkerID,
	   MPV.VarietyNr,
	   MarkerName = M.MarkerName,
	   VarietyName = V.Shortname
    FROM MarkerPerVariety MPV
    JOIN Marker M ON M.MarkerID = MPV.MarkerID
    JOIN Variety V ON V.VarietyNr = MPV.VarietyNr;
END
GO

DROP PROCEDURE IF EXISTS PR_SaveMarkerPerVarieties
GO

-- PR_SaveMarkerPerVarieties N'[{"MarkerPerVarID":2,"MarkerID":6,"VarietyNr":9008,"Action":"I"}]';
-- PR_SaveMarkerPerVarieties N'[]'
CREATE PROCEDURE PR_SaveMarkerPerVarieties
(
    @DataAsJson NVARCHAR(MAX)
)AS BEGIN
    SET NOCOUNT ON;
    
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
	   MarkerID	   INT,
	   VarietyNr	   INT,
	   [Action]	   CHAR(1)
    ) T ON T.MarkerPerVarID = V.MarkerPerVarID
    WHERE T.[Action] = 'D';
END
GO