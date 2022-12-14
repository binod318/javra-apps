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

	DECLARE @PeriodID INT, @RejectedSamples INT;

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
		Remarks,
		DA.StatusCode,
		S.StatusName
	FROM DeterminationAssignment DA
	JOIN [Status] S ON S.StatusCode = Da.StatusCode AND S.StatusTable = 'DeterminationAssignment'
	WHERE DetAssignmentID = @DetAssignmentID

	SELECT TOP 1 @RejectedSamples = ISNULL(NrOfSamples,0) FROM Pattern WHERE DetAssignmentID = @DetAssignmentID AND [Status] = 200

	--ResultInfo
	SELECT
		--QualityClass = MAX(DA.QualityClass),
		--Rejected = ,
		--OffTypes =  CAST(ISNULL(MAX(Deviation),0) AS NVARCHAR(20)) + '/' + CAST (MAX(ActualSamples) AS NVARCHAR(20)) ,
		--Inbred = CAST (ISNULL(MAX(Inbreed),0) AS NVARCHAR(20)) + '/' + CAST (MAX(ActualSamples) AS NVARCHAR(20)),
		--PossibleInbred = CAST (ISNULL(MAX(PossibleInbreed),0) AS NVARCHAR(10)) + '/' + CAST(MAX(ActualSamples) AS NVARCHAR(20)),
		--TestResultQuality = CAST(CAST(MAX(T.ValidScore) * 100 / CAST(MAX(T.TotalScore) AS DECIMAL(5,0))AS DECIMAL(4,1)) AS NVARCHAR(10)) + '%'

		QualityClass = MAX(DA.QualityClass),
		Rejected = CASE WHEN MAX(PR.NrOfSamples) IS NULL THEN 0 ELSE MAX(PR.NrOfSamples) END,
		OffTypes =  ISNULL(MAX(Deviation),0),
		Inbred = ISNULL(MAX(Inbreed),0),
		PossibleInbred = ISNULL(MAX(PossibleInbreed),0),
		TestResultQuality = CAST(MAX(T.ValidScore) * 100 / CAST(MAX(T.TotalScore) AS DECIMAL(5,0))AS DECIMAL(4,1)),
		TotalSamples = MAX(ActualSamples)

	FROM DeterminationAssignment DA
	JOIN Pattern P ON P.DetAssignmentID = DA.DetAssignmentID 
	LEFT JOIN Pattern PR ON PR.DetAssignmentID = DA.DetAssignmentID AND PR.[Status] = 200
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


