DROP PROCEDURE IF EXISTS [PR_GetVarieties]
GO

-- PR_GetVarieties 'EK'
CREATE PROCEDURE [dbo].[PR_GetVarieties]
(
    @VarietyName NVARCHAR(100) = ''
) AS BEGIN
    SET NOCOUNT ON;

    SELECT 
	   V.VarietyNr,
	   VarietyName = V.Shortname
    FROM Variety V
    WHERE --V.[Status] = '100' AND 
    V.Shortname LIKE '%' + @VarietyName + '%';
END
GO