DROP PROCEDURE IF EXISTS [dbo].[PR_FindMatchingVarieties]
GO


-- =============================================
-- Author:		Binod Gurung
-- Create date: 2019/09/05
-- Description:	Procedure to find matching varieties based on give marker values and db marker values
-- =============================================
/*	DECLARE @Json NVARCHAR(MAX) = N'[
					{"ID":1,"MarkerID":44,"MarkerValue":"0102"},
					{"ID":2,"MarkerID":45,"MarkerValue":"0101"},
					{"ID":3,"MarkerID":46,"MarkerValue":"0101"},
					{"ID":4,"MarkerID":47,"MarkerValue":"0101"},
					{"ID":5,"MarkerID":48,"MarkerValue":"0102"},
					{"ID":2,"MarkerID":49,"MarkerValue":"0102"},
					{"ID":3,"MarkerID":50,"MarkerValue":"0102"},
					{"ID":4,"MarkerID":51,"MarkerValue":"0102"}
				]';
	DECLARE @ReturnVarieties nvarchar(max);
	EXEC PR_FindMatchingVarieties @Json, 'TO', 1011843, @ReturnVarieties OUTPUT;
	SELECT @ReturnVarieties;
*/
CREATE PROCEDURE [dbo].[PR_FindMatchingVarieties]
(
	@Json	NVARCHAR(MAX),
	@Crop	NVARCHAR(10),
	@VarietyNr	INT,
	@ReturnVarieties NVARCHAR(MAX) OUTPUT
)
AS
BEGIN
	SET NOCOUNT ON;

	-- step 1
	DECLARE @MarkerTbl Table(ID INT,MarkerID INT, MarkerValue NVARCHAR(10));
	DECLARE @Table1 Table(VarietyNr INT); 
	DECLARE @Table2 Table(VarietyNr INT); 
	DECLARE @FirstMarkerID INT;
	DECLARE @FirstMarkerValue NVARCHAR(20);

	--Insert MarkerID and MarkerVlaue to Table from JSON
	INSERT INTO @MarkerTbl (ID, MarkerID, MarkerValue)
	SELECT ID, MarkerID, MarkerValue
	FROM OPENJSON(@Json) WITH
	(
		ID			INT '$.ID',
		MarkerID	INT '$.MarkerID',
		MarkerValue	NVARCHAR(MAX) '$.MarkerValue'
	)
	
	SELECT 
		@FirstMarkerID = MarkerID,
		@FirstMarkerValue = MarkerValue 
	FROM @MarkerTbl WHERE ID = 1;
	
	-- step 2 - Fill temptable from all varieties which has no markervaluepervariety or has markervaluepervariety and is matching
	INSERT INTO @Table1 (VarietyNr)
	(
		-- find varieties which has matching score 
		SELECT 		
			V.VarietyNr
		FROM Variety V
		JOIN MarkerValuePerVariety MVPV ON MVPV.VarietyNr = V.VarietyNr AND MVPV.MarkerID = @FirstMarkerID AND dbo.FN_IsMatching(@FirstMarkerValue, MVPV.AlleleScore) = 1
		WHERE V.CropCode = @Crop AND V.PacComp = 1 AND V.[Status] NOT IN ('100','999', 'PD', 'GB')
		GROUP BY V.VarietyNr
		UNION
		-- find varieties which has no score
		SELECT		
			V.VarietyNr
		FROM Variety V
		LEFT JOIN MarkerValuePerVariety MVPV ON MVPV.VarietyNr = V.VarietyNr AND MVPV.MarkerID = @FirstMarkerID
		WHERE V.CropCode = @Crop AND MVPV.VarietyNr IS NULL AND V.PacComp = 1 AND V.[Status] NOT IN ('100','999', 'PD', 'GB')
		GROUP BY V.VarietyNr
	) 

	--step 3 - Find varieties from filled temp-table which has mvpv and not matching
	INSERT INTO @Table2 (VarietyNr)
	(
		SELECT		
			MVPV.VarietyNr		
		FROM @Table1 V
		JOIN MarkerValuePerVariety MVPV ON MVPV.VarietyNr = V.VarietyNr 
		JOIN @MarkerTbl MT ON MT.MarkerID = MVPV.MarkerID AND dbo.FN_IsMatching(MT.Markervalue, MVPV.AlleleScore) = 0
		WHERE MT.ID <> 1
		GROUP BY MVPV.VarietyNr
	) 

	--Delete all records from @Table1 found in @table2 because these are varieties that has score but not matching
	DELETE T1 
	FROM @Table1 T1
	JOIN @Table2 T2 ON T2.VarietyNr = T1.VarietyNr

	--step 4 - Place input varieties at first in the list 
	SET @ReturnVarieties = @VarietyNr;
	DELETE FROM @Table1 WHERE VarietyNr = @VarietyNr;

	--step 5 - Return Varities in comma separated list
	SELECT @ReturnVarieties = COALESCE( @ReturnVarieties + ',' + CAST(VarietyNr AS NVARCHAR(20)), '') 
	FROM @Table1
	
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

	DECLARE @DeviationCount INT, @TotalSamples INT, @ActualSamples INT = 0, @MatchCounter INT = 0, @InbreedCounter INT = 0, @QualityClass INT, @Result DECIMAL;
	
	SET NOCOUNT ON;

	IF NOT EXISTS(SELECT DetAssignmentID FROM DeterminationAssignment WHERE DetAssignmentID = @DetAssignmentID AND StatusCode = 500)
		RETURN;

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

	SELECT @TotalSamples = SUM(ISNULL(NrOfSamples,0)) FROM pattern WHERE DetAssignmentID = @DetAssignmentID

	DECLARE Pattern_Cursor CURSOR LOCAL FAST_FORWARD FOR
	SELECT PatternID, ISNULL(NrOfSamples,0) FROM Pattern WHERE DetAssignmentID = @DetAssignmentID
	OPEN Pattern_Cursor;
	FETCH NEXT FROM Pattern_Cursor INTO @PatternID, @NrOfSamples;
	
	WHILE @@FETCH_STATUS = 0
	BEGIN

		SET @GoodPattern = 0; 
		SET @Badpattern = 0;
		SET @Type = 'Deviating';
		SET @PatternStatus = 100; --'Active';
				
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

			--if the tested variety is in the clustervarlist this is a matching pattern, and it does not deviate
			IF (LEFT(@ReturnedVarieties,(PATINDEX('%,%',@ReturnedVarieties))-1) = @VarietyNr)
			BEGIN
				SET @Type = 'Match';
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
			MatchingVar = @MatchingVarieties,
			SamplePer	= CASE WHEN @PatternStatus = 100 THEN ROUND(@NrOfSamples / CAST (@TotalSamples AS DECIMAL) * 100, 2) ELSE 0 END
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


