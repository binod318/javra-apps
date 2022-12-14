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

	SELECT 
		PlateName = MAX(PL.PlateName),
		Positions = STUFF 
			(
				(
					SELECT DISTINCT ', ' + W.Position FROM Well W
					JOIN Pattern P ON P.DetAssignmentID = W.DetAssignmentID
					WHERE W.PlateID = PL.PlateID AND P.PatternID = @PatternID
					ORDER BY ', ' + W.Position FOR XML PATH('')
				), 1, 2, ''
			)
	FROM
	Pattern P
	JOIN Well W ON W.DetAssignmentID = P.DetAssignmentID
	JOIN Plate PL On PL.PlateID = W.PlateID
	WHERE P.PatternID = @PatternID
	GROUP BY PL.PlateID
	ORDER BY PlateName

	
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
			('PlateName', 'MotherPlate', 1, 150),
			('Positions', 'Positions', 2, 500)
		) V (ColumnID, [Label], [Order], Width)
	) V1
	ORDER BY [Order];
	
END
GO


