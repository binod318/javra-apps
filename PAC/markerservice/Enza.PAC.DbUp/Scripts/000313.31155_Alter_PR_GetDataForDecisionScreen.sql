DROP PROCEDURE IF EXISTS [dbo].[PR_GetDataForDecisionScreen]
GO


/*
Author					Date			Remarks
Binod Gurung			2020-jan-23		Transcation isolation level implemented to avoid record lock

=================EXAMPLE=============

--EXEC PR_GetDataForDecisionScreen 1864376
*/

CREATE PROCEDURE [dbo].[PR_GetDataForDecisionScreen]
(
    @DetAssignmentID INT
) 
AS 
BEGIN
    SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

	DECLARE @PeriodID INT;

	SELECT 
		@PeriodID = MAX(T.PeriodID)
	FROM Test T
	LEFT JOIN Plate P On P.TestID = T.TestID 
	LEFT JOIN Well W ON W.PlateID = P.PlateID
	WHERE W.DetAssignmentID = @DetAssignmentID
	GROUP BY T.TestID
	
	--TestInfo
	SELECT 
		FolderName = MAX(T.TestName),
		Plates = 
		STUFF 
		(
			(
				SELECT DISTINCT ', ' + PlateName FROM Plate P 
				JOIN Well W ON W.PlateID = P.PlateID 
				WHERE TestID = T.TestID AND W.DetAssignmentID = @DetAssignmentID FOR  XML PATH('')
			), 1, 2, ''
		),
		LastExport = FORMAT(MAX(DA.CalculatedDate), 'dd/MM/yyyy HH:mm:ss', 'en-US')
	FROM Test T
	LEFT JOIN Plate P On P.TestID = T.TestID 
	LEFT JOIN Well W ON W.PlateID = P.PlateID
	JOIN DeterminationAssignment DA ON DA.DetAssignmentID = W.DetAssignmentID
	WHERE W.DetAssignmentID = @DetAssignmentID
	GROUP BY T.TestID

	--DetAssignmentInfo
	SELECT 
		SampleNr,
		BatchNr,
		DetAssignmentID,
		Reciprocal = CASE WHEN ISNULL(DA.ReciprocalProd,0) = 0 THEN 'N' ELSE 'Y' END,
		Remarks,
		DA.StatusCode,
		S.StatusName
	FROM DeterminationAssignment DA
	JOIN [Status] S ON S.StatusCode = Da.StatusCode AND S.StatusTable = 'DeterminationAssignment'
	WHERE DetAssignmentID = @DetAssignmentID

	--ResultInfo
	SELECT
		QualityClass = ISNULL(MAX(DA.QualityClass),''),
		Rejected = ISNULL(MAX(PR.RejectedSamples),0),
		OffTypes =  ISNULL(MAX(Deviation),0),
		Inbred = ISNULL(MAX(Inbreed),0),
		PossibleInbred = ISNULL(MAX(PossibleInbreed),0),
		TestResultQuality = ISNULL(CAST(MAX(T.ValidScore) * 100 / CAST(MAX(T.TotalScore) AS DECIMAL(5,0))AS DECIMAL(4,1)),0),
		TotalSamples = ISNULL(MAX(ActualSamples),0)

	FROM DeterminationAssignment DA
	JOIN Pattern P ON P.DetAssignmentID = DA.DetAssignmentID 
	LEFT JOIN
	(
		SELECT DetAssignmentID, RejectedSamples = SUM(ISNULL(NrOfSamples,0)) FROM Pattern 
		WHERE [Status] = 200
		GROUP BY DetAssignmentID
	) PR ON PR.DetAssignmentID = DA.DetAssignmentID
	JOIN
	(
		SELECT 
			DetAssignmentID,
			TotalScore = SUM(TotalScore),
			ValidScore = SUM(ValidScore)
		FROM
		(
			SELECT 
				DetAssignmentID,
				P.PatternID, 
				COUNT(DetAssignmentID) * NrOfSamples AS TotalScore,
				SUM(CASE WHEN Score NOT IN ('9999','0099','-') THEN NrOfSamples ELSE 0 END)  AS ValidScore
			FROM PatternResult PR
			JOIN Pattern P On P.PatternID = PR.PatternID
			GROUP BY DetAssignmentID, P.PatternID, NrOfSamples
		) D
		GROUP BY DetAssignmentID
	) T On T.DetAssignmentID = DA.DetAssignmentID
	WHERE DA.DetAssignmentID = @DetAssignmentID
	GROUP BY DA.DetAssignmentID

	--ValidationInfo
	SELECT
		[Date] = FORMAT(ValidatedOn, 'dd/MM/yyyy HH:mm:ss', 'en-US'),
		[UserName] = ISNULL(ValidatedBy, '')
	FROM DeterminationAssignment
	WHERE DetAssignmentID = @DetAssignmentID

	--VarietyInfo
	EXEC PR_GetDeclusterResult @PeriodID, @DetAssignmentID;

END
GO


