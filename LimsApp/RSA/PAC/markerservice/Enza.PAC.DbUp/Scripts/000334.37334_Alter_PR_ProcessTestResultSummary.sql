DROP TYPE IF EXISTS [dbo].[TVP_Marker_Score]
GO

CREATE TYPE [dbo].[TVP_Marker_Score] AS TABLE(
	RowNr INT, 
	MarkerID INT, 
	Score NVARCHAR(10)
)
GO

DROP PROCEDURE IF EXISTS [dbo].[PR_ProcessTestResultSummary]
GO

--EXEC PR_ProcessTestResultSummary 1864376;
CREATE PROCEDURE [dbo].[PR_ProcessTestResultSummary]
(
    @DetAssignmentID INT
) AS BEGIN
    SET NOCOUNT ON;
    DECLARE @TransCount BIT = 0;	
	DECLARE @TempTbl TVP_Marker_Score;
	    
    DECLARE @SQL NVARCHAR(MAX), @Columns NVARCHAR(MAX), @Columns2 NVARCHAR(MAX);
	
	IF NOT EXISTS(SELECT DetAssignmentID FROM DeterminationAssignment WHERE DetAssignmentID = @DetAssignmentID AND StatusCode = 500)
	  RETURN;

    SELECT
	   @Columns = COALESCE(@Columns + ',', '') + QUOTENAME(MarkerID),
	   @Columns2 = COALESCE(@Columns2 + ',', '') + QUOTENAME(MarkerID) + ' NVARCHAR(20)'
    FROM
    (
	   SELECT DISTINCT 
		  TR.MarkerID    
	   FROM TestResult TR
	   JOIN Well W ON W.WellID = TR.WellID
	   WHERE W.DetAssignmentID = @DetAssignmentID
    ) C
	ORDER BY C.MarkerID;

	INSERT @TempTbl(RowNr, MarkerID, Score)
	SELECT 
		RowNr = ROW_NUMBER() OVER(PARTITION BY TR.MarkerID ORDER BY W.WellID),
		TR.MarkerID,
		TR.Score
	FROM TestResult TR
	JOIN Well W ON W.WellID = TR.WellID
	WHERE W.DetAssignmentID = @DetAssignmentID;	
	
    SET @SQL = N'	
				WITH CTE AS
				(
				   SELECT 
					  ID = ROW_NUMBER() OVER(ORDER BY NrOfSample),
					  *
				   FROM
				   (
					  SELECT '+ @Columns + N', 
						 NrOfSample = COUNT(RowNr)
					  FROM
					  (
						 SELECT * FROM @TempTbl
						 PIVOT
						 (
							MAX(Score)
							FOR MarkerID IN('+ @Columns + N')
						 ) P1
					  ) V2 GROUP BY '+ @Columns + 
				   N') T1
				)
				SELECT 
				  ID,
				  NrOfSample,
				  Details = 
				  (
					  SELECT
						 *
					  FROM CTE
					  WHERE ID = T.ID
					  FOR JSON PATH
				  )
				FROM CTE T';

    BEGIN TRY
	   IF @@TRANCOUNT = 0 BEGIN
		  BEGIN TRANSACTION;
		  SET @TransCount = 1;
	   END

	   DECLARE @tbl TABLE(ID INT, NrOfSamples INT, Details NVARCHAR(MAX));
	   DECLARE @Pattern PatternTVP;

	   --Delete existing pattern and pattern results before creating new one
	   DELETE PR FROM Pattern P
	   JOIN PatternResult PR ON PR.PatternID = P.PatternID
	   WHERE P.DetAssignmentID = @DetAssignmentID

	   DELETE FROM Pattern
	   WHERE DetAssignmentID = @DetAssignmentID

	   INSERT @tbl(ID, NrOfSamples, Details)
	   EXEC sp_executesql @SQL, N'@DetAssignmentID INT, @TempTbl TVP_Marker_Score READONLY', @DetAssignmentID, @TempTbl;
	   
	   MERGE Pattern T
	   USING @tbl S ON 1 = 0
	   WHEN NOT MATCHED THEN
		  INSERT(DetAssignmentID, NrOfSamples, SamplePer, [Type], MatchingVar)
		  VALUES(@DetAssignmentID, S.NrOfSamples, 0, '', '')
	   OUTPUT INSERTED.PatternID, S.Details INTO @Pattern;

	   SET @SQL = N'
	   SELECT 
		  UP.PatternID,
		  UP.MarkerID,
		  UP.Score
	   FROM
	   (
		  SELECT 
			 P.PatternID,
			 P2.*
		  FROM @Pattern P
		  CROSS APPLY OPENJSON(P.Details) WITH (' + @Columns2 + N') P2
	   ) T UNPIVOT
	   (
		  Score
		  FOR MarkerID IN (' + @Columns + N')
	   ) UP';

	   INSERT PatternResult(PatternID, MarkerID, Score)
	   EXEC sp_executesql @SQL, N'@Pattern PatternTVP READONLY', @Pattern;

	   IF @TransCount = 1 
		  COMMIT;
    END TRY
    BEGIN CATCH
	   IF @TransCount = 1 
		  ROLLBACK;
	   THROW;
    END CATCH
END
GO


