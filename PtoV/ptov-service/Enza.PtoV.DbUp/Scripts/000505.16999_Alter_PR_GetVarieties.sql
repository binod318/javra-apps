DROP PROCEDURE IF EXISTS [dbo].[PR_GetVarieties]
GO


-- EXEC [PR_GetVarieties] '3754362'
CREATE PROCEDURE [dbo].[PR_GetVarieties]
(
	@GIDs	NVARCHAR(MAX) -- comma separated ids
) AS BEGIN
	SET NOCOUNT ON;

	SELECT 
	   V1.*,
	   MaintainerPONr = V2.PONumber
	FROM
	(
	    SELECT 
		  V.VarietyID,
		  V.GID,
		  V.SyncCode,
		  V.CropCode,
		  V.BrStationCode,
		  V.FemalePar,
		  V.MalePar,
		  V.Maintainer,
		  V.TransferType,
		  V.PONumber,
		  VarmasStatus = ISNULL(S.StatusName,'')
	    FROM Variety V
		LEFT JOIN [Status] S ON V.VarmasStatusCode = S.StatusCode AND S.StatusTable = 'VarmasStatus'
	    JOIN string_split(@GIDs, ',') V2 ON CAST(V2.[Value] AS INT) = V.GID
	) V1
	LEFT JOIN Variety V2 ON V2.GID = ISNULL(V1.Maintainer, 0);
END
GO


