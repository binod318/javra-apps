/*
	==================================================================
	CHANGED BY			DATE				REMARKS
	------------------------------------------------------------------
	Krishna Gautam		March-12-2019		Created new service to import variety and its associated lot from pedigree service
	Krishna Gautam		Nov-13-2020			#17015:Change IsDefault for lot in importing data 

	==================================================================

*/
ALTER PROCEDURE [dbo].[PR_Import_Germplasm_From_Pedigree]
(	
	@TVPRow		TVP_ImportVarieties READONLY,
	@TVPColumn  TVP_Column1 READONLY,
	@TVPCell	TVP_Cell READONLY,
	@TVPlot		TVP_Lot READONLY,
	@GID		INT
)
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY
		BEGIN TRAN	
		DECLARE @RowData TABLE([RowID] int,	[RowNr] int	);
		DECLARE @FileID INT,@CropCode NVARCHAR(MAX),@BreedingStation NVARCHAR(MAX), @SyncCode NVARCHAR(MAX);
		DECLARE @MaxRowNr INT,@InsertedRowID INT;
		DECLARE @IsDefault BIT;

		SELECT @CropCode = CropCode,@BreedingStation = BrStationCode,@SyncCode = SyncCode FROM Variety WHERE GID = @GID;

		SELECT @FileID = Fileid FROM [File] F
		WHERE CropCode = @CropCode;

		IF(ISNULL(@FileID,'') = '') BEGIN
			EXEC PR_ThrowError 'Invalid GID.';
			RETURN;
		END	

		SELECT @MaxRowNr=  MAX(RowNr) FROM [Row] WHERE FileID = @FileID;


		--Cerate new row record if not exists
		INSERT INTO [Row] ( [RowNr], [MaterialKey], [FileID])
		OUTPUT INSERTED.[RowID],INSERTED.[RowNr] INTO @RowData
		SELECT T.RowNr +( @MaxRowNr +1) ,T.GID, @FileID 
		FROM @TVPRow T
		WHERE NOT EXISTS
		(
			SELECT R.MaterialKey 
			FROM [Row] R
			JOIN @TVPRow T1 ON T1.GID = R.MaterialKey
			WHERE R.MaterialKey = T.GID
		);
		
		SELECT @InsertedRowID = MAX(RowID) FROM @RowData;
		IF(ISNULL(@InsertedRowID, 0) <> 0) BEGIN
		    INSERT INTO [Cell](ColumnID,RowID,[Value])
		    SELECT C2.ColumnID,@InsertedRowID,[Value]
		    FROM @TVPCell C
		    JOIN @TVPColumn C1 ON C1.ColumnNr = C.ColumnNr
		    JOIN [Column] C2 ON C2.ColumLabel = C1.ColumLabel
		    WHERE C2.FileID = @FileID;
		END
			   
		--Create variety if not exists
		MERGE INTO Variety T
		USING @TVPRow S ON S.GID = T.GID			
		WHEN NOT MATCHED THEN 
			INSERT([GID], [CropCode], [GenerationCode], [MalePar], [FemalePar], [Maintainer], [StembookShort], [MasterNr], [PONumber], [Stem], [PlasmaType], 
			[CMSSource], [GMS], [RestorerGenes], [BrStationCode], [TransferType], [StatusCode],[SyncCode], ENumber,LotGID,[Name], VarietyName)
			VALUES (S.GID, @CropCode, S.[GenerationCode], S.[MalePar], S.[FemalePar], S.[Maintainer], S.[StembookShort], S.[MasterNr], S.[PONumber], S.[Stem], S.[PlasmaType], 
			S.[CMSSource], S.[GMS], S.[RestorerGenes],@BreedingStation , ISNULL(S.[TransferType],'OP'), 100, @SyncCode, S.ENumber,S.GID,S.[Name], S.VarietyName);

		--check if any of the data have default lot or not
		--@TVPLot should contain only one lot data
		IF EXISTS (SELECT L.GID FROM Lot L
					JOIN @TVPlot LT ON L.GID = LT.GID AND L.IsDefault = 1)
		BEGIN
			SET @IsDefault = 0;
		END

		ELSE
		BEGIN
			SET @IsDefault = 1;
		END

		--Create lot if not exists
		MERGE INTO LOT L
		USING @TVPlot S
		ON S.GID = L.GID AND L.PhenomeLotID = S.ID
		WHEN NOT MATCHED THEN 
		INSERT(GID,PhenomeLotID,StatusCode,IsDefault)
		Values(S.GID,S.ID,100,@IsDefault)
		WHEN MATCHED AND L.IsDefault != S.IsDefault THEN
		UPDATE SET L.IsDefault = S.IsDefault;
	COMMIT;
	END TRY
	BEGIN CATCH
		ROLLBACK;
		THROW;
	END CATCH
