DROP PROCEDURE IF EXISTS [dbo].[PR_FindMatchingVarietiesForPattern]
GO

/*
============================================================================
Author					Date			Description
Binod Gurung			2020/10/18		Find matching varieties in bulk for pattern
=========================================================================	
	EXEC PR_FindMatchingVarietiesForPattern 32323 43434 'TO'
*/
CREATE PROCEDURE [dbo].[PR_FindMatchingVarietiesForPattern]
(
	@DetAssignmentID INT,
	@VarietyNr INT,
	@Crop NVARCHAR(10)
)
AS
BEGIN

	DECLARE @ReturnVarieties NVARCHAR(MAX) ;	

	DECLARE @MarkerTbl Table(ID INT IDENTITY(1,1),MarkerID INT, MarkerValue NVARCHAR(10));
	--DECLARE @Table1 Table(VarietyNr INT); 
	--DECLARE @Table2 Table(VarietyNr INT); 
	DECLARE @FirstMarkerID INT;
	DECLARE @FirstMarkerValue NVARCHAR(20);

	DECLARE @tbl TABLE(ID INT IDENTITY(1, 1), PatternID INT);
	DECLARE @OutputTbl TABLE (PatternID INT, Varieties NVARCHAR(MAX));
	DECLARE @PatternID INT, @ID INT = 1, @Count INT;

	DROP TABLE IF EXISTS #Table1 
	DROP TABLE IF EXISTS #Table2

	CREATE TABLE #Table1
	(VarietyNr INT)
	CREATE CLUSTERED INDEX ix_tempCIndexAft1 ON #Table1 (VarietyNr);
	
	CREATE TABLE #Table2
	(VarietyNr INT)
	CREATE CLUSTERED INDEX ix_tempCIndexAft2 ON #Table2 (VarietyNr);
    
	INSERT @tbl(PatternID)
	SELECT PatternID FROM Pattern where DetAssignmentID = @DetAssignmentID;
	
	SELECT @Count = COUNT(ID) FROM @tbl;
	WHILE(@ID <= @Count) BEGIN

		SELECT 
			@PatternID = PatternID 
		FROM @tbl
		WHERE ID = @ID;

		--Reset
		DELETE FROM @MarkerTbl

		--Insert MarkerID and MarkerVlaue to Table from JSON
		INSERT INTO @MarkerTbl (MarkerID, MarkerValue)
		SELECT MarkerID, Score FROM PatternResult WHERE PatternID = @PatternID
	
		SELECT 
			@FirstMarkerID = MarkerID,
			@FirstMarkerValue = MarkerValue 
		FROM @MarkerTbl WHERE ID = 1;
	
		-- step 2 - Fill temptable from all varieties which has no markervaluepervariety or has markervaluepervariety and is matching
		INSERT INTO #Table1 (VarietyNr)
		(			
			-- find varieties which has matching score 
			SELECT 		
				V.VarietyNr
			FROM Variety V
			JOIN MarkerValuePerVariety MVPV ON MVPV.VarietyNr = V.VarietyNr AND MVPV.MarkerID = @FirstMarkerID AND dbo.FN_IsMatching(@FirstMarkerValue, MVPV.AlleleScore) = 1
			WHERE V.CropCode = @Crop AND V.PacComp = 1 AND V.[Status] NOT IN ('100','999', 'PD', 'GB')
			GROUP BY V.VarietyNr
			UNION
			-- find varieties which has no score
			SELECT		
				V.VarietyNr
			FROM Variety V
			LEFT JOIN MarkerValuePerVariety MVPV ON MVPV.VarietyNr = V.VarietyNr AND MVPV.MarkerID = @FirstMarkerID
			WHERE V.CropCode = @Crop AND MVPV.VarietyNr IS NULL AND V.PacComp = 1 AND V.[Status] NOT IN ('100','999', 'PD', 'GB')
			GROUP BY V.VarietyNr
		)	

		--step 3 - Find varieties from filled temp-table which has mvpv and not matching
		INSERT INTO #Table2 (VarietyNr)
		(
			SELECT		
				MVPV.VarietyNr		
			FROM #Table1 V
			JOIN MarkerValuePerVariety MVPV ON MVPV.VarietyNr = V.VarietyNr 
			JOIN @MarkerTbl MT ON MT.MarkerID = MVPV.MarkerID AND dbo.FN_IsMatching(MT.Markervalue, MVPV.AlleleScore) = 0
			WHERE MT.ID <> 1
			GROUP BY MVPV.VarietyNr
		) 

		--Delete all records from #Table1 found in #Table2 because these are varieties that has score but not matching
		DELETE T1 
		FROM #Table1 T1
		JOIN #Table2 T2 ON T2.VarietyNr = T1.VarietyNr

		--step 4 - Place input varieties at first in the list 
		IF EXISTS (SELECT VarietyNr FROM #Table1 WHERE VarietyNr = @VarietyNr)
		BEGIN
			SET @ReturnVarieties = @VarietyNr;
			DELETE FROM #Table1 WHERE VarietyNr = @VarietyNr;
		END;

		--step 5 - Return Varities in comma separated list
		SELECT @ReturnVarieties = COALESCE( @ReturnVarieties + ',' + CAST(VarietyNr AS NVARCHAR(20)), '') 
		FROM #Table1

		INSERT @OutputTbl(PatternID,Varieties)
		VALUES(@PatternID, @ReturnVarieties)

		SET @ID = @ID + 1;
	END

	MERGE INTO Pattern T
	USING @OutputTbl S ON S.PatternID = T.PatternID			
	WHEN MATCHED THEN
		UPDATE SET T.MatchingVar = S.Varieties;

END
GO


