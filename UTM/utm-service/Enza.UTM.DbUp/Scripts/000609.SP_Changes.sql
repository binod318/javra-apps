
/*
Author					Date				Description
KRIAHNA GAUTAM			2021-11-23			SP created.

============Example===================
EXEC PR_SH_TestToExcelForExport 14761
*/
ALTER PROCEDURE [dbo].[PR_SH_TestToExcelForExport]
(
	@TestID INT
)
AS
BEGIN
	
	--This query can be used for sql server 2017 or later
	/*
	SELECT 
		Customer = 569,
		[Article Name] = MAX(T.TestName),
		Crop = MAX(F.CropCode),
		LotNumber = '',
		Process = MAX(T.LotSampleType),
		Planner = 'SH',
		[Sample quantity] = '',
		Determinations = STRING_AGG(D.DeterminationName, ', ')
	FROM [Test] T
	JOIN [File] F ON F.FileID = T.FileID
	JOIN LD_SampleTest ST ON ST.TestID = T.TestID
	JOIN LD_SampleTestDetermination STD ON STD.SampleTestID = ST.SampleTestID
	JOIN Determination D ON D.DeterminationID = STD.DeterminationID
	WHERE T.TestID = @TestID
	GROUP BY ST.SampleTestID;
	*/


	--query for sqlserver 2016 and earlier
	SELECT 
		Customer = 569,
		[Article Name] = MAX(T.TestName),
		Crop = MAX(F.CropCode),
		[Sample ID] = ST.SampleTestID,
		Process = MAX(T.LotSampleType),
		Planner = 'SH',
		[Sample quantity] = MAX(S.Quantity),
		Determinatons = STUFF( 
									(SELECT ', ' + D.DeterminationName 
										FROM Determination D
										JOIN LD_SampleTestDetermination STD ON STD.DeterminationID = D.DeterminationID
									WHERE ST.SampleTestID = STD.SampleTestID
									FOR XML PATH(''))
									,1,1,'')
	FROM [Test] T
	JOIN [File] F ON F.FileID = T.FileID
	JOIN LD_SampleTest ST ON ST.TestID = T.TestID
	JOIN LD_Sample S ON S.SampleID = ST.SampleID
	WHERE T.TestID = @TestID
	GROUP BY ST.SampleTestID;

END
GO