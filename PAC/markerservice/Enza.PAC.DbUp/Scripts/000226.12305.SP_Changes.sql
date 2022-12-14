DROP PROCEDURE IF EXISTS [dbo].[PR_ProcessTestResultSummary]
GO

--EXEC PR_ProcessTestResultSummary 835633;
CREATE PROCEDURE [dbo].[PR_ProcessTestResultSummary]
(
    @DetAssignmentID INT
) AS BEGIN
    SET NOCOUNT ON;
    DECLARE @TransCount BIT = 0;
    
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
			 SELECT * FROM
			 (
				SELECT 
				    RowNr = ROW_NUMBER() OVER(PARTITION BY TR.MarkerID ORDER BY W.WellID),
				    TR.MarkerID,
				    TR.Score
				FROM TestResult TR
				JOIN Well W ON W.WellID = TR.WellID
				WHERE W.DetAssignmentID = @DetAssignmentID
			 ) V1
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
	   EXEC sp_executesql @SQL, N'@DetAssignmentID INT', @DetAssignmentID;
	   
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


DROP PROCEDURE IF EXISTS [dbo].[PR_ReceiveResultsinKscoreCallback]
GO


/*

Author					Date			Remarks
Binod Gurung			-				-
Krishna Gautam			2020/01/20		Change on stored procedure to adjust logic of data is sent to LIMS for retest for specific determination but in response we get all result of that folder back.
Binod Gurung			2020/04/14		Delete existing test result before creating new. Test result also created for status 500 because when no result
										is recieved then status still goes to 500 and when result is sent again from LIMS for that test then result 
										should be stored.

============ExAMPLE===================
DECLARE  @DataAsJson NVARCHAR(MAX) = N'[{"LIMSPlateID":21,"MarkerNr":67,"AlleleScore":"0101","Position":"A01"}]'
EXEC PR_ReceiveResultsinKscoreCallback 331, @DataAsJson
*/
CREATE PROCEDURE [dbo].[PR_ReceiveResultsinKscoreCallback]
(
    @RequestID	 INT, --TestID
    @DataAsJson NVARCHAR(MAX)
) AS BEGIN
	
    SET NOCOUNT ON;
    BEGIN TRY
		BEGIN TRANSACTION;

		--Delete existing test result before creating new
		DELETE TR FROM Test T
		JOIN Plate P ON P.TestID = T.TestID
		JOIN Well W ON W.PlateID = P.PlateID
		JOIN TestResult TR ON TR.WellID = W.WellID
		WHERE T.TestID = @RequestID

		INSERT TestResult (WellID, MarkerID, Score, CreationDate)
		SELECT WellID, MarkerNr, AlleleScore, CreationDate
		FROM
		(	
			SELECT 
				W.WellID,
				T1.MarkerNr, 
				T1.AlleleScore,
				T1.CreationDate,
				W.DetAssignmentID				
			FROM OPENJSON(@DataAsJson) WITH
			(
				LIMSPlateID	INT,
				MarkerNr	INT,
				AlleleScore	NVARCHAR(20),
				Position	NVARCHAR(20),
				CreationDate DATETIME
			) T1
			JOIN Well W ON W.Position = T1.Position 
			JOIN Plate P ON P.PlateID = W.PlateID AND P.LabPlateID = T1.LIMSPlateID 
			JOIN DeterminationAssignment DA ON DA.DetAssignmentID = W.DetAssignmentID	
			JOIN 
			(
				SELECT T.DetAssignmentID, MarkerID FROM
				(
					SELECT MTB.MarkerID, DetAssignmentID FROM MarkerToBeTested MTB
					UNION
					SELECT MarkerID, DA.DetAssignmentID FROM MarkerPerVariety MPV
					JOIN DeterminationAssignment DA ON DA.VarietyNr = MPV.VarietyNr
					WHERE MPV.StatusCode = 100
				) T
				JOIN TestDetAssignment TDA On TDA.DetAssignmentID = T.DetAssignmentID
				WHERE TDA.TestID = @RequestID
				GROUP BY T.DetAssignmentID, MarkerID
			) MTB ON MTB.DetAssignmentID = DA.DetAssignmentID AND MTB.MarkerID = T1.MarkerNr	--store result only for the requested marker	
			WHERE P.TestID = @RequestID AND DA.StatusCode IN (400,500,650)						--store result only when status is InLIMS or Received or Re-test
			GROUP BY W.WellID, T1.MarkerNr, T1.AlleleScore, T1.CreationDate, W.DetAssignmentID
		) S;

		--update test status
		UPDATE Test SET StatusCode = 500 WHERE TestID = @RequestID;

		--update determination assignment status
		UPDATE DA
			SET DA.StatusCode = 500
		FROM DeterminationAssignment DA
		JOIN TestDetAssignment TDA ON TDA.DetAssignmentID = DA.DetAssignmentID
		WHERE TDA.TestID = @RequestID AND DA.StatusCode IN (400,500,650)	 --InLIMS or Received or Re-test  
	   
	   COMMIT;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
            ROLLBACK;
		THROW;
	END CATCH    
END
GO


