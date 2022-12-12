DROP PROCEDURE IF EXISTS [dbo].[PR_SH_GetDataToPrint]
GO


CREATE PROCEDURE [dbo].[PR_SH_GetDataToPrint]
(
	@TestID INT
)
AS
BEGIN

	SELECT 
		TestID = @TestID,
		TestName = MAX(T.TestName),
		STD.DeterminationID,
		DeterminationName = MAX(D.DeterminationName),
		SampleID = MAX(S.SampleID),
		SampleName = MAX(S.SampleName)
	FROM LD_SampleTestDetermination STD
	JOIN LD_SampleTest ST ON STD.SampleTestID = ST.SampleTestID
	JOIN LD_Sample S ON ST.SampleID = S.SampleID
	JOIN Test T ON T.TestID = ST.TestID
	JOIN Determination D ON D.DeterminationID = STD.DeterminationID
	WHERE T.TestID = @TestID
	GROUP BY STD.DeterminationID, STD.SampleTestID

END
GO


