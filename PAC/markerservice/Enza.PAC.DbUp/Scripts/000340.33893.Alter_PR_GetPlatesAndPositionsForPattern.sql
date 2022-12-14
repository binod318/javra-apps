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
			('Positions', 'Positions', 2, 1200)
		) V (ColumnID, [Label], [Order], Width)
	) V1
	ORDER BY [Order];
	
END
GO


