
/*
Author					Date			Description
Binod Gurung			2021/06/08		Save Plots to sample
===================================Example================================
EXEC [PR_LFDISK_SaveSampleTest] 1018, 'MySampleT',5
*/
ALTER PROCEDURE [dbo].[PR_LFDISK_SaveSampleTest]
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
	DECLARE @CustName NVARCHAR(50), @Counter INT = 1, @StatusCode INT;
	
	IF NOT EXISTS (SELECT TestID FROM Test WHERE TestID = @TestID )
	BEGIN
		EXEC PR_ThrowError N'Invalid Test.';
		RETURN;
	END

	SELECT @StatusCode = StatusCode FROM Test WHERE TestID = @TestID;

	IF(ISNULL(@StatusCode,0) >=500)
	BEGIN
		EXEC PR_ThrowError 'Cannot save sample for test which is sent to LIMS.';
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

/*
    DECLARE @DataAsJson NVARCHAR(MAX) = N'{"TestID":12675,"SampleInfo":[{"SampleTestID":512,"Key":"12132","Value":"1"}],"Action":"update","Determinations":[],"SampleIDs":[],"PageNumber":1,"PageSize":3,"TotalRows":0,"Filter":[]}';
    
	EXEC PR_LFDISK_ManageInfo1 4582, @DataAsJson;
*/

ALTER PROCEDURE [dbo].[PR_LFDISK_ManageInfo]
(
    @TestID	 INT,
    @DataAsJson NVARCHAR(MAX)
) AS BEGIN
    SET NOCOUNT ON;

	DECLARE @StatusCode INT;

	SELECT @StatusCode = StatusCode FROM Test WHERE TestID = @TestID;

	IF(ISNULL(@StatusCode,0) >=500)
	BEGIN
		EXEC PR_ThrowError 'Cannot Channge data for test which is sent to LIMS.';
		RETURN;
	END

	MERGE INTO [LD_Sample] T
	USING
	(
		SELECT
			SampleID,
			ReferenceCode = MAX(ReferenceCode),
			SampleName = MAX(SampleName)
		FROM
		(
			SELECT 
				SampleID, 
				ReferenceCode = CASE WHEN [Key] = 'referenceCode' THEN [Value] ELSE NULL END,
				SampleName = CASE WHEN [Key] = 'sampleName' THEN [Value] ELSE NULL END
			FROM
			(
				SELECT 
					S.SampleID,
					[Key],
					[Value]
				FROM 
				OPENJSON(@DataAsJson,'$.SampleInfo') WITH
				(
					SampleTestID INT '$.SampleTestID',
					[Key] NVARCHAR(MAX) '$.Key',
					[Value] NVARCHAR(MAX) '$.Value'
				) T1
				JOIN LD_SampleTest ST ON ST.SampleTestID = T1.SampleTestID
				JOIN LD_sample S ON ST.SampleID = S.SampleID
				WHERE [Key] IN('referenceCode','sampleName') 
				AND ST.TestID = @TestID
			) T2
		) T3
		GROUP BY SampleID
	) S ON S.SampleID = T.SampleID
	WHEN MATCHED THEN
	UPDATE SET 
		ReferenceCode = COALESCE(S.ReferenceCode, T.ReferenceCode), 
		SampleName = COALESCE(S.SampleName, T.SampleName);

	

	MERGE INTO LD_SampleTestDetermination T
    USING 
    ( 
		SELECT 
			SampleTestID, 
			DeterminationID = CAST([Key] AS INT), 
			Selected =CAST([Value] AS BIT)
		FROM
		(
			SELECT 
				SampleTestID,
				[key],
				[Value]
			FROM 
			OPENJSON(@DataAsJson,'$.SampleInfo') WITH
			(
				SampleTestID INT '$.SampleTestID',
				[Key] NVARCHAR(MAX) '$.Key',
				[Value] NVARCHAR(MAX) '$.Value'
			) T1
	   		WHERE ISNUMERIC(ISNULL(T1.[Key],'')) = 1
		) T2
    ) S
    ON T.SampleTestID = S.SampleTestID AND T.DeterminationID = S.DeterminationID
    WHEN NOT MATCHED THEN 
	   INSERT(SampleTestID, DeterminationID, StatusCode) 
	   VALUES(S.SampleTestID,S.DeterminationID,100)
	WHEN MATCHED AND Selected = 0 THEN
		DELETE;

