DROP PROCEDURE IF EXISTS [dbo].[PR_GetInfoForUpdateDA]
GO


/*
Author					Date			Remarks
Binod Gurung			2020-jan-21		Get information for UpdateDA
Binod Gurung			2020-jan-23		Transcation isolation level implemented to avoid record lock
Binod Gurung			2020-aug-14		NrOfWells, NrOfDeviation, NrOfInbreds added in the output statement
=================EXAMPLE=============
EXEC PR_GetInfoForUpdateDA 1864376
*/
CREATE PROCEDURE [dbo].[PR_GetInfoForUpdateDA]
(
	@DetAssignmentID INT
)
AS
BEGIN
	
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

	DECLARE @StatusCode INT, @TestID INT, @NrOfWells INT;

	SELECT @StatusCode = StatusCode FROM DeterminationAssignment WHERE DetAssignmentID = @DetAssignmentID;
	IF(ISNULL(@DetAssignmentID,0) = 0)
	BEGIN
		EXEC PR_ThrowError 'Invalid ID.';
		RETURN
	END

	IF(@StatusCode <> 600)
	BEGIN
		EXEC PR_ThrowError 'Invalid determination assignment status.';
		RETURN
	END

	SELECT 
		@NrOfWells = COUNT (DISTINCT W.WellID)
	FROM TestDetAssignment TDA
	JOIN Plate P On P.TestID = TDA.TestID
	JOIN Well W ON W.PlateID = P.PlateID AND W.DetAssignmentID = TDA.DetAssignmentID
	WHERE TDA.DetAssignmentID = @DetAssignmentID

	PRINT @NrOfWells;

	SELECT
		DetAssignmentID = Max(DA.DetAssignmentID),
		ValidatedOn		= FORMAT(MAX(ValidatedOn), 'yyyy-MM-dd', 'en-US'),
		Result			= CAST ( ((ISNULL(MAX(DA.Inbreed),0) + ISNULL(MAX(DA.Deviation),0)) * CAST(100 AS DECIMAL(5,2)) / @NrOfWells) AS DECIMAL(5,2)), --CAST ((MAX(DA.ActualSamples) * 100 / SUM(P.NrOfSamples)) AS DECIMAL),
		QualityClass	= MAX(QualityClass),
		ValidatedBy		= MAX(ValidatedBy),
		NrOfWells		= @NrOfWells,
		Inbreed			= MAX(DA.Inbreed),
		Deviation		= MAX(DA.Deviation),
		Remarks			= MAX(DA.Remarks)
	FROM DeterminationAssignment DA
	LEFT JOIN Pattern P On P.DetAssignmentID = DA.DetAssignmentID 
	WHERE DA.DetAssignmentID = @DetAssignmentID
	GROUP BY DA.DetAssignmentID

END

GO


