DROP PROCEDURE IF EXISTS [dbo].[PR_ProcessAllTestResultSummary]
GO


-- EXEC PR_ProcessAllTestResultSummary 0.43, 
-- All input values are in percentage (1 - 100)
CREATE PROCEDURE [dbo].[PR_ProcessAllTestResultSummary]
(
	@MissingResultPercentage DECIMAL,
	@ThresholdA	DECIMAL,
	@ThresholdB DECIMAL
)
AS 
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
	   BEGIN TRANSACTION;
    
	   DECLARE @tbl TABLE(ID INT IDENTITY(1, 1), DetAssignmentID INT);
    
	   INSERT @tbl(DetAssignmentID)
	   SELECT 
		  W.DetAssignmentID
	   FROM TestResult TR
	   JOIN Well W ON W.WellID = TR.WellID
	   JOIN TestDetAssignment TDA ON TDA.DetAssignmentID = W.DetAssignmentID
	   JOIN DeterminationAssignment DA ON DA.DetAssignmentID = TDA.DetAssignmentID
	   WHERE ISNULL(W.DetAssignmentID, 0) <> 0
	   AND DA.StatusCode = 500
	   GROUP BY W.DetAssignmentID;

	   DECLARE @DetAssignmentID INT, @ID INT = 1, @Count INT;
	   SELECT @Count = COUNT(ID) FROM @tbl;
	   WHILE(@ID <= @Count) BEGIN
		  SELECT 
			 @DetAssignmentID = DetAssignmentID 
		  FROM @tbl
		  WHERE ID = @ID;

		  --Background task 1
		  EXEC PR_ProcessTestResultSummary @DetAssignmentID;

		  --Background task 2, 3, 4
		  EXEC PR_BG_Task_2_3_4 @DetAssignmentID, @MissingResultPercentage, @ThresholdA, @ThresholdB;

		  SET @ID = @ID + 1;
	   END

	   COMMIT;
    END TRY
    BEGIN CATCH
	   IF @@TRANCOUNT > 0
		  ROLLBACK;
	   THROW;
    END CATCH
END
GO

DROP PROCEDURE IF EXISTS [dbo].[PR_ProcessTestResultSummary]
GO

--EXEC PR_ProcessTestResultSummary 835633;
CREATE PROCEDURE [dbo].[PR_ProcessTestResultSummary]
(
    @DetAssignmentID INT
) AS BEGIN
    SET NOCOUNT ON;
    DECLARE @TransCount BIT = 0;
    
    DECLARE @SQL NVARCHAR(MAX), @Columns NVARCHAR(MAX), @Columns2 NVARCHAR(MAX);

	IF NOT EXISTS(SELECT DetAssignmentID FROM DeterminationAssignment WHERE DetAssignmentID = @DetAssignmentID AND StatusCode = 500)
		RETURN;

    SELECT
	   @Columns = COALESCE(@Columns + ',', '') + QUOTENAME(MarkerID),
	   @Columns2 = COALESCE(@Columns2 + ',', '') + QUOTENAME(MarkerID) + ' NVARCHAR(20)'
    FROM
    (
	   SELECT DISTINCT 
		  TR.MarkerID    
	   FROM TestResult TR
	   JOIN Well W ON W.WellID = TR.WellID
	   WHERE W.DetAssignmentID = @DetAssignmentID
    ) C;

    SET @SQL = N'
    WITH CTE AS
    (
	   SELECT 
		  ID = ROW_NUMBER() OVER(ORDER BY NrOfSample),
		  *
	   FROM
	   (
		  SELECT '+ @Columns + N', 
			 NrOfSample = COUNT(RowNr)
		  FROM
		  (
			 SELECT * FROM
			 (
				SELECT 
				    RowNr = ROW_NUMBER() OVER(PARTITION BY TR.MarkerID ORDER BY TR.MarkerID),
				    TR.MarkerID,
				    TR.Score
				FROM TestResult TR
				JOIN Well W ON W.WellID = TR.WellID
				WHERE W.DetAssignmentID = @DetAssignmentID
			 ) V1
			 PIVOT
			 (
				MAX(Score)
				FOR MarkerID IN('+ @Columns + N')
			 ) P1
		  ) V2 GROUP BY '+ @Columns + 
	   N') T1
    )
    SELECT 
	  ID,
	  NrOfSample,
	  Details = 
	  (
		  SELECT
			 *
		  FROM CTE
		  WHERE ID = T.ID
		  FOR JSON PATH
	  )
    FROM CTE T';

    BEGIN TRY
	   IF @@TRANCOUNT = 0 BEGIN
		  BEGIN TRANSACTION;
		  SET @TransCount = 1;
	   END

	   DECLARE @tbl TABLE(ID INT, NrOfSamples INT, Details NVARCHAR(MAX));
	   INSERT @tbl(ID, NrOfSamples, Details)
	   EXEC sp_executesql @SQL, N'@DetAssignmentID INT', @DetAssignmentID;

	   DECLARE @Pattern PatternTVP;

	   MERGE Pattern T
	   USING @tbl S ON 1 = 0
	   WHEN NOT MATCHED THEN
		  INSERT(DetAssignmentID, NrOfSamples, SamplePer, [Type], MatchingVar)
		  VALUES(@DetAssignmentID, S.NrOfSamples, 0, '', '')
	   OUTPUT INSERTED.PatternID, S.Details INTO @Pattern;

	   SET @SQL = N'
	   SELECT 
		  UP.PatternID,
		  UP.MarkerID,
		  UP.Score
	   FROM
	   (
		  SELECT 
			 P.PatternID,
			 P2.*
		  FROM @Pattern P
		  CROSS APPLY OPENJSON(P.Details) WITH (' + @Columns2 + N') P2
	   ) T UNPIVOT
	   (
		  Score
		  FOR MarkerID IN (' + @Columns + N')
	   ) UP';

	   INSERT PatternResult(PatternID, MarkerID, Score)
	   EXEC sp_executesql @SQL, N'@Pattern PatternTVP READONLY', @Pattern;

	   IF @TransCount = 1 
		  COMMIT;
    END TRY
    BEGIN CATCH
	   IF @TransCount = 1 
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