END

GO

/*
Author					Date				Description
KRIAHNA GAUTAM			2021-06-09			#22641:SP created.

====================Example======================
DECLARE @Determinations NVARCHAR(MAX) = '88221';
DECLARE @ColNames NVARCHAR(MAX) --= N'GID, plant name';
DECLARE @Filters NVARCHAR(MAX) --= '[GID] LIKE ''%2250651%'' AND [Plant name] LIKE ''%Test33360-01-01%''';
EXEC PR_LFDISK_AssignMarkers 4562, @Determinations, @ColNames, @Filters;
*/
ALTER PROCEDURE [dbo].[PR_LFDISK_AssignMarkers]
(
    @TestID				INT,
    @Determinations	    NVARCHAR(MAX),
	@SelectedMaterial	NVARCHAR(MAX),
    @Filters		    NVARCHAR(MAX)
) AS BEGIN
    SET NOCOUNT ON;
    
    DECLARE @FileID INT, @StatusCode INT;
    DECLARE @SQL NVARCHAR(MAX);
    DECLARE @ColumnIDs NVARCHAR(MAX), @ColumnNames NVARCHAR(MAX);
    DECLARE @Samples TABLE(SampleTestID INT);

    SELECT @FileID = FileID, @StatusCode = StatusCode FROM Test WHERE TestID = @TestID;

	IF(ISNULL(@StatusCode,0) >=500)
	BEGIN
		EXEC PR_ThrowError 'Cannot assign merker for test which is sent to LIMS.';
		RETURN;
	END

     IF(ISNULL(@SelectedMaterial,'') <> '')
	 BEGIN
		INSERT INTO @Samples(SampleTestID)		
		SELECT [value] FROM string_split(@SelectedMaterial,',');

	 END

    ELSE IF(ISNULL(@Filters, '') <> '') BEGIN
		SET @SQL = N'SELECT 
						LDST.SampleTestID 
					FROM [LD_Sample] LDS
					JOIN [LD_SampleTest] LDST ON LDST.SampleID = LDS.SampleID
					WHERE LDST.TestID = @TestID AND '+@Filters;
		
	   INSERT INTO @Samples(SampleTestID)		
	   EXEC sp_executesql @SQL, N'@TestID INT', @TestID;
    END
	--if no filter is applied then apply determination to all sample
    ELSE BEGIN
	   INSERT INTO @Samples(SampleTestID)
	   SELECT 
			LDST.SampleTestID 
		FROM [LD_Sample] LDS
		JOIN [LD_SampleTest] LDST ON LDST.SampleID = LDS.SampleID
		WHERE LDST.TestID = @TestID;
    END

    MERGE INTO LD_SampleTestDetermination T
    USING 
    ( 
	   SELECT 
		  T1.SampleTestID, 
		  D.DeterminationID
	   FROM @Samples T1 
	   CROSS APPLY 
	   (
		  SELECT 
			 DeterminationID  = [Value]
		  FROM string_split(@Determinations, ',') 
		  GROUP BY [Value]
	   ) D 		
    ) S
    ON T.SampleTestID = S.SampleTestID AND T.DeterminationID = S.DeterminationID
    WHEN NOT MATCHED THEN 
	   INSERT(SampleTestID, DeterminationID, StatusCode) 
	   VALUES(S.SampleTestID,S.DeterminationID,100);
END

