DROP PROCEDURE IF EXISTS [dbo].[PR_GetDataForDecisionScreen]
GO


-- PR_GetDataForDecisionScreen 1443598
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
		--Plates = 'P19-00201-MP01,P19-00201-MP02,P19-00201-MP03,P19-00201-MP04',
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
		QualityClass = 5,
		OffTypes = 	'2/184',
		Inbred = '3/184',
		PossibleInbred = '4/184',
		TestResultQuality = '92%' 
	FROM DeterminationAssignment WHERE DetAssignmentID = @DetAssignmentID;

	--ValidationInfo
	SELECT TOP 1 
		[Date] = GetDate(),
		[UserName] = 'Binod Gurung'
	FROM Test

	--VarietyInfo
	EXEC PR_GetDeclusterResult @PeriodID, @DetAssignmentID;

END
GO


