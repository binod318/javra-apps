/*
Author					Date				Description
Krishna Gautam								Sp Created.
KRIAHNA GAUTAM			2020-March-20		#11673: Allow lab user to delete test which have status In Lims (StatusCode = 500)

=================Example===============

EXEC PR_Delete_Test 4582
*/

ALTER PROCEDURE [dbo].[PR_Delete_Test]
(
	@TestID INT,
	@ForceDelete BIT = 0,
	@Status INT OUT,
	@PlatePlanName NVARCHAR(MAX) OUT
)
AS BEGIN
	DECLARE @FileID INT, @FileCount INT = 0;
	DECLARE @TestType NVARCHAR(50),@RequiredPlates BIT,@DeterminationRequired BIT;
	IF NOT EXISTS(SELECT TestID FROM Test WHERE TestID = @TestID) BEGIN
		EXEC PR_ThrowError 'Invalid test.';
		RETURN;
	END

	SELECT 
		@Status = ISNULL(T.StatusCode,0),
		@PlatePlanName = ISNULL(T.LabPlatePlanName,''),
		@FileID = ISNULL(T.FileID,0),
		@TestType = TT.TestTypeCode,
		@RequiredPlates = CASE WHEN ISNULL(TT.PlateTypeID,0) = 0 THEN 0 ELSE 1 END,
		@DeterminationRequired = CASE WHEN ISNULL(TT.DeterminationRequired,0) = 0 THEN 0 ELSE 1 END
	FROM Test T 
	JOIN TestType TT ON TT.TestTypeID = T.TestTypeID
	WHERE T.TestID = @TestID;

	IF(ISNULL(@ForceDelete,0) = 0 AND @Status > 400) BEGIN
		EXEC PR_ThrowError 'Cannot delete test which is sent to LIMS.';
		RETURN;
	END

	IF(ISNULL(@ForceDelete,0) = 0 AND @Status > 100 AND @TestType = 'RDT') BEGIN
		EXEC PR_ThrowError 'Cannot delete test which is sent to LIMS.';
		RETURN;
	END

	IF(ISNULL(@ForceDelete,0) = 1 AND @Status > 500) BEGIN
		EXEC PR_ThrowError 'Cannot delete test having result from LIMS';
		RETURN;
	END
	
	SET NOCOUNT ON;
	BEGIN TRY
		BEGIN TRANSACTION;
		
		IF(@TestType = 'C&T') BEGIN

			WHILE 1 =1
			BEGIN
				DELETE TOP (15000) I
				FROM CnTInfo I
				JOIN [Row] R ON R.RowID = I.RowID
				JOIN [File] F ON F.FileID = R.FileID
				JOIN Test T ON T.FileID = F.FileID
				WHERE T.TestID = @TestID;

				IF @@ROWCOUNT < 15000
				BREAK;
			END
		END
		--RDT
		IF(@TestType = 'RDT') BEGIN

			WHILE 1 =1
			BEGIN
				DELETE TOP (15000) TM
				FROM TestMaterial TM
				WHERE TM.TestID = @TestID;
				IF @@ROWCOUNT < 15000
				BREAK;
			END
		END
		
		IF(@RequiredPlates = 1)
		BEGIN
			--delete from testmaterialdeterminationwell
			DELETE TMDW
			FROM TestMaterialDeterminationWell TMDW
			JOIN Well W ON W.WellID = TMDW.WellID
			JOIN Plate P ON P.PlateID = W.PlateID
			WHERE P.TestID = @TestID;

			--delete from well
			DELETE W
			FROM Well W 
			JOIN Plate P ON P.PlateID = W.PlateID
			WHERE P.TestID = @TestID;

			--delete from Plate
			DELETE Plate WHERE TestID = @TestID;
		END
		--delete from slottest
		DELETE SlotTest WHERE TestID = @TestID;

		--delete from testmaterialdetermination
		IF(@DeterminationRequired = 1)
		BEGIN
			
			WHILE 1=1
			BEGIN
				DELETE TOP (15000) TestMaterialDetermination WHERE TestID = @TestID				
				IF @@ROWCOUNT < 15000
				BREAK;
			END

			
		END
		
		IF(@TestType = 'S2S')
		BEGIN
			--delete Donor info for S2S 
			
			WHILE 1=1
			BEGIN
				DELETE TOP (15000) SD 
				FROM Test T 
				JOIN [Row] R ON R.FileID = T.FileID
				JOIN S2SDonorInfo SD ON SD.RowID = R.RowID
				WHERE T.TestID = @TestID

				IF @@ROWCOUNT < 15000
				BREAK;
			END
			
						
			WHILE 1=1
			BEGIN
				--delete marker score
				DELETE TOP(15000) FROM S2SDonorMarkerScore WHERE TestID = @TestID

				IF @@ROWCOUNT < 15000
				BREAK;
			END

			
		END

		IF(@TestType = 'LDISK')
		BEGIN
			

			--DELETE SampleTestDetermination
			DELETE  STD FROM Test T 
			JOIN LD_SampleTest ST ON ST.TestID = T.TestID
			JOIN LD_SampleTestDetermination STD ON STD.SampleTestID = ST.SampleTestID				
			WHERE T.TestID = @TestID

				
			--DELETE sampletestmaterial
			DELETE  STM FROM Test T 
			JOIN LD_SampleTest ST ON ST.TestID = T.TestID
			JOIN LD_SampleTestMaterial STM ON STM.SampleTestID = ST.SampleTestID				
			WHERE T.TestID = @TestID

			DECLARE @Deleted TABLE(ID INT);
			--DELETE sampletest
			DELETE FROM LD_SampleTest 
			OUTPUT DELETED.SampleID INTO @Deleted
			WHERE TestID = @TestID

			--delete sample
			DELETE S FROM [LD_Sample] S
			JOIN @Deleted T ON S.SampleID = T.ID;

			--Delete materialPlant
			DELETE MP FROM LD_MaterialPlant MP
			JOIN TestMaterial TM ON TM.TestMaterialID = MP.TestMaterialID
			WHERE TM.TestID = @TestID;


			--delete testmaterial
			DELETE FROM TestMaterial WHERE TestID = @TestID;

			SELECT @FileCount = Count(TestID)  FROM Test WHERE FileID = @FileID AND testID <> @TestID;

		END
		--delete test
		DELETE Test WHERE TestID = @TestID

		--Delete file, cell, row, column if that file is not used for more than 1 tests.
		IF(ISNULl(@FileCount,0) = 0)
		BEGIN
			WHILE 1= 1 
			BEGIN
				--delete cell
				DELETE TOP (15000) C FROM Cell C 
				JOIN [Row] R ON R.RowID = C.RowID
				WHERE R.FileID = @FileID
			
				IF @@ROWCOUNT < 15000
				BREAK;
			END
			--delete column
			DELETE [Column] WHERE FileID = @FileID

			--delete row
			DELETE [Row] WHERE FileID = @FileID

			--delete file
			DELETE [File] WHERE FileID = @FileID
			END

		COMMIT;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
            ROLLBACK;
		THROW;
	END CATCH


	