GO

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
			JOIN LD_SampleTest ST ON ST.TestID = T.TestFlowType
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
Author							Date				Description
Binod Gurung					2021/06/14			Automatic sample filling for selection/crosses
=================Example===============
EXEC [PR_LFDISK_Calculate_Sample_Filling] 12684, 20
*/
ALTER PROCEDURE [dbo].[PR_LFDISK_Calculate_Sample_Filling]
(
	@TestID INT,
	@TotalPlantsInSample INT
)
AS BEGIN
	SET NOCOUNT ON;
	DECLARE @ReCalculate BIT, @ImportLevel NVARCHAR(20), @TestTypeID INT, @TotalPlants INT, @Counter INT, @SampleCounter INT, @SampleName NVARCHAR(50), @TestName NVARCHAR(MAX);
	DECLARE @MatPlant TABLE (TestMaterialID INT, MaterialName NVARCHAR(30), NrOfPlants INT);
	DECLARE @Plants TABLE(ID INT, TestMaterialID INT, PlantName NVARCHAR(50));
	DECLARE @SampleTest TABLE(SampleTestID INT, TestID INT);
	DECLARE @DeleteSample TABLE(ID INT);
	DECLARE @TestMaterialID INT, @PlantName NVARCHAR(150), @ID INT = 1, @Count INT, @NewSample BIT = 1, @SampleCount INT = 1, @StatusCode INT;

	IF NOT EXISTS (SELECT TestID FROM Test WHERE TestID = @TestID)
	BEGIN
		EXEC PR_ThrowError 'Invalid test.'; 
		RETURN;
	END

	SELECT @TestName = TestName, @ReCalculate = RearrangePlateFilling, @ImportLevel = ImportLevel, @TestTypeID = TestTypeID, @StatusCode = StatusCode FROM Test WHERE TestID = @TestID

	IF (@TestTypeID <> 9)
	BEGIN
		EXEC PR_ThrowError 'Calculation is performed only for Leafdisk.';
		RETURN;
	END

	IF (@ImportLevel <> 'CROSSES/SELECTION')
	BEGIN
		EXEC PR_ThrowError 'Automatic sample calculation is only for selection/crosses';
		RETURN;
	END

	--Only perform recalculate if @ReCalculate flag is set  -- NULL for first time
	IF (ISNULL(@ReCalculate,1) = 1 AND @StatusCode < 500) --do not update once it is sent to LIMS
	BEGIN

		--delete all old records

		DELETE STD FROM LD_SampleTestDetermination STD
		JOIN LD_SampleTest ST ON ST.SampleTestID = STD.SampleTestID
		WHERE ST.TestID = @TestID;

		DELETE M FROM LD_MaterialPlant M
		JOIN LD_SampleTestMaterial STM ON STM.MaterialPlantID = M.MaterialPlantID
		JOIN LD_SampleTest ST ON ST.SampleTestID = STM.SampleTestID
		where ST.TestID = @TestID

		DELETE STM from LD_SampleTestMaterial STM
		JOIN LD_SampleTest ST on ST.SampleTestID = STM.SampleTestID
		where ST.testid = @TestID

		INSERT @DeleteSample(ID)
		SELECT ST.SampleID FROM LD_SampleTest ST
		JOIN LD_Sample S ON s.SampleID = ST.SampleID 
		WHERE st.testid = @TestID

		DELETE FROM LD_SampleTest
		WHERE SampleID In (SELECT ID FROM @DeleteSample);

		DELETE FROM LD_Sample
		WHERE SampleID In (SELECT ID FROM @DeleteSample);

		---------------

		INSERT @MatPlant (TestMaterialID, MaterialName, NrOfPlants)
		SELECT 
			TM.TestMaterialID, 
			MaterialName = COALESCE(T3.Plantnumber, T3.Femalecode), 
			NrOfPlants 
		FROM TestMaterial TM
		JOIN 
		(
			SELECT T2.TestMaterialID, T2.Plantnumber, T2.[Female code] AS Femalecode
					FROM
					(
						SELECT 
							T.TestID,
							TM.TestMaterialID,
							C.ColumLabel,
							CellValue = CL.[Value]
						FROM [File] F
						JOIN [Row] R ON R.FileID = F.FileID
						JOIN Material M ON M.MaterialKey = R.MaterialKey
						JOIN [Column] C ON C.FileID = F.FileID
						JOIN Test T ON T.FileID = F.FileID
						JOIN TestMaterial TM ON TM.TestID = T.TestID AND Tm.MaterialID = M.materialID
						LEFT JOIN [Cell] CL ON CL.RowID = R.RowID AND CL.ColumnID = C.ColumnID
						WHERE C.ColumLabel IN('Plantnumbr', 'Female code') AND T.TestID = @TestID
					) T1
					PIVOT
					(
						Max(CellValue)
						FOR [ColumLabel] IN ([Plantnumber], [Female code])
					) T2
		) T3 On T3.TestMaterialID = TM.TestMaterialID
		WHERE  testid = @TestID AND ISNULL(NrOfPlants,0) > 0;


		WITH CTE AS
		(
			SELECT TestMaterialID, MaterialName, NrOfPlants FROM @MatPlant
			UNION ALL
			SELECT TestMaterialID, MaterialName, NrOfPlants - 1 FROM CTE WHERE NrOfPlants > 1
		)

		INSERT @Plants(ID, TestMaterialID, PlantName)
		SELECT	
			ROW_NUMBER() OVER (ORDER BY TestMaterialID, NrOfPlants),
			TestMaterialID,
			PlantName = ISNULL(MaterialName,'') + '-' + CAST( NrOfPlants AS NVARCHAR(10))
		FROM CTE
		ORDER BY
			TestMaterialID, NrOfPlants

		--remove suffix -1 for from plantname for materials with only one plant
		UPDATE @Plants 		
		SET PlantName = REPLACE(PlantName, '-1', '')
		WHERE ID IN 
		(
			SELECT MIN(ID) FROM @Plants
			GROUP BY TestMaterialID
			HAVING COUNT(TestMaterialID) = 1
		)
		
		BEGIN TRY
		BEGIN TRANSACTION;

			SELECT @Count = COUNT(ID) FROM @Plants;
			WHILE(@ID <= @Count) BEGIN
			
				SELECT 
					@TestMaterialID = TestMaterialID,
					@PlantName = PlantName 
				FROM @Plants
				WHERE ID = @ID;

				--create Sample/SampleTest if @NewSample = 1
				IF(@NewSample = 1)
				BEGIN
					
					DELETE FROM @SampleTest;

					INSERT LD_Sample(SampleName)
					--OUTPUT INSERTED.SampleID INTO @Sample
					VALUES(@TestName + '_' + CAST(@SampleCount AS NVARCHAR(10)));

					INSERT LD_SampleTest(SampleID, TestID)
					OUTPUT INSERTED.SampleTestID, INSERTED.TestID INTO @SampleTest
					--SELECT ID, @TestID FROM @Sample;
					VALUES(SCOPE_IDENTITY(), @TestID);

					SET @NewSample = 0;
				END

				--create MaterialPlant/SampleTestMaterial
				INSERT LD_MaterialPlant(TestMaterialID, [Name])
				VALUES(@TestMaterialID, @PlantName);

				INSERT LD_SampleTestMaterial(MaterialPlantID, SampleTestID)
				SELECT SCOPE_IDENTITY(), SampleTestID FROM @SampleTest

				IF(@ID % @TotalPlantsInSample = 0) 
				BEGIN
					SET @NewSample = 1;
					SET @SampleCount = @SampleCount + 1;
				END

				SET @ID = @ID + 1;
			END   

		COMMIT;
		END TRY
		BEGIN CATCH

			IF @@TRANCOUNT > 0
				ROLLBACK;

		END CATCH

		--SET @ReCalculate = 0;
		UPDATE Test
		SET RearrangePlateFilling = 0
		WHERE TestID = @TestID
	END

END

GO