END

GO

/*
	==================================================================
	CHANGED BY			DATE				REMARKS
	------------------------------------------------------------------
	Krishna Gautam		-					-
	Krishna Gautam		Nov-13-2020			#17015:Change IsDefault for lot in importing data 

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
	DECLARE @LotTable AS TABLE (GID INT, PhenomeLotID INT, VarmasLotNr INT);
	
	--Previous get lot method commented
	/*
	--insert default lot for GID
	INSERT INTO @LotTable
	SELECT V.LotGID, MAX(L.PhenomeLotID) FROM Variety V
	JOIN string_split(@VarietyIDs, ',') T2 ON CAST(T2.[value] AS INT) = V.VarietyID
	LEFT JOIN LOT L ON L.GID = V.GID AND L.IsDefault = 1
	GROUP BY V.LotGID
	*/
	
	--Conditional replace lot is required for sending data varmas for previous method and new method
	--this will get default lot for first version of replace lot
	INSERT INTO @LotTable(GID, PhenomeLotID, VarmasLotNr)
	SELECT 
		V.LotGID, 
		MAX(L.PhenomeLotID), 
		MAX(L.VarmasLot) 
	FROM Variety V
	JOIN string_split(@VarietyIDs, ',') T2 ON CAST(T2.[value] AS INT) = V.VarietyID
	LEFT JOIN LOT L ON L.GID = V.GID AND L.IsDefault = 1
	WHERE ISNULL(V.ReplacedLotID,0)=0 --this condition will not fetch all lot data for new implementation
	GROUP BY V.LotGID

	--this will get lot information after implementation replce lot from pedigree data shown to frontend
	INSERT INTO @LotTable(GID, PhenomeLotID, VarmasLotNr)
	SELECT 
		V.LotGID, 
		MAX(L.PhenomeLotID), 
		MAX(L.VarmasLot) 
	FROM Variety V
	JOIN string_split(@VarietyIDs, ',') T2 ON CAST(T2.[value] AS INT) = V.VarietyID
	LEFT JOIN LOT L ON L.GID = V.GID AND L.PhenomeLotID = V.ReplacedLotID --this condition will fetch data for replace lot with pedigree data
	GROUP BY V.LotGID

	--if default lot is not available then insert any lot present on lot table
	UPDATE LT 
	SET LT.PhenomeLotID = L.PhenomeLotID
	FROM @LotTable LT 
	JOIN (SELECT GID,Max(PhenomeLotID) AS PhenomeLotID FROM LOT GROUP BY GID) L ON L.GID = LT.GID
	WHERE ISNULL(LT.PhenomeLotID,0) =0

	UPDATE LT 
	SET LT.VarmasLotNr = L.VarmasLot
	FROM @LotTable LT 
	JOIN Lot L ON L.GID = LT.GID AND L.PhenomeLotID = LT.PhenomeLotID
	WHERE ISNULL(LT.VarmasLotNr,0) =0

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

GO