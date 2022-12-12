/*
Changed By			DATE				Description

Krishna Gautam		-					Stored procedure created	
Krishna Gautam		2021-05-15			#21378: Change in service to cancel test
Krishna Gautam		2021-05-18			#21381: Change in service to update max plants on test.

*/

ALTER PROCEDURE [dbo].[PR_SaveTestMaterialDetermination_ForRDT]
(
	@TestTypeID								INT,
	@TestID									INT,
	@Columns								NVARCHAR(MAX) = NULL,
	@Filter									NVARCHAR(MAX) = NULL,
	@TVPTestWithExpDate TVP_TMD_WithDate	READONLY,
	@Determinations TVP_Determinations		READONLY,
	@TVPProperty TVP_PropertyValue			READONLY
) AS BEGIN
	SET NOCOUNT ON;
	DECLARE @FileName NVARCHAR(100);
	DECLARE @Tbl TABLE (MaterialID INT, MaterialKey NVARCHAR(50));
	DECLARE @CropCode	NVARCHAR(10),@TestType1 INT,@StatusCode INT;
	DECLARE @FileID		INT;


	BEGIN TRY
		BEGIN TRANSACTION;
		SELECT 
			@FileID = F.FileID,
			@FileName = F.FileTitle,
			@CropCode = CropCode,
			@TestType1 = T.TestTypeID,
			@StatusCode = T.StatusCode
		FROM [File] F
		JOIN Test T ON T.FileID = F.FileID AND T.RequestingUser = F.UserID 
		WHERE T.TestID = @TestID --AND F.UserID = @UserID;

		IF(ISNULL(@FileName, '') = '') BEGIN
			EXEC PR_ThrowError 'Specified file not found';
			RETURN;
		END
		IF(ISNULL(@CropCode,'')='')
		BEGIN
			EXEC PR_ThrowError 'Specified crop not found';
			RETURN;
		END
		--Prevent changing testType when user choose different type of test after creating test.
		IF(ISNULL(@TestTypeID,0) <> ISNULL(@TestType1,0)) BEGIN
			EXEC PR_ThrowError 'Cannot assign different test type for already created test.';
			RETURN;
		END


		--Prevent asigning determination when status is changed to point of no return
		IF(ISNULL(@StatusCode,0) >=200)
		BEGIN
			IF EXISTS (SELECT 1 FROM @Determinations) BEGIN	
				EXEC PR_ThrowError 'Cannot assign determination for test already sent to LIMS.';
				RETURN;
			END
			
		END

		IF EXISTS (SELECT 1 FROM @Determinations) BEGIN	
			EXEC  PR_SaveTestMaterialDeterminationWithQuery_ForRDT @FileID, @CropCode, @TestID, @Columns, @Filter, @Determinations
		END
		ELSE BEGIN
			EXEC PR_SaveTestMaterialDeterminationWithTVP_ForRDT @CropCode, @TestID, @TVPTestWithExpDate, @TVPProperty
		END

		--IF EXISTS(SELECT TestID FROM Test WHERE StatusCode = 300 AND TestID = @TestID) BEGIN
		--	EXEC PR_Update_TestStatus @TestID, 350;
		--END
		SELECT TestID, StatusCode 
		FROM Test WHERE TestID = @TestID;

		COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION;
		THROW;
	END CATCH	
END
