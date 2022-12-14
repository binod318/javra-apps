DROP PROCEDURE IF EXISTS [dbo].[PR_GetDataForDecisionScreen]
GO




/*
Author					Date			Remarks
Binod Gurung			2020-jan-23		Transcation isolation level implemented to avoid record lock

=================EXAMPLE=============

--EXEC PR_GetDataForDecisionScreen 1568336
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
	WHERE W.DetAssignmentID = @DetAssignmentID --AND T.StatusCode = 500
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
	WHERE W.DetAssignmentID = @DetAssignmentID --AND T.StatusCode = 500
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

	--ResultInfo
	SELECT
		QualityClass = MAX(DA.QualityClass),
		OffTypes =  CAST(MAX(Deviation) AS NVARCHAR(20)) + '/' + CAST (MAX(ActualSamples) AS NVARCHAR(20)) ,
		Inbred = CAST (MAX(Inbreed) AS NVARCHAR(20)) + '/' + CAST (MAX(ActualSamples) AS NVARCHAR(20)),
		PossibleInbred = CAST (MAX(Inbreed) AS NVARCHAR(10)) + '/' + CAST(MAX(ActualSamples) AS NVARCHAR(20)),
		TestResultQuality = CAST(MAX(DA.ActualSamples) * 100 / CAST(SUM(P.NrOfSamples) AS DECIMAL(4,1)) AS NVARCHAR(10)) + '%'
	FROM DeterminationAssignment DA
	JOIN Pattern P On P.DetAssignmentID = DA.DetAssignmentID 
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


