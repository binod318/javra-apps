DROP PROCEDURE IF EXISTS [dbo].[PR_GetDataForDecisionDetailScreen]
GO

-- [PR_GetDataForDecisionDetailScreen] 1444777
CREATE PROCEDURE [dbo].[PR_GetDataForDecisionDetailScreen]
(
    @DetAssignmentID INT
) 
AS 
BEGIN
    SET NOCOUNT ON;
	DECLARE @SQL NVARCHAR(MAX), @Columns NVARCHAR(MAX), @Columns2 NVARCHAR(MAX);

	SET @DetAssignmentID = 1444777;

	SELECT
		@Columns = COALESCE(@Columns + ',', '') + QUOTENAME(MarkerID),
		@Columns2 = COALESCE(@Columns2 + ',', '') + QUOTENAME(MarkerID) + 'AS' + QUOTENAME(MarkerFullName)
	FROM
	(
		SELECT DISTINCT 
		   PR.MarkerID,
		   M.MarkerFullName    
		FROM Pattern P
		JOIN PatternResult PR ON PR.PatternID = P.PatternID
		JOIN Marker M ON M.MarkerID = PR.MarkerID
		WHERE P.DetAssignmentID = @DetAssignmentID
	) C;

	IF(ISNULL(@Columns, '') <> '')
	BEGIN
		SET @SQl = N'SELECT 
			[Pat#] = ROW_NUMBER() OVER (ORDER BY P.NrOfSamples DESC),
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
		ORDER BY P.NrOfSamples DESC';
	END;
	ELSE 
	BEGIN
		SET @SQl = N'SELECT 
						[Pat#] = ROW_NUMBER() OVER (ORDER BY P.NrOfSamples DESC),
						[Sample] = P.NrOfSamples,
						[Sam%] = P.SamplePer,
						[Type:] = P.[Type],
						[Matching Varieties] = P.MatchingVar
					FROM Pattern P
					WHERE P.DetAssignmentID = @DetAssignmentID
					ORDER BY P.NrOfSamples DESC'
	END;

	EXEC sp_executesql @SQL, N'@DetAssignmentID INT', @DetAssignmentID;

END
GO


