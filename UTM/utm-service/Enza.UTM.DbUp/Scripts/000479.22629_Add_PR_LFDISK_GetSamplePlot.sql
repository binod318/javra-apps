DROP PROCEDURE IF EXISTS [dbo].[PR_LFDISK_GetSamplePlot]
GO


/*
Author					Date			Description
Binod Gurung			2021/06/08		Get sample plot information for selected test
===================================Example================================
EXEC [PR_LFDISK_GetSamplePlot] 4556
*/
CREATE PROCEDURE [dbo].[PR_LFDISK_GetSamplePlot]
(
	@TestID INT
)
AS
BEGIN
	
	SET NOCOUNT ON;

	DECLARE @ColumnTable TABLE(ColumnID NVARCHAR(MAX), Label NVARCHAR(MAX),[Order] INT, IsVisible BIT);

	IF NOT EXISTS (SELECT TestID FROM Test WHERE TestID = @TestID AND TestTypeID = 9)
	BEGIN
		EXEC PR_ThrowError N'Invalid Test.';
		RETURN;
	END

	INSERT @ColumnTable(ColumnID, Label, [Order], IsVisible)
	VALUES  ('SampleID', 'SampleID', 0, 0),
			('SampleName', 'SampleName', 1, 1),
			('GID', 'GID', 2, 1),
			('Plot name', 'Plot name', 3, 1);

	SELECT 
		S.SampleID,
		S.SampleName,
		T3.GID,
		T3.[Plot name]
	FROM [LD_Sample] S
	JOIN [LD_SampleTest] ST ON ST.SampleID = S.SampleID
	JOIN [LD_SampleTestMaterial] STM ON STM.SampleTestID = ST.SampleTestID
	JOIN [LD_MaterialPlant] MP On MP.MaterialPlantID = STM.MaterialPlantID
	JOIN [Material] M ON M.MaterialID = MP.MaterialID
	JOIN [Row] R ON R.MaterialKey = M.MaterialKey
	JOIN
	(
		SELECT T2.MaterialKey,  T2.[GID], T2.[Plot name], T2.TestID
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
				WHERE C.ColumLabel IN('GID', 'Plot name')
			) T1
			PIVOT
			(
				Max(CellValue)
				FOR [ColumLabel] IN ([GID], [Plot name])
			) T2
	) T3 ON T3.MaterialKey = M.MaterialKey AND T3.TestID = ST.TestID
	WHERE ST.TestID = @TestID

	SELECT * FROM @ColumnTable ORDER BY [Order]

END
GO


DROP PROCEDURE IF EXISTS [dbo].[PR_LFDISK_SaveSamplePlot]
GO


/*
Author					Date			Description
Binod Gurung			2021/06/08		Save Plots to sample
===================================Example================================
EXEC [PR_LFDISK_SaveSamplePlot] 4556, ''
*/
CREATE PROCEDURE [dbo].[PR_LFDISK_SaveSamplePlot]
(
	@TestID INT,
	@Json NVARCHAR(MAX)
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

	INSERT @Material(SampleID, MaterialID)
	SELECT SampleID, MaterialID
			FROM OPENJSON(@Json) WITH
			(
				SampleID	INT '$.SampleID',
				MaterialID	NVARCHAR(MAX) '$.MaterialID'
			)

	--Insert to MaterialPlant and copy MaterialPlantID for SampleTestMaterial
	INSERT LD_MaterialPlant(MaterialID, [Name])
	OUTPUT INSERTED.MaterialPlantID, INSERTED.MaterialID INTO @MaterialPlant

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

	--Insert into SampleTestMaterial
	INSERT LD_SampleTestMaterial(SampleTestID, MaterialPlantID)
	SELECT 
		ST.SampleTestID, 
		MP.MaterialPlantID 
	FROM @Material M
	JOIN @MaterialPlant MP ON MP.MaterialID = M.MaterialID
	JOIN LD_SampleTest ST ON ST.SampleID = M.SampleID 
	WHERE ST.TestID = @TestID

END
GO

DROP PROCEDURE IF EXISTS [dbo].[PR_LFDISK_SaveSampleTest]
GO

/*
Author					Date			Description
Binod Gurung			2021/06/08		Save Plots to sample
===================================Example================================
EXEC [PR_LFDISK_SaveSampleTest] 1018, 'Test sample name3'
*/
CREATE PROCEDURE [dbo].[PR_LFDISK_SaveSampleTest]
(
	@TestID INT,
	@SampleName NVARCHAR(150),
	@SampleID INT = NULL
)
AS
BEGIN
	
	SET NOCOUNT ON;
	DECLARE @Sample TABLE(ID INT);
	
	IF NOT EXISTS (SELECT TestID FROM Test WHERE TestID = @TestID )
	BEGIN
		EXEC PR_ThrowError N'Invalid Test.';
		RETURN;
	END

	--insert
	IF(ISNULL(@SampleID,0) = 0)
	BEGIN

		INSERT LD_Sample(SampleName)
		OUTPUT INSERTED.SampleID INTO @Sample
		VALUES(@SampleName);

		INSERT LD_SampleTest(SampleID, TestID)
		SELECT ID, @TestID FROM @Sample;

	END
	--update
	ELSE
	BEGIN

		UPDATE LD_Sample
		SET SampleName = @SampleName
		WHERE SampleID = @SampleID

	END

END
GO

