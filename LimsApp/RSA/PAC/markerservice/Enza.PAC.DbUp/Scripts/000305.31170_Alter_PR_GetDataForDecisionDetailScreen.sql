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
	   IsExtraTraitMarker = CASE WHEN ISNULL(MAX(MPV.VarietyNr),0) > 0 THEN 1 ELSE 0 END  
    FROM Pattern P
    JOIN PatternResult PR ON PR.PatternID = P.PatternID
    JOIN Marker M ON M.MarkerID = PR.MarkerID
	JOIN Determinationassignment D oN D.Detassignmentid = P.Detassignmentid 
	LEFT JOIN MarkerPerVariety MPV ON MPV.VarietyNr = D.VarietyNr AND MPV.MarkerID = PR.MarkerID
    WHERE P.DetAssignmentID = @DetAssignmentID
	GROUP BY PR.MarkerID
	ORDER BY PR.MarkerID;

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


