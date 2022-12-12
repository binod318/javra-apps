
/*
Author							Date				Description
Krishna Gautam					2021/07/01			#22645:Sp created to export result to excel file.


=================Example===============
EXEC PR_LFDISK_GetResultToExcel 12725;
*/

ALTER PROCEDURE [dbo].[PR_LFDISK_GetResultToExcel]
(
	@TestID INT
)
AS
BEGIN
	DECLARE @SelectColumns NVARCHAR(MAX);
	DECLARE @ColumnsID NVARCHAR(MAX);
	DECLARE @Query NVARCHAR(MAX);

	SELECT 
		@SelectColumns = COALESCE(@SelectColumns+ ',','') + QUOTENAME(D.DeterminationID) +' AS '+ QUOTENAME(MAX(DeterminationName)),
		@ColumnsID = COALESCE(@ColumnsID+ ',','') + QUOTENAME(D.DeterminationID)
	FROM LD_TestResult TR 
	JOIN LD_SampleTest ST ON ST.SampleTestID = TR.SampleTestID
	JOIN Determination D ON D.DeterminationID = TR.DeterminationID
	WHERE ST.TestID = @TestID
	GROUP BY D.DeterminationID ;


	IF(ISNULL(@SelectColumns,'') <> '')
	BEGIN
		SET @Query = '
		SELECT S.SampleName, '+@SelectColumns +' FROM LD_Sample S
		JOIN LD_SampleTest ST ON S.SampleID = ST.SampleID
		LEFT JOIN 
		(
			SELECT *
			FROM
			(
				SELECT TR.SampleTestID,Score,DeterminationID FROM 
				LD_TestResult TR 
				JOIN LD_SampleTest ST ON ST.SampleTestID = TR.SampleTestID
				WHERE ST.TestID = @TestID
			) SRC
			PIVOT
			(
				MAX(Score)
				FOR DeterminationID IN ('+@ColumnsID+')
			) PIV
		
		)T ON T.SampleTestID = ST.SampleTestID
		WHERE ST.TestID = @TestID'

	END

	ELSE
	BEGIN
		SET @Query = '
		SELECT S.SampleName FROM LD_Sample S
		JOIN LD_SampleTest ST ON S.SampleID = ST.SampleID
		WHERE ST.TestID = @TestID'

	END


	EXEC sp_executesql @Query, N'@TestID INT', @TestID;
END