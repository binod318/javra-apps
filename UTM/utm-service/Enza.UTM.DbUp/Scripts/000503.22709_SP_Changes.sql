DROP PROCEDURE IF EXISTS PR_LFDISK_GetPunchlist
GO
/*
Author							Date				Description
Krishna Gautam					2021/06/21			#22712:Created sp to get data
=================Example===============
EXEC PR_LFDISK_GetPunchlist] 12669
*/

CREATE PROCEDURE [dbo].[PR_LFDISK_GetPunchlist]
(
	@TestID INT
)
AS
BEGIN

	SELECT S.SampleID, S.SampleName, MP.MaterialPlantID, MP.[Name] FROM LD_SampleTestMaterial STM
	JOIN LD_MaterialPlant MP ON MP.MaterialPlantID = STM.MaterialPlantID
	JOIN LD_SampleTest ST ON ST.SampleTestID = STM.SampleTestID
	JOIN LD_Sample S ON S.SampleID = ST.SampleID
	WHERE ST.TestID = @TestID
	ORDER BY S.SampleID, MP.MaterialPlantID;
	
END
GO


DROP PROCEDURE IF EXISTS PR_LFDISK_SaveSampleMaterial
GO

/*
Author					Date			Description
Binod Gurung			2021/06/08		Save Plots to sample
===================================Example================================
EXEC [PR_LFDISK_SaveSampleMaterial] 4556, ''
*/
CREATE PROCEDURE [dbo].[PR_LFDISK_SaveSampleMaterial]
(
	@TestID INT,
	@Json NVARCHAR(MAX),
	@Action NVARCHAR(MAX)
)
AS
BEGIN
	
	SET NOCOUNT ON;
	DECLARE @ImportLevel NVARCHAR(20);
	DECLARE @MaterialPlant TABLE(MaterialPlantID INT, MaterialID INT); 
	DECLARE @Material TABLE(SampleID INT, MaterialID INT);
	
	IF NOT EXISTS (SELECT TestID FROM Test WHERE TestID = @TestID AND TestTypeID = 9)
	BEGIN
		EXEC PR_ThrowError N'Invalid Test.';
		RETURN;
	END

	SELECT @ImportLevel = ImportLevel FROM Test WHERE TestID = @TestID;

	--ADD material to sample
	IF(ISNULL(@Action,'') = 'Add')
	BEGIN
		INSERT @Material(SampleID, MaterialID)
		SELECT SampleID, MaterialID
				FROM OPENJSON(@Json) WITH
				(
					SampleID	INT '$.SampleID',
					MaterialID	NVARCHAR(MAX) '$.MaterialID'
				)

				
		--Insert to MaterialPlant and copy MaterialPlantID for SampleTestMaterial
		MERGE INTO LD_MaterialPlant T
		USING
		(
			
			SELECT 
				M.MaterialID,
				PlantName = CASE WHEN @ImportLevel = 'Plot' THEN T3.Plotname ELSE COALESCE(T3.Plantnumber, T3.Femalecode) END
			FROM @Material S
			JOIN Material M ON M.MaterialID = S.MaterialID
			JOIN
			(
				SELECT T2.MaterialKey,  T2.[Plot name] AS Plotname, T2.Plantnumber, T2.[Female code] AS Femalecode
					FROM
					(
						SELECT 
							T.TestID,
							R.MaterialKey,
							C.ColumLabel,
							CellValue = CL.[Value]
						FROM [File] F
						JOIN [Row] R ON R.FileID = F.FileID
						JOIN [Column] C ON C.FileID = F.FileID
						JOIN Test T ON T.FileID = F.FileID
						LEFT JOIN [Cell] CL ON CL.RowID = R.RowID AND CL.ColumnID = C.ColumnID
						WHERE C.ColumLabel IN('Plot name', 'Plantnumber', 'Female code') AND T.TestID = @TestID
					) T1
					PIVOT
					(
						Max(CellValue)
						FOR [ColumLabel] IN ([Plot name], [Plantnumber], [Female code])
					) T2
			) T3 ON T3.MaterialKey = M.MaterialKey

		) S ON S.MaterialID = T.MaterialID
		WHEN NOT MATCHED THEN
			INSERT (MaterialID, [Name])
			VALUES (MaterialID,PlantName);

		--Merge into SampleTestMaterial
		MERGE INTO LD_SampleTestMaterial T
		USING
		(
			SELECT 
				MP.MaterialPlantID, 
				M.MaterialID,
				ST.SampleTestID
			FROM @Material M
			JOIN LD_MaterialPlant MP ON MP.MaterialID = M.MaterialID
			JOIN LD_SampleTest ST ON ST.SampleID = M.SampleID


		) S ON T.MaterialPlantID = S.MaterialPlantID AND T.SampleTestID = S.SampleTestID
		WHEN NOT MATCHED THEN
		INSERT (SampleTestID,MaterialPlantID)
		VALUES(S.SampleTestID, S.MaterialPlantID);
	END

	ELSE IF(ISNULL(@Action,'') = 'Remove')
	BEGIN
		--here sampleID is SampleTestID
		INSERT @Material(SampleID, MaterialID)
		SELECT SampleID, MaterialID
				FROM OPENJSON(@Json) WITH
				(
					SampleID	INT '$.SampleID',
					MaterialID	NVARCHAR(MAX) '$.MaterialID'
				)

		--delete data
		MERGE INTO LD_SampleTestMaterial T
		USING
		(
			SELECT 
				MP.MaterialPlantID, 
				M.MaterialID,
				ST.SampleTestID
			FROM @Material M
			JOIN LD_MaterialPlant MP ON MP.MaterialID = M.MaterialID
			JOIN LD_SampleTest ST ON ST.SampleID = M.SampleID


		) S ON T.MaterialPlantID = S.MaterialPlantID AND T.SampleTestID = S.SampleTestID
		WHEN MATCHED THEN
		DELETE;
		
	END
