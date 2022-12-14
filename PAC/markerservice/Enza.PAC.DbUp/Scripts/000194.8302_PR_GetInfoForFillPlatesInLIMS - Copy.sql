ALTER TABLE DeterminationAssignment
ADD PossibleInbreed INT

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
	@MissingResultPercentage DECIMAL,
	@ThresholdA	DECIMAL,
	@ThresholdB DECIMAL
)
AS
BEGIN
		
	DECLARE @PatternID INT, @NrOfSamples INT, @PatternStatus INT, @PatternRemarks NVARCHAR(255), @Type NVARCHAR(20);
	DECLARE @Reciprocal BIT, @VarietyNr INT, @GoodPattern DECIMAL, @BadPattern DECIMAL, @MaleParent INT, @FemaleParent INT;
	DECLARE @JsonTbl TABLE (ID INT IDENTITY(1,1), MarkerID INT, MarkerValue NVARCHAR(10));
	DECLARE @ReturnedVarieties NVARCHAR(MAX), @MatchingVarieties NVARCHAR(MAX), @Crop NVARCHAR(10), @IsCropInbred BIT, @Json NVARCHAR(MAX), @TestedVariety NVARCHAR(20);

	DECLARE @DeviationCount INT, @TotalSamples INT, @ActualSamples INT = 0, @MatchCounter INT = 0, @InbreedCounter INT = 0, @QualityClass INT, @Result DECIMAL;
	
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

	DECLARE Pattern_Cursor CURSOR LOCAL FAST_FORWARD FOR
	SELECT PatternID, ISNULL(NrOfSamples,0) FROM Pattern WHERE DetAssignmentID = @DetAssignmentID
	OPEN Pattern_Cursor;
	FETCH NEXT FROM Pattern_Cursor INTO @PatternID, @NrOfSamples;
	
	WHILE @@FETCH_STATUS = 0
	BEGIN
		--Reset
		SET @GoodPattern = 0; 
		SET @Badpattern = 0;
		SET @Type = 'Deviating';
		SET @PatternStatus = 100; --'Active';
		DELETE FROM @JsonTbl;
				
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
		END
		ELSE
		BEGIN			

			SET @ActualSamples = @ActualSamples + @NrOfSamples;

			-- BG Task 2 : Find matching varieties section

			--prepare json to feed sp
			INSERT INTO @JsonTbl(MarkerID, MarkerValue)
			SELECT MarkerID, Score from PatternResult WHERE PatternID = @PatternID

			SET @Json = (SELECT * FROM @JsonTbl FOR JSON AUTO);
			EXEC PR_FindMatchingVarieties @Json, @Crop, @VarietyNr, @ReturnedVarieties OUTPUT;

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
			IF (@IsCropInbred = 1)
			BEGIN

				IF (@Reciprocal = 0 AND EXISTS (SELECT [value] FROM STRING_SPLIT(@ReturnedVarieties, ',') WHERE [value] = @FemaleParent))
				OR (@Reciprocal = 1 AND EXISTS (SELECT [value] FROM STRING_SPLIT(@ReturnedVarieties, ',') WHERE [value] = @MaleParent))
				BEGIN
					SET @Type = 'Inbreed';
					SET @InbreedCounter = @InbreedCounter + @NrOfSamples
				END;

			END;
			
		END;
				
		UPDATE Pattern
		SET [Type]		= @Type,
			[Status]	= @PatternStatus,
			MatchingVar = @MatchingVarieties,
			SamplePer	= ROUND(ISNULL(@NrOfSamples,0) / CAST (@TotalSamples AS DECIMAL) * 100, 2)
		WHERE PatternID = @PatternID
			
		FETCH NEXT FROM Pattern_Cursor INTO @PatternID, @NrOfSamples;
	END

	CLOSE Pattern_Cursor;
	DEALLOCATE Pattern_Cursor;

	--BG Task 4
	SET @DeviationCount = @ActualSamples - @MatchCounter - @InbreedCounter;

	SET @Result = (@InbreedCounter + @DeviationCount) * 100 / CAST (@ActualSamples AS DECIMAL);

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

	--if A < 75% of originally planned number of samples (derived from method code) then class = 4. 
	IF (@ActualSamples < @TotalSamples * 0.75)
		SET @QualityClass = 4;

	UPDATE DeterminationAssignment
	SET Deviation			= @DeviationCount,
		Inbreed				= @InbreedCounter,
		ActualSamples		= @ActualSamples,
		QualityClass		= @QualityClass,
		StatusCode			= 600,
		CalculatedDate		= GETDATE()
	WHERE DetAssignmentID	= @DetAssignmentID
	
END
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
		OffTypes =  CAST(ISNULL(MAX(Deviation),0) AS NVARCHAR(20)) + '/' + CAST (MAX(ActualSamples) AS NVARCHAR(20)) ,
		Inbred = CAST (ISNULL(MAX(Inbreed),0) AS NVARCHAR(20)) + '/' + CAST (MAX(ActualSamples) AS NVARCHAR(20)),
		PossibleInbred = CAST (ISNULL(MAX(PossibleInbreed),0) AS NVARCHAR(10)) + '/' + CAST(MAX(ActualSamples) AS NVARCHAR(20)),
		TestResultQuality = CAST(CAST(MAX(T.ValidScore) * 100 / CAST(MAX(T.TotalScore) AS DECIMAL(5,0))AS DECIMAL(4,1)) AS NVARCHAR(10)) + '%'
	FROM DeterminationAssignment DA
	JOIN Pattern P On P.DetAssignmentID = DA.DetAssignmentID 
	JOIN
	(
		SELECT 
			DetAssignmentID, 
			COUNT(DetAssignmentID) AS TotalScore,
			SUM(CASE WHEN Score NOT IN ('9999','0099','-') THEN 1 ELSE 0 END) AS ValidScore
		FROM PatternResult PR
		JOIN Pattern P On P.PatternID = PR.PatternID
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



