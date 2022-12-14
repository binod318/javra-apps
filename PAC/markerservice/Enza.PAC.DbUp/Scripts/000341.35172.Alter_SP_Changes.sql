DROP PROCEDURE IF EXISTS [dbo].[PR_GetPlatesAndPositionForPattern]
GO



/*
Author					Date			Remarks
Binod Gurung			2022-march-12	Display plates and positions for pattern

=================EXAMPLE=============

--EXEC PR_GetPlatesAndPositionForPattern 3127
*/

CREATE PROCEDURE [dbo].[PR_GetPlatesAndPositionForPattern]
(
    @PatternID INT
) 
AS 
BEGIN
    SET NOCOUNT ON;

	--SELECT 
	--	PlateName = MAX(PL.PlateName),
	--	Positions = dbo.FN_ShortenPositions(STUFF 
	--		(
	--			(
	--				SELECT DISTINCT ', ' + W.Position FROM Well W
	--				JOIN Pattern P ON P.DetAssignmentID = W.DetAssignmentID
	--				WHERE W.PlateID = PL.PlateID AND P.PatternID = @PatternID
	--				ORDER BY ', ' + W.Position FOR XML PATH('')
	--			), 1, 2, ''
	--		))
	--FROM
	--Pattern P
	--JOIN Well W ON W.DetAssignmentID = P.DetAssignmentID
	--JOIN Plate PL On PL.PlateID = W.PlateID
	--WHERE P.PatternID = @PatternID
	--GROUP BY PL.PlateID
	--ORDER BY PlateName

	SELECT * FROM
	(
		SELECT 
			PlateName = MAX(P2.PlateName),
			Positions = STUFF 
					(
						(
							SELECT ', ' + T.Position FROM
							(
								SELECT 
									W1.Position,
									MarkerScores = STUFF 
										(
											(
												SELECT ', ' + CAST (TR.MarkerID AS NVARCHAR(10)) + '-' + TR.Score FROM Well W2
												JOIN TestResult TR ON TR.WellID = W2.WellID
												WHERE W2.WellID = W1.WellID FOR XML PATH('')
											), 1, 2, ''
										),
									PatternScores = STUFF 
										(
											(
												SELECT ', ' + CAST (PR.MarkerID AS NVARCHAR(10)) + '-' + PR.Score FROM Pattern P
												JOIN PatternResult PR ON PR.PatternID = P.PatternID
												WHERE P.PatternID = @PatternID 
												FOR XML PATH('')
											), 1, 2, ''
										)
								FROM Well W1
								JOIN Plate P On P.PlateID = W1.PlateID
								WHERE P.PlateID = P2.PlateID
							) T
							WHERE MarkerScores = PatternScores FOR XML PATH('')
						), 1, 2, ''
					)	
		FROM Plate P2
		JOIN Well W On W.PlateID = P2.PlateID
		JOIN Pattern PT ON PT.DetAssignmentID = W.DetAssignmentID
		WHERE PT.PatternID = @PatternID
		GROUP By P2.PlateID
	) T2
	WHERE Positions IS NOT NULL
	ORDER By PlateName
	
	SELECT 
		ColumnID, 
		[Label], 
		[Order],
		Width
	FROM
	(
		SELECT *
		FROM
		(
			VALUES
			('PlateName', 'Mother plate', 1, 140),
			('Positions', 'Positions', 2, 1240)
		) V (ColumnID, [Label], [Order], Width)
	) V1
	ORDER BY [Order];
	
END
GO


DROP PROCEDURE IF EXISTS [dbo].[PR_GetDataForDecisionDetailScreen]
GO


/*
Author					Date			Remarks
Binod Gurung			2020-jan-23		Transcation isolation level implemented to avoid record lock
Dibya					2020-Mar-05		added column headers for details result

=================EXAMPLE=============

-- [PR_GetDataForDecisionDetailScreen] 1444777
*/

CREATE PROCEDURE [dbo].[PR_GetDataForDecisionDetailScreen]
(
    @DetAssignmentID INT,
	@SortBy NVARCHAR(50),
	@SortOrder NVARCHAR(50)
) 
AS 
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
    DECLARE @SQL NVARCHAR(MAX), @Columns NVARCHAR(MAX), @Columns2 NVARCHAR(MAX), @Sorting NVARCHAR(100);
    DECLARE @Markers TABLE(ID INT IDENTITY(0, 1), MarkerID INT, MarkerName NVARCHAR(100), IsExtraTraitMarker BIT, Editable BIT);

    INSERT @Markers(MarkerID, MarkerName, IsExtraTraitMarker)
    SELECT  
	   PR.MarkerID,
	   MAX(M.MarkerFullName),
	   IsExtraTraitMarker = CASE WHEN ISNULL(MAX(MPV.VarietyNr),0) > 0 THEN 1 ELSE 0 END  
    FROM Pattern P
    JOIN PatternResult PR ON PR.PatternID = P.PatternID
    JOIN Marker M ON M.MarkerID = PR.MarkerID
	JOIN Determinationassignment D oN D.Detassignmentid = P.Detassignmentid 
	LEFT JOIN MarkerPerVariety MPV ON MPV.VarietyNr = D.VarietyNr AND MPV.MarkerID = PR.MarkerID
    WHERE P.DetAssignmentID = @DetAssignmentID
	GROUP BY PR.MarkerID
	ORDER BY PR.MarkerID;

	IF(ISNULL(@SortBy,'') = '')
		SET @Sorting = '[Pat#]';
	ELSE
		SET @Sorting = @SortBy + ' ' + ISNULL(@SortOrder,'');

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
			[Type] = P.[Type],
			[Matching Varieties] = P.MatchingVar,
			' + @Columns2 + ',
			P.Remarks,
			P.PatternID
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
		ORDER BY ' + @Sorting;
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
						[Type] = P.[Type],
						[Matching Varieties] = P.MatchingVar,
						P.Remarks,
						P.PatternID
					FROM Pattern P
					WHERE P.DetAssignmentID = @DetAssignmentID
					ORDER BY ' + @Sorting;
	END;

	EXEC sp_executesql @SQL, N'@DetAssignmentID INT', @DetAssignmentID;

	SELECT 
		ColumnID, 
		ColumnLabel, 
		IsExtraTraitMarker = CASE WHEN ColumnID = 'Remarks' THEN 0 ELSE IsExtraTraitMarker1 END,
		DisplayOrder,
		Editable,
		Sort
	FROM
	(
		SELECT *
		FROM
		(
			VALUES
			('Pat#', 'Pat#', 0, 0, 0, 0),
			('Sample', 'Sample', 0, 1, 0, 0),
			('Type', 'Type:', 0, 2, 0, 1),
			('Matching Varieties', 'Matching Varieties', 0, 3, 0, 0),
			('Remarks', 'Remarks', 1, 999, 1, 0)
		) V(ColumnID, ColumnLabel, IsExtraTraitMarker1, DisplayOrder, Editable, Sort)
		UNION
		SELECT 
			ColumnID = CAST(MarkerID AS VARCHAR(10)), 
			ColumnLabel = MarkerName,
			IsExtraTraitMarker,
			DisplayOrder = ID + 4,
			0,
			0
		FROM @Markers
	) V1
	ORDER BY IsExtraTraitMarker1, DisplayOrder;
END
GO