END

GO

DROP PROCEDURE PR_LFDISK_SaveSampleMaterial
GO
/*
Author					Date			Description
Binod Gurung			2021/06/08		Save Plots to sample
===================================Example================================
EXEC [PR_LFDISK_SaveSampleMaterial] 4556, ''
*/
CREATE PROCEDURE [dbo].[PR_LFDISK_SaveSampleMaterial]
(
	@TestID INT,
	@Json NVARCHAR(MAX),
	@Action NVARCHAR(MAX)
)
AS
BEGIN
	
	SET NOCOUNT ON;
	DECLARE @ImportLevel NVARCHAR(20);
	DECLARE @MaterialPlant TABLE(MaterialPlantID INT, MaterialID INT); 
	DECLARE @Material TABLE(SampleID INT, MaterialID INT);
	
	IF NOT EXISTS (SELECT TestID FROM Test WHERE TestID = @TestID AND TestTypeID = 9)
	BEGIN
		EXEC PR_ThrowError N'Invalid Test.';
		RETURN;
	END

	SELECT @ImportLevel = ImportLevel FROM Test WHERE TestID = @TestID;
	IF(ISNULL(@ImportLevel,'') = 'Plot')
	BEGIN
		--ADD material to sample
		IF(ISNULL(@Action,'') = 'Add')
		BEGIN
			INSERT @Material(SampleID, MaterialID)
			SELECT SampleID, MaterialID
					FROM OPENJSON(@Json) WITH
					(
						SampleID	INT '$.SampleID',
						MaterialID	NVARCHAR(MAX) '$.MaterialID'
					)

				
			--Insert to MaterialPlant and copy MaterialPlantID for SampleTestMaterial
		

			MERGE INTO LD_MaterialPlant T
			USING
			(
			
				SELECT 
					M.MaterialID,
					PlantName = CASE WHEN @ImportLevel = 'Plot' THEN T3.Plotname ELSE COALESCE(T3.Plantnumber, T3.Femalecode) END
				FROM @Material S
				JOIN Material M ON M.MaterialID = S.MaterialID
				JOIN
				(
					SELECT T2.MaterialKey,  T2.[Plot name] AS Plotname, T2.Plantnumber, T2.[Female code] AS Femalecode
						FROM
						(
							SELECT 
								T.TestID,
								R.MaterialKey,
								C.ColumLabel,
								CellValue = CL.[Value]
							FROM [File] F
							JOIN [Row] R ON R.FileID = F.FileID
							JOIN [Column] C ON C.FileID = F.FileID
							JOIN Test T ON T.FileID = F.FileID
							LEFT JOIN [Cell] CL ON CL.RowID = R.RowID AND CL.ColumnID = C.ColumnID
							WHERE C.ColumLabel IN('Plot name', 'Plantnumber', 'Female code') AND T.TestID = @TestID
						) T1
						PIVOT
						(
							Max(CellValue)
							FOR [ColumLabel] IN ([Plot name], [Plantnumber], [Female code])
						) T2
				) T3 ON T3.MaterialKey = M.MaterialKey

			) S ON S.MaterialID = T.MaterialID
			WHEN NOT MATCHED THEN
				INSERT (MaterialID, [Name])
				VALUES (MaterialID,PlantName);

			--Merge into SampleTestMaterial
			MERGE INTO LD_SampleTestMaterial T
			USING
			(
				SELECT 
					MP.MaterialPlantID, 
					M.MaterialID,
					ST.SampleTestID
				FROM @Material M
				JOIN LD_MaterialPlant MP ON MP.MaterialID = M.MaterialID
				JOIN LD_SampleTest ST ON ST.SampleID = M.SampleID


			) S ON T.MaterialPlantID = S.MaterialPlantID AND T.SampleTestID = S.SampleTestID
			WHEN NOT MATCHED THEN
			INSERT (SampleTestID,MaterialPlantID)
			VALUES(S.SampleTestID, S.MaterialPlantID);
		END
	

	ELSE IF(ISNULL(@Action,'') = 'Remove')
		BEGIN
			--here sampleID is SampleTestID
			INSERT @Material(SampleID, MaterialID)
			SELECT SampleID, MaterialID
					FROM OPENJSON(@Json) WITH
					(
						SampleID	INT '$.SampleID',
						MaterialID	NVARCHAR(MAX) '$.MaterialID'
					)

			--delete data
			MERGE INTO LD_SampleTestMaterial T
			USING
			(
				SELECT 
					MP.MaterialPlantID, 
					M.MaterialID,
					ST.SampleTestID
				FROM @Material M
				JOIN LD_MaterialPlant MP ON MP.MaterialID = M.MaterialID
				JOIN LD_SampleTest ST ON ST.SampleID = M.SampleID


			) S ON T.MaterialPlantID = S.MaterialPlantID AND T.SampleTestID = S.SampleTestID
			WHEN MATCHED THEN
			DELETE;
		
		END
	END
END

GO