DROP PROCEDURE IF EXISTS PR_LFDISK_GetSample
GO
/*
=============================================
Author:					Date				Remark
Krishna Gautam			2021/06/17			SP Created.
=========================================================================

EXEC PR_LFDISK_GetSample 10625
*/

CREATE PROCEDURE [dbo].[PR_LFDISK_GetSample]
(
	@TestID INT
)
AS
BEGIN

	SELECT 
		ST.SampleID, 
		S.SampleName 
	FROM LD_Sample S
	JOIN LD_SampleTest ST ON S.SampleID = ST.SampleID
	WHERE ST.TestID = @TestID;
END