DROP PROCEDURE IF EXISTS [dbo].[PR_ProcessAllTestResultSummary]
GO

/*
Author					Date			Remarks
Binod Gurung			2020-jan-23		Trigger background summary calculation for all determination assignment whose result is determined(500)
Binod Gurung			2021-july-16	ThresholdA and ThresholdB is now considered per crop. Also calculation is only done for crops which is not marked
										to do calculation from external application

=================EXAMPLE=============

-- EXEC PR_ProcessAllTestResultSummary 43
-- All input values are in percentage (1 - 100)
*/

CREATE PROCEDURE [dbo].[PR_ProcessAllTestResultSummary]
(
	@MissingResultPercentage DECIMAL
)
AS 
BEGIN
    SET NOCOUNT ON;
	    
	DECLARE @tbl TABLE(ID INT IDENTITY(1, 1), DetAssignmentID INT, ThresholdA DECIMAL(5,2), ThresholdB DECIMAL(5,2));
	DECLARE @ThresholdA DECIMAL(5,2), @ThresholdB DECIMAL(5,2);

	DECLARE @Errors TABLE (DetAssignmentID INT, ErrorMessage NVARCHAR(MAX));
   
	INSERT @tbl(DetAssignmentID, ThresholdA, ThresholdB)
	SELECT 
		W.DetAssignmentID,
		MAX(ISNULL(CCPR.ThresholdA,0)),
		MAX(ISNULL(CCPR.ThresholdB,0))
	FROM TestResult TR
	LEFT JOIN Well W ON W.WellID = TR.WellID
	LEFT JOIN TestDetAssignment TDA ON TDA.DetAssignmentID = W.DetAssignmentID
	LEFT JOIN DeterminationAssignment DA ON DA.DetAssignmentID = TDA.DetAssignmentID
	JOIN ABSCrop AC ON AC.ABSCropCode = DA.ABSCropCode
	JOIN CalcCriteriaPerCrop CCPR On CCPR.CropCode = AC.CropCode
	WHERE ISNULL(W.DetAssignmentID, 0) <> 0
	AND DA.StatusCode = 500
	AND ISNULL(CCPR.CalcExternalAppl,0) = 0 --Do not trigger calculation for crop that is done from external application
	GROUP BY W.DetAssignmentID;

	DECLARE @DetAssignmentID INT, @ID INT = 1, @Count INT;
	SELECT @Count = COUNT(ID) FROM @tbl;
	WHILE(@ID <= @Count) BEGIN
			
		SELECT 
			@DetAssignmentID = DetAssignmentID,
			@ThresholdA = ThresholdA,
			@ThresholdB = ThresholdB 
		FROM @tbl
		WHERE ID = @ID;

		BEGIN TRY
		BEGIN TRANSACTION;
			
			--Background task 1
			EXEC PR_ProcessTestResultSummary @DetAssignmentID;

			--Background task 2, 3, 4
			EXEC PR_BG_Task_2_3_4 @DetAssignmentID, @MissingResultPercentage, @ThresholdA, @ThresholdB;

		COMMIT;
		END TRY
		BEGIN CATCH

			--Store exceptions
			INSERT @Errors(DetAssignmentID, ErrorMessage)
			SELECT @DetAssignmentID, ERROR_MESSAGE(); 

			IF @@TRANCOUNT > 0
				ROLLBACK;

		END CATCH

		SET @ID = @ID + 1;
	END   

	SELECT DetAssignmentID, ErrorMessage FROM @Errors;

END
GO


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


