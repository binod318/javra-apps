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
				  T1.AlleleScore				
		   FROM OPENJSON(@DataAsJson) WITH
		   (
			  LIMSPlateID	INT,
			  MarkerNr	INT,
			  AlleleScore	NVARCHAR(20),
			  Position	NVARCHAR(20)
		   ) T1
		   JOIN Well W ON W.Position = T1.Position 
		   JOIN Plate P ON P.PlateID = W.PlateID AND P.LabPlateID = T1.LIMSPlateID 			
		   WHERE P.TestID = @RequestID
		   GROUP BY W.WellID, T1.MarkerNr, T1.AlleleScore

	   ) S ON S.WellID = T.WellID AND S.MarkerNr = T.MarkerID
	   WHEN NOT MATCHED 
	   THEN INSERT(WellID, MarkerID, Score)
	   VALUES(S.WellID, S.MarkerNr,S.AlleleScore);
	   	   
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


DROP PROCEDURE IF EXISTS [dbo].[PR_BG_Task_2_3_4]
GO


-- =============================================
-- Author:		Binod Gurung
-- Create date: 2020/01/13
-- Description:	Background Task part 2, 3, 4
-- =============================================

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
	DECLARE @ReturnedVarieties NVARCHAR(MAX), @MatchingVarieties NVARCHAR(MAX), @Crop NVARCHAR(10), @IsCropInbred BIT, @Json NVARCHAR(MAX);

	DECLARE @DeviationCount INT, @TotalSamples INT = 0, @ActualSamples INT = 0, @MatchCounter INT = 0, @InbreedCounter INT = 0, @QualityClass INT, @Result DECIMAL;
	
	SET NOCOUNT ON;

	SELECT 
		@Reciprocal		= ReciprocalProd,
		@VarietyNr		= DA.VarietyNr,
		@MaleParent		= V.Male,
		@FemaleParent	= V.Female,
		@Crop			= V.CropCode,
		@IsCropInbred	= C.InBreed 
	FROM DeterminationAssignment DA
	JOIN Variety V ON V.VarietyNr = DA.VarietyNr
	JOIN CropRD C ON C.CropCode = V.CropCode
	WHERE DA.DetAssignmentID = @DetAssignmentID

	DECLARE Pattern_Cursor CURSOR LOCAL FAST_FORWARD FOR
	SELECT PatternID, ISNULL(NrOfSamples,0) FROM Pattern WHERE DetAssignmentID = @DetAssignmentID
	OPEN Pattern_Cursor;
	FETCH NEXT FROM Pattern_Cursor INTO @PatternID, @NrOfSamples;
	
	WHILE @@FETCH_STATUS = 0
	BEGIN

		SET @GoodPattern = 0; 
		SET @Badpattern = 0;
		SET @Type = 'Deviating';
		SET @TotalSamples = @TotalSamples + @NrOfSamples;
		SET @PatternStatus = 100; --'Active';

		IF EXISTS ( SELECT * FROM PatternResult WHERE PatternID = @PatternID AND Score IN ('9999','0099','-')) 
		BEGIN
			SET @BadPattern = @BadPattern + 1;
		END
		ELSE 
		BEGIN
			SET @GoodPattern = @GoodPattern + 1;
		END

		--If Bad pattern percentage is greater than threshold then reject the pattern
		IF (@BadPattern * 100 / (@BadPattern + @GoodPattern) > @MissingResultPercentage)
		BEGIN

			SET @PatternStatus = 200; --'Blocked';
			SET @Type = 'Pattern Rejected';

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

			--if the tested variety is in the clustervarlist this is a matching pattern, and it does not deviate
			IF (LEFT(@ReturnedVarieties,(PATINDEX('%,%',@ReturnedVarieties))-1) = @VarietyNr)
			BEGIN
				SET @Type = 'Matched';
				SET @MatchCounter = @MatchCounter + @NrOfSamples;
			END

			-- For inbred crop, if the parent of tested variety is in the clustervarlist this is inbred
			IF (@IsCropInbred = 1)
			BEGIN

				IF (@Reciprocal = 0 AND LEFT(@ReturnedVarieties,(PATINDEX('%,%',@ReturnedVarieties))-1) = @FemaleParent)
				OR (@Reciprocal = 1 AND LEFT(@ReturnedVarieties,(PATINDEX('%,%',@ReturnedVarieties))-1) = @MaleParent)
				BEGIN
					SET @Type = 'Inbreed';
					SET @InbreedCounter = @InbreedCounter + @NrOfSamples
				END;

			END;
			
		END;
				
		UPDATE Pattern
		SET [Type]		= @Type,
			[Status]	= @PatternStatus,
			MatchingVar = @MatchingVarieties
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
		StatusCode			= 600
	WHERE DetAssignmentID	= @DetAssignmentID
	
END
GO


