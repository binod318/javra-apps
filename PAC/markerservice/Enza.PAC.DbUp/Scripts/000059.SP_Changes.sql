DROP PROCEDURE IF EXISTS [dbo].[PR_GetMarkers]
GO

-- PR_GetMarkers 'SL'
CREATE PROCEDURE [dbo].[PR_GetMarkers]
(
    @MarkerName NVARCHAR(100) = ''
) AS BEGIN
    SET NOCOUNT ON;

    SELECT 
	   M.MarkerID,
	   MarkerName = M.MarkerFullName
    FROM Marker M
    WHERE M.StatusCode = 100 
    AND M.MarkerFullName LIKE '%' + @MarkerName + '%';
END
GO


DROP PROCEDURE IF EXISTS [dbo].[PR_GetMarkerPerVarieties]
GO

-- PR_GetMarkerPerVarieties
CREATE PROCEDURE [dbo].[PR_GetMarkerPerVarieties]
AS BEGIN
    SET NOCOUNT ON;

    SELECT 
	   V.CropCode AS 'Crop',
	   MPV.MarkerPerVarID,
	   MPV.MarkerID,
	   V.Shortname AS 'Variety name',
	   MPV.VarietyNr AS 'Variety number',
	   M.MarkerFullName AS 'Trait marker',
	   MPV.ExpectedResult AS 'Expected result', 
	   MPV.Remarks,
	   S.StatusName
    FROM MarkerPerVariety MPV
    JOIN Marker M ON M.MarkerID = MPV.MarkerID
    JOIN Variety V ON V.VarietyNr = MPV.VarietyNr
    JOIN [Status] S ON S.StatusCode = MPV.StatusCode AND S.StatusTable = 'Marker'
    ORDER BY S.StatusCode, M.MarkerName;
END
GO


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
    
    --New records
    INSERT MarkerPerVariety(MarkerID, VarietyNr, StatusCode, ExpectedResult, Remarks)
    SELECT T.MarkerID, T.VarietyNr, 100, T.ExpectedResult, T.Remarks
    FROM OPENJSON(@DataAsJson) WITH
    (
	   MarkerPerVarID	INT,
	   MarkerID			INT,
	   VarietyNr		INT,
	   ExpectedResult	NVARCHAR(20),
	   Remarks			NVARCHAR(MAX),
	   [Action]			CHAR(1)
    ) T
    LEFT JOIN MarkerPerVariety V ON V.MarkerPerVarID = T.MarkerPerVarID
    WHERE T.[Action] = 'I' AND V.MarkerPerVarID IS NULL;

    --Updates
    UPDATE V SET 
	   V.MarkerID = T.MarkerID,
	   V.VarietyNr = T.VarietyNr,
	   V.ExpectedResult = T.ExpectedResult,
	   V.Remarks		= T.Remarks
    FROM MarkerPerVariety V
    JOIN OPENJSON(@DataAsJson) WITH
    (
	   MarkerPerVarID	INT,
	   MarkerID			INT,
	   VarietyNr		INT,
	   ExpectedResult	NVARCHAR(20),
	   Remarks			NVARCHAR(MAX),
	   [Action]			CHAR(1)
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


