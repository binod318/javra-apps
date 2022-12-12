/*
	==================================================================
	CHNGED BY			DATE				REMARKS
	------------------------------------------------------------------
	Krishna Gautam		March-11-2019		Change request not to set default for newly created lot and set status of Lot to 200 which was 100 earlier.
	Krishna Gautam		May-16-2019			Change on update EZVarietyRelation table where ID is reserved from another sp.
	Krishna Gautam		2021-May-10			#22127:Change logic on updating relationptov table with new gid.


	==================================================================


	DECLARE @DATA NVARCHAR(MAX) = N'[{"GID": 123123, "VarietyNr": 32123}]';
	EXEC PR_VtoPSync_UpdatePtoVRelationship @DATA
*/
ALTER  PROCEDURE [dbo].[PR_VtoPSync_UpdatePtoVRelationship]
(
	@DataAsJson	NVARCHAR(MAX)
) AS BEGIN
	SET NOCOUNT ON;

	DECLARE @tbl TABLE(GID INT, VarietyNr INT, PhenomeLotID INT, VarmasLotNr INT, EZID INT,NewGID INT);
	DECLARE @InsertedGID TABLE(GID INT,[Action] NVARCHAR(MAX));
	
	INSERT INTO @tbl(GID, VarietyNr, PhenomeLotID, VarmasLotNr, EZID, NewGID)
	SELECT 
		GID, 
		VarietyNr,
		PhenomeLotID,
		VarmasLotNr,
		EZID,
		NewGID
	FROM OPENJSON(@DataAsJson)  
	WITH 
	(	
		GID INT '$.GID', 
		VarietyNr INT '$.VarietyNr',
		PhenomeLotID INT '$.PLotNr', 
		VarmasLotNr INT '$.VLotNr',
		EZID INT '$.EZID',
		NewGID INT '$.NewGID'
	);

	--INSERT OR UPDATE RELATION
	MERGE INTO RelationPtoV T
	USING 
	(
		SELECT 
			GID, 
			VarietyNr,
			NewGID
		FROM @tbl
	) S	ON S.GID = T.GID
	WHEN NOT MATCHED THEN
		INSERT(GID, VarietyNr, StatusCode)
		VALUES(S.GID, S.VarietyNr, 100)		
	WHEN MATCHED AND ISNULL(T.NewGID,0) <> ISNULL(S.NewGID,0) THEN
		UPDATE SET T.NewGId = S.NewGID
		OUTPUT  INSERTED.GID,$action INTO @InsertedGID;

    
	DECLARE @log TABLE(LotID INT, GID INT);

	--Add New records
	INSERT INTO LOT(GID, PhenomeLotID, VarmasLot, StatusCode, IsDefault)
	OUTPUT INSERTED.LotID, INSERTED.GID INTO @log
	SELECT 
		CASE WHEN ISNULL(T1.NewGID,0) <> 0 THEN T1.NewGID
			ELSE T1.GID END,
		T1.PhenomeLotID, 
		T1.VarmasLotNr, 
		200, 
		0 --CASE WHEN ISNULL(L.GID,0)=0 THEN 1 ELSE 0 END
	FROM @tbl T1
	LEFT JOIN LOT L ON L.GID = T1.GID AND L.PhenomeLotID = T1.PhenomeLotID
	WHERE L.LotID IS NULL;
	
	--new method to make default which is true only for newly created germplasm but not for only new lot.
	UPDATE L SET IsDefault = 1
	FROM Lot L 
	JOIN @InsertedGID G ON G.GID = L.GID
	WHERE G.[Action] = 'INSERT';

END
