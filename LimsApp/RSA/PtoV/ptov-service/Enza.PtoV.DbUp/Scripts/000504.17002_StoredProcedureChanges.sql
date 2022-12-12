/*
Author				Date			Description
Krishna Gautam		-				Stored procedure created
Krishna Gautam		2020/11/13		#17002: Make relation of variety and GID always active without checking variety status.

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
	--DECLARE @TblRelationPtoV TABLE([GID] [int], [VarietyNr] [int], [StatusCode] [int]);
	--DECLARE @TblLOT TABLE([GID] [int],	[PhenomeLotID] [int], [VarmasLot] [int], [StatusCode] [int], [IsDefault] [bit]);
	--DECLARE @TblRow TABLE(MaterialKey NVARCHAR(100));

	BEGIN TRY
		SELECT @FileID = FileID FROM [File] WHERE CropCode = @CropCode
		BEGIN TRANSACTION

			INSERT INTO @VarmasPtoVStatus(VarmasStatusCode,VarmasStatusName)
			SELECT StatusCode,StatusName
			FROM [Status] WHERE StatusTable = 'VarmasStatus'

			--update to InActive
			UPDATE @VarmasPtoVStatus SET PtoVStatusCode = 300 WHERE VarmasStatusName IN ('100','500','600','700','800','900','999','P3','PD');
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
	
END	
GO


/*
Author				Date					Remarks
Krishna Gautam		2020-Feb-07				Create a row record for variety which is used as parent and also which is used as parent after having same po number.
Krishna Gautam		2020-June-12			#14093: Delete variety for same po number based on status code(which is already sent to varmas).
Krishna Gautam		2020-June-12			#15108: Delete variety for same po number based on status code and replacedGID 
Krishna Gautam		2020-Nov-13				#17002: Create Row if variety uses po number with status inactive but that record is used as parent.

*/

