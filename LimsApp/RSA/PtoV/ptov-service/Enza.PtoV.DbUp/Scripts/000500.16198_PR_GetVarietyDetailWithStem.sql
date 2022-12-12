/*
=========Changes====================
Created By			DATE				Description
Krishna Gautam		2019-Nov-12			Fetch all varieties having same stem as input GIDs
Krishna Gautam		2020-Sep-30			#16198: Do not fetch use stem if replace lot is done by already sent variety.

========Example=============
EXEC PR_GetVarietyDetailWithStem N'102594'
*/


ALTER PROCEDURE [dbo].[PR_GetVarietyDetailWithStem]
(
	@VarietyIDs	NVARCHAR(MAX) -- comma separated ids
) 
AS 
BEGIN
	DECLARE @CropCode Nvarchar(10);
	SET NOCOUNT ON;

	SELECT TOP 1 @CropCode = CropCode FROM Variety WHERE VarietyID IN (SELECT [value] FROM string_split(@VarietyIDs, ','))

	;WITH CTE AS
	(
		SELECT V1.*, NULL as Children
		FROM Variety V1
		JOIN string_split(@VarietyIDs, ',') T2 ON CAST(T2.[value] AS INT) = V1.VarietyID AND V1.StatusCode = 100
		UNION ALL		
		SELECT V.*,C.GID AS Parent
		FROM Variety V
		JOIN CTE C ON C.MalePar = V.GID OR C.FemalePar = V.GID OR C.Maintainer = V.GID
	)
	
	SELECT VarietyID, V.GID, V.Enumber, R.VarietyNr, V.Stem, V.StatusCode 
	FROM Variety V
	JOIN RelationPtoV R ON R.GID = V.GID
	JOIN CropRD C ON C.CropCode = V.CropCode 
	WHERE   ISNULL(C.UsePONr,0) = 0 /* Only Crop that doesn't use PO Number */
		AND V.StatusCode		IN (200, 250)
		AND V.CropCode			= @CropCode
		AND	R.StatusCode		= 100
		AND V.Stem IN ( SELECT Stem FROM Variety V WHERE V.VarietyID IN (SELECT VarietyID FROM CTE))

END
