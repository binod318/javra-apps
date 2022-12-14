DROP PROCEDURE IF EXISTS [PR_GetMarkerPerVarieties]
GO
-- PR_GetMarkerPerVarieties
CREATE PROCEDURE [dbo].[PR_GetMarkerPerVarieties]
AS BEGIN
    SET NOCOUNT ON;

    SELECT 
	   MPV.MarkerPerVarID,
	   MPV.MarkerID,
	   MPV.VarietyNr,
	   MarkerName = M.MarkerName,
	   VarietyName = V.Shortname,
	   S.StatusName
    FROM MarkerPerVariety MPV
    JOIN Marker M ON M.MarkerID = MPV.MarkerID
    JOIN Variety V ON V.VarietyNr = MPV.VarietyNr
    JOIN [Status] S ON S.StatusCode = MPV.StatusCode AND S.StatusTable = 'Marker';
END
GO

DROP PROCEDURE IF EXISTS PR_ConfirmPlanning
Go

/*
Author					Date			Description
Binod Gurung			2019-Sept-04	Service to confirm planning

===================================Example================================

EXEC PR_ConfirmPlanning N'[{"DetAssignmentID":1,"Action":"U"},{"DetAssignmentID":2,"Action":"D"}]';
*/
CREATE PROCEDURE [dbo].[PR_ConfirmPlanning]
(
    @DataAsJson NVARCHAR(MAX)
)
AS 
BEGIN
	 SET NOCOUNT ON;
	 BEGIN TRY
	   BEGIN TRANSACTION;
	   
	   DELETE DA
	   FROM DeterminationAssignment DA
	   JOIN OPENJSON(@DataAsJson) WITH
	   (
		  DetAssignmentID INT,
		  [Action]	   CHAR(1)
	   ) S ON S.DetAssignmentID = DA.DetAssignmentID
	   WHERE S.[Action] = 'D';

	   --Change status to 200 of those records which falls under that period
	   UPDATE DA
	   SET DA.StatusCode = 200
	   FROM DeterminationAssignment DA
	   JOIN OPENJSON(@DataAsJson) WITH
	   (
		  DetAssignmentID INT,
		  [Action]	   CHAR(1)
	   ) S ON S.DetAssignmentID = DA.DetAssignmentID
	   WHERE S.[Action] = 'U';
	   
	   COMMIT;
	END TRY
	BEGIN CATCH
	   IF @@TRANCOUNT > 0 
		ROLLBACK;
	   THROW;
	END CATCH
END
GO

DROP PROCEDURE IF EXISTS [PR_SaveMarkerPerVarieties]
GO

-- PR_SaveMarkerPerVarieties N'[{"MarkerPerVarID":2,"MarkerID":6,"VarietyNr":9008,"Action":"I"}]';
-- PR_SaveMarkerPerVarieties N'[]'
CREATE PROCEDURE [dbo].[PR_SaveMarkerPerVarieties]
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