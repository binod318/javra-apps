-- PR_GetMarkerPerVarieties
ALTER PROCEDURE [dbo].[PR_GetMarkerPerVarieties]
AS BEGIN
    SET NOCOUNT ON;

    SELECT 
	   V.CropCode,
	   MPV.MarkerPerVarID,
	   MPV.MarkerID,
	   MPV.VarietyNr,
	   MarkerName = M.MarkerFullName,
	   VarietyName = V.Shortname,
	   S.StatusName
    FROM MarkerPerVariety MPV
    JOIN Marker M ON M.MarkerID = MPV.MarkerID
    JOIN Variety V ON V.VarietyNr = MPV.VarietyNr
    JOIN [Status] S ON S.StatusCode = MPV.StatusCode AND S.StatusTable = 'Marker'
    ORDER BY S.StatusCode, M.MarkerName;
END
GO