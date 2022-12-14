DROP PROCEDURE IF EXISTS [dbo].[PR_GetDataForDecisionDetailScreen]
GO


/*
Author					Date			Remarks
Binod Gurung			2020-jan-23		Transcation isolation level implemented to avoid record lock
Dibya			    2020-Mar-05		added column headers for details result

=================EXAMPLE=============

-- [PR_GetDataForDecisionDetailScreen] 1444777
*/

CREATE PROCEDURE [dbo].[PR_GetDataForDecisionDetailScreen]
(
    @DetAssignmentID INT
) 
AS 
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
    DECLARE @SQL NVARCHAR(MAX), @Columns NVARCHAR(MAX), @Columns2 NVARCHAR(MAX);
    DECLARE @Markers TABLE(ID INT IDENTITY(0, 1), MarkerID INT, MarkerName NVARCHAR(100), IsExtraTraitMarker BIT);

    INSERT @Markers(MarkerID, MarkerName, IsExtraTraitMarker)
    SELECT  
	   PR.MarkerID,
	   MAX(M.MarkerFullName),
	   IsExtraTraitMarker = CASE WHEN ISNULL(PR.MarkerID,0) > 0 THEN 1 ELSE 0 END       
    FROM Pattern P
    JOIN PatternResult PR ON PR.PatternID = P.PatternID
    JOIN Marker M ON M.MarkerID = PR.MarkerID
	JOIN Determinationassignment D oN D.Detassignmentid = P.Detassignmentid 
	LEFT JOIN MarkerPerVariety MPV ON MPV.VarietyNr = D.VarietyNr AND MPV.MarkerID = PR.MarkerID
    WHERE P.DetAssignmentID = @DetAssignmentID
	GROUP BY PR.MarkerID

	SELECT
		@Columns = COALESCE(@Columns + ',', '') + QUOTENAME(MarkerID),
		@Columns2 = COALESCE(@Columns2 + ',', '') + QUOTENAME(MarkerID) + 'AS' + QUOTENAME(MarkerID)
	FROM @Markers C;

	IF(ISNULL(@Columns, '') <> '')
	BEGIN
		SET @SQl = N'SELECT 
			[Pat#] = ROW_NUMBER() OVER (ORDER BY  P.NrOfSamples DESC,  CAST (CASE	WHEN P.[Type] = ''Match'' THEN 1
																					WHEN P.[Type] = ''Inbreed'' THEN 2
																					WHEN P.[Type] = ''Possible Inbreed'' THEN 3
																					WHEN P.[Type] = ''Deviating'' THEN 4
																					WHEN P.[Type] = ''Pattern Rejected'' THEN 6
																					ELSE 5 END AS INT)),
			[Sample] = P.NrOfSamples,
			[Sam%] = P.SamplePer,
			[Type:] = P.[Type],
			[Matching Varieties] = P.MatchingVar,
			' + @Columns2 + '
		FROM Pattern P
		JOIN
		(
			SELECT * FROM 
			(
				SELECT 
					P.PatternID,
					PR.MarkerID,
					PR.Score
				FROM Pattern P
				JOIN PatternResult PR ON PR.PatternID = P.PatternID
				WHERE P.DetAssignmentID = @DetAssignmentID
			) V1
			PIVOT
			(
				MAX(Score)
				FOR MarkerID IN(' + @Columns + ')
			) P1
		) P2 ON P2.PatternID = P.PatternID
		ORDER BY [Pat#]';
	END;
	ELSE 
	BEGIN
		SET @SQl = N'SELECT 
						[Pat#] = ROW_NUMBER() OVER (ORDER BY  P.NrOfSamples DESC,  CAST (CASE	WHEN P.[Type] = ''Match'' THEN 1
																								WHEN P.[Type] = ''Inbreed'' THEN 2
																								WHEN P.[Type] = ''Possible Inbreed'' THEN 3
																								WHEN P.[Type] = ''Deviating'' THEN 4
																								WHEN P.[Type] = ''Pattern Rejected'' THEN 6																								
																								ELSE 5 END AS INT)),
						[Sample] = P.NrOfSamples,
						[Sam%] = P.SamplePer,
						[Type:] = P.[Type],
						[Matching Varieties] = P.MatchingVar
					FROM Pattern P
					WHERE P.DetAssignmentID = @DetAssignmentID
					ORDER BY [Pat#]'
	END;

	EXEC sp_executesql @SQL, N'@DetAssignmentID INT', @DetAssignmentID;

	SELECT 
		ColumnID, 
		ColumnLabel, 
		IsExtraTraitMarker,
		DisplayOrder
	FROM
	(
		SELECT *
		FROM
		(
			VALUES
			('Pat#', 'Pat#', 0, 0),
			('Sample', 'Sample', 0, 1),
			('Type:', 'Type:', 0, 2),
			('Matching Varieties', 'Matching Varieties', 0, 3)
		) V(ColumnID, ColumnLabel, IsExtraTraitMarker, DisplayOrder)
		UNION
		SELECT 
			ColumnID = CAST(MarkerID AS VARCHAR(10)), 
			ColumnLabel = MarkerName,
			IsExtraTraitMarker,
			DisplayOrder = ID + 4
		FROM @Markers
	) V1
	ORDER BY IsExtraTraitMarker, DisplayOrder;
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

	DROP TABLE IF EXISTS #VarietyMarkerValueTbl
	DROP TABLE IF EXISTS #Table1 
	DROP TABLE IF EXISTS #Table2
		
	--Combined Markervaluepervariety and markerpervariety
	CREATE TABLE #VarietyMarkerValueTbl
	(VarietyNr INT, MarkerID INT, MarkerValue NVARCHAR(10))
	CREATE CLUSTERED INDEX ix_tempCIndexVarMar ON #VarietyMarkerValueTbl (VarietyNr, MarkerID);

	CREATE TABLE #Table1
	(VarietyNr INT)
	CREATE CLUSTERED INDEX ix_tempCIndexAft1 ON #Table1 (VarietyNr);

	CREATE TABLE #Table2
	(VarietyNr INT)
	CREATE CLUSTERED INDEX ix_tempCIndexAft2 ON #Table2 (VarietyNr);
    
	INSERT @tbl(PatternID)
	SELECT PatternID FROM Pattern where DetAssignmentID = @DetAssignmentID;

	INSERT INTO #VarietyMarkerValueTbl (VarietyNr, MarkerID, MarkerValue)
	SELECT * FROM 
	(
		SELECT VarietyNr, MarkerID, AlleleScore FROM MarkerValuePerVariety
		UNION
		SELECT VarietyNr, MarkerID, ExpectedResult FROm MarkerPerVariety
	) R;
		
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
			JOIN #VarietyMarkerValueTbl MVPV ON MVPV.VarietyNr = V.VarietyNr AND MVPV.MarkerID = @FirstMarkerID AND dbo.FN_IsMatching(@FirstMarkerValue, MVPV.MarkerValue) = 1
			WHERE V.CropCode = @Crop AND V.PacComp = 1 AND V.[Status] NOT IN ('100','999', 'PD', 'GB')
			GROUP BY V.VarietyNr
			UNION
			-- find varieties which has no score
			SELECT		
				V.VarietyNr
			FROM Variety V
			LEFT JOIN #VarietyMarkerValueTbl MVPV ON MVPV.VarietyNr = V.VarietyNr AND MVPV.MarkerID = @FirstMarkerID
			WHERE V.CropCode = @Crop AND MVPV.VarietyNr IS NULL AND V.PacComp = 1 AND V.[Status] NOT IN ('100','999', 'PD', 'GB')
			GROUP BY V.VarietyNr
		)	

		--step 3 - Find varieties from filled temp-table which has mvpv and not matching
		INSERT INTO #Table2 (VarietyNr)
		(
			SELECT		
				MVPV.VarietyNr		
			FROM #Table1 V
			JOIN #VarietyMarkerValueTbl MVPV ON MVPV.VarietyNr = V.VarietyNr 
			JOIN @MarkerTbl MT ON MT.MarkerID = MVPV.MarkerID AND dbo.FN_IsMatching(MT.Markervalue, MVPV.MarkerValue) = 0
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


