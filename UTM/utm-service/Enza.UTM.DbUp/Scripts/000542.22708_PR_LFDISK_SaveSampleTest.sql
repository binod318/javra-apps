/*
Author					Date			Description
Binod Gurung			2021/06/08		Save Plots to sample
Krishna Gautam			2021/06/29		Change service to prevent giving duplicate sample name for atleast same test.
===================================Example================================
EXEC [PR_LFDISK_SaveSampleTest] 12701, 'PSample',5
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
	DECLARE @ExistingSample TABLE(SampleID INT, SampleName NVARCHAR(MAX));
	DECLARE @SampleToCreate TABLE(SampleName NVARCHAR(MAX));
	DECLARE @CustName NVARCHAR(50), @Counter INT = 1, @StatusCode INT;
	DECLARE @DuplicateNameFound BIT;
	
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
	--get name for number of samples
	IF(ISNULL(@SampleID,0) = 0)
	BEGIN
		--get already existing samples
		INSERT INTO @ExistingSample(SampleID, SampleName)
		SELECT 
			S.SampleID,
			S.SampleName 
		FROM LD_Sample S
		JOIN LD_SampleTest ST ON S.SampleID = ST.SampleID
		WHERE ST.TestID  = @TestID

		IF(@NrOfSamples <=1)
		BEGIN
			
			SET @CustName = @SampleName;
			SELECT @DuplicateNameFound = CASE WHEN ISNULL(COUNT(SampleID),0) > 0 THEN 1 ELSE 0 END  FROM @ExistingSample WHERE SampleName = @CustName;
			WHILE(ISNULL(@DuplicateNameFound,0) <> 0)
			BEGIN
			
				IF(@NrOfSamples >=1000)
					RETURN;
				IF(@NrOfSamples >= 100)
					SET @CustName = @SampleName + '-' + RIGHT('000'+CAST(@Counter AS NVARCHAR(10)),3);
				ELSE IF(@NrOfSamples >= 10)
					SET @CustName = @SampleName + '-' + RIGHT('00'+CAST(@Counter AS NVARCHAR(10)),2);
				ELSE
					SET @CustName = @SampleName + '-' + CAST(@Counter AS NVARCHAR(10));
				--get name with counter value
				SELECT @DuplicateNameFound = CASE WHEN ISNULL(COUNT(SampleID),0) > 0 THEN 1 ELSE 0 END  FROM @ExistingSample WHERE SampleName = @CustName;
				--increase counter after that.
				SET @Counter = @Counter + 1;
			END
			INSERT INTO @SampleToCreate(SampleName)
			Values(@CustName);

		END
		--When more than 1 material required
		ELSE
		BEGIN
			--this loop is necessary for avoiding same name
			WHILE ( @Counter <= @NrOfSamples)
			BEGIN	
				SET @DuplicateNameFound = 1;
				WHILE(ISNULL(@DuplicateNameFound,0) <> 0)
				BEGIN
					IF(@Counter >=1000)
						RETURN;

					SET @CustName = @SampleName + '-' + CAST(@Counter AS NVARCHAR(10));

					--Check if same name exists if exists then increase the sample name
				
					SELECT @DuplicateNameFound = CASE WHEN ISNULL(COUNT(SampleID),0) > 0 THEN 1 ELSE 0 END  FROM @ExistingSample WHERE SampleName = @CustName;
					IF(ISNULL(@DuplicateNameFound,0) <> 0)
					BEGIN
						--increase both counter to get new name
						SET @Counter  = @Counter  + 1
						SET @NrOfSamples = @NrOfSamples +1;
					END
				END

				INSERT INTO @SampleToCreate(SampleName)
				Values(@CustName);
				SET @Counter  = @Counter  + 1
			END
		END
		INSERT INTO LD_Sample(SampleName)
		OUTPUT inserted.SampleID INTO @Sample
		SELECT SampleName FROM @SampleToCreate;

		INSERT INTO LD_SampleTest(SampleID,TestID)
		SELECT ID, @TestID FROM @Sample;

	END
	--rename sample name
	ELSE
	BEGIN

		UPDATE LD_Sample
		SET SampleName = @SampleName
		WHERE SampleID = @SampleID

	END

END
