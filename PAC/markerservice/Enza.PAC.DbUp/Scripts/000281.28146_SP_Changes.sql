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
				T1.CreationDate,
				W.DetAssignmentID				
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
	    
	DECLARE @DetAssignment TABLE(DetAssignmentID INT, CropCode CHAR(2), UsedFor NVARCHAR(10));
	DECLARE @tbl TABLE(ID INT IDENTITY(1, 1), DetAssignmentID INT, ThresholdA DECIMAL(5,2), ThresholdB DECIMAL(5,2));
	DECLARE @ThresholdA DECIMAL(5,2), @ThresholdB DECIMAL(5,2), @Crop NVARCHAR(10);

	DECLARE @Errors TABLE (DetAssignmentID INT, ErrorMessage NVARCHAR(MAX));
	DECLARE @PlatformID INT = (SELECT PlatformID FROM [Platform] WHERE PlatformCode = 'LS'); --light scanner ;
	DECLARE @DetAssignmentID INT, @ID INT = 1, @Count INT;
   
	INSERT @DetAssignment(DetAssignmentID, CropCode, UsedFor)
	SELECT 
		W.DetAssignmentID,
		MAX(AC.CropCode),
		UsedFor = CASE WHEN MAX(V.[Type]) = 'P' THEN 'Par' WHEN CAST(MAX(CAST(v.HybOp as INT)) AS BIT) = 1 AND MAX(V.[Type]) <> 'P' THEN 'Hyb' ELSE 'Op' END --CASE WHEN MAX(V1.UsedFor) = 'HYB' THEN 1 ELSE 0 END 
	FROM TestResult TR
	JOIN Well W ON W.WellID = TR.WellID
	JOIN TestDetAssignment TDA ON TDA.DetAssignmentID = W.DetAssignmentID
	JOIN DeterminationAssignment DA ON DA.DetAssignmentID = TDA.DetAssignmentID
	JOIN ABSCrop AC ON AC.ABSCropCode = DA.ABSCropCode
	-- Do not use Cropmethod because same abscrop+methodID has both hybrid and parent for methodID 8 : That is confusing
	--JOIN
	--(
	--	SELECT
	--		AC.ABSCropCode,
	--		PM.MethodCode,
	--		CM.UsedFor
	--	FROM CropMethod CM
	--	JOIN ABSCrop AC ON AC.ABSCropCode = CM.ABSCropCode
	--	JOIN Method PM ON PM.MethodID = CM.MethodID
	--	WHERE CM.PlatformID = @PlatformID
	--) V1 ON V1.ABSCropCode = DA.ABSCropCode AND V1.MethodCode = DA.MethodCode
	JOIN Variety V ON V.VarietyNr = DA.VarietyNr
	WHERE ISNULL(W.DetAssignmentID, 0) <> 0
	AND DA.StatusCode = 500
	GROUP BY W.DetAssignmentID;

	INSERT @tbl(DetAssignmentID, ThresholdA, ThresholdB)
	SELECT
		D.DetAssignmentID,
		ISNULL(CC.ThresholdA,0),
		ISNULL(CC.ThresholdB,0)
	FROM @DetAssignment D
	LEFT JOIN CalcCriteriaPerCrop CC ON CC.CropCode = D.CropCode
	WHERE (UsedFor = 'Hyb' AND ISNULL(CC.CalcExternalAppHybrid,0) = 0) OR (UsedFor = 'Par' AND ISNULL(CC.CalcExternalAppParent,0) = 0)
	--If Hybrid do not trigger calculation if CalcExternalAppHybrid = 1, if Parent do not trigger calculation if CalcExternalAppParent = 1

	SELECT @Count = COUNT(ID) FROM @tbl;
	WHILE(@ID <= @Count) BEGIN
			
		SELECT 
			@DetAssignmentID = DetAssignmentID,
			@ThresholdA = ThresholdA,
			@ThresholdB = ThresholdB 
		FROM @tbl
		WHERE ID = @ID;

		SET @ID = @ID + 1;

		--threshold value not saved for crop
		IF (@ThresholdA = 0 AND @ThresholdB = 0)
		BEGIN

			SELECT @Crop = AC.CropCode FROM DeterminationAssignment DA 
			JOIN ABSCrop AC ON AC.ABSCropCode = DA.ABSCropCode
			WHERE DA.DetAssignmentID = @DetAssignmentID

			INSERT @Errors(DetAssignmentID, ErrorMessage)
			SELECT @DetAssignmentID, 'Threshold value not found for crop ' + @Crop; 
			
			CONTINUE;
		END

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

	END   

	SELECT DetAssignmentID, ErrorMessage FROM @Errors;

