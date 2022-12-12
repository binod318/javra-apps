DROP PROCEDURE IF EXISTS PR_LFDISK_DeleteSampleTest
GO
/*
Author					Date			Description
Krishna Gautam			2021/06/03		SP created to delete sample.
===================================Example================================
EXEC PR_LFDISK_DeleteSampleTest 12764, '654,646'
*/
CREATE PROCEDURE [dbo].[PR_LFDISK_DeleteSampleTest]
(
	@TestID INT,
	@SelectedMaterial NVARCHAR(MAX)
)
AS
BEGIN

	DECLARE @SampleIDs TABLE(SampleID INT);

	DELETE ST 
	OUTPUT deleted.SampleID INTO @SampleIDs
	FROM LD_SampleTest ST
	JOIN string_split(@SelectedMaterial,',') T1 ON T1.value = ST.SampleTestID;

	DELETE S FROM LD_Sample S 
	JOIN @SampleIDs T1 ON T1.SampleID = S.SampleID
END