DROP PROCEDURE IF EXISTS [dbo].[PR_ReceiveResultsinKscoreCallback]
GO


/*

Author					Date			Remarks
Binod Gurung			-				-
Krishna Gautam			2020/01/20		Change on stored procedure to adjust logic of data is sent to LIMS for retest for specific determination but in response we get all result of that folder back.
Binod Gurung			2020/04/14		Delete existing test result before creating new. Test result also created for status 500 because when no result
										is recieved then status still goes to 500 and when result is sent again from LIMS for that test then result 
										should be stored.

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

	DECLARE @StatusCode INT;

    BEGIN TRY
		BEGIN TRANSACTION;

		--Delete existing test result before creating new
		DELETE TR FROM Test T
		JOIN Plate P ON P.TestID = T.TestID
		JOIN Well W ON W.PlateID = P.PlateID
		JOIN TestResult TR ON TR.WellID = W.WellID
		WHERE T.TestID = @RequestID
		
		INSERT TestResult (WellID, MarkerID, Score, CreationDate)
		SELECT WellID, MarkerNr, AlleleScore, CreationDate
		FROM
		(	
			SELECT 
				W.WellID,
				T1.MarkerNr, 
				T1.AlleleScore,
				CONVERT(DATE,T1.CreationDate,105) AS CreationDate, -- CreationDate is in format dd-mm-yyyy from LIMS(22-02-2022) so we convert this with this rule select convert(date, varchar_date, 105)
				W.DetAssignmentID				
			FROM OPENJSON(@DataAsJson) WITH
			(
				LIMSPlateID	INT,
				MarkerNr	INT,
				AlleleScore	NVARCHAR(20),
				Position	NVARCHAR(20),
				CreationDate NVARCHAR(20)
			) T1
			JOIN Well W ON W.Position = T1.Position 
			JOIN Plate P ON P.PlateID = W.PlateID AND P.LabPlateID = T1.LIMSPlateID 
			JOIN DeterminationAssignment DA ON DA.DetAssignmentID = W.DetAssignmentID	
			JOIN 
			(
				SELECT T.DetAssignmentID, MarkerID FROM
				(
					SELECT MTB.MarkerID, DetAssignmentID FROM MarkerToBeTested MTB
					UNION
					SELECT MarkerID, DA.DetAssignmentID FROM MarkerPerVariety MPV
					JOIN DeterminationAssignment DA ON DA.VarietyNr = MPV.VarietyNr
					WHERE MPV.StatusCode = 100
				) T
				JOIN TestDetAssignment TDA On TDA.DetAssignmentID = T.DetAssignmentID
				WHERE TDA.TestID = @RequestID
				GROUP BY T.DetAssignmentID, MarkerID
			) MTB ON MTB.DetAssignmentID = DA.DetAssignmentID AND MTB.MarkerID = T1.MarkerNr	--store result only for the requested marker	
			WHERE P.TestID = @RequestID AND DA.StatusCode IN (400,500,650)						--store result only when status is InLIMS or Received or Re-test
			GROUP BY W.WellID, T1.MarkerNr, T1.AlleleScore, T1.CreationDate, W.DetAssignmentID
		) S;

		--If CalcCriteriaPerCrop exists for the particular crop with hybrid/parent combination then status directly goes to 600 instead of 500 
		IF EXISTS
		(
			SELECT CropCode FROM
			(
				SELECT 
					AC.CropCode,
					UsedFor = CASE WHEN [Type] = 'P' THEN 'Par' WHEN HybOp = 1 AND [Type] <> 'P' THEN 'Hyb' ELSE '' END,
					UsedForCriteria =  CASE WHEN ISNULL(CCPC.CalcExternalAppHybrid,0) <> 0 AND ISNULL(CCPC.CalcExternalAppParent,0) = 0 THEN 'Hyb' 
											WHEN ISNULL(CCPC.CalcExternalAppHybrid,0) = 0 AND ISNULL(CCPC.CalcExternalAppParent,0) <> 0 THEN 'Par'
											WHEN ISNULL(CCPC.CalcExternalAppHybrid,0) <> 0 AND ISNULL(CCPC.CalcExternalAppParent,0) <> 0 THEN 'Hyb/Par'
											ELSE ''
										END
				FROM DeterminationAssignment DA
				JOIN ABSCrop AC ON AC.ABSCropCode = DA.ABSCropCode
				JOIN Variety V ON V.VarietyNr = DA.VarietyNr
				JOIN CalcCriteriaPerCrop CCPC ON CCPC.CropCode = AC.CropCode
				WHERE DA.DetAssignmentID IN (SELECT TOP 1 DetAssignmentID FROM TestDetAssignment WHERE TestID = @RequestID)
			) T
			WHERE UsedForCriteria LIKE '%' + UsedFor + '%'
		)
			SET @StatusCode = 600;
		ELSE
			SET @StatusCode = 500;


		--update test status
		UPDATE Test SET StatusCode = @StatusCode WHERE TestID = @RequestID;

		--update determination assignment status
		UPDATE DA
			SET DA.StatusCode = @StatusCode
		FROM DeterminationAssignment DA
		JOIN TestDetAssignment TDA ON TDA.DetAssignmentID = DA.DetAssignmentID
		WHERE TDA.TestID = @RequestID AND DA.StatusCode IN (400,500,650)	 --InLIMS or Received or Re-test  
	   
	   COMMIT;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
            ROLLBACK;
		THROW;
	END CATCH    
END
GO


