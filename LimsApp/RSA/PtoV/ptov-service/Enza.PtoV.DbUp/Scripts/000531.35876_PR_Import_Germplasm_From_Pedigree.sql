
/*
	==================================================================
	CHANGED BY			DATE				REMARKS
	------------------------------------------------------------------
	Krishna Gautam		March-12-2019		Created new service to import variety and its associated lot from pedigree service
	Krishna Gautam		Nov-13-2020			#17015:Change IsDefault for lot in importing data 
	Krishna Gautam		2022-04-06			#35876:sync changed data when existing variety is used for replace lot

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

		--update cell record if record already sent record is used for replace lot
		ELSE
		BEGIN
			MERGE INTO Cell T
			USING
			(
				SELECT 
					R.RowID, C.ColumnID, CV.[Value], C.TraitID 
				FROM [File] F
				JOIN [Row] R ON R.FileID = F.FileID
				JOIN [Column] C ON C.FileID = F.FileID
				JOIN @TVPRow R1 ON R1.GID = R.MaterialKey
				LEFT JOIN @TVPColumn C1 ON C1.ColumLabel = C.ColumLabel
				LEFT JOIN @TVPCell CV ON CV.RowNr = R1.RowNr AND CV.ColumnNr = C1.ColumnNr
				WHERE F.FileID = @FileID
			) S ON S.RowID = T.RowID AND S.ColumnID = T.ColumnID
			WHEN NOT MATCHED AND ISNULL(S.[Value],'') <> '' THEN INSERT (ColumnID, RowID, [Value])
						VALUES(S.ColumnID, S.RowID, S.[Value])
			WHEN MATCHED AND ISNULL(S.[Value],'') <> T.[Value] THEN UPDATE SET T.[Value] = S.[value] , T.Modified = CASE WHEN ISNULL(S.TraitID,0) <> 0 THEN 1 ELSE 0 END;
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

