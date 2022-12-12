ALTER PROCEDURE [dbo].[PR_GetImportedGIDsToSync]
(
	@CropCode NVARCHAR(10)
)
AS
BEGIN
	SELECT 
		V.GID
	FROM [Row] T1
	JOIN [File] T2 ON T2.FileID = T1.FileID
	JOIN Variety V ON V.GID = T1.MaterialKey
	LEFT JOIN RelationPtoV R ON R.GID = V.GID --this left join is required to sync variety which is not sent to varmas
	--WHERE ISNULL(R.StatusCode,100) = 100 AND T2.CropCode = @CropCode AND (V.StatusCode = 100 OR (V.StatusCode IN (200, 250) AND V.VarmasStatusCode In (20,30,40,130,140)))
	WHERE V.StatusCode = 100 
		  OR (R.StatusCode = 100 AND T2.CropCode = @CropCode AND V.StatusCode IN (200, 250) AND V.VarmasStatusCode In (20,30,40,130,140))
END	

GO


ALTER PROCEDURE [dbo].[PR_SynchronizePhenome]
(
	@TVP	TVP_Synchronization READONLY
) AS BEGIN
	SET NOCOUNT ON;

	MERGE [Cell] AS T
	USING
	(
		SELECT 
			T2.RowID,
			T1.ColumnID,
			T1.[Value],
			V.StatusCode	
		FROM @TVP T1
		JOIN [Row] T2 ON T2.MaterialKey = T1.GID
		JOIN Variety V ON V.GID = T2.Materialkey
	) AS S ON S.RowID = T.RowID AND S.ColumnID = T.ColumnID
	WHEN MATCHED AND  ISNULL(S.[Value],'') = '' AND S.StatusCode = 100 THEN
		DELETE
	WHEN MATCHED AND S.[Value] <> T.[Value] THEN
		UPDATE SET [Value] = S.[Value], Modified = CASE WHEN S.StatusCode IN(200, 250) THEN 1 ELSE 0 END
	
	WHEN NOT MATCHED AND ISNULL(S.[Value], '') <> '' AND ISNULL(S.RowID,0) <> 0 AND ISNULL(S.ColumnID,0) <> 0 THEN
		INSERT (RowID, ColumnID, [Value], Modified)
		VALUES(S.RowID, S.ColumnID, S.[Value], CASE WHEN S.StatusCode IN(200, 250) THEN 1 ELSE 0 END);
END

GO


--EXEC PR_GetVarmasDataToSync 'ED'
ALTER PROCEDURE [dbo].[PR_GetVarmasDataToSync]
(
	@CropCode	NVARCHAR(10)
) AS BEGIN
	SET NOCOUNT ON;

	DECLARE @Table Table (SyncCode NVARCHAR(MAX), GID INT, VarietyNr INT, VarmasLot INT,ScreeningFieldNr INT, ScreeningFieldValue NVARCHAR(MAX), IsValid BIT, CellID INT,TraitID INT,TraitName NVARCHAR(MAX), ColumnLabel NVARCHAR(MAX));

	INSERT INTO @Table(SyncCode, GID,VarietyNr,VarmasLot,ScreeningFieldNr,ScreeningFieldValue,IsValid,CellID,TraitID,TraitName,ColumnLabel)
	SELECT
		V1.SyncCode,
		V1.GID,
		V1.VarietyNr,
		V1.VarmasLot,
		V1.ScreeningFieldNr,
		ScreeningFieldValue = CASE WHEN IsValid = 1 THEN ISNULL(V1.ScreeningValue,V1.[Value]) ELSE V1.[Value] END,
		IsValid = CAST(V1.IsValid AS BIT),
		V1.CellID,
		V1.TraitID,
		V1.TraitName,
		V1.ColumLabel
	FROM
	(
		SELECT
			C1.CellID, 
			V.SyncCode,
			RPTV.VarietyNr,
			V.GID,
			L.VarmasLot,
			SF.ScreeningFieldNr,
			C1.[Value],
			TSR.ScreeningValue,
			T.TraitID,
			T.TraitName,
			C.ColumLabel,
			IsValid =	CASE	WHEN ISNULL(C1.[Value], '') = '' THEN 1
								WHEN ISNULL(SF.ScreeningFieldNr, 0) = 0 THEN 0 
								WHEN ISNULL(T.ListOfValues, 0) = 0 THEN 1
								WHEN ISNULL(TSR.TraitValueChar, '') = ISNULL(C1.[Value], '') THEN 1 
								ELSE 0 
						END
		FROM dbo.[File] F
		JOIN dbo.[Column] C ON C.FileID = F.FileID
		JOIN dbo.[Row] R ON R.FileID = F.FileID
		JOIN Cell C1 ON C1.RowID = R.RowID AND C1.ColumnID = C.ColumnID
		JOIN dbo.Variety V ON V.GID = R.MaterialKey AND V.CropCode = F.CropCode
		JOIN LOT L ON L.GID = V.GID AND L.IsDefault = 1
		JOIN RelationPtoV RPTV On RPTV.GID = V.GID
		JOIN Trait T ON T.TraitID = C.TraitID
		JOIN CropTrait CT ON CT.TraitID = T.TraitID AND F.CropCode = CT.CropCode
		LEFT JOIN RelationTraitScreening RTS ON RTS.CropTraitID = CT.CropTraitID
		LEFT JOIN ScreeningField SF ON SF.ScreeningFieldID = RTS.ScreeningFieldID AND SF.CropCode = V.CropCode
		LEFT JOIN TraitScreeningResult TSR ON TSR.TraitScreeningID = RTS.TraitScreeningID AND TSR.TraitValueChar = C1.[Value]		
		WHERE F.CropCode =  @CropCode
		AND V.StatusCode IN (200,250)
		AND V.VarmasStatusCode In (20,30,40,130,140) -- Varmas variety only with status R0, R1, R2, P0, P1 are allowed to update 
		AND RPTV.StatusCode = 100 --Synchronize screening data to varmas only if relation of GID to varmas variety is active
		AND C1.Modified = 1 AND ISNULL(V.SyncCode,'') <> '' AND ISNULL(L.VarmasLot,0) <> 0
	) V1;

	--now update rest of the cell data to modified to 0 so that inactive relation data and updated cell modified data to 0.
	UPDATE C SET C.Modified = 0 
	FROM [Cell] C 
	JOIN [Row] R ON R.RowID = C.RowID
	JOIN [File] F ON F.FileID = R.FileID
	LEFT JOIN @Table T ON T.CellID = C.CellID
	WHERE F.CropCode = @CropCode AND C.Modified = 1 AND ISNULL(T.CellID,0) = 0 


	SELECT 
		SyncCode,
		GID,
		VarietyNr,
		VarmasLot,
		ScreeningFieldNr,
		ScreeningFieldValue,
		IsValid,
		CellID,
		TraitID,
		TraitName,
		ColumnLabel
	FROM @Table;
END
