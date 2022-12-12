
--EXEC PR_DeleteImportedGermplasms '1126,1127,1128,1129,1130,1131,1132,1133,1134,1135,1136,1137,1138,1139', 1
--EXEC PR_DeleteImportedGermplasms '1222', 1
ALTER PROCEDURE [dbo].[PR_DeleteImportedGermplasms]
(
	@VarietyIDs NVARCHAR(MAX),
	@DeleteParentAlso BIT
) AS BEGIN
	SET NOCOUNT ON;

	BEGIN TRY
		BEGIN TRAN
			
			DECLARE @Hybrid TABLE(GID INT,Maintainer INT,FemalePar INT,MalePar INT);
			DECLARE @Parent TABLE(GID INT);
			--DECLARE @Rows TABLE (RowID INT);
			DECLARE @Variety TABLE(VarietyID INT);

			INSERT INTO @Variety(varietyID) 
			SELECT  VALUE FROM string_split(@VarietyIDs,',');
			

			DELETE V
			OUTPUT DELETED.GID, DELETED.Maintainer,DELETED.FemalePar,DELETED.MalePar INTO @Hybrid(GID,Maintainer,FemalePar,MalePar)
			FROM Variety V
			JOIN string_split(@VarietyIDs, ',') T1 ON T1.[value] = V.VarietyID
			LEFT JOIN Variety VD ON VD.MalePar = V.GID OR VD.FemalePar = V.GID OR VD.Maintainer = V.GID OR (VD.LotGID = V.GID AND VD.GID <> VD.LotGID)
			WHERE VD.VarietyID IS NULL AND V.StatusCode = 100;

			IF(ISNULL(@DeleteParentAlso,0 ) <> 0) BEGIN			
				
				INSERT INTO @Parent
				SELECT V.GID FROM Variety V 
				JOIN @Hybrid T1	ON T1.MalePar = V.GID OR T1.FemalePar = V.GID
				WHERE V.StatusCode = 100
				GROUP BY V.GID;

				INSERT INTO @Parent
				SELECT V.Maintainer FROM Variety V 
				JOIN @Hybrid T1	ON T1.FemalePar = V.GID
				WHERE V.StatusCode = 100
				GROUP BY V.Maintainer;

								

				DELETE P FROM @Parent P
				JOIN Variety V ON V.MalePar = P.GID OR V.FemalePar = P.GID OR V.Maintainer = P.GID
				WHERE V.StatusCode != 100 
				OR V.VarietyID NOT IN (SELECT VarietyID FROM @Variety);
				
				

				--Delete variety				
				DELETE V
				OUTPUT DELETED.GID INTO @Hybrid(GID)
				FROM Variety V
				JOIN @Parent P ON V.GID = P.GID;

				--Delete cell
				DELETE C
				FROM [Cell] C 
				JOIN [Row] R ON R.RowID = C.RowID
				JOIN @Hybrid H ON H.GID = R.MaterialKey
				
				--Delete Row
				DELETE R 
				--OUTPUT Deleted.RowID INTO @Rows(RowID)
				FROM [Row] R 
				JOIN @Hybrid H ON H.GID = R.MaterialKey

				--DELETE C FROM Cell C
				--JOIN @Rows R ON R.RowID = C.RowID;

				--Delete Lot
				DELETE L 
				FROM LOT L 
				JOIN @Hybrid H ON H.GID = L.GID;

			END

		COMMIT;
		
	END TRY
	BEGIN CATCH
		ROLLBACK;
		THROW;
	END CATCH
END

GO
