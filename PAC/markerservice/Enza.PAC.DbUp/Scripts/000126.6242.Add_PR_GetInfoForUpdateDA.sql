DROP PROCEDURE IF EXISTS [dbo].[PR_GetInfoForUpdateDA]
GO

-- =============================================
-- Author:		Binod Gurung
-- Create date: 2020/01/21
-- Description:	Get information for UpdateDA
-- =============================================
/*
EXEC PR_GetInfoForUpdateDA 1568336
*/
CREATE PROCEDURE [dbo].[PR_GetInfoForUpdateDA]
(
	@DetAssignmentID INT
)
AS
BEGIN
	
	SET NOCOUNT ON;

	SELECT
		DetAssignmentID = Max(DA.DetAssignmentID),
		ValidatedOn		= FORMAT(MAX(ValidatedOn), 'yyyy-MM-dd', 'en-US'),
		Result			= CAST ((MAX(DA.ActualSamples) * 100 / SUM(P.NrOfSamples)) AS DECIMAL),
		QualityClass	= MAX(QualityClass),
		ValidatedBy		= MAX(ValidatedBy)
	FROM DeterminationAssignment DA
	LEFT JOIN Pattern P On P.DetAssignmentID = DA.DetAssignmentID 
	WHERE DA.DetAssignmentID = @DetAssignmentID
	GROUP BY DA.DetAssignmentID
	
END

GO


