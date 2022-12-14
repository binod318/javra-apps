DROP FUNCTION IF EXISTS [dbo].[FN_ShortenPositions]
GO

-- =============================================
-- Author:		Binod Gurung
-- Create date: 2022/05/04
-- Description:	Function to shorten position value

-- =============================================
-- SELECT  dbo.FN_ShortenPositions(N'A01, A02, A03, A04, A05, A06, A07, A08, A09, A10, A11, A12, B02, B03, B04, B05, B06, B07, B08, B09, B10, B11, B12, C01, C02, C03, C04, C05, C06, C07, C08, C09, C10, C11, C12, D02, D03, D04, D05, D06, D07, D08, D09, D10, D11, D12, E01, E02, E03, E04, E05, E06, E07, E08, E09, E10, E11, E12, F02, F03, F04, F05, F06, F07, F08, F09, F10, F11, F12, G01, G02, G03, G04, G05, G06, G07, G08, G09, G10, G11, G12, H02, H03, H04, H05, H06, H07, H08, H09, H10, H11, H12')
CREATE FUNCTION [dbo].[FN_ShortenPositions]
(
	@Positions NVARCHAR(MAX)
)
RETURNS NVARCHAR(MAX)
AS
BEGIN

	DECLARE @ReturnValue NVARCHAR(MAX);

	SELECT
		@ReturnValue = COALESCE(@ReturnValue + ',', '') + [Value]
	FROM
	(
		SELECT 
			[Value] = CONCAT([Row],MIN([Column]), '-', MAX([Column]))
		FROM
		(

			SELECT 
				[Row] = Substring([Val],1,1), 
				[Column] = SUBSTRING([Val],2,2),
				[val]
			FROM
			(
				SELECT [val] = RTRIM(LTRIM([Value])) FROM string_split(@Positions,',')
			) T
		) T1
		GROUP BY [Row]
	) T2

	Return @ReturnValue;

END

GO


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
		Positions = dbo.FN_ShortenPositions(STUFF 
			(
				(
					SELECT DISTINCT ', ' + W.Position FROM Well W
					JOIN Pattern P ON P.DetAssignmentID = W.DetAssignmentID
					WHERE W.PlateID = PL.PlateID AND P.PatternID = @PatternID
					ORDER BY ', ' + W.Position FOR XML PATH('')
				), 1, 2, ''
			))
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
			('PlateName', 'Mother plate', 1, 150),
			('Positions', 'Positions', 2, 1390)
		) V (ColumnID, [Label], [Order], Width)
	) V1
	ORDER BY [Order];
	
END
GO


