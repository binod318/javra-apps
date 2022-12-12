DROP PROCEDURE IF EXISTS [dbo].[PR_LFDISK_GetSampleMaterial]
GO


/*
Author					Date			Description
Binod Gurung			2021/06/08		Get sample plot information for selected test
===================================Example================================
EXEC [PR_LFDISK_GetSampleMaterial] 12655
*/
CREATE PROCEDURE [dbo].[PR_LFDISK_GetSampleMaterial]
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
		GID = ISNULL(T3.GID,''),
		Plotname = ISNULL(T3.[Plot name],'')
	FROM [LD_Sample] S
	JOIN [LD_SampleTest] ST ON ST.SampleID = S.SampleID
	LEFT JOIN [LD_SampleTestMaterial] STM ON STM.SampleTestID = ST.SampleTestID
	LEFT JOIN [LD_MaterialPlant] MP On MP.MaterialPlantID = STM.MaterialPlantID
	LEFT JOIN [Material] M ON M.MaterialID = MP.MaterialID
	LEFT JOIN [Row] R ON R.MaterialKey = M.MaterialKey
	LEFT JOIN
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


DROP PROCEDURE IF EXISTS [dbo].[PR_LFDISK_SaveSampleTest]
GO


/*
Author					Date			Description
Binod Gurung			2021/06/08		Save Plots to sample
===================================Example================================
EXEC [PR_LFDISK_SaveSampleTest] 1018, 'MySampleT',5
*/
CREATE PROCEDURE [dbo].[PR_LFDISK_SaveSampleTest]
(
	@TestID INT,
	@SampleName NVARCHAR(150),
	@NrOfSamples INT,
	@SampleID INT = NULL
)
AS
BEGIN
	
	SET NOCOUNT ON;
	DECLARE @Sample TABLE(ID INT);
	DECLARE @CustName NVARCHAR(50), @Counter INT = 1;
	
	IF NOT EXISTS (SELECT TestID FROM Test WHERE TestID = @TestID )
	BEGIN
		EXEC PR_ThrowError N'Invalid Test.';
		RETURN;
	END

	--insert
	IF(ISNULL(@SampleID,0) = 0)
	BEGIN

		--create multiple samples
		IF(ISNULL(@NrOfSamples,0) > 1)
		BEGIN

			WHILE ( @Counter <= @NrOfSamples)
			BEGIN 
				--Reset temp-table
				DELETE FROM @Sample;

				IF(@NrOfSamples >= 100)
					SET @CustName = @SampleName + '_' + RIGHT('000'+CAST(@Counter AS NVARCHAR(10)),3);
				ELSE IF(@NrOfSamples >= 10)
					SET @CustName = @SampleName + '_' + RIGHT('00'+CAST(@Counter AS NVARCHAR(10)),2);
				ELSE
					SET @CustName = @SampleName + '_' + CAST(@Counter AS NVARCHAR(10));

				INSERT LD_Sample(SampleName)
				OUTPUT INSERTED.SampleID INTO @Sample
				VALUES(@CustName);

				INSERT LD_SampleTest(SampleID, TestID)
				SELECT ID, @TestID FROM @Sample;

				SET @Counter  = @Counter  + 1
			END


		END
		ELSE
		BEGIN

			INSERT LD_Sample(SampleName)
			OUTPUT INSERTED.SampleID INTO @Sample
			VALUES(@SampleName);

			INSERT LD_SampleTest(SampleID, TestID)
			SELECT ID, @TestID FROM @Sample;

		END

	END
	--rename sample name
	ELSE
	BEGIN

		UPDATE LD_Sample
		SET SampleName = @SampleName
		WHERE SampleID = @SampleID

	END

END
GO


