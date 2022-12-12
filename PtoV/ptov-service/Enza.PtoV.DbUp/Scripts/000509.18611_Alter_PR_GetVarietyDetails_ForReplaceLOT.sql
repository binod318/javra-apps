/*
	==================================================================
	CHANGED BY			DATE				REMARKS
	------------------------------------------------------------------
	Krishna Gautam		-					-
	Krishna Gautam		Nov-13-2020			#17015:Change IsDefault for lot in importing data 
	Krishna Gautam		Jan-22-2021			#17015:Change IsDefault for lot in importing data

	==================================================================

*/

ALTER PROCEDURE [dbo].[PR_GetVarietyDetails_ForReplaceLOT]
(
	@VarietyIDs	NVARCHAR(MAX)
) AS
BEGIN
	DECLARE @ReplacedLotTable AS TABLE
	(
		GID INT,
		VarietyNr INT,
		TransferType NVARCHAR(MAX)
	);
	DECLARE @LotTable AS TABLE (GID INT, GID1 INT, PhenomeLotID INT, VarmasLotNr INT);
	
	--Previous get lot method commented
	/*
	--insert default lot for GID
	INSERT INTO @LotTable
	SELECT V.LotGID, MAX(L.PhenomeLotID) FROM Variety V
	JOIN string_split(@VarietyIDs, ',') T2 ON CAST(T2.[value] AS INT) = V.VarietyID
	LEFT JOIN LOT L ON L.GID = V.GID AND L.IsDefault = 1
	GROUP BY V.LotGID
	*/
	
	----Conditional replace lot is required for sending data varmas for previous method and new method
	----this will get default lot for first version of replace lot
	--INSERT INTO @LotTable(GID, PhenomeLotID, VarmasLotNr)
	--SELECT 
	--	V.LotGID, 
	--	MAX(L.PhenomeLotID), 
	--	MAX(L.VarmasLot) 
	--FROM Variety V
	--JOIN string_split(@VarietyIDs, ',') T2 ON CAST(T2.[value] AS INT) = V.VarietyID
	--LEFT JOIN LOT L ON L.GID = V.GID AND L.IsDefault = 1
	--WHERE ISNULL(V.ReplacedLotID,0)=0 --this condition will not fetch all lot data for new implementation
	--GROUP BY V.LotGID

	--this will get lot information after implementation replce lot from pedigree data shown to frontend
	INSERT INTO @LotTable(GID, GID1, PhenomeLotID, VarmasLotNr)
	SELECT 
		V.LotGID,
		MAX(L.GID),
		MAX(L.PhenomeLotID), 
		MAX(L.VarmasLot) 
	FROM Variety V
	JOIN string_split(@VarietyIDs, ',') T2 ON CAST(T2.[value] AS INT) = V.VarietyID
	LEFT JOIN LOT L ON L.PhenomeLotID = V.ReplacedLotID AND L.GID = V.LotGID --this condition will fetch data for replace lot with pedigree data
	GROUP BY V.LotGID

	IF EXISTS (SELECT GID FROM @LotTable WHERE ISNULL(GID1,0) = 0)
	BEGIN
		EXEC PR_ThrowError 'Replaced lot data not found.';
		RETURN;
	END

	----if default lot is not available then insert any lot present on lot table
	--UPDATE LT 
	--SET LT.PhenomeLotID = L.PhenomeLotID
	--FROM @LotTable LT 
	--JOIN (SELECT GID,Max(PhenomeLotID) AS PhenomeLotID FROM LOT GROUP BY GID) L ON L.GID = LT.GID
	--WHERE ISNULL(LT.PhenomeLotID,0) =0

	--UPDATE LT 
	--SET LT.VarmasLotNr = L.VarmasLot
	--FROM @LotTable LT 
	--JOIN Lot L ON L.GID = LT.GID AND L.PhenomeLotID = LT.PhenomeLotID
	--WHERE ISNULL(LT.VarmasLotNr,0) =0

	INSERT INTO @ReplacedLotTable(GID,VarietyNr,TransferType)
		SELECT 
			V.LotGID,
			R.VarietyNr,
			CASE WHEN ISNULL(CR.HasOp,0) = 0 AND  MAX(V.TransferType) = 'OP' THEN 'Male' ELSE MAX(V.TransferType) END
		FROM Variety V
		JOIN string_split(@VarietyIDs, ',') T ON CAST(T.[value] AS INT) = V.VarietyID
		JOIN RelationPtoV R ON R.GID = V.GID
		JOIN CropRD CR ON CR.CropCode= v.CropCode
		WHERE 
		V.ReplacedLot = 1 AND V.StatusCode BETWEEN 200 AND 250
		GROUP BY LotGID, VarietyNr,CR.HasOp


	SELECT 
		V.VarietyID,
		V.CropCode,
		V.BrStationCode,
		V.GID,
		T.TransferType,
		V.ENumber,
		V.NewCropCode,
		V.ProdSegCode,
		V.SyncCode,
		V.StatusCode,
		V.Maintainer,
		V.FemalePar,
		V.MalePar,
		0 AS Children,
		ISNULL(L.PhenomeLotID,0) AS PhenomeLotID,
		T.VarietyNr,
		V.CountryOfOrigin,
		CRD.UsePONr,
		V.Stem,
		L.VarmasLotNr
	FROM Variety V 
	JOIN @ReplacedLotTable T ON T.GID = V.GID
	JOIN CropRD CRD ON CRD.CropCode = V.CropCode
	LEFT JOIN @LotTable L ON L.GID = V.GID 
END

