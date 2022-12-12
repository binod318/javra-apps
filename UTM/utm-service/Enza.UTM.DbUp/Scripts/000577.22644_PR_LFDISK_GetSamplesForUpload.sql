--EXEC PR_LFDISK_GetSamplesForUpload 13749;
ALTER PROCEDURE [dbo].[PR_LFDISK_GetSamplesForUpload]
(
	@TestID		INT
) AS BEGIN
	SET NOCOUNT ON;
	DECLARE @ImportType NVARCHAR(50), @MaterialExist BIT, @DeterminationExist BIT;

	IF NOT EXISTS(SELECT TestID FROM Test WHERE TestID = @TestID)
	BEGIN
		EXEC PR_ThrowError N'Invalid Test.';
		RETURN;
	END

	IF NOT EXISTS(SELECT TestID FROM Test WHERE TestID = @TestID AND TestTypeID = 9)
	BEGIN
		EXEC PR_ThrowError N'Invalid TestType.';
		RETURN;
	END

	IF NOT EXISTS(SELECT TestID FROM Test WHERE TestID = @TestID AND StatusCode < 500)
	BEGIN
		EXEC PR_ThrowError N'Invalid Test Status.';
		RETURN;
	END

	--Validate if there is sample added to test
	IF NOT EXISTS(SELECT TestID FROM LD_SampleTest WHERE TestID = @TestID)
	BEGIN
		EXEC PR_ThrowError N'No Sample attached to this Test. Please add Sample before sending to LIMS!';
		RETURN;
	END

	--Validate if all the samples have QRCode
	--IF EXISTS(SELECT SampleID FROm LD_Sample WHERE SampleID IN ( SELECT SampleID FROM LD_SampleTest WHERE TestID = @TestID) AND ISNULL(ReferenceCode,'') = '' )
	--BEGIN
	--	EXEC PR_ThrowError N'Not all the Samples have QR code filled. Please fill the QR Code for all Samples!';
	--	RETURN;
	--END
	
	--Validate if all the samples have material(s) added
	SELECT
		@MaterialExist = CASE WHEN STM.SampleTestID IS NULL THEN 0 ELSE 1 END
	FROM LD_SampleTest ST
	LEFT JOIN LD_SampleTestMaterial STM ON STM.SampleTestID = ST.SampleTestID
	WHERE ST.TestID = @TestID

	IF (@MaterialExist = 0)
	BEGIN
		EXEC PR_ThrowError N'Material(s) are not added for few Samples. Please fill the Sample or delete the Sample!';
		RETURN;
	END

	--Validate if all the samples have determination(s) added
	SELECT
		@DeterminationExist = CASE WHEN STD.SampleTestID IS NULL THEN 0 ELSE 1 END
	FROM LD_SampleTest ST
	LEFT JOIN LD_SampleTestDetermination STD ON STD.SampleTestID = ST.SampleTestID
	WHERE ST.TestID = @TestID

	IF (@DeterminationExist = 0)
	BEGIN
		EXEC PR_ThrowError N'Determination(s) are not used for few Samples. Please fill the Sample or delete the Sample!';
		RETURN;
	END

	SELECT
		F.CropCode AS 'Crop',
		T.BreedingStationCode AS 'BrStation',
		T.TestID AS 'RequestID',
		SL.SiteName AS 'Site',
		'UTM' AS 'RequestingSystem',
		STD.SampleTestDetID,
		ST.SampleID,
		D.OriginID AS 'DeterminationID', --STD.DeterminationID
		ISNULL(D.DeterminationName,'') AS 'MethodCode',
		S.SampleName,
		S.ReferenceCode--, --this is qr code		
	FROM Test T
	JOIN [File] F ON F.FileID = T.FileID	
	JOIN SiteLocation SL ON SL.SiteID = T.SiteID
	JOIN LD_SampleTest ST On ST.TestID = T.TestID
	JOIN LD_Sample S ON S.SampleID = ST.SampleID
	JOIN LD_SampleTestDetermination STD ON STD.SampleTestID = ST.SampleTestID
	JOIN Determination D ON D.DeterminationID = STD.DeterminationID	
	WHERE T.TestID = @TestID

END