END

GO



/*
Author					Date			Description
Binod Gurung			2021/06/08		Get sample plot information for selected test
===================================Example================================
EXEC [PR_LFDISK_GetSampleMaterial] 12692,1,100,'SampleName like ''%_%''',20
*/
ALTER PROCEDURE [dbo].[PR_LFDISK_GetSampleMaterial]
(
	@TestID INT,
	@Page INT,
	@PageSize INT,
	@FilterQuery NVARCHAR(MAX),
	@TotalPlantsInSample INT = NULL
)
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @ReCalculate BIT, @ImportLevel NVARCHAR(20), @Offset INT, @TotalRowsWithoutFilter NVARCHAR(MAX);
	DECLARE @ColumnTable TVP_ColumnDetail;
	DECLARE @RequiredColumns NVARCHAR(MAX), @RequiredColumns1 NVARCHAR(MAX);
	DECLARE @Query NVARCHAR(MAX);

	IF NOT EXISTS (SELECT TestID FROM Test WHERE TestID = @TestID AND TestTypeID = 9)
	BEGIN
		EXEC PR_ThrowError N'Invalid Test.';
		RETURN;
	END

	IF(ISNULL(@FilterQuery,'') <> '')
	BEGIN
		SET @FilterQuery = ' AND '+ @FilterQuery ;
	END
	ELSE
	BEGIN
		SET @FilterQuery = ''; 
	END

	SET @Offset = @PageSize * (@Page -1);

	SELECT @ReCalculate = RearrangePlateFilling, @ImportLevel = ImportLevel FROM Test WHERE TestID = @TestID

	--Automatic calculate platefilling for Selection/Crosses
	IF(@ImportLevel = 'CROSSES/SELECTION' AND ISNULL(@ReCalculate,1) = 1 )
	BEGIN
		EXEC PR_LFDISK_Calculate_Sample_Filling @TestID, @TotalPlantsInSample;
	END
	
	--now get total rows without filter value after recalculating.
	SELECT 
		@TotalRowsWithoutFilter = CAST(COUNT(ST.SampleID) AS NVARCHAR(MAX)) 
	FROM [LD_Sample] S
	JOIN [LD_SampleTest] ST ON ST.SampleID = S.SampleID
	JOIN Test T ON T.TestID = ST.TestID
	JOIN [File] F ON F.FileID = T.FileID	
	LEFT JOIN [LD_SampleTestMaterial] STM ON STM.SampleTestID = ST.SampleTestID
	LEFT JOIN [LD_MaterialPlant] MP On MP.MaterialPlantID = STM.MaterialPlantID
	LEFT JOIN [TestMaterial] TM ON TM.TestMaterialID = MP.TestmaterialID
	LEFT JOIN [Material] M ON M.MaterialID = TM.MaterialID
	LEFT JOIN [Row] R ON R.MaterialKey = M.MaterialKey AND R.FileID = F.FileID
	WHERE ST.TestID = @TestID AND T.TestID = @TestID

	INSERT @ColumnTable(ColumnID, ColumnLabel, [Order], Visible,AllowFilter,DataType,Editable,Width)
	VALUES  ('SampleID', 'SampleID', 0, 0 ,0, 'integer', 0,10),
			('MaterialID', 'MaterialID', 0, 0 ,0, 'integer', 0,10),
			('SampleName', 'Sample', 1, 1, 1, 'string', 0, 150);

	IF(@ImportLevel = 'PLOT')
	BEGIN
		INSERT @ColumnTable(ColumnID, ColumnLabel, [Order], Visible, AllowFilter, DataType, Editable,Width)
		VALUES  
		('FEID', 'FEID', 2, 1, 1,'string',0, 100),
		('Plot name', 'Plot name', 3, 1, 1,'string',0, 100);
	END
	ELSE
	BEGIN
		INSERT @ColumnTable(ColumnID, ColumnLabel, [Order], Visible, AllowFilter, DataType, Editable,Width)
		VALUES  
		('GID', 'GID', 2, 1, 1,'string',0, 100),
		('Origin', 'Origin', 3, 1, 1,'string',0, 100),
		('Female code', 'Female code', 4, 1, 1,'string',0, 100);
		
	END

	SELECT 
		@RequiredColumns = COALESCE(@RequiredColumns + ',', '') + QUOTENAME(ColumnID),
		@RequiredColumns1 = COALESCE(@RequiredColumns1 + ',', '') + QUOTENAME(ColumnID,'''')
	FROM @ColumnTable WHERE [Order] >= 2;

	SET @Query = ';WITH CTE AS
	(

		
	SELECT
		[Delete] = CASE WHEN (ISNULL(STM.SampleTestID,0) <> 0 AND @ImportLevel = ''PLOT'') THEN 1 ELSE 0 END,
		S.SampleID,
		M.MaterialID,
		S.SampleName,
		'+@RequiredColumns+',
		Total = '+@TotalRowsWithoutFilter+' 
	FROM [LD_Sample] S
	JOIN [LD_SampleTest] ST ON ST.SampleID = S.SampleID
	JOIN Test T ON T.TestID = ST.TestID
	JOIN [File] F ON F.FileID = T.FileID	
	LEFT JOIN [LD_SampleTestMaterial] STM ON STM.SampleTestID = ST.SampleTestID
	LEFT JOIN [LD_MaterialPlant] MP On MP.MaterialPlantID = STM.MaterialPlantID
	LEFT JOIN [TestMaterial] TM ON TM.TestMaterialID = MP.TestmaterialID
	LEFT JOIN [Material] M ON M.MaterialID = TM.MaterialID
	LEFT JOIN [Row] R ON R.MaterialKey = M.MaterialKey AND R.FileID = F.FileID
	LEFT JOIN
	(
		SELECT T2.MaterialKey,  '+@RequiredColumns+', T2.TestID
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
				WHERE T.TestID = @TestID AND C.ColumLabel IN('+@RequiredColumns1+')
			) T1
			PIVOT
			(
				Max(CellValue)
				FOR [ColumLabel] IN ('+@RequiredColumns+')
			) T2
	) T3 ON T3.MaterialKey = R.MaterialKey AND T3.TestID = ST.TestID
	WHERE T.TestID = @TestID '+@FilterQuery+' ), Count_CTE AS (SELECT COUNT([SampleID]) AS [TotalRows] FROM CTE) 

	SELECT CTE.*, Count_CTE.[TotalRows] FROM CTE, COUNT_CTE
	ORDER BY CTE.[SampleID]
	OFFSET ' + CAST(@Offset AS NVARCHAR) + ' ROWS
	FETCH NEXT ' + CAST (@PageSize AS NVARCHAR) + ' ROWS ONLY'

	
	PRINT @Query;
	EXEC sp_executesql @Query, N'@TestID INT, @ImportLevel NVARCHAR(MAX)', @TestID, @ImportLevel;	

	IF(@ImportLevel <> 'PLOT')
	BEGIN
		INSERT @ColumnTable(ColumnID, ColumnLabel, [Order], Visible, AllowFilter, DataType, Editable,Width)
		VALUES
		('Name', 'Name', 5, 1, 1,'string',0,150);
	END

	SELECT * FROM @ColumnTable ORDER BY [Order]


END

GO

