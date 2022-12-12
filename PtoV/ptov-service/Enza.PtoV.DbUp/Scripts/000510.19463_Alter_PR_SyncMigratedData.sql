
/*
Author				Date			Description
Krishna Gautam		-				Stored procedure created
Krishna Gautam		2020/11/13		#17002: Make relation of variety and GID always active without checking variety status.
Krishna Gautam		2021/02/16		#19463: Add P2 and R3(400) in inavtive list during import.

*/


ALTER PROCEDURE [dbo].[PR_SyncMigratedData]
(
	@TVP_VarietyAndRelation TVP_VarietyAndRelation READONLY,
	@Columns				TVP_Column1 READONLY,
	@CropCode				NVARCHAR(10),
	@ResearchGroupID		INT
)
AS 
BEGIN
	
	DECLARE @VarmasPtoVStatus AS TABLE(VarmasStatusCode INT,VarmasStatusName NVARCHAR(MAX), PtoVStatusCode INT);
	DECLARE @FileID INT,@MaxRowNr INT,@MaxColumnNr INT;
	
	--Create logs
	--DECLARE @TblFile TABLE(FileTitle NVARCHAR(100));
	--DECLARE @TblColumn TABLE(ColumnLabel NVARCHAR(200));
	DECLARE @TblVariety TABLE
	(
	   [Action] CHAR(10),
	   [GID] [int],
	   [CropCode] [nchar](2),
	   [NewCropCode] [nvarchar](10),
	   [ProdSegCode] [nvarchar](10),
	   [GenerationCode] [nvarchar](10),
	   [MalePar] [int],
	   [FemalePar] [int],
	   [Maintainer] [int],
	   [StembookShort] [nvarchar](max),
	   [MasterNr] [nvarchar](80),
	   [PONumber] [nvarchar](30),
	   [Stem] [nvarchar](255),
	   [PlasmaType] [nchar](1),
	   [CMSSource] [nvarchar](10),
	   [GMS] [nvarchar](10),
	   [RestorerGenes] [nvarchar](5),
	   [BrStationCode] [nvarchar](4),
	   [TransferType] [nvarchar](10),
	   [ENumber] [nvarchar](40),
	   [StatusCode] [int],
	   [SyncCode] [nvarchar](4),
	   [LotGID] [int],
	   [ReplacedLot] [bit],
	   [Name] [nvarchar](200),
	   [ReplacingLot] [bit],
	   [Raciprocated] [bit],
	   [VarietyName] [nvarchar](100),
	   [ReplacedLotID] [int],
	   [CountryOfOrigin] [nvarchar](max),
	   [VarmasStatusCode] [int]
     );
	
	BEGIN TRY
		SELECT @FileID = FileID FROM [File] WHERE CropCode = @CropCode
		BEGIN TRANSACTION

			INSERT INTO @VarmasPtoVStatus(VarmasStatusCode,VarmasStatusName)
			SELECT StatusCode,StatusName
			FROM [Status] WHERE StatusTable = 'VarmasStatus'

			--update to InActive
			UPDATE @VarmasPtoVStatus SET PtoVStatusCode = 300 WHERE VarmasStatusName IN ('100','500','600','700','800','900','999','P3','PD','P2','400');
			UPDATE @VarmasPtoVStatus SET PtoVStatusCode = 200 WHERE VarmasStatusName NOT IN ('100','500','600','700','800','900','999','P3','PD');
			
			IF(ISNULL(@FileID,0) = 0)
			BEGIN
				INSERT INTO [File](CropCode,FileTitle,ImportDateTime,ObjectID,ObjectType,UserID)
				--OUTPUT INSERTED.FileTitle INTO @TblFile
				VALUES (@CropCode,@CropCode,GETUTCDATE(),@ResearchGroupID,5,'PtoV');

				SELECT @FileID = FileID FROM [File] WHERE CropCode = @CropCode
			END
			SELECT @MaxRowNr = ISNULl(MAX(RowNr),0) FROM [Row] WHERE FileID = @FileID;
			SELECT @MaxColumnNr = ISNULL(MAX(ColumnNr),0) FROM [Column] WHERE FileID = @FileID;
			IF(ISNULL(@MaxRowNr,0) =0)
			BEGIN
				SET @MaxRowNr = 0;
			END
			IF(ISNULL(@MaxColumnNr,0) =0)
			BEGIN
				SET @MaxColumnNr = 0;
			END

			--merge column table
			MERGE INTO [Column] T
			USING
			(
				SELECT C.ColumLabel,C.DataType,C.VariableID,C.PhenomeColID,
				ColumnNr = Row_Number() OVER(ORDER BY ColumnLabel),
				T.TraitID,
				FileID = @FileID
				FROM @Columns C
				LEFT JOIN 
				(
					SELECT CT.TraitID,T.TraitName, T.ColumnLabel
					FROM Trait T 
					JOIN CropTrait CT ON CT.TraitID = T.TraitID
					WHERE CT.CropCode = @CropCode AND T.Property = 0
				)
				T ON T.ColumnLabel = C.ColumLabel 
			) S ON S.ColumLabel = T.ColumLabel AND T.FileID = S.FileID
			WHEN NOT MATCHED THEN
			INSERT(ColumnNr,TraitID,ColumLabel,FileID,DataType,VariableID,PhenomeColID)
			VALUES(S.ColumnNr,S.TraitID,S.ColumLabel,S.FileID,S.DataType,S.VariableID,S.PhenomeColID);
			--OUTPUT INSERTED.ColumLabel INTO @TblColumn;

			--merge varietyTable
			MERGE INTO Variety T 
			USING
			(
				SELECT 
				    VR.*,
				    VS.PtoVStatusCode,
				    VS.VarmasStatusCode AS VarmasStatusCode2
				FROM @TVP_VarietyAndRelation VR
				JOIN @VarmasPtoVStatus VS ON VS.VarmasStatusName = VR.VarmasStatusCode				
			) S
			ON T.GID = S.GID
			WHEN NOT MATCHED THEN
			INSERT 
				(
					GID,CropCode,NewCropCode,ProdSegCode,GenerationCode,MalePar,FemalePar,	Maintainer,	StembookShort,Masternr,PONumber,stem,PlasmaType,CMSSource,RestorerGenes,
					TransferType,ENumber,StatusCode,SyncCode,LotGID,ReplacedLot,[Name],ReplacingLot,VarietyName,CountryOfOrigin,VarmasStatusCode, BrStationCode
				)
			VALUES
				(
					S.GID,@CropCode,S.NewCropCode,S.ProdSegCode,S.Gen,S.MaleParGID,S.FemParGID,S.MaintainerGID,
					S.Pedigree,--pedigree is equivalent to stembookshort
					S.Masternr,S.[PO nr],S.stem,S.[Plasma typ],S.[CMS source],S.[Rest.genes],S.TransferType,S.[E-Number],S.PtoVStatusCode,S.SyncCode,S.GID,0,S.[Name],0,
					S.Variety, -- variety is equivalent to varietyName
					S.CountryOfOrigin,S.VarmasStatusCode2, S.BreedStat
				)
			WHEN MATCHED THEN 
			UPDATE 
			SET	
				T.CropCode = @CropCode,
				T.NewCropCode = S.NewCropCode,
				T.ProdSegCode = S.ProdSegCode,
				T.GenerationCode = S.Gen,
				T.MalePar = S.MaleParGID,T.FemalePar = S.FemParGID,
				T.Maintainer = S.MaintainerGID,
				T.Stembookshort = S.Pedigree,
				T.Masternr = S.Masternr,
				T.PoNumber = S.[PO nr],
				T.Stem = S.stem,
				T.PlasmaType = S.[Plasma typ],
				T.CMSSource = S.[CMS source],
				T.RestorerGenes = S.[Rest.genes],
				T.TransferType = S.TransferType,
				T.ENumber = S.[E-Number],
				T.SyncCode = S.SyncCode,
				T.[Name] = S.[Name],
				T.VarietyName = S.Variety,
				T.CountryOfOrigin = S.CountryOfOrigin,
				T.VarmasStatusCode = S.VarmasStatusCode2,
				T.BrStationCode = S.BreedStat
			 OUTPUT 
				$ACTION, 
				INSERTED.GID,
				CASE WHEN ISNULL(INSERTED.CropCode, '') <> ISNULL(DELETED.CropCode, '') THEN INSERTED.CropCode END,
				CASE WHEN ISNULL(INSERTED.NewCropCode, '') <> ISNULL(DELETED.NewCropCode, '') THEN INSERTED.NewCropCode END,
				CASE WHEN ISNULL(INSERTED.ProdSegCode, '') <> ISNULL(DELETED.ProdSegCode, '') THEN INSERTED.ProdSegCode END,
				CASE WHEN ISNULL(INSERTED.GenerationCode, '') <> ISNULL(DELETED.GenerationCode, '') THEN INSERTED.GenerationCode END,
				CASE WHEN ISNULL(INSERTED.MalePar, 0) <> ISNULL(DELETED.MalePar, 0) THEN INSERTED.MalePar END,
				CASE WHEN ISNULL(INSERTED.FemalePar, 0) <> ISNULL(DELETED.FemalePar, 0) THEN INSERTED.FemalePar END,
				CASE WHEN ISNULL(INSERTED.Maintainer, 0) <> ISNULL(DELETED.Maintainer, 0) THEN INSERTED.Maintainer END,
				CASE WHEN ISNULL(INSERTED.StembookShort, '') <> ISNULL(DELETED.StembookShort, '') THEN INSERTED.StembookShort END,
				CASE WHEN ISNULL(INSERTED.Masternr, '') <> ISNULL(DELETED.Masternr, '') THEN INSERTED.Masternr END,
				CASE WHEN ISNULL(INSERTED.PONumber, '') <> ISNULL(DELETED.PONumber, '') THEN INSERTED.PONumber END,
				CASE WHEN ISNULL(INSERTED.Stem, '') <> ISNULL(DELETED.Stem, '') THEN INSERTED.Stem END,
				CASE WHEN ISNULL(INSERTED.PlasmaType, '') <> ISNULL(DELETED.PlasmaType, '') THEN INSERTED.PlasmaType END,
				CASE WHEN ISNULL(INSERTED.CMSSource, '') <> ISNULL(DELETED.CMSSource, '') THEN INSERTED.CMSSource END,
				CASE WHEN ISNULL(INSERTED.GMS, '') <> ISNULL(DELETED.GMS, '') THEN INSERTED.GMS END,
				CASE WHEN ISNULL(INSERTED.RestorerGenes, '') <> ISNULL(DELETED.RestorerGenes, '') THEN INSERTED.RestorerGenes END,
				CASE WHEN ISNULL(INSERTED.BrStationCode, '') <> ISNULL(DELETED.BrStationCode, '') THEN INSERTED.BrStationCode END,
				CASE WHEN ISNULL(INSERTED.TransferType, '') <> ISNULL(DELETED.TransferType, '') THEN INSERTED.TransferType END,
				CASE WHEN ISNULL(INSERTED.ENumber, '') <> ISNULL(DELETED.ENumber, '') THEN INSERTED.ENumber END,
				CASE WHEN ISNULL(INSERTED.StatusCode, '') <> ISNULL(DELETED.StatusCode, '') THEN INSERTED.StatusCode END,
				CASE WHEN ISNULL(INSERTED.SyncCode, '') <> ISNULL(DELETED.SyncCode, '') THEN INSERTED.SyncCode END,
				CASE WHEN ISNULL(INSERTED.LotGID, 0) <> ISNULL(DELETED.LotGID, 0) THEN INSERTED.LotGID END,
				CASE WHEN ISNULL(INSERTED.ReplacedLot, 0) <> ISNULL(DELETED.ReplacedLot, 0) THEN INSERTED.ReplacedLot END,
				CASE WHEN ISNULL(INSERTED.[Name], '') <> ISNULL(DELETED.[Name], '') THEN INSERTED.[Name] END,
				CASE WHEN ISNULL(INSERTED.ReplacingLot, 0) <> ISNULL(DELETED.ReplacingLot, 0) THEN INSERTED.ReplacingLot END,
				CASE WHEN ISNULL(INSERTED.Raciprocated, 0) <> ISNULL(DELETED.Raciprocated, 0) THEN INSERTED.Raciprocated END,
				CASE WHEN ISNULL(INSERTED.VarietyName, '') <> ISNULL(DELETED.VarietyName, '') THEN INSERTED.VarietyName END,
				CASE WHEN ISNULL(INSERTED.ReplacedLotID, 0) <> ISNULL(DELETED.ReplacedLotID, 0) THEN INSERTED.ReplacedLotID END,
				CASE WHEN ISNULL(INSERTED.CountryOfOrigin, '') <> ISNULL(DELETED.CountryOfOrigin, '') THEN INSERTED.CountryOfOrigin END,
				CASE WHEN ISNULL(INSERTED.VarmasStatusCode, 0) <> ISNULL(DELETED.VarmasStatusCode, 0) THEN INSERTED.VarmasStatusCode END
			 INTO @TblVariety;
				
			--merge relationPtoV table
			/*Change made to make relation status always active (status code 100) instead of checking variety status and making active/inactive. */
			MERGE INTO RelationPtoV T
			USING
			@TVP_VarietyAndRelation S
			ON S.VarietyNr = T.VarietyNr
			WHEN NOT MATCHED THEN
			    INSERT (GID,VarietyNr,StatusCode)
			    VALUES (S.GID,S.varietyNr,100);


			--MERGE INTO RelationPtoV T
			--USING
			--(
			--	SELECT VR.*,
			--	RelationStatus = CASE WHEN ISNULL(VS.PtoVStatusCode,0) = 200 THEN 100 ELSE 200 END 
			--	FROM @TVP_VarietyAndRelation VR
			--	JOIN @VarmasPtoVStatus VS ON VS.VarmasStatusName = VR.VarmasStatusCode
			--) S
			--ON S.VarietyNr = T.VarietyNr
			--WHEN NOT MATCHED THEN
			--    INSERT (GID,VarietyNr,StatusCode)
			--    VALUES (S.GID,S.varietyNr,S.RelationStatus);
			-- --OUTPUT INSERTED.GID, INSERTED.VarietyNr, INSERTED.StatusCode INTO @TblRelationPtoV;


			--merge lot table
			MERGE INTO LOT T
			USING
			(
				SELECT VR.*,
				RelationStatus = CASE WHEN ISNULL(VS.PtoVStatusCode,0) = 200 THEN 200 ELSE 300 END 
				FROM @TVP_VarietyAndRelation VR
				JOIN @VarmasPtoVStatus VS ON VS.VarmasStatusName = VR.VarmasStatusCode
				WHERE ISNULL(VR.PhenomeLotID, 0) <> 0
				AND ISNULL(VR.VarmasLotNr, 0) <> 0
			) S
			ON S.PhenomeLotID = T.PhenomeLotID
			WHEN NOT MATCHED THEN
			 INSERT(GID,PhenomeLotID, VarmasLot, StatusCode, IsDefault)
			 VALUES(S.GID,S.PhenomeLotID,S.VarmasLotNr,S.RelationStatus,1);
			 --OUTPUT INSERTED.GID, INSERTED.PhenomeLotID, INSERTED.VarmasLot, INSERTED.StatusCode, INSERTED.IsDefault INTO @TblLOT;


			--merge row table
			MERGE INTO [Row] T 
			USING
			(
				SELECT VR.*,				
				FileID = @FileID,
				RowNr = Row_Number() OVER(ORDER BY GID)
				FROM @TVP_VarietyAndRelation VR
				JOIN @VarmasPtoVStatus VS ON VS.VarmasStatusName = VR.VarmasStatusCode
				WHERE VS.PtoVStatusCode = 200
			) S
			ON S.GID = T.MaterialKey AND T.FileID = S.FileID
			WHEN NOT MATCHED THEN
			 INSERT (RowNr,Materialkey,FileID)
			 VALUES(@MaxRowNr +S.RowNr ,S.GID,S.FileID);
		  --OUTPUT INSERTED.MaterialKey INTO @TblRow;

		COMMIT;
	END TRY
	BEGIN CATCH
		ROLLBACK;
		THROW;
	END CATCH

	SELECT * FROM @TblVariety;
	--SELECT * FROM @TblFile;
	--SELECT * FROM @TblColumn; 
	--SELECT * FROM @TblRelationPtoV;
	--SELECT * FROM @TblLOT;
	--SELECT * FROM @TblRow;
END			   
