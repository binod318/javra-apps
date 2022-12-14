ALTER TABLE TestResult 
ADD CreationDate DATETIME

GO



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
				SELECT ', ' + PlateName FROM Plate WHERE TestID = T.TestID FOR  XML PATH('')
			), 1, 2, ''
		),
		LastExport = FORMAT(MAX(T1.CreationDate), 'yyyy-MM-dd', 'en-US')
	FROM Test T
	LEFT JOIN Plate P On P.TestID = T.TestID 
	LEFT JOIN Well W ON W.PlateID = P.PlateID
	LEFT JOIN 
	(
		SELECT P.TestID, CreationDate = MAX(TR.CreationDate) 
		FROM TestResult TR
		JOIN Well W ON W.WellID = TR.WellID
		JOIN Plate P On P.PlateID = W.PlateID
		GROUP BY P.TestID
	) T1 ON T1.TestID = T.TestID
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


DROP PROCEDURE IF EXISTS [dbo].[PR_ReceiveResultsinKscoreCallback]
GO

/*

Author					Date			Remarks
Binod Gurung			-				-
Krishna Gautam			2020/01/20		Change on stored procedure to adjust logic of data is sent to LIMS for retest for specific determination but in response we get all result of that folder back.


============ExAMPLE===================
DECLARE  @DataAsJson NVARCHAR(MAX) = N'[{"LIMSPlateID":21,"MarkerNr":67,"AlleleScore":"0101","Position":"A01"}]'
EXEC PR_ReceiveResultsinKscoreCallback 331, @DataAsJson
*/
CREATE PROCEDURE [dbo].[PR_ReceiveResultsinKscoreCallback]
(
    @RequestID	 INT, --TestID
    @DataAsJson NVARCHAR(MAX)
) AS BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
	   BEGIN TRANSACTION;


	   --INSERT ONLY Not existed record, because when we re-do the test, then only test result data for selected determination is removed..
	   --rest of the data is already there and we are not allowed to change already existing data.
	   MERGE INTO TestResult T
	   USING
	   (
			SELECT 
				  W.WellID,
				  T1.MarkerNr, 
				  T1.AlleleScore,
				  T1.CreationDate				
		   FROM OPENJSON(@DataAsJson) WITH
		   (
			  LIMSPlateID	INT,
			  MarkerNr	INT,
			  AlleleScore	NVARCHAR(20),
			  Position	NVARCHAR(20),
			  CreationDate DATETIME
		   ) T1
		   JOIN Well W ON W.Position = T1.Position 
		   JOIN Plate P ON P.PlateID = W.PlateID AND P.LabPlateID = T1.LIMSPlateID 			
		   WHERE P.TestID = @RequestID
		   GROUP BY W.WellID, T1.MarkerNr, T1.AlleleScore, T1.CreationDate

	   ) S ON S.WellID = T.WellID AND S.MarkerNr = T.MarkerID
	   WHEN NOT MATCHED 
	   THEN INSERT(WellID, MarkerID, Score, CreationDate)
	   VALUES(S.WellID, S.MarkerNr,S.AlleleScore, S.CreationDate);
	   	   
	   --update test status
	   UPDATE Test SET StatusCode = 500 WHERE TestID = @RequestID;

	   --update determination assignment status
	   UPDATE DA
		 SET DA.StatusCode = 500
	   FROM DeterminationAssignment DA
	   JOIN TestDetAssignment TDA ON TDA.DetAssignmentID = DA.DetAssignmentID
	   WHERE TDA.TestID = @RequestID	   
	   
	   COMMIT;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
            ROLLBACK;
		THROW;
	END CATCH    
END
GO


