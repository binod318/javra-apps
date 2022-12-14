ALTER TABLE DeterminationAssignment
ADD ReasonForRejection NVARCHAR(255)

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
    @DetAssignmentID INT,
	@QualityThresholdPercentage DECIMAL(5,2)
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
		TotalSamples = ISNULL(MAX(ActualSamples),0),
		ReasonForRejection = ISNULL(MAX(DA.ReasonForRejection),''),
		QualityThreshold = ISNULL(@QualityThresholdPercentage,0)
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


DROP PROCEDURE IF EXISTS [dbo].[PR_ProcessAllTestResultSummary]
GO



/*
Author					Date			Remarks
Binod Gurung			2020-jan-23		Trigger background summary calculation for all determination assignment whose result is determined(500)
Binod Gurung			2021-july-16	ThresholdA and ThresholdB is now considered per crop. Also calculation is only done for crops which is not marked
										to do calculation from external application
Binod Gurung			2022-march-05   Test result quality threshold percentage used from pipeline variable [#31737]

=================EXAMPLE=============

-- EXEC PR_ProcessAllTestResultSummary 43
-- All input values are in percentage (1 - 100)
*/

CREATE PROCEDURE [dbo].[PR_ProcessAllTestResultSummary]
(
	@MissingResultPercentage DECIMAL(5,2),
	@QualityThresholdPercentage DECIMAL(5,2)
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
			EXEC PR_BG_Task_2_3_4 @DetAssignmentID, @MissingResultPercentage, @ThresholdA, @ThresholdB, @QualityThresholdPercentage;

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


DROP PROCEDURE IF EXISTS [dbo].[PR_BG_Task_2_3_4]
GO


-- =============================================
-- Author:		Binod Gurung
-- Create date: 2020/01/13
-- Description:	Background Task part 2, 3, 4
-- =============================================
-- EXEC PR_BG_Task_2_3_4 835633, 43, 30, 90
CREATE PROCEDURE [dbo].[PR_BG_Task_2_3_4]
(
	@DetAssignmentID	INT,
	@MissingResultPercentage DECIMAL(5,2),
	@ThresholdA	DECIMAL(5,2),
	@ThresholdB DECIMAL(5,2),
	@QualityThresholdPercentage DECIMAL(5,2)
)
AS
BEGIN
		
	DECLARE @PatternID INT, @NrOfSamples INT, @PatternStatus INT, @PatternRemarks NVARCHAR(255), @Type NVARCHAR(20);
	DECLARE @Reciprocal BIT, @VarietyNr INT, @GoodPattern DECIMAL, @BadPattern DECIMAL, @MaleParent INT, @FemaleParent INT;
	DECLARE @JsonTbl TABLE (ID INT IDENTITY(1,1), MarkerID INT, MarkerValue NVARCHAR(10));
	DECLARE @ReturnedVarieties NVARCHAR(MAX), @MatchingVarieties NVARCHAR(MAX), @Crop NVARCHAR(10), @IsCropInbred BIT, @Json NVARCHAR(MAX), @TestedVariety NVARCHAR(20);

	DECLARE @DeviationCount INT, @TotalSamples INT, @ActualSamples INT = 0, @MatchCounter INT = 0, @InbreedCounter INT = 0, @PossibleInbreedCounter INT = 0,
			@QualityClass INT, @Result DECIMAL(6,2), @RejectedCounter INT = 0, @ReasonForRejection NVARCHAR(255);
	
	SET NOCOUNT ON;

	IF NOT EXISTS(SELECT DetAssignmentID FROM DeterminationAssignment WHERE DetAssignmentID = @DetAssignmentID AND StatusCode = 500)
		RETURN;

	SELECT 
		@Reciprocal		= ISNULL(ReciprocalProd,0),
		@VarietyNr		= DA.VarietyNr,
		@MaleParent		= ISNULL(V.Male,0),
		@FemaleParent	= ISNULL(V.Female,0),
		@Crop			= V.CropCode,
		@IsCropInbred	= ISNULL(C.InBreed,0) 
	FROM DeterminationAssignment DA
	JOIN Variety V ON V.VarietyNr = DA.VarietyNr
	JOIN CropRD C ON C.CropCode = V.CropCode
	WHERE DA.DetAssignmentID = @DetAssignmentID

	SELECT @TotalSamples = SUM(ISNULL(NrOfSamples,0)) FROM pattern WHERE DetAssignmentID = @DetAssignmentID

	-- BG Task 2 : Find matching varieties section
	EXEC PR_FindMatchingVarietiesForPattern @DetAssignmentID, @VarietyNr, @Crop;

	DECLARE Pattern_Cursor CURSOR LOCAL FAST_FORWARD FOR
	SELECT PatternID, MatchingVar, ISNULL(NrOfSamples,0) FROM Pattern WHERE DetAssignmentID = @DetAssignmentID
	OPEN Pattern_Cursor;
	FETCH NEXT FROM Pattern_Cursor INTO @PatternID, @ReturnedVarieties, @NrOfSamples;
	
	WHILE @@FETCH_STATUS = 0
	BEGIN
		--Reset
		SET @GoodPattern = 0; 
		SET @Badpattern = 0;
		SET @Type = 'Deviating';
		SET @PatternStatus = 100; --'Active';
		DELETE FROM @JsonTbl;

		SET @ActualSamples = @ActualSamples + @NrOfSamples;
				
		--Find Badpattern with score '9999', '0099', '-'
		SELECT @BadPattern = COUNT(PatternID) FROM PatternResult WHERE PatternID = @PatternID AND Score IN ('9999','0099','-')

		--Find GoodPattern
		SELECT @GoodPattern = COUNT(PatternID) FROM PatternResult WHERE PatternID = @PatternID AND Score NOT IN ('9999','0099','-')

		--If Bad pattern percentage is greater than threshold then reject the pattern
		IF (@BadPattern * 100 / (@BadPattern + @GoodPattern) > @MissingResultPercentage)
		BEGIN

			SET @PatternStatus = 200; --'Blocked';
			SET @Type = 'Pattern Rejected';
			SET @MatchingVarieties = '';
			SET @RejectedCounter = @RejectedCounter + @NrOfSamples;

		END
		ELSE
		BEGIN			

			---- BG Task 2 : Find matching varieties section

			----prepare json to feed sp
			--INSERT INTO @JsonTbl(MarkerID, MarkerValue)
			--SELECT MarkerID, Score from PatternResult WHERE PatternID = @PatternID

			--SET @Json = (SELECT * FROM @JsonTbl FOR JSON AUTO);
			--EXEC PR_FindMatchingVarieties @Json, @Crop, @VarietyNr, @ReturnedVarieties OUTPUT;

			--find comma separated variety name from comma separated variety number
			SELECT 
				@MatchingVarieties =
				STUFF 
				(
					(
						SELECT ',' + ShortName FROM Variety WHERE VarietyNr IN (SELECT [value] FROM STRING_SPLIT(@ReturnedVarieties, ','))FOR  XML PATH('')
					), 1, 1, ''
				);

			-- BG Task 3

			-- If only one variety or empty list returned
			IF(PATINDEX('%,%',@ReturnedVarieties) = 0)
				SET @TestedVariety = @ReturnedVarieties;
			ELSE
				SET @TestedVariety = LEFT(@ReturnedVarieties,(PATINDEX('%,%',@ReturnedVarieties))-1);

			--if the tested variety is in the clustervarlist this is a matching pattern, and it does not deviate
			IF ( @TestedVariety = @VarietyNr)
			BEGIN
				SET @Type = 'Match';
				SET @MatchCounter = @MatchCounter + @NrOfSamples;
			END

			-- For inbred crop, if the parent of tested variety is in the clustervarlist this is inbred
			-- old code : IF (@Type <> 'Match' AND @IsCropInbred = 1 AND ISNULL(@ReturnedVarieties,'') <> '')
			IF (@IsCropInbred = 1 AND ISNULL(@ReturnedVarieties,'') <> '')
			BEGIN

				IF (@Reciprocal = 0 AND EXISTS (SELECT [value] FROM STRING_SPLIT(@ReturnedVarieties, ',') WHERE [value] = @FemaleParent))
				OR (@Reciprocal = 1 AND EXISTS (SELECT [value] FROM STRING_SPLIT(@ReturnedVarieties, ',') WHERE [value] = @MaleParent))
				BEGIN

					--Check for possible inbred
										
					--Find 9999 scores in pattern result for all the heterozygous markers of variety
					--If all heterozygous markers has 9999 score then Possible Inbred
					IF NOT EXISTS (
						SELECT PatternResID FROM PatternResult 
						WHERE PatternID = @PatternID 
							AND MarkerID IN 
							(
								select DISTINCT MTB.MarkerID from MarkerToBeTested MTB
								JOIN DeterminationAssignment DA ON DA.DetAssignmentID = MTB.DetAssignmentID
								JOIN MarkerValuePerVariety MVPV ON MVPV.VarietyNr = DA.VarietyNr AND MVPV.MarkerID = MTB.MarkerID
								WHERE MTB.DetAssignmentID = @DetAssignmentID AND SUBSTRING(MVPV.AlleleScore,1,2) <> SUBSTRING(MVPV.AlleleScore,3,2) --check heterozygous
							) 
							AND Score NOT IN ('9999','0099','-')
					)
					BEGIN
						SET @Type = 'Possible Inbred';
						SET @PossibleInbreedCounter = @PossibleInbreedCounter + @NrOfSamples
					END
					ELSE
					BEGIN
						SET @Type = 'Inbred';
						SET @InbreedCounter = @InbreedCounter + @NrOfSamples
					END;
				END;

			END;
			
		END;
				
		UPDATE Pattern
		SET [Type]		= @Type,
			[Status]	= @PatternStatus,
			MatchingVar = @MatchingVarieties,
			SamplePer	= ROUND(ISNULL(@NrOfSamples,0) / CAST (@TotalSamples AS DECIMAL(5,2)) * 100, 2)
		WHERE PatternID = @PatternID
			
		FETCH NEXT FROM Pattern_Cursor INTO @PatternID, @ReturnedVarieties, @NrOfSamples;
	END

	CLOSE Pattern_Cursor;
	DEALLOCATE Pattern_Cursor;

	--BG Task 4
	SET @ActualSamples = @TotalSamples - @RejectedCounter;
	SET @DeviationCount = @ActualSamples - @MatchCounter - @InbreedCounter;

	IF (@ActualSamples > 0)
		SET @Result = (@InbreedCounter + @DeviationCount) * 100 / CAST (@ActualSamples AS DECIMAL);
	ELSE 
		SET @Result = 0;

	--if no thresholds found class = 4.
	IF(ISNULL(@ThresholdA,0) = 0 OR ISNULL(@ThresholdB,0) = 0)
		SET @QualityClass = 4
	--if (I + D * 100) / A <= treshold A then class = 5
	ELSE IF (@Result <= @ThresholdA)
		SET @QualityClass = 5;
	--if (I + D * 100) / A > treshold A and <= thresholdB then class = 6
	ELSE IF (@Result > @ThresholdA AND @Result <= @ThresholdB)
		SET @QualityClass = 6;
	ELSE
		SET @QualityClass = 7;
		
	--#29394 If @QualityClass is 5 and there is any Possible Inbred samples then it is always 4 (Last rule to be set)
	IF (@QualityClass = 5 AND ISNULL(@PossibleInbreedCounter,0) > 0)
		SET @QualityClass = 4;
			
	IF (@QualityClass IN (5,6,7))
	BEGIN
		--When a trait marker is not a match with the expected score -> Automatically a 4 score. (independent on the other markers) #31737
		IF EXISTS 
		(
			SELECT P.PatternID FROM Pattern P
			JOIN PatternResult PR ON PR.PatternID = P.PatternID
			JOIN DeterminationAssignment DA ON DA.DetAssignmentID = P.DetAssignmentID
			JOIN MarkerPerVariety MPV ON MPV.VarietyNr = DA.VarietyNr AND MPV.MarkerID = PR.MarkerID
			WHERE P.DetAssignmentID = @DetAssignmentID AND MPV.ExpectedResult <> PR.Score --Find trait marker whose expected result is not matching with score from LIMS
		)
		BEGIN
			SET @QualityClass = 4;
			SET @ReasonForRejection = 'Trait marker not matching expected score';
		END

		--If the Test result quality is below 70% -> Automatically a 4 score (independent on the other markers) : 70% is configurable #31737
		IF (@ActualSamples < @TotalSamples * @QualityThresholdPercentage / 100)
		BEGIN
			SET @QualityClass = 4;
			SET @ReasonForRejection = 'Test result quality below ' + @QualityThresholdPercentage + '%.';
		END
	END

	UPDATE DeterminationAssignment
	SET Deviation			= @DeviationCount,
		Inbreed				= @InbreedCounter,
		PossibleInbreed		= @PossibleInbreedCounter,
		ActualSamples		= @TotalSamples,
		QualityClass		= @QualityClass,
		ReasonForRejection  = @ReasonForRejection,
		StatusCode			= 600,
		CalculatedDate		= GETDATE()
	WHERE DetAssignmentID	= @DetAssignmentID
	
END
GO




