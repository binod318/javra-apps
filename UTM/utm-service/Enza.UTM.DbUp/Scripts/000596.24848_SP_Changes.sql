DROP PROCEDURE IF EXISTS [dbo].[PR_SH_TestToExcelForExport]
GO



/*
Author					Date				Description
KRIAHNA GAUTAM			2021-11-23			SP created.

============Example===================
EXEC PR_SH_GetOverview 'ON',1,100,'',0,1
*/
CREATE PROCEDURE [dbo].[PR_SH_TestToExcelForExport]
(
	@TestID INT
)
AS
BEGIN
	
	SELECT 
		Customer = 569,
		[Article Name] = T.TestName,
		Crop = F.CropCode,
		LotNumber = '',
		Process = T.LotSampleType,
		Planner = 'SH',
		[Sample quantity] = '',
		Determinations = ''
	FROM [Test] T
	JOIN [File] F ON F.FileID = T.FileID 
	WHERE TestID = @TestID;

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

		IF(@TestType = 'LDISK' OR @TestType = 'Seedhealth')
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
			IF(@TestType = 'LDISK')
			BEGIN				
				DELETE MP FROM LD_MaterialPlant MP
				JOIN TestMaterial TM ON TM.TestMaterialID = MP.TestMaterialID
				WHERE TM.TestID = @TestID;
			END
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


DROP PROCEDURE IF EXISTS PR_SH_TestToABS
GO
/*
Author					Date				Description
Krishna Gautam								Sp Created.


=================Example===============

EXEC PR_SH_TestToABS 4582
*/
CREATE PROCEDURE PR_SH_TestToABS
(
	@TestID INT
)
AS BEGIN

	--Check if sample exists or not
	IF NOT EXISTS(SELECT TOP 1 * FROM LD_SampleTest WHERE TestID = @TestID)
	BEGIN
		EXEC PR_ThrowError 'No Sample found to send to ABS.';
		RETURN;
	END


	IF EXISTS (SELECT TOP 1 * FROM LD_SampleTest ST
	LEFT JOIN LD_SampleTestDetermination STD ON STD.SampleTestID = ST.SampleTestID
	WHERE ST.TestID = @TestID AND STD.DeterminationID IS NULL)
	BEGIN
		EXEC PR_ThrowError 'Sample is missing tests. Please assign test to sample or delete sample before sending to ABS.';
		RETURN;

	END
	

	SELECT 
		Customer = 569,
		[Article Name] = T.TestName,
		Crop = F.CropCode,
		LotNumber = '',
		Process = T.LotSampleType,
		Planner = 'SH',
		[Sample quantity] = '',
		Determinations = ''
	FROM [Test] T
	JOIN [File] F ON F.FileID = T.FileID 
	WHERE TestID = @TestID;


END
GO