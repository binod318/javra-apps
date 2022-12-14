DROP PROCEDURE IF EXISTS [dbo].[PR_GetDataForDecisionScreen]
GO


-- PR_GetDataForDecisionScreen 1568336
CREATE PROCEDURE [dbo].[PR_GetDataForDecisionScreen]
(
    @DetAssignmentID INT
) 
AS 
BEGIN
    SET NOCOUNT ON;

	DECLARE @PeriodID INT;

	SELECT 
		@PeriodID = MAX(T.PeriodID)
	FROM Test T
	LEFT JOIN Plate P On P.TestID = T.TestID 
	LEFT JOIN Well W ON W.PlateID = P.PlateID
	WHERE W.DetAssignmentID = @DetAssignmentID --AND T.StatusCode = 500
	GROUP BY T.TestID
	
	--TestInfo
	SELECT 
		FolderName = MAX(T.TestName),
		Plates = 
		STUFF 
		(
			(
				SELECT ', ' + PlateName FROM Plate WHERE TestID = T.TestID FOR  XML PATH('')
			), 1, 2, ''
		),
		LastExport = CAST (GETDATE() AS DATETIME)
	FROM Test T
	LEFT JOIN Plate P On P.TestID = T.TestID 
	LEFT JOIN Well W ON W.PlateID = P.PlateID
	WHERE W.DetAssignmentID = @DetAssignmentID --AND T.StatusCode = 500
	GROUP BY T.TestID

	--DetAssignmentInfo
	SELECT 
		SampleNr,
		BatchNr,
		DetAssignmentID,
		Remarks,
		S.StatusName
	FROM DeterminationAssignment DA
	JOIN [Status] S ON S.StatusCode = Da.StatusCode AND S.StatusTable = 'DeterminationAssignment'
	WHERE DetAssignmentID = @DetAssignmentID

	--ResultInfo
	SELECT
		QualityClass = MAX(DA.QualityClass),
		OffTypes =  CAST ((MAX(Deviation) + '/' + MAX(ActualSamples)) AS NVARCHAR(20)) ,
		Inbred = CAST ((MAX(Inbreed) + '/' + MAX(ActualSamples)) AS NVARCHAR(20)),
		PossibleInbred = CAST ((MAX(Inbreed) + '/' + MAX(ActualSamples)) AS NVARCHAR(20)),
		TestResultQuality = CAST ((MAX(DA.ActualSamples) * 100 / SUM(P.NrOfSamples) + '%') AS NVARCHAR(20))
	FROM DeterminationAssignment DA
	JOIN Pattern P On P.DetAssignmentID = DA.DetAssignmentID 
	WHERE DA.DetAssignmentID = @DetAssignmentID
	GROUP BY DA.DetAssignmentID

	--ValidationInfo
	SELECT
		[Date] = FORMAT(ValidatedOn, 'yyyy-MM-dd', 'en-US'),
		[UserName] = ISNULL(ValidatedBy, '')
	FROM DeterminationAssignment
	WHERE DetAssignmentID = @DetAssignmentID

	--VarietyInfo
	EXEC PR_GetDeclusterResult @PeriodID, @DetAssignmentID;

END
GO


