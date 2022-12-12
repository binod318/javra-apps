
/*
Author				Date					Remarks
Krishna Gautam		2020-Feb-07				Create a row record for variety which is used as parent and also which is used as parent after having same po number.
Krishna Gautam		2020-June-12			#14093: Delete variety for same po number based on status code(which is already sent to varmas).
Krishna Gautam		2020-June-12			#15108: Delete variety for same po number based on status code and replacedGID 
Krishna Gautam		2020-Nov-13				#17002: Create Row if variety uses po number with status inactive but that record is used as parent. 
Krishna Gautam		2022-Jan-21				#31712: Create Row for variety which is inactive and have same po number. 

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
					AND V.StatusCode >= 200 --AND R1.StatusCode = 100 --this and clause is removed on 
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

					--MERGE INTO [Row] T
					--USING
					--(
					--	SELECT T1.ExistingGID FROM Variety V
					--	JOIN @TblPO T1 ON T1.ImportingGID = V.Maintainer OR T1.ImportingGID = V.MalePar OR T1.ImportingGID = V.FemalePar
					--	--WHERE V.StatusCode < 200
					--	GROUP BY T1.ExistingGID
					--) 
					--S ON T.MaterialKey = S.ExistingGID
					--WHEN NOT MATCHED THEN 
					--INSERT ([RowNr], [MaterialKey], [FileID])
					--VALUES (@MaxRowNr+1,S.ExistingGID, @FileID); 

					MERGE INTO [Row] T
					USING
					(
						SELECT V.GID FROM Variety V
						JOIN @TblPO T ON T.PoNumber = V.PoNumber
						GROUP BY V.GID

					)S ON S.GID = T.MaterialKey
					WHEN NOT MATCHED THEN 
					INSERT ([RowNr], [MaterialKey], [FileID])
					VALUES (@MaxRowNr+1,S.GID, @FileID);
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


