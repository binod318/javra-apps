DROP PROCEDURE IF EXISTS [dbo].[PR_LFDISK_GetPrintLabels]
GO



-- EXEC PR_LFDISK_GetPrintLabels 87
CREATE PROCEDURE [dbo].[PR_LFDISK_GetPrintLabels]
(
	@TestID	INT
) AS BEGIN
	SET NOCOUNT ON;

	DECLARE @StatusCode INT, @TesttypeID INT;

	SELECT @StatusCode = StatusCode, @TesttypeID = TestTypeID  FROM Test WHERE TestID = @TestID;
	
	IF(ISNULL(@StatusCode,0) < 150)
	BEGIN
		EXEC PR_ThrowError 'Invalid TestID.';
		RETURN;
	END

	IF(ISNULL(@TesttypeID,0) <> 9)
	BEGIN
		EXEC PR_ThrowError 'Invalid Test.';
		RETURN;
	END


	SELECT 
		F.CropCode,
		S.SampleName
	FROM [File] F
	JOIN Test T On T.FileID = F.FileID
	JOIN LD_SampleTest ST ON ST.TestID = T.TestID
	JOIN LD_Sample S ON S.SampleID = ST.SampleID
	WHERE T.TestID = @TestID

END
GO


