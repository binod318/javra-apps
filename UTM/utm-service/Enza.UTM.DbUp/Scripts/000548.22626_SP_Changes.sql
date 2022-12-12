DROP PROCEDURE IF EXISTS [dbo].[PR_LFDISK_ImportFromExistingConfiguration]
GO


/*
=========Changes====================
Changed By			DATE				Description
Binod Gurung		2021/06/25			#22627 : Import leaf disk materials from existing configuration

========Example=============
EXEC PR_LFDISK_ImportFromExistingConfiguration 0, 12701,'binod.gurung@javra.com',1009,'TodayImport1','',1,2
*/

CREATE PROCEDURE [dbo].[PR_LFDISK_ImportFromExistingConfiguration]
(
	@TestID						INT OUTPUT,
	@SourceID					INT,
	--@CropCode					NVARCHAR(10),
	--@BrStationCode				NVARCHAR(10),
	--@SyncCode					NVARCHAR(10),
	--@CountryCode				NVARCHAR(10),
	@UserID						NVARCHAR(100),
	@TestProtocolID				INT,
	@TestName					NVARCHAR(200),
	--@Source						NVARCHAR(50) = 'Phenome',
	--@ObjectID					NVARCHAR(100),
	--@ImportLevel				NVARCHAR(20),
	--@TVPColumns TVP_Column		READONLY,
	--@TVPRow TVP_Row				READONLY,
	--@TVPCell TVP_Cell			READONLY,
	--@FileID						INT,
	@PlannedDate				DATETIME,
	@MaterialTypeID				INT,
	@SiteID						INT
)
AS BEGIN
    SET NOCOUNT ON;

	DECLARE @TestTypeID INT = 9;
	DECLARE @FileID INT, @BrStationCode NVARCHAR(10), @CountryCode NVARCHAR(10), @CropCode NVARCHAR(10), @SyncCode NVARCHAR(10);
	DECLARE @Source NVARCHAR(50), @ImportLevel NVARCHAR(50);
	DECLARE @Sample TABLE(ID INT);
	DECLARE @TestMaterial TABLE(ID INT IDENTITY(1,1), TestMaterialID INT);
	DECLARE @LinkTestMaterial TABLE (ID INT, [NewID] INT, [OldID] INT);
	DECLARE @SampleTest TABLE (ID INT IDENTITY(1,1), SampleTestID INT);
	DECLARE @LinkSampleTest TABLE (ID INT, [NewID] INT, [OldID] INT);
	DECLARE @MaterialPlant TABLE (ID INT IDENTITY(1,1), MatPlantID INT);
	DECLARE @LinkMaterial TABLE (ID INT, [NewID] INT, [OldID] INT);

	--validation for SourceID
	IF NOT EXISTS(SELECT TestID FROM Test WHERE TestID = @SourceID )
	BEGIN
		EXEC PR_ThrowError 'Invalid Source configuration.';
		RETURN;
	END

	SELECT 
		@FileID = FileID, 
		@BrStationCode = BreedingStationCode,
		@CountryCode = CountryCode,
		@SyncCode = SyncCode,
		@Source = [RequestingSystem],
		@ImportLevel = ImportLevel
	FROM Test WHERE TestID = @SourceID -- @SourceID carries original testid

	IF (ISNULL(@FileID,0) = 0)
	BEGIN
		EXEC PR_ThrowError 'File information missing for existing configuration.';
		RETURN;
	END

	SELECT @CropCode = CropCode FROM [File] WHERE FileID = @FileID

	IF EXISTS(SELECT FileTitle FROM [File] F 
		JOIN Test T ON T.FileID = F.FileID WHERE T.BreedingStationCode = @BrStationCode AND F.CropCode = @CropCode AND T.TestName =@TestName) 
	BEGIN
		EXEC PR_ThrowError 'File already exists.';
		RETURN;
	END

	--validation for siteID
	IF NOT EXISTS(SELECT SiteID FROM [SiteLocation] WHERE SiteID = @SiteID )
	BEGIN
		EXEC PR_ThrowError 'Invalid Lab location.';
		RETURN;
	END

	IF(ISNULL(@TestTypeID,0) <> 9) 
	BEGIN
		EXEC PR_ThrowError 'Invalid Testtype.';
		RETURN;
	END

	IF NOT EXISTS(SELECT TestProtocolID FROM TestProtocol WHERE TestProtocolID = @TestProtocolID )
	BEGIN
		EXEC PR_ThrowError 'Invalid Method.';
		RETURN;
	END

	IF NOT EXISTS(SELECT MaterialTypeID FROM MaterialType WHERE MaterialTypeID = @MaterialTypeID )
	BEGIN
		EXEC PR_ThrowError 'Invalid Material Type.';
		RETURN;
	END

    BEGIN TRY
		BEGIN TRANSACTION;
			
			--Create Test
			INSERT INTO [Test]([TestTypeID],[FileID],[RequestingSystem],[RequestingUser],[TestName],[CreationDate],[StatusCode],[BreedingStationCode],
			[SyncCode], [ImportLevel], CountryCode, TestProtocolID, PlannedDate, MaterialTypeID, SiteID, RearrangePlateFilling)
			VALUES(@TestTypeID, @FileID, @Source, @UserID, @TestName, GETUTCDATE(), 100, @BrStationCode, 
			@SyncCode, CASE WHEN ISNULL(@ImportLevel,'') ='Plot' THEN 'Plot' ELSE 'CROSSES/SELECTION' END, @CountryCode, @TestProtocolID,@PlannedDate, @MaterialTypeID, @SiteID, 0);
			--Get Last inserted testid
			SELECT @TestID = SCOPE_IDENTITY();
			
			--Create TestMaterial
			INSERT TestMaterial(TestID,MaterialID,NrOfPlants)
			OUTPUT INSERTED.TestMaterialID INTO @TestMaterial(TestMaterialID)
			SELECT @TestID, MaterialID, NrOfPlants FROM TestMaterial WHERE TestID = @SourceID

			--Create Link between new primary key and old primary key
			INSERT @LinkTestMaterial(ID, [NewID], [OldID])
			SELECT 
				T1.ID,
				[NewID] = T1.TestMaterialID,
				[OldID] = T2.TestMaterialID
			FROM @TestMaterial T1
			JOIN 
			(
				SELECT 
					ROW_NUMBER() OVER(ORDER BY TestMaterialID ASC) AS Row#,
					TestMaterialID 
				FROM TestMaterial WHERE TestID = @SourceID
			) T2 ON T1.ID = T2.Row#

			--Create Sample
			INSERT LD_Sample(SampleName)			
			OUTPUT INSERTED.SampleID INTO @Sample (ID)
			SELECT SampleName FROM LD_Sample S
			JOIN LD_SampleTest ST ON ST.SampleID = S.SampleID
			WHERE ST.TestID = @SourceID


			--Create SampleTest
			INSERT LD_SampleTest (TestID, SampleID)
			OUTPUT INSERTED.SampleTestID INTO @SampleTest(SampleTestID)
			SELECT @TestID, ID FROM @Sample
						
			INSERT @LinkSampleTest(ID, [NewID], [OldID])
			SELECT 
				T1.ID,
				[NewID] = T1.SampleTestID,
				[OldID] = T2.SampleTestID
			FROM @SampleTest T1
			JOIN 
			(
				SELECT 
					ROW_NUMBER() OVER(ORDER BY SampleTestID ASC) AS Row#,
					SampleTestID 
				FROM LD_SampleTest WHERE TestID = @SourceID
			) T2 ON T1.ID = T2.Row#

			--Create MaterialPlant			
			INSERT LD_MaterialPlant(TestMaterialID, [Name])
			OUTPUT INSERTED.MaterialPlantID INTO @MaterialPlant(MatPlantID)
			SELECT L1.[NewID], MP.[Name]  FROM @LinkTestMaterial L1
			JOIN LD_MaterialPlant MP ON MP.TestMaterialID = L1.OldID

			INSERT @LinkMaterial(ID, [NewID], [OldID])
			SELECT 
				T1.ID,
				[NewID] = T1.MatPlantID,
				[OldID] = T2.MaterialPlantID
			FROM @MaterialPlant T1
			JOIN 
			(
				SELECT 
					ROW_NUMBER() OVER(ORDER BY MaterialPlantID ASC) AS Row#,
					MaterialPlantID 
				FROM LD_MaterialPlant MP
				JOIN TestMaterial TM ON TM.TestMaterialID = MP.TestMaterialID WHERE TestID = @SourceID
			) T2 ON T1.ID = T2.Row#

			--Create SampleTestMaterial
			INSERT INTO LD_SampleTestMaterial(SampleTestID, MaterialPlantID)
			SELECT LST.[NewID], LM.[NewID] FROM LD_SampleTestMaterial STM
			JOIN @LinkSampleTest LST ON LST.[OldID] = STM.SampleTestID
			JOIN @LinkMaterial LM ON LM.[OldID] = STM.MaterialPlantID 
			WHERE SampleTestID IN (SELECT SampleTestID FROM LD_SampleTest WHERE TestID = @SourceID)

			--SELECT LST.[NewID], LM.[NewID], * FROM @LinkMaterial LM
			--JOIN LD_MaterialPlant MP ON MP.MaterialPlantID = LM.OldID
			--JOIN TestMaterial TM ON TM.TestMaterialID = MP.TestMaterialID
			--JOIN LD_SampleTest ST ON ST.TestID = TM.TestID
			--JOIN LD_SampleTestMaterial STM ON STm.MaterialPlantID = LM.OldID AND STM.MaterialPlantID = MP.MaterialPlantID
			--JOIN @LinkSampleTest LST On LST.OldID = ST.SampleTestID
			--WHERE TM.TestID = @SourceID

		COMMIT;
	END TRY
	BEGIN CATCH
	   IF @@TRANCOUNT > 0 
		ROLLBACK;
	   THROW;
	END CATCH
END
GO