ALTER PROCEDURE [dbo].[PR_ImportData]
(
	@FileName   NVARCHAR(100),
	@ObjectID	NVARCHAR(50),
	@ObjectType NVARCHAR(15),
	@TVPRow		TVP_ImportVarieties READONLY,
	@TVPColumn	TVP_Column1  READONLY,
	@TVPCell	TVP_Cell READONLY,
	@TVPlot		TVP_Lot READONLY
)
AS 
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY		
		IF(ISNULL(@FileName,'') = '') BEGIN
			EXEC PR_ThrowError 'Import failed. Invalid name.';
			RETURN;
		END
		DECLARE @TblPO TABLE(ExistingGID INT, ImportingGID INT, PONumber NVARCHAR(100));
		DECLARE @TblDuplicatePO TABLE(PoNr NVARCHAR(100));
		DECLARE @RowData TABLE([RowID] INT, [RowNr] INT, Materialkey INT);
		DECLARE @ColumnData TABLE(ColumnID INT, [ColumnNr] int, ColumnLabel NVARCHAR(200));
		DECLARE @GIDInserted TABLE(GID INT, LotGID INT);
		DECLARE @FileID INT =0,@RowNr INT = 0 ,@CropCode NVARCHAR(10), @MaxRowNr INT;
		DECLARE @UsePoNr BIT;
		DECLARE @ReplacelotGID TABLE(GID INT);
		--DECLARE @tblCell TVP_Cell;

		SELECT @FileID = FileID, @CropCode = CropCode FROM [File] where FileTitle = @FileName;
		SELECT @UsePoNr = UsePoNR FROM CropRD WHERE CropCode = @CropCode;
		--Validate of another gid contains same ponr of any parent and not already sent to varmas

		IF(@UsePoNr = 1) BEGIN
		
			--Insert into table with Imported Germplasm which is not yet sent to varmas
			INSERT INTO @TblPO(ExistingGID, ImportingGID, PONumber)
				SELECT 
				    ExistingGID = MAX(V.GID), 
				    R.GID,
				    V.PONumber
				FROM Variety V
				JOIN @TVPRow R ON R.PONumber = V.PONumber
				WHERE ISNULL(V.PONumber, '') <> ''
				AND V.StatusCode = 100
				AND V.CropCode = @CropCode
				GROUP BY V.PONumber, R.GID
				

			--Insert vareity which is already sent to varmas 
			MERGE INTO @TblPo T
			USING
			(
				SELECT 
						MAX(V.GID) AS ExistingGID, 
						R.GID AS ImportingGID,
						V.PONumber
					FROM Variety V
					JOIN @TVPRow R ON R.PONumber = V.PONumber
					JOIN RelationPtoV R1 ON R1.GID = V.GID
					WHERE ISNULL(V.PONumber, '') <> ''
					AND V.StatusCode >= 200 AND R1.StatusCode = 100
					AND V.CropCode = @CropCode					
					GROUP BY V.PONumber, R.GID
			) S ON S.PONumber = T.PONumber AND S.ImportingGID = T.ImportingGID
			WHEN NOT MATCHED THEN 
			INSERT (ExistingGID, ImportingGID, PONumber)
			VALUES(S.ExistingGID, S.ImportingGID, S.PONumber)
			WHEN MATCHED
				THEN UPDATE 
				SET T.ExistingGID = S.ExistingGID;
			
			-- if gid1 = gid2 then remove (this means already imported gid is again in import list)
			DELETE T FROM @TblPo T WHERE T.ExistingGID = T.ImportingGID;

			INSERT INTO @TblDuplicatePO
				SELECT 
					PONumber 
				FROM @TblPO GROUP BY PONumber HAVING COUNT(*) > 1 

			--now only take variety which is latest one (that means delete same po record if status is 200)
			DELETE T FROM @TblPO  T
			JOIN @TblDuplicatePO T1 ON T1.PoNr = T.PONumber
			JOIN RelationPtoV R ON R.GID = T.ExistingGID
			WHERE R.StatusCode = 200;

		END
				
		BEGIN TRANSACTION		
			--IF File not found import all data present on all tvp
			IF(ISNULL(@FileID, 0) = 0) BEGIN

				INSERT INTO [FILE] ([CropCode],[FileTitle],[UserID],[ImportDateTime],ObjectID,ObjectType)
				VALUES(@FileName, @FileName, 'PtoV', GETUTCDATE(),@ObjectID,@ObjectType);
				--Get Last inserted fileid
				SELECT @FileID = SCOPE_IDENTITY();

				INSERT INTO [Row] ([RowNr], [MaterialKey], [FileID])
				OUTPUT INSERTED.[RowID], INSERTED.[RowNr], inserted.MaterialKey INTO @RowData(RowID, RowNr,Materialkey)
				SELECT T.RowNr, T.GID, @FileID 
				FROM @TVPRow T;

				INSERT INTO [Column] ([ColumnNr], [TraitID], [ColumLabel], [FileID], [DataType],[VariableID],[PhenomeColID])
				OUTPUT INSERTED.[ColumnID], INSERTED.[ColumnNr], INSERTED.ColumLabel INTO @ColumnData(ColumnID,ColumnNr,ColumnLabel)
				SELECT T1.[ColumnNr], T.[TraitID], T1.[ColumLabel], @FileID, T1.[DataType],T1.[VariableID],T1.[PhenomeColID]
				FROM @TVPColumn T1
				LEFT JOIN 
				(
					SELECT CT.TraitID,T.TraitName, T.ColumnLabel
					FROM Trait T 
					JOIN CropTrait CT ON CT.TraitID = T.TraitID
					WHERE CT.CropCode = @FileName AND T.Property = 0
				)
				T ON T.ColumnLabel = T1.ColumLabel

				INSERT INTO [Cell] ([RowID], [ColumnID], [Value])
				SELECT [RowID], [ColumnID], [Value] 
				FROM @TVPCell T1
				JOIN @RowData T2 ON T2.RowNr = T1.RowNr
				JOIN @ColumnData T3 ON T3.ColumnNr = T1.ColumnNr
				WHERE ISNULL(T1.[Value],'') <> '';				
			END
		
			--if file found than we have to merge data.
			ELSE 
			BEGIN
				
				DECLARE @LastColumnNr INT = 0;
				SELECT 
				    @LastColumnNr = ISNULL(MAX(ColumnNr), 0)
				FROM [Column] 
				WHERE FileID = @FileID;

				--add only new columns at the end of the table columns
				INSERT INTO [Column] ([ColumnNr], [TraitID], [ColumLabel], [FileID], [DataType],[VariableID],[PhenomeColID])
				SELECT 
				    NewColumnNr = ROW_NUMBER() OVER(ORDER BY C1.ColumnNr) + @LastColumnNr,
				    T.TraitID,
				    C1.ColumLabel,
				    @FileID,
				    C1.DataType,
				    C1.VariableID,
				    C1.PhenomeColID
				FROM @TVPColumn C1
				LEFT JOIN 
				(
					SELECT CT.TraitID,T.TraitName, T.ColumnLabel
					FROM Trait T 
					JOIN CropTrait CT ON CT.TraitID = T.TraitID
					WHERE CT.CropCode = @FileName AND T.Property = 0
				)
				T ON T.ColumnLabel = C1.ColumLabel
				LEFT JOIN
				(
				    SELECT ColumnID, ColumLabel FROM [Column]
				    WHERE FileID = @FileID
				) C2 ON C2.ColumLabel = C1.ColumLabel
				WHERE C2.ColumnID IS NULL;

				--Update columnnr of tvpcolumns with updated list of columns
				INSERT INTO @ColumnData(ColumnID, ColumnNr,ColumnLabel)
				SELECT 
				    C2.ColumnID,
				    C2.ColumnNr,
					C2.ColumLabel
				FROM @TVPColumn C1
				JOIN [Column] C2 ON C2.ColumLabel = C1.ColumLabel
				WHERE FileID = @FileID;

				--insert rows
				INSERT INTO [Row] ([RowNr], [MaterialKey], [FileID])
				OUTPUT INSERTED.[RowID],INSERTED.[RowNr],INSERTED.MaterialKey INTO @RowData(RowID, RowNr,Materialkey)
				SELECT T.RowNr,T.GID, @FileID 
				FROM @TVPRow T
				WHERE NOT EXISTS
				(
					SELECT R.MaterialKey 
					FROM [Row] R
					JOIN @TVPRow T1 ON T1.GID = R.MaterialKey
					WHERE R.MaterialKey = T.GID
				);

				--this is new
				INSERT INTO [Cell](RowID,ColumnID,Value)
				SELECT RD.RowID,C.ColumnID,TC.[Value] FROM @TVPCell TC
				JOIN @TVPRow TR ON TR.RowNr = TC.RowNr
				JOIN @RowData RD ON RD.Materialkey = TR.GID
				JOIN @TVPColumn TCol ON TCol.ColumnNr = TC.ColumnNr
				JOIN @ColumnData C ON C.ColumnLabel = TCol.ColumLabel
				WHERE ISNULL(TC.[Value],'') <> '';
								
			END

			--CREATE Materials if not already created
			MERGE INTO Variety T
			USING @TVPRow S ON S.GID = T.GID			
			WHEN NOT MATCHED THEN 
				INSERT([GID], [CropCode], [GenerationCode], [MalePar], [FemalePar], [Maintainer], [StembookShort], [MasterNr], [PONumber], [Stem], [PlasmaType], 
				[CMSSource], [GMS], [RestorerGenes], [BrStationCode], [TransferType], [StatusCode],[SyncCode], ENumber,LotGID,[Name], VarietyName)
				VALUES (S.GID, @FileName, S.[GenerationCode], S.[MalePar], S.[FemalePar], S.[Maintainer], S.[StembookShort], S.[MasterNr], S.[PONumber], S.[Stem], S.[PlasmaType], 
				S.[CMSSource], S.[GMS], S.[RestorerGenes], S.[BrStationCode], ISNULL(S.[TransferType],'OP'), 100, S.[SyncCode], S.ENumber,S.GID,S.[Name], S.VarietyName)
			OUTPUT
			INSERTED.GID INTO @GIDInserted(GID);

			--This merge statement is used when parent is imported as OP but another hybrid or CMS is imported later which used already imported Germplasm as parent(male/female for hybrid) or maintainer(for CMS)
			--This statement need to be optimized later.
			MERGE INTO Variety T
			USING
			(
				SELECT MalePar FROM @TVPRow 
				GROUP BY MalePar
			) 
			S ON T.GID = S.Malepar AND T.StatusCode = 100 			
			WHEN MATCHED THEN
			UPDATE SET T.TransferType = 'Male';


			MERGE INTO Variety T
			USING
			(
				SELECT FemalePar FROM @TVPRow 
				GROUP BY FemalePar
			) 
			S ON T.GID = S.FemalePar AND T.StatusCode = 100 			
			WHEN MATCHED THEN
			UPDATE SET T.TransferType = 'Female';


			MERGE INTO Variety T
			USING
			(
				SELECT Maintainer FROM @TVPRow 
				GROUP BY Maintainer
			) 
			S ON T.GID = S.Maintainer AND T.StatusCode = 100 			
			WHEN MATCHED THEN
			UPDATE SET T.TransferType = 'Maintainer';

			--used to insert lot information of imported GID or change isdefault value for already imported lot and new default lot.
			MERGE INTO LOT L
			USING @TVPlot S
			ON S.GID = L.GID AND L.PhenomeLotID = S.ID
			WHEN NOT MATCHED THEN 
			INSERT(GID,PhenomeLotID,StatusCode,IsDefault)
			Values(S.GID,S.ID,100,S.IsDefault)
			WHEN MATCHED AND L.IsDefault != S.IsDefault THEN
			UPDATE SET L.IsDefault = S.IsDefault;

			--handle same ponumber of different parent gids and cleanup table
			IF(@UsePoNr = 1)
			BEGIN
				IF EXISTS (SELECT TOP 1 ExistingGID FROM @TblPO)
				BEGIN

					INSERT INTO @ReplacelotGID(GID)
					SELECT 
						LotGID 
					FROM @TblPO T
					JOIN Variety V ON V.LotGID = T.ImportingGID AND V.GID <> V.LotGID
					
					--update Female parent
					UPDATE V SET
						V.FemalePar = T.ExistingGID
					FROM Variety V
					JOIN @TblPO T ON T.ImportingGID = V.FemalePar
					WHERE V.StatusCode < 200

					--update male parent
					UPDATE V SET
						V.MalePar =T.ExistingGID
					FROM Variety V
					JOIN @TblPO T ON T.ImportingGID = V.MalePar
					WHERE V.StatusCode < 200

					--update maintainer parent
					UPDATE V SET				
						V.Maintainer =  T.ExistingGID
					FROM Variety V
					JOIN @TblPO T ON T.ImportingGID =V.Maintainer
					WHERE V.StatusCode < 200

					/* #17002 changes */
					SELECT @MaxRowNr = MAX(RowNr) FROM [Row] WHERE FileID = @FileID;

					MERGE INTO [Row] T
					USING
					(
						SELECT T1.ExistingGID FROM Variety V
						JOIN @TblPO T1 ON T1.ImportingGID = V.Maintainer OR T1.ImportingGID = V.MalePar OR T1.ImportingGID = V.FemalePar
						WHERE V.StatusCode < 200
						GROUP BY T1.ExistingGID
					) 
					S ON T.MaterialKey = S.ExistingGID
					WHEN NOT MATCHED THEN 
					INSERT ([RowNr], [MaterialKey], [FileID])
					VALUES (@MaxRowNr+1,S.ExistingGID, @FileID); 
					/* #17002 changes completed */


					IF EXISTS (SELECT TOP 1 GID FROM @ReplacelotGID)
					BEGIN
							--delete Cell
						DELETE C FROM [Cell] C
						JOIN [Row] R ON R.RowID = C.RowID
						JOIN @TblPO T ON T.ImportingGID = R.MaterialKey
						JOIN Variety V ON V.GID = T.ImportingGID
						WHERE V.StatusCode < 200 
								AND V.GID NOT IN (SELECT GID FROM @ReplacelotGID);

						--delete Row
						DELETE R FROM [Row] R
						JOIN @TblPO T ON T.ImportingGID = R.MaterialKey
						JOIN Variety V ON V.GID = T.ImportingGID
						WHERE V.StatusCode < 200
						AND V.GID NOT IN (SELECT GID FROM @ReplacelotGID);

						--remove duplicate lot records whose GID is not imported
						DELETE 
							L 
						FROM Lot L
						JOIN Variety V ON V.GID = L.GID
						JOIN @TblPO T ON T.ImportingGID = L.GID
						WHERE V.StatusCode < 200
						AND V.GID NOT IN (SELECT GID FROM @ReplacelotGID);

						--remove duplicate variety records but new one which contains same PO Number
						DELETE 
							V 
						FROM Variety V
						JOIN @TblPO T ON T.ImportingGID = V.GID
						WHERE V.StatusCode < 200
						AND V.GID NOT IN (SELECT GID FROM @ReplacelotGID);
					END
					ELSE 
					BEGIN
						--delete Cell
						DELETE C FROM [Cell] C
						JOIN [Row] R ON R.RowID = C.RowID
						JOIN @TblPO T ON T.ImportingGID = R.MaterialKey
						JOIN Variety V ON V.GID = T.ImportingGID
						WHERE V.StatusCode < 200;

						--delete Row
						DELETE R FROM [Row] R
						JOIN @TblPO T ON T.ImportingGID = R.MaterialKey
						JOIN Variety V ON V.GID = T.ImportingGID
						WHERE V.StatusCode < 200;

						--remove duplicate lot records whose GID is not imported
						DELETE 
							L 
						FROM Lot L
						JOIN Variety V ON V.GID = L.GID
						JOIN @TblPO T ON T.ImportingGID = L.GID
						WHERE V.StatusCode < 200;

						--remove duplicate variety records but new one which contains same PO Number
						DELETE 
							V 
						FROM Variety V
						JOIN @TblPO T ON T.ImportingGID = V.GID
						WHERE V.StatusCode < 200;
					END
				END
			END
			
		COMMIT;
	END TRY
	BEGIN CATCH
		ROLLBACK;
		THROW;
	END CATCH
END

GO



/*
=========Changes====================
Created By			DATE				Description
Binod Gurung							Fetch all varieties having same stem as input GIDs
Krishna Gautam		2020-Nov-12			Fetch all varieties having same stem as input GIDs
Krishna Gautam		2020-Nov-25			#17002: Get all varieties with matching stem value without variety status but only with relation status to active.(100).
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
		--AND V.StatusCode		IN (200, 250)
		AND V.CropCode			= @CropCode
		AND	R.StatusCode		= 100
		AND V.Stem IN ( SELECT Stem FROM Variety V WHERE V.VarietyID IN (SELECT VarietyID FROM CTE))

END

GO


