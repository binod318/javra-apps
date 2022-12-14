DROP PROCEDURE IF EXISTS [dbo].[PR_FindMatchingVarieties]
GO



-- =============================================
-- Author:		Binod Gurung
-- Create date: 2019/09/05
-- Description:	Procedure to find matching varieties based on give marker values and db marker values
-- =============================================
/*	DECLARE @Json NVARCHAR(MAX) = N'[
					{"ID":1,"MarkerID":44,"MarkerValue":"0102"},
					{"ID":2,"MarkerID":45,"MarkerValue":"0101"},
					{"ID":3,"MarkerID":46,"MarkerValue":"0101"},
					{"ID":4,"MarkerID":47,"MarkerValue":"0101"},
					{"ID":5,"MarkerID":48,"MarkerValue":"0102"},
					{"ID":2,"MarkerID":49,"MarkerValue":"0102"},
					{"ID":3,"MarkerID":50,"MarkerValue":"0102"},
					{"ID":4,"MarkerID":51,"MarkerValue":"0102"}
				]';
	DECLARE @ReturnVarieties nvarchar(max);
	EXEC PR_FindMatchingVarieties @Json, 'TO', 1011843, @ReturnVarieties OUTPUT;
	SELECT @ReturnVarieties;
*/
CREATE PROCEDURE [dbo].[PR_FindMatchingVarieties]
(
	@Json	NVARCHAR(MAX),
	@Crop	NVARCHAR(10),
	@VarietyNr	INT,
	@ReturnVarieties NVARCHAR(MAX) OUTPUT
)
AS
BEGIN
	SET NOCOUNT ON;

	-- step 1
	DECLARE @MarkerTbl Table(ID INT,MarkerID INT, MarkerValue NVARCHAR(10));
	DECLARE @Table1 Table(VarietyNr INT); 
	DECLARE @Table2 Table(VarietyNr INT); 
	DECLARE @FirstMarkerID INT;
	DECLARE @FirstMarkerValue NVARCHAR(20);

	--Insert MarkerID and MarkerVlaue to Table from JSON
	INSERT INTO @MarkerTbl (ID, MarkerID, MarkerValue)
	SELECT ID, MarkerID, MarkerValue
	FROM OPENJSON(@Json) WITH
	(
		ID			INT '$.ID',
		MarkerID	INT '$.MarkerID',
		MarkerValue	NVARCHAR(MAX) '$.MarkerValue'
	)
	
	SELECT 
		@FirstMarkerID = MarkerID,
		@FirstMarkerValue = MarkerValue 
	FROM @MarkerTbl WHERE ID = 1;
	
	-- step 2 - Fill temptable from all varieties which has no markervaluepervariety or has markervaluepervariety and is matching
	INSERT INTO @Table1 (VarietyNr)
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
	INSERT INTO @Table2 (VarietyNr)
	(
		SELECT		
			MVPV.VarietyNr		
		FROM @Table1 V
		JOIN MarkerValuePerVariety MVPV ON MVPV.VarietyNr = V.VarietyNr 
		JOIN @MarkerTbl MT ON MT.MarkerID = MVPV.MarkerID AND dbo.FN_IsMatching(MT.Markervalue, MVPV.AlleleScore) = 0
		WHERE MT.ID <> 1
		GROUP BY MVPV.VarietyNr
	) 

	--Delete all records from @Table1 found in @table2 because these are varieties that has score but not matching
	DELETE T1 
	FROM @Table1 T1
	JOIN @Table2 T2 ON T2.VarietyNr = T1.VarietyNr

	--step 4 - Place input varieties at first in the list 
	IF EXISTS (SELECT VarietyNr FROM @Table1 WHERE VarietyNr = @VarietyNr)
	BEGIN
		SET @ReturnVarieties = @VarietyNr;
		DELETE FROM @Table1 WHERE VarietyNr = @VarietyNr;
	END;

	--step 5 - Return Varities in comma separated list
	IF(ISNULL(@ReturnVarieties,'') <> '')
		SET @ReturnVarieties = @ReturnVarieties + ',';

	SELECT @ReturnVarieties = @ReturnVarieties + CAST(VarietyNr AS NVARCHAR(20)) + ',' from @Table1;
	SET @ReturnVarieties = SUBSTRING(@ReturnVarieties, 0, LEN(@ReturnVarieties));
	
END
GO


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

	DECLARE @MarkerTbl Table(ID INT, MarkerID INT, MarkerValue NVARCHAR(10));
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
		DELETE FROM #Table1;
		DELETE FROM #Table2;
		SET @ReturnVarieties = '';

		--Insert MarkerID and MarkerVlaue to Table from JSON
		INSERT INTO @MarkerTbl (ID, MarkerID, MarkerValue)
		SELECT ROW_NUMBER() OVER (ORDER BY MarkerID), MarkerID, Score FROM PatternResult WHERE PatternID = @PatternID
	
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
		IF(ISNULL(@ReturnVarieties,'') <> '')
			SET @ReturnVarieties = @ReturnVarieties + ',';

		SELECT @ReturnVarieties = @ReturnVarieties + CAST(VarietyNr AS NVARCHAR(20)) + ',' from #Table1;
		SET @ReturnVarieties = SUBSTRING(@ReturnVarieties, 0, LEN(@ReturnVarieties));

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