END
GO


DROP PROCEDURE IF EXISTS [dbo].[PR_GetInfoForUpdateDA]
GO


/*
Author					Date			Remarks
Binod Gurung			2020-jan-21		Get information for UpdateDA
Binod Gurung			2020-jan-23		Transcation isolation level implemented to avoid record lock
Binod Gurung			2020-aug-14		NrOfWells, NrOfDeviation, NrOfInbreds added in the output statement
=================EXAMPLE=============
EXEC PR_GetInfoForUpdateDA 837822
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

	SELECT
		DetAssignmentID = Max(DA.DetAssignmentID),
		ValidatedOn		= FORMAT(MAX(ValidatedOn), 'yyyy-MM-dd', 'en-US'),
		Result			= CAST ( ((ISNULL(MAX(DA.Inbreed),0) + ISNULL(MAX(DA.Deviation),0)) * CAST(100 AS DECIMAL(5,2)) / @NrOfWells) AS DECIMAL(6,2)), --CAST ((MAX(DA.ActualSamples) * 100 / SUM(P.NrOfSamples)) AS DECIMAL),
		QualityClass	= MAX(QualityClass),
		ValidatedBy		= MAX(ValidatedBy),
		NrOfWells		= @NrOfWells,
		Inbreed			= MAX(DA.Inbreed),
		Deviation		= MAX(DA.Deviation),
		Remarks			= MAX(DA.Remarks),
		SendToABS		= MAX(T1.SendToABS)
	FROM DeterminationAssignment DA
	--Get calculation criteria per crop for hybrid/parent based on varietynr
	JOIN
	(
		SELECT 
			DetAssignmentID,
			SendToABS = CASE WHEN UsedForCriteria LIKE '%' + UsedFor + '%' THEN 0 ELSE 1 END
		FROM
		(
			SELECT 
				AC.CropCode,
				DA.DetAssignmentID,
				UsedFor = CASE WHEN [Type] = 'P' THEN 'Par' WHEN HybOp = 1 AND [Type] <> 'P' THEN 'Hyb' ELSE 'Op' END,
				UsedForCriteria =  CASE WHEN ISNULL(CCPC.CalcExternalAppHybrid,0) <> 0 AND ISNULL(CCPC.CalcExternalAppParent,0) = 0 THEN 'Hyb' 
										WHEN ISNULL(CCPC.CalcExternalAppHybrid,0) = 0 AND ISNULL(CCPC.CalcExternalAppParent,0) <> 0 THEN 'Par'
										WHEN ISNULL(CCPC.CalcExternalAppHybrid,0) <> 0 AND ISNULL(CCPC.CalcExternalAppParent,0) <> 0 THEN 'Hyb/Par'
										ELSE ''
									END
			FROM DeterminationAssignment DA
			JOIN ABSCrop AC ON AC.ABSCropCode = DA.ABSCropCode
			JOIN Variety V ON V.VarietyNr = DA.VarietyNr
			LEFT JOIN CalcCriteriaPerCrop CCPC ON CCPC.CropCode = AC.CropCode
			WHERE DA.DetAssignmentID = @DetAssignmentID
		) T
	) T1 ON T1.DetAssignmentID = DA.DetAssignmentID
	LEFT JOIN Pattern P On P.DetAssignmentID = DA.DetAssignmentID 
	WHERE DA.DetAssignmentID = @DetAssignmentID
	GROUP BY DA.DetAssignmentID

END

GO


