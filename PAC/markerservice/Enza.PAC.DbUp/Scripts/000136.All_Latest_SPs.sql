/****** Object:  StoredProcedure [dbo].[PR_ValidateCapacityPerFolder]    Script Date: 1/23/2020 5:39:12 PM ******/
DROP PROCEDURE IF EXISTS [dbo].[PR_ValidateCapacityPerFolder]
GO
/****** Object:  StoredProcedure [dbo].[PR_UpdateTestStatus]    Script Date: 1/23/2020 5:39:12 PM ******/
DROP PROCEDURE IF EXISTS [dbo].[PR_UpdateTestStatus]
GO
/****** Object:  StoredProcedure [dbo].[PR_ThrowError]    Script Date: 1/23/2020 5:39:12 PM ******/
DROP PROCEDURE IF EXISTS [dbo].[PR_ThrowError]
GO
/****** Object:  StoredProcedure [dbo].[PR_SavePlanningCapacitySO_LS]    Script Date: 1/23/2020 5:39:12 PM ******/
DROP PROCEDURE IF EXISTS [dbo].[PR_SavePlanningCapacitySO_LS]
GO
/****** Object:  StoredProcedure [dbo].[PR_SaveMarkerPerVarieties]    Script Date: 1/23/2020 5:39:12 PM ******/
DROP PROCEDURE IF EXISTS [dbo].[PR_SaveMarkerPerVarieties]
GO
/****** Object:  StoredProcedure [dbo].[PR_SaveCapacity]    Script Date: 1/23/2020 5:39:12 PM ******/
DROP PROCEDURE IF EXISTS [dbo].[PR_SaveCapacity]
GO
/****** Object:  StoredProcedure [dbo].[PR_ReTestDetermination]    Script Date: 1/23/2020 5:39:12 PM ******/
DROP PROCEDURE IF EXISTS [dbo].[PR_ReTestDetermination]
GO
/****** Object:  StoredProcedure [dbo].[PR_ReservePlateplansInLimsCallback]    Script Date: 1/23/2020 5:39:12 PM ******/
DROP PROCEDURE IF EXISTS [dbo].[PR_ReservePlateplansInLimsCallback]
GO
/****** Object:  StoredProcedure [dbo].[PR_ReceiveResultsinKscoreCallback]    Script Date: 1/23/2020 5:39:12 PM ******/
DROP PROCEDURE IF EXISTS [dbo].[PR_ReceiveResultsinKscoreCallback]
GO
/****** Object:  StoredProcedure [dbo].[PR_ProcessTestResultSummary]    Script Date: 1/23/2020 5:39:12 PM ******/
DROP PROCEDURE IF EXISTS [dbo].[PR_ProcessTestResultSummary]
GO
/****** Object:  StoredProcedure [dbo].[PR_ProcessAllTestResultSummary]    Script Date: 1/23/2020 5:39:12 PM ******/
DROP PROCEDURE IF EXISTS [dbo].[PR_ProcessAllTestResultSummary]
GO
/****** Object:  StoredProcedure [dbo].[PR_PlateFilling]    Script Date: 1/23/2020 5:39:12 PM ******/
DROP PROCEDURE IF EXISTS [dbo].[PR_PlateFilling]
GO
/****** Object:  StoredProcedure [dbo].[PR_PlanAutoDeterminationAssignments]    Script Date: 1/23/2020 5:39:12 PM ******/
DROP PROCEDURE IF EXISTS [dbo].[PR_PlanAutoDeterminationAssignments]
GO
/****** Object:  StoredProcedure [dbo].[PR_Ignite_Decluster]    Script Date: 1/23/2020 5:39:12 PM ******/
DROP PROCEDURE IF EXISTS [dbo].[PR_Ignite_Decluster]
GO
/****** Object:  StoredProcedure [dbo].[PR_GetVarieties]    Script Date: 1/23/2020 5:39:12 PM ******/
DROP PROCEDURE IF EXISTS [dbo].[PR_GetVarieties]
GO
/****** Object:  StoredProcedure [dbo].[PR_GetTestInfoForLIMS]    Script Date: 1/23/2020 5:39:12 PM ******/
DROP PROCEDURE IF EXISTS [dbo].[PR_GetTestInfoForLIMS]
GO
/****** Object:  StoredProcedure [dbo].[PR_GetPlatesOverview]    Script Date: 1/23/2020 5:39:12 PM ******/
DROP PROCEDURE IF EXISTS [dbo].[PR_GetPlatesOverview]
GO
/****** Object:  StoredProcedure [dbo].[PR_GetPlateLabels]    Script Date: 1/23/2020 5:39:12 PM ******/
DROP PROCEDURE IF EXISTS [dbo].[PR_GetPlateLabels]
GO
/****** Object:  StoredProcedure [dbo].[PR_GetPlanningCapacitySO_LS]    Script Date: 1/23/2020 5:39:12 PM ******/
DROP PROCEDURE IF EXISTS [dbo].[PR_GetPlanningCapacitySO_LS]
GO
/****** Object:  StoredProcedure [dbo].[PR_GetPeriod]    Script Date: 1/23/2020 5:39:12 PM ******/
DROP PROCEDURE IF EXISTS [dbo].[PR_GetPeriod]
GO
/****** Object:  StoredProcedure [dbo].[PR_GetMinTestStatusPerPeriod]    Script Date: 1/23/2020 5:39:12 PM ******/
DROP PROCEDURE IF EXISTS [dbo].[PR_GetMinTestStatusPerPeriod]
GO
/****** Object:  StoredProcedure [dbo].[PR_GetMarkers]    Script Date: 1/23/2020 5:39:12 PM ******/
DROP PROCEDURE IF EXISTS [dbo].[PR_GetMarkers]
GO
/****** Object:  StoredProcedure [dbo].[PR_GetMarkerPerVarieties]    Script Date: 1/23/2020 5:39:12 PM ******/
DROP PROCEDURE IF EXISTS [dbo].[PR_GetMarkerPerVarieties]
GO
/****** Object:  StoredProcedure [dbo].[PR_GetInfoForUpdateDA]    Script Date: 1/23/2020 5:39:12 PM ******/
DROP PROCEDURE IF EXISTS [dbo].[PR_GetInfoForUpdateDA]
GO
/****** Object:  StoredProcedure [dbo].[PR_GetInfoForFillPlatesInLIMS]    Script Date: 1/23/2020 5:39:12 PM ******/
DROP PROCEDURE IF EXISTS [dbo].[PR_GetInfoForFillPlatesInLIMS]
GO
/****** Object:  StoredProcedure [dbo].[PR_GetFolderDetails]    Script Date: 1/23/2020 5:39:12 PM ******/
DROP PROCEDURE IF EXISTS [dbo].[PR_GetFolderDetails]
GO
/****** Object:  StoredProcedure [dbo].[PR_GetDeterminationAssignments]    Script Date: 1/23/2020 5:39:12 PM ******/
DROP PROCEDURE IF EXISTS [dbo].[PR_GetDeterminationAssignments]
GO
/****** Object:  StoredProcedure [dbo].[PR_GetDeterminationAssigmentOverview]    Script Date: 1/23/2020 5:39:12 PM ******/
DROP PROCEDURE IF EXISTS [dbo].[PR_GetDeterminationAssigmentOverview]
GO
/****** Object:  StoredProcedure [dbo].[PR_GetDeterminationAssigmentForSetABS]    Script Date: 1/23/2020 5:39:12 PM ******/
DROP PROCEDURE IF EXISTS [dbo].[PR_GetDeterminationAssigmentForSetABS]
GO
/****** Object:  StoredProcedure [dbo].[PR_GetDeclusterResult]    Script Date: 1/23/2020 5:39:12 PM ******/
DROP PROCEDURE IF EXISTS [dbo].[PR_GetDeclusterResult]
GO
/****** Object:  StoredProcedure [dbo].[PR_GetDataForDecisionScreen]    Script Date: 1/23/2020 5:39:12 PM ******/
DROP PROCEDURE IF EXISTS [dbo].[PR_GetDataForDecisionScreen]
GO
/****** Object:  StoredProcedure [dbo].[PR_GetDataForDecisionDetailScreen]    Script Date: 1/23/2020 5:39:12 PM ******/
DROP PROCEDURE IF EXISTS [dbo].[PR_GetDataForDecisionDetailScreen]
GO
/****** Object:  StoredProcedure [dbo].[PR_GetCapacity]    Script Date: 1/23/2020 5:39:12 PM ******/
DROP PROCEDURE IF EXISTS [dbo].[PR_GetCapacity]
GO
/****** Object:  StoredProcedure [dbo].[PR_GetBatch]    Script Date: 1/23/2020 5:39:12 PM ******/
DROP PROCEDURE IF EXISTS [dbo].[PR_GetBatch]
GO
/****** Object:  StoredProcedure [dbo].[PR_GetAvailableCapacity_For_AutoPlan_LS]    Script Date: 1/23/2020 5:39:12 PM ******/
DROP PROCEDURE IF EXISTS [dbo].[PR_GetAvailableCapacity_For_AutoPlan_LS]
GO
/****** Object:  StoredProcedure [dbo].[PR_GenerateFolderDetails]    Script Date: 1/23/2020 5:39:12 PM ******/
DROP PROCEDURE IF EXISTS [dbo].[PR_GenerateFolderDetails]
GO
/****** Object:  StoredProcedure [dbo].[PR_FitPlatesToFolder]    Script Date: 1/23/2020 5:39:12 PM ******/
DROP PROCEDURE IF EXISTS [dbo].[PR_FitPlatesToFolder]
GO
/****** Object:  StoredProcedure [dbo].[PR_FindMatchingVarieties]    Script Date: 1/23/2020 5:39:12 PM ******/
DROP PROCEDURE IF EXISTS [dbo].[PR_FindMatchingVarieties]
GO
/****** Object:  StoredProcedure [dbo].[PR_FindInbredMarker]    Script Date: 1/23/2020 5:39:12 PM ******/
DROP PROCEDURE IF EXISTS [dbo].[PR_FindInbredMarker]
GO
/****** Object:  StoredProcedure [dbo].[PR_Decluster]    Script Date: 1/23/2020 5:39:12 PM ******/
DROP PROCEDURE IF EXISTS [dbo].[PR_Decluster]
GO
/****** Object:  StoredProcedure [dbo].[PR_ConfirmPlanning]    Script Date: 1/23/2020 5:39:12 PM ******/
DROP PROCEDURE IF EXISTS [dbo].[PR_ConfirmPlanning]
GO
/****** Object:  StoredProcedure [dbo].[PR_BG_Task_2_3_4]    Script Date: 1/23/2020 5:39:12 PM ******/
DROP PROCEDURE IF EXISTS [dbo].[PR_BG_Task_2_3_4]
GO
/****** Object:  StoredProcedure [dbo].[PR_ApproveDetermination]    Script Date: 1/23/2020 5:39:12 PM ******/
DROP PROCEDURE IF EXISTS [dbo].[PR_ApproveDetermination]
GO
/****** Object:  StoredProcedure [dbo].[EZ_GetDeterminationAssignment]    Script Date: 1/23/2020 5:39:12 PM ******/
DROP PROCEDURE IF EXISTS [dbo].[EZ_GetDeterminationAssignment]
GO
/****** Object:  UserDefinedFunction [dbo].[FN_IsPacProfileComplete]    Script Date: 1/23/2020 5:39:12 PM ******/
DROP FUNCTION IF EXISTS [dbo].[FN_IsPacProfileComplete]
GO
/****** Object:  UserDefinedFunction [dbo].[FN_IsMatching]    Script Date: 1/23/2020 5:39:12 PM ******/
DROP FUNCTION IF EXISTS [dbo].[FN_IsMatching]
GO
/****** Object:  UserDefinedFunction [dbo].[FN_IsMatching]    Script Date: 1/23/2020 5:39:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Binod Gurung
-- Create date: 2019/09/05
-- Description:	Function to determine if proposed value and referenced value is matching
-- =============================================
-- SELECT  dbo.FN_IsMatching ('0000','1111')
CREATE FUNCTION [dbo].[FN_IsMatching]
(
	@ProposedValue NVARCHAR(20),
	@ReferenceValue NVARCHAR(20)
)
RETURNS BIT
AS
BEGIN

	DECLARE @HighNibbleProp NVARCHAR(10), @LowNibbleProp NVARCHAR(10), @HighNibbleRef NVARCHAR(10), @LowNibbleRef NVARCHAR(10);
	
	IF(CAST(@ProposedValue AS INT) < 100)
	BEGIN
		
		IF( (@ProposedValue = '0001' AND @ReferenceValue = '0000') OR (@ReferenceValue = '0001' AND @ProposedValue = '0000'))
			RETURN 0;
		IF(@ProposedValue NOT IN ('0000','0001','0002','0055','0099','9999') OR @ReferenceValue NOT IN ('0000','0001','0055','0099','9999'))
			RETURN 0;
		RETURN 1;

	END
	ELSE
	BEGIN

		IF (@ProposedValue = '' OR @ReferenceValue = '' OR @ProposedValue = @ReferenceValue OR @ProposedValue IN ('9999','5555') OR @ReferenceValue IN ('5555','5599','9999'))
			RETURN 1;

		SELECT	@HighNibbleProp = SUBSTRING(@ProposedValue,0,2),
				@LowNibbleProp	= SUBSTRING(@ProposedValue,2,2),
				@HighNibbleRef	= SUBSTRING(@ProposedValue,0,2),
				@LowNibbleRef	= SUBSTRING(@ProposedValue,2,2);

		IF(@LowNibbleProp IN ('55','99') AND (@HighNibbleProp = @HighNibbleRef OR @HighNibbleProp = @LowNibbleRef))
			RETURN 1;
		IF(@LowNibbleRef IN ('55','99') AND (@HighNibbleRef = @HighNibbleProp OR @HighNibbleRef = @LowNibbleProp))
			RETURN 1;
		IF (@LowNibbleProp = '55' AND @LowNibbleRef = '99')
			RETURN 1;
		RETURN 0;

	END

	RETURN 0;
END
GO
/****** Object:  UserDefinedFunction [dbo].[FN_IsPacProfileComplete]    Script Date: 1/23/2020 5:39:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Binod Gurung
-- Create date: 2019/09/05
-- Description:	Function to check if pac profile is comlete for variety or not
-- =============================================
-- SELECT  dbo.FN_IsPacProfileComplete (21047, 8, 'SP')
CREATE FUNCTION [dbo].[FN_IsPacProfileComplete]
(
	@VarietyNr INT,
	@PlatformID INT,
	@CropCode NVARCHAR(5)
)
RETURNS BIT
AS
BEGIN

	DECLARE @ReturnValue BIT;

	IF EXISTS 
	(
		SELECT MCP.MarkerID
		FROM MarkerCropPlatform MCP
		LEFT JOIN MarkerValuePerVariety MVPV ON VarietyNr = @VarietyNr AND MVPV.MarkerID = MCP.MarkerID 
		WHERE PlatformID = @PlatformID AND CropCode = @CropCode AND InMMS = 1 AND VarietyNr IS NULL
	)
		SET @ReturnValue = 0;
	ELSE
		SET @ReturnValue = 1;

	Return @ReturnValue;

END
GO
/****** Object:  StoredProcedure [dbo].[EZ_GetDeterminationAssignment]    Script Date: 1/23/2020 5:39:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--EXEC [EZ_GetDeterminationAssignment] NULL, '2019-09-02', '2019-09-08' , 'PAC-01,PAC-EL', 'TO,SP,HP,EP', '5', '1,2,3,5,7', 0, 100;
CREATE PROCEDURE [dbo].[EZ_GetDeterminationAssignment] 
     @Determination_assignment INT = 0 --= 1207375                               [OPTIONAL VALUE!!]
       ,@Planned_date_From DateTime --= '2016-03-04 00:00:00.000'  
       ,@Planned_date_To DateTime --= '2018-12-06 00:00:00.000'
       ,@MethodCode Varchar(MAX) --= 'PAC-01'
       ,@ABScrop Varchar(MAX) --= 'SP'
       ,@StatusCode Varchar(MAX) --= '5'
       ,@Priority Varchar(MAX) --= '1,2,3,4'
       ,@PageNumber INT --= 0
       ,@PageSize INT --= 10

AS 
BEGIN

SET @StatusCode = replace(@StatusCode, ' ', '') 
SET @Priority = replace(@Priority, ' ', '') 

DECLARE @TotalCount INT
SELECT @TotalCount = Count(*) 
 FROM ABS_Determination_assignments
WHERE 
       CASE WHEN @Determination_assignment IS NULL OR @Determination_assignment = 0
             THEN 1
             ELSE Determination_assignment
       END = CASE WHEN @Determination_assignment IS NULL OR @Determination_assignment = 0
                           THEN 1
                           ELSE @Determination_assignment
       END
   --    And 
	  --(
	  -- (ISNULL(@Planned_date_From, '') = '' OR Date_booked >= @Planned_date_From)
	  -- And 
	  -- (ISNULL(@Planned_date_To, '') = '' OR Date_booked <= @Planned_date_To)
	  -- )
       AND Method_code IN (SELECT [value] FROM STRING_SPLIT(@MethodCode, ','))
       AND Crop_code   IN (SELECT [value] FROM STRING_SPLIT(@ABScrop, ','))
    AND Determination_status_code IN (SELECT [value] FROM STRING_SPLIT(@StatusCode, ','))
    AND Priority_code IN (SELECT [value] FROM STRING_SPLIT(@Priority, ','))
	
	
SELECT DA.[Determination_assignment] AS DeterminationAssignment
         ,DA.[Date_booked] AS planned_date 
         ,DA.[Sample_number] AS Sample
         ,DA.[Priority_code] AS Prio
         ,DA.[Method_code] AS MethodCode
         ,DA.[Crop_code] AS ABScrop
         ,DA.[Primary_number] AS VarietyNumber
         ,DA.[Batch_number] AS BatchNumber
         ,DA.[Repeat_indicator] AS RepeatIndicator
         ,DA.[Process_code] AS Process
         ,DA.Determination_status_code AS ProductStatus                          -- Vervangen voor juiste kolom
         ,PL.Batch_output_description AS BatchOutputDescription           -- Zie [ABS_DATA].[dbo].[Process_lots] 
         ,DA.[Utmost_inlay_date] AS UtmostInlayDate
         ,DA.[Expected_date_ready] AS ExpectedReadyDate
		 ,GETUTCDATE()
		 ,CAST(0 AS BIT)
		 ,CAST(0 AS BIT)
		 ,'M3'
		 ,'NLEN'
         ,@TotalCount AS TotalCount
  FROM ABS_Determination_assignments DA
  LEFT JOIN dbo.ABS_Process_lots PL
  ON PL.Batch_number = DA.Batch_number
  WHERE 
       CASE WHEN @Determination_assignment IS NULL OR @Determination_assignment = 0
             THEN 1
             ELSE Determination_assignment
       END = CASE WHEN @Determination_assignment IS NULL OR @Determination_assignment = 0
                           THEN 1
                           ELSE @Determination_assignment
       END
   --   And 
	  --(
	  -- (ISNULL(@Planned_date_From, '') = '' OR Date_booked >= @Planned_date_From)
	  -- And 
	  -- (ISNULL(@Planned_date_To, '') = '' OR Date_booked <= @Planned_date_To)
	  -- )
       AND Method_code IN (SELECT [value] FROM STRING_SPLIT(@MethodCode, ','))
       AND Crop_code   IN (SELECT [value] FROM STRING_SPLIT(@ABScrop, ','))
	AND Determination_status_code IN (SELECT [value] FROM STRING_SPLIT(@StatusCode, ','))
       AND Priority_code IN (SELECT [value] FROM STRING_SPLIT(@Priority, ','))
  ORDER BY Crop_code 
  OFFSET @PageSize * (@PageNumber -1) ROWS 
  FETCH NEXT @PageSize ROWS ONLY

END

GO
/****** Object:  StoredProcedure [dbo].[PR_ApproveDetermination]    Script Date: 1/23/2020 5:39:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
Author					Date			Remarks
Krishna Gautam			2020/01/10		Created service to approve determinationAssignment to approved.

============ExAMPLE===================
--EXEC PR_ApproveDetermination 125487
*/
CREATE PROCEDURE [dbo].[PR_ApproveDetermination]
(
	@ID INT,
	@User NVARCHAR(MAX) = NULL
)
AS 
BEGIN

	IF NOT EXISTS (SELECT DetAssignmentID FROM DeterminationAssignment WHERE DetAssignmentID = @ID)
	BEGIN
		EXEC PR_ThrowError 'Invalid ID.';
		RETURN
	END

	DECLARE @TestID INT;

	SELECT TOP 1 @TestID = TestID FROM TestDetAssignment WHERE DetAssignmentID = @ID;

	UPDATE DeterminationAssignment 
		SET 
		StatusCode = 700,
		ValidatedBy = @User,
		ValidatedOn = GETUTCDATE()		
	WHERE DetAssignmentID = @ID;

	IF NOT EXISTS(SELECT * FROM TestDetAssignment TDA JOIN DeterminationAssignment DA ON DA.DetAssignmentID = TDA.TestDetAssignmentID
	WHERE TDA.TestID = @TestID AND DA.StatusCode NOT IN (700,999))
	BEGIN
		UPDATE Test SET StatusCode = 600 WHERE TestID = @TestID;
	END
	
END
GO
/****** Object:  StoredProcedure [dbo].[PR_BG_Task_2_3_4]    Script Date: 1/23/2020 5:39:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
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
/****** Object:  StoredProcedure [dbo].[PR_ConfirmPlanning]    Script Date: 1/23/2020 5:39:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
Author					Date			Description
Binod Gurung			2019-Sept-04	Service to confirm planning
Krishna Gautam			2020-jan-09		Changes to made to add extra folder or extra variety on plate filling after confirming with high lab priority even if plates is already requested on LIMS.
Binod Gurung			2020-jan-23		Transcation isolation level implemented to avoid record lock
										SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

===================================Example================================

EXEC PR_ConfirmPlanning 4780, N'[{"DetAssignmentID":733313,"MethodCode":"PAC-01","ABSCropCode":"HP","SampleNr":1223714,"UtmostInlayDate":"11/03/2016","ExpectedReadyDate":"08/03/2016",
"PriorityCode":1,"BatchNr":0,"RepeatIndicator":false,"VarietyNr":20993,"ProcessNr":"0","ProductStatus":"5","Remarks":null,"PlannedDate":"08/01/2016","IsPlanned":false,"UsedFor":"Hyb",
"CanEditPlanning":true,"can":true,"init":false,"flag":true,"change":true,"Action":"i"}]';
*/
CREATE PROCEDURE [dbo].[PR_ConfirmPlanning]
(
    @PeriodID	 INT,
    @DataAsJson NVARCHAR(MAX)
)
AS 
BEGIN
    SET NOCOUNT ON;

	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    DECLARE @TransCount BIT = 0;
    DECLARE @StartDate DATE, @EndDate DATE;   
    DECLARE @PlatformID INT = (SELECT PlatformID FROM [Platform] WHERE PlatformCode = 'LS'); --light scanner   

    SELECT 
	   @StartDate = P.StartDate,
	   @EndDate = P.EndDate
    FROM [Period] P 
    WHERE P.PeriodID = @PeriodID;

    BEGIN TRY
	   IF @@TRANCOUNT = 0 BEGIN
		  BEGIN TRANSACTION;
		  SET @TransCount = 1;
	   END
	   
	   DELETE DA
	   FROM DeterminationAssignment DA
	   JOIN OPENJSON(@DataAsJson) WITH
	   (
		  DetAssignmentID INT,
		  [Action]	   CHAR(1)
	   ) S ON S.DetAssignmentID = DA.DetAssignmentID
	   WHERE S.[Action] = 'D'
	   AND CAST(DA.PlannedDate AS DATE) BETWEEN @StartDate AND @EndDate;

	   --Change status to 200 of those records which falls under that period
	   UPDATE DA SET 
		  DA.IsLabPriority = S.IsLabPriority
	   FROM DeterminationAssignment DA
	   JOIN OPENJSON(@DataAsJson) WITH
	   (
		  DetAssignmentID INT,
		  IsLabPriority   BIT,
		  [Action]	   CHAR(1)
	   ) S ON S.DetAssignmentID = DA.DetAssignmentID
	   WHERE S.[Action] = 'U'
	   AND CAST(DA.PlannedDate AS DATE) BETWEEN @StartDate AND @EndDate;

	   --update status of all records of that particular week if there are no any data comes in json
	   UPDATE DA
		  SET DA.StatusCode = 200
	   FROM DeterminationAssignment DA
	   WHERE DA.StatusCode = 100 
	   AND CAST(DA.PlannedDate AS DATE) BETWEEN @StartDate AND @EndDate; 
	   	   
	   --validate
	   DECLARE @Groups TABLE
	   (
		  ABSCropCode	    NVARCHAR(10), 
		  MethodCode	    NVARCHAR(50), 
		  UsedFor	    VARCHAR(5), 
		  ReservePlates   DECIMAL(5,2),
		  TotalPlates	DECIMAL(5,2)
	   );

	   INSERT @Groups(ABSCropCode, MethodCode, UsedFor, ReservePlates, TotalPlates)
	   EXEC PR_ValidateCapacityPerFolder @PeriodID, @DataAsJson;

	   IF @@ROWCOUNT > 0 BEGIN
		  SELECT 
			 ABSCropCode, 
			 MethodCode, 
			 UsedFor, 
			 ReservePlates, 
			 TotalPlates
		  FROM @Groups;
		  
		  IF @TransCount = 1 
			 ROLLBACK;

		  RETURN;
	   END
	   
	   --insert new records if it is not in automatic plan but user has checked it up
	   INSERT INTO DeterminationAssignment
	   (
			DetAssignmentID, 
			SampleNr, 
			PriorityCode, 
			MethodCode, 
			ABSCropCode, 
			VarietyNr, 
			BatchNr, 
			RepeatIndicator, 
			Process, 
			ProductStatus, 
			Remarks, 
			PlannedDate, 
			UtmostInlayDate, 
			ExpectedReadyDate,
			StatusCode,		  
			ReceiveDate,
			ReciprocalProd,
			BioIndicator,
			LogicalClassificationCode,
			LocationCode,
			IsLabPriority
	   )
	   SELECT 
			S.DetAssignmentID, 
			S.SampleNr, 
			S.PriorityCode, 
			S.MethodCode, 
			S.ABSCropCode, 
			S.VarietyNr, 
			S.BatchNr, 
			S.RepeatIndicator, 
			S.Process, 
			S.ProductStatus, 
			S.Remarks, 
			CASE WHEN CAST(S.PlannedDate AS DATE) BETWEEN @StartDate AND @EndDate THEN S.PlannedDate ELSE @EndDate END,
			S.UtmostInlayDate, 
			S.ExpectedReadyDate,
			200,	  
			S.ReceiveDate,
			S.ReciprocalProd,
			S.BioIndicator,
			S.LogicalClassificationCode,
			S.LocationCode,
			S.IsLabPriority
	   FROM OPENJSON(@DataAsJson) WITH
	   (
			DetAssignmentID	   INT,
			SampleNr		   INT,
			PriorityCode	   INT,
			MethodCode		   NVARCHAR(25),
			ABSCropCode		   NVARCHAR(10),
			VarietyNr		   INT,
			BatchNr		   INT,
			RepeatIndicator	   BIT,
			Process			   NVARCHAR(100),
			ProductStatus	   NVARCHAR(100),
			Remarks			   NVARCHAR(250),
			PlannedDate		   DATETIME,
			UtmostInlayDate	   DATETIME,
			ExpectedReadyDate   DATETIME,
			IsLabPriority	  BIT,
			[Action]	   CHAR(1),	   
			ReceiveDate		DATETIME,
			ReciprocalProd	BIT,
			BioIndicator		BIT,
			LogicalClassificationCode	NVARCHAR(20),
			LocationCode				NVARCHAR(20)
	   ) S
	   JOIN ABSCrop C ON C.ABSCropCode = S.ABSCropCode
	   JOIN Variety V ON V.VarietyNr = S.VarietyNr
	   LEFT JOIN DeterminationAssignment DA ON DA.DetAssignmentID = S.DetAssignmentID
	   WHERE S.[Action] = 'I'
	   AND S.PriorityCode NOT IN(4, 7, 8)
	   AND DA.DetAssignmentID IS NULL
	   AND dbo.FN_IsPacProfileComplete (V.VarietyNr, @PlatformID, C.CropCode) = 1 -- #8068 Only plan if PAC profile complete is true
	   
	   --Generate folder structure based on confirmed data
	   --EXEC PR_GenerateFolderDetails @PeriodID, 0; --Process for Non IsLabPriority determination assignments first
	   EXEC PR_FitPlatesToFolder @PeriodID;
	   
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
/****** Object:  StoredProcedure [dbo].[PR_Decluster]    Script Date: 1/23/2020 5:39:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		Binod Gurung
-- Create date: 2019/10/16
-- Description:	Procedure to decluster varieties
-- =============================================
/*	
	DECLARE @ReturnVarieties NVARCHAR(MAX);
	EXEC [PR_Decluster] 1297740, @ReturnVarieties OUTPUT;
	SELECT @ReturnVarieties;
*/
CREATE PROCEDURE [dbo].[PR_Decluster]
(
	@DetAssignmentID	INT,
	@ReturnVarieties	NVARCHAR(MAX) OUTPUT
)
AS
BEGIN

	DECLARE @VarietyNr INT, @Female INT, @Male INT, @IsParent BIT, @Crop NVARCHAR(10), @MarkerID INT, @PlatformID INT, @InMMS BIT, @Score NVARCHAR(10), @VarietyScore NVARCHAR(10), @ImsMarker INT, @Reciprocal BIT;
	DECLARE @ClusteredVarieties NVARCHAR(MAX), @CountClusteredVarieties INT, @Json NVARCHAR(MAX), @List NVARCHAR(MAX) = '';
	DECLARE @MarkerTbl TABLE(DetAssignmentID INT, MarkerID INT, InEDS BIT, InIMS BIT);
	DECLARE @MMSMarkerTbl TABLE (MarkerID INT, MarkerValue NVARCHAR(10));
	DECLARE @EdmMarkerTbl TABLE (MarkerID INT, MarkerValue NVARCHAR(10));
	DECLARE @EdmMarkerTblOrig TABLE (MarkerID INT, MarkerValue NVARCHAR(10));	
	DECLARE @JsonTbl TABLE (ID INT IDENTITY(1,1), MarkerID INT, MarkerValue NVARCHAR(10));
	DECLARE @ClusterVarTbl TABLE(VarietyNr INT);
	DECLARE @EffectPerMarkerTbl Table(MarkerID INT, Total INT);
	DECLARE @Count1 INT, @Count2 INT, @HighestScore INT, @HighestMarker INT;	
	
	SET NOCOUNT ON;

	SET @ReturnVarieties = '';
	
	-- step 1 : calculate cluster varieties

	--delete all previous marker test before starting new
	DELETE MarkerToBeTested
	WHERE DetAssignmentID = @DetAssignmentID;

	--find variety linked to determination assignment
	SELECT 
		@VarietyNr = VarietyNr,
		@Reciprocal = ReciprocalProd
	FROM DeterminationAssignment WHERE DetAssignmentID = @DetAssignmentID;

	--find variety information
	SELECT 
		@Crop = CropCode,
		@Female = V.Female,
		@Male = V.Male,
		@IsParent = (CASE WHEN V.HybOp = 0 AND V.[Type] = 'P' THEN 1 ELSE 0 END)
	FROM Variety V WHERE V.VarietyNr = @VarietyNr;

	DECLARE Marker_Cursor CURSOR LOCAL FAST_FORWARD FOR
		SELECT MarkerID, P.PlatformID, InMMS FROM MarkerCropPlatform MCP
		JOIN [Platform] P ON P.PlatformID = MCP.PlatformID 
		WHERE CropCode = @Crop AND P.UsedForPac = 1
	OPEN Marker_Cursor;
	FETCH NEXT FROM Marker_Cursor INTO @MarkerID, @PlatformID, @InMMS;
	
	WHILE @@FETCH_STATUS = 0
	BEGIN

		SELECT @Score = MVPV.AlleleScore FROM MarkerValuePerVariety MVPV WHERE MVPV.VarietyNr = @VarietyNr AND MarkerID = @MarkerID;

		-- if no score available and marker is in MMS
		IF(ISNULL(@Score,'') = '' AND @InMMS = 1)
			RETURN; --return 

		IF(ISNULL(@Score,'') <> '')
		BEGIN

			IF((@InMMS = 1 OR @IsParent = 1)) --and platform of test and marker is same
			BEGIN
				
				INSERT INTO @MMSMarkerTbl
				VALUES(@MarkerID, @Score);

				INSERT INTO @MarkerTbl
				VALUES(@DetAssignmentID, @MarkerID, ~@InMMS, 0)

			END;
			ELSE IF (@InMMS = 0)
			BEGIN
				
				INSERT INTO @EdmMarkerTbl
				VALUES(@MarkerID, @Score);

			END
		END

		FETCH NEXT FROM Marker_Cursor INTO @MarkerID, @PlatformID, @InMMS;
	END
	
	CLOSE Marker_Cursor;
	DEALLOCATE Marker_Cursor;

	--variables used on next step
	--@MMSMarkerTbl

	--step 2: call findmatchingvarieties
	
	--prepare json to feed sp
	INSERT INTO @JsonTbl(MarkerID, MarkerValue)
	SELECT MarkerID, MarkerValue from @MMSMarkerTbl

	SET @Json = (SELECT * FROM @JsonTbl FOR JSON AUTO);
	EXEC PR_FindMatchingVarieties @Json, @Crop, @VarietyNr, @ClusteredVarieties OUTPUT;

	--insert comma separated list of varieties to table
	INSERT INTO @ClusterVarTbl
	SELECT [value] FROM STRING_SPLIT(@ClusteredVarieties, ',');

	--variables used on next step
	--@ClusterVarTbl, @EdmMarkerTbl

	--step 3 : Apply extra declustering markers

	--data in @EdmMarkerTbl table gets lesser everytime so we need the original list later for finding inbred marker
	INSERT INTO @EdmMarkerTblOrig
	SELECT * FROM @EdmMarkerTbl;

	SELECT @CountClusteredVarieties = COUNT(VarietyNr) FROM @ClusterVarTbl;
			
	--declusterloop
	WHILE (@CountClusteredVarieties > 1)
	BEGIN

		INSERT INTO @EffectPerMarkerTbl
		SELECT MVPV.MarkerID, COUNT(MVPV.MarkerID) FROM 
		(
			SELECT VarietyNr, ED.MarkerID, ED.MarkerValue FROM @ClusterVarTbl
			CROSS APPLY @EdmMarkerTbl ED
		) V2
		LEFT JOIN MarkerValuePerVariety MVPV ON MVPV.VarietyNr = V2.VarietyNr AND MVPV.MarkerID = V2.MarkerID
		WHERE dbo.FN_IsMatching(V2.MarkerValue, MVPV.AlleleScore) = 0
		GROUP BY MVPV.MarkerID
		
		-- Get score and marker with highest score count
		SET @HighestScore = 0;
		SET @HighestMarker = 0;

		SELECT TOP 1
			@HighestMarker = EP.MarkerID,
			@HighestScore = EP.Total
		FROM @EffectPerMarkerTbl EP 
		ORDER BY EP.Total DESC
		--WHERE EP.Total = (SELECT MAX(Total) FROM @EffectPerMarkerTbl)
				
		--if no marker found with @EffectPerMarkerTbl then quit this loop
		IF(ISNULL(@HighestScore, 0) = 0)
			BREAK;

		-- if marker found then remove marker from edm markerlist
		DELETE FROM @EdmMarkerTbl
		WHERE MarkerID = @HighestMarker

		--Remove varieties from Clusteredlist that no longer match the variety in test - that has markervaluepervariety record but not matcing
		
		SELECT TOP 1 @VarietyScore = AlleleScore FROM MarkerValuePerVariety WHERE VarietyNr = @VarietyNr AND MarkerID = @MarkerID;

		DELETE CV FROM @ClusterVarTbl CV
		JOIN MarkerValuePerVariety MVPV ON MVPV.VarietyNr = CV.VarietyNr AND MVPV.MarkerID = @HighestMarker AND dbo.FN_IsMatching(@VarietyScore, MVPV.AlleleScore) = 0
								
		--Keep input variety in list in case removed
		IF NOT EXISTS (SELECT * FROM @ClusterVarTbl WHERE VarietyNr = @VarietyNr)
		BEGIN
			INSERT INTO @ClusterVarTbl
			VALUES(@VarietyNr);
		END;

		--Create marker to be tested in temptable
		INSERT INTO @MarkerTbl
		VALUES(@DetAssignmentID, @HighestMarker, 1, 0)

		SELECT @CountClusteredVarieties = COUNT(VarietyNr) FROM @ClusterVarTbl;
	END

	--step 4 : Try to find inbred marker
			
	-- find inbred marker if crop allows inbred
	IF EXISTS (SELECT * FROM CropRD WHERE CropCode = @Crop AND InBreed = 1)
	BEGIN

		--convert table column value to comma separated list
		SET @List = '';
		SELECT @List = @List + MarkerValue + ',' from @MMSMarkerTbl;
		SET @List = SUBSTRING(@List, 0, LEN(@List));

		EXEC [PR_FindInbredMarker] @List, @VarietyNr, @Female, @Male, @Reciprocal, @ImsMarker OUTPUT; --Reciprocal indicator not available in db so 0 used for now

		-- if no inbred marker found using MMSMarkers
		IF(@ImsMarker = 0)
		BEGIN			

			--convert table column value to comma separated list
			SET @List = '';
			SELECT @List = @List + MarkerValue + ',' from @EdmMarkerTblOrig;
			SET @List = SUBSTRING(@List, 0, LEN(@List));

			EXEC [PR_FindInbredMarker] @List, @VarietyNr, @Female, @Male, 0, @ImsMarker OUTPUT; --Reciprocal indicator not available in db so 0 used for now

		END;

		--if marker found
		IF(@ImsMarker > 0)
		BEGIN

			--If record already exists for same test/marker update InIms to true
			MERGE INTO @MarkerTbl T
			USING
			(
				SELECT @ImsMarker AS Marker
			) S ON T.MarkerID = S.Marker
			WHEN NOT MATCHED THEN
				INSERT (DetAssignmentID, MarkerID, InEDS, InIMS)
				VALUES (@DetAssignmentID, @ImsMarker, 0, 1)
			WHEN MATCHED THEN
				UPDATE SET T.InIMS = 1;

		END;

	END;
			
	--Create MarkerToBeTested record in database from temptable @MarkerTbl
	INSERT INTO MarkerToBeTested (DetAssignmentID, MarkerID, InEDS, InIMS, [Audit])
	SELECT DetAssignmentID, MarkerID, InEDS, InIMS, 'AutoDecluster, ' + CONVERT(NVARCHAR(50), getdate()) FROM @MarkerTbl

	--convert table column value to comma separated list
	SET @List = '';
	SELECT @List = @List + CONVERT(NVARCHAR(20),VarietyNr) + ',' from @ClusterVarTbl;
	SET @List = SUBSTRING(@List, 0, LEN(@List));
	SET @ReturnVarieties = @List;
	
END
GO
/****** Object:  StoredProcedure [dbo].[PR_FindInbredMarker]    Script Date: 1/23/2020 5:39:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Binod Gurung
-- Create date: 2019/10/15
-- Description:	Procedure to find inbred marker based on given marker list
-- =============================================
/*	
	DECLARE @ReturnMarker INT;
	EXEC [PR_FindInbredMarker] '22,33,44', 9235, 234, 345, 0, @ReturnMarker OUTPUT;
	SELECT @ReturnMarker;
*/
CREATE PROCEDURE [dbo].[PR_FindInbredMarker]
(
	@MarkerList		NVARCHAR(MAX),
	@VarietyNr		INT,
	@FemaleParent	INT,
	@MaleParent		INT,
	@Reciprocal		BIT,
	@ReturnMarker	INT OUTPUT
)
AS
BEGIN

	DECLARE @VarietyScore NVARCHAR(10), @FemaleScore NVARCHAR(10), @MaleScore NVARCHAR(10), @MarkerID INT;

	SET NOCOUNT ON;
	
	SET @ReturnMarker = 0;
	
	DECLARE Marker_Cursor CURSOR LOCAL FAST_FORWARD FOR
	SELECT [value] FROM string_split(@MarkerList,',');
	OPEN Marker_Cursor;
	FETCH NEXT FROM Marker_Cursor INTO @MarkerID;
	
	WHILE @@FETCH_STATUS = 0
	BEGIN

		SELECT	@VarietyScore = '',
				@FemaleScore  = '',
				@MaleScore	  = '';
		
		SELECT @VarietyScore = V1.AlleleScore FROM MarkerValuePerVariety V1 WHERE V1.VarietyNr	= @VarietyNr	AND V1.MarkerID = @MarkerID

		SELECT @FemaleScore = V2.AlleleScore FROM MarkerValuePerVariety V2 WHERE V2.VarietyNr	= @FemaleParent AND V2.MarkerID = @MarkerID
	
		SELECT @MaleScore = V3.AlleleScore FROM MarkerValuePerVariety V3 WHERE V3.VarietyNr		= @MaleParent	AND V3.MarkerID = @MarkerID

		IF (ISNULL(@VarietyScore,'') <> '' AND ISNULL(@FemaleScore,'') <> '' AND ISNULL(@MaleScore,'') <> '')
		BEGIN

			-- if score of female is less than 100
			IF(@FemaleScore < '100')
			BEGIN
				
				IF(@Reciprocal = 1 AND @FemaleScore = '0001' AND @MaleScore = '0000')
				BEGIN
					SET @ReturnMarker = @MarkerID;
					BREAK;
				END;

				IF(@Reciprocal = 0 AND @FemaleScore = '0000' AND @MaleScore = '00001')
				BEGIN
					SET @ReturnMarker = @MarkerID;
					BREAK;
				END;

			END;
			-- if score of female is greater than or equal to 100
			ELSE
			BEGIN
				
				IF( @VarietyScore < '999'
				AND REPLACE(@VarietyScore, '55', '') = @VarietyScore
				AND @FemaleScore < '999'
				AND @FemaleScore > '100'
				AND REPLACE(@FemaleScore, '55', '') = @FemaleScore
				AND @MaleScore < '999'
				AND @MaleScore > '100'
				AND REPLACE(@MaleScore, '55', '') = @MaleScore)
				BEGIN

					--if female score and male score is not matching
					IF(dbo.FN_IsMatching(@FemaleScore, @MaleScore) = 0)
					BEGIN
						SET @ReturnMarker = @MarkerID;
						BREAK;
					END;

				END;
			END;
		END;

		FETCH NEXT FROM Marker_Cursor INTO @MarkerID;
	END;
	
	CLOSE Marker_Cursor;
	DEALLOCATE Marker_Cursor;
	
END
GO
/****** Object:  StoredProcedure [dbo].[PR_FindMatchingVarieties]    Script Date: 1/23/2020 5:39:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
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
		WHERE V.CropCode = @Crop AND V.PacComp = 1 --removed because this is checked while planning with marker values
		GROUP BY V.VarietyNr
		UNION
		-- find varieties which has no score
		SELECT		
			V.VarietyNr
		FROM Variety V
		LEFT JOIN MarkerValuePerVariety MVPV ON MVPV.VarietyNr = V.VarietyNr AND MVPV.MarkerID = @FirstMarkerID
		WHERE V.CropCode = @Crop AND MVPV.VarietyNr IS NULL AND V.PacComp = 1 
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
/****** Object:  StoredProcedure [dbo].[PR_FitPlatesToFolder]    Script Date: 1/23/2020 5:39:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
Author					Date			Remarks
Krishna Gautam			2020/01/10		Created folder structcture based on lab priority and excelude already sent test while preparing folder structure
Binod Gurung			2020-jan-23		Transcation isolation level implemented to avoid record lock
										SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
============ExAMPLE===================
--EXEC PR_FitPlatesToFolder 4792
*/
CREATE PROCEDURE [dbo].[PR_FitPlatesToFolder]
(
	@PeriodID INT
)
AS BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

	DECLARE @TransCount BIT = 0;
	 
    BEGIN TRY	  
	   IF @@TRANCOUNT = 0 BEGIN
		  BEGIN TRANSACTION;
		  SET @TransCount = 1;
	   END
		  DECLARE @StartDate DATE, @EndDate DATE, @PlateMaxLimit DECIMAL = 16.0, @loopCountGroup INT=1,@TotalTestRequired INT =0, @TotalCreatedTests INT =0,  @CropCode NVARCHAR(MAX), @MethodCode NVARCHAR(MAX), @PlatformName NVARCHAR(MAX), @TotalGroups INT, @TotalFolderRequired INT =0, @TestID INT =0, @groupLoopCount INT =0, @Offset INT=0, @NextRows INT =0;
		  --declare table to insert data of determinatonAssignment
		  DECLARE @tblDA TABLE(ID INT IDENTITY(1,1), CropCode NVARCHAR(10),MethodCode NVARCHAR(100),PlatformName NVARCHAR(100),DetAssignmentID INT,NrOfPlates DECIMAL(6,2),TestID INT);
		  --this is group table which is required to calculate how many folders are required per method per crop per platform
		  DECLARE @tblDAGroups TABLE(ID INT IDENTITY(1,1), CropCode NVARCHAR(10),MethodCode NVARCHAR(100),PlatformName NVARCHAR(100),groupRequired INT,MaxRowToSelect INT);
		  --declare Temp test table
		  DECLARE @tblTempTest TABLE(ID INT IDENTITY(1,1), CropCode NVARCHAR(10),MethodCode NVARCHAR(100),PlatformName NVARCHAR(100), TestID INT);
		  --declare test table to get sequential test ID
		  DECLARE @tblSeqTest TABLE(ID INT IDENTITY(1,1), TestID INT);
			
			
		  --get date range of current period
		  SELECT 
			 @StartDate = StartDate,
			 @EndDate = EndDate
		  FROM [Period] 
		  WHERE PeriodID = @PeriodID;

		  --for now do not insert testID this should be updated or inserted later depending upon condition
		  INSERT INTO @tblDA(CropCode,MethodCode,PlatformName,DetAssignmentID,NrOfPlates)
			 SELECT 
				    C.CropCode,
				    DA.MethodCode,
				    P.PlatformDesc,
				    DA.DetAssignmentID,
				    M.NrOfSeeds/92.0
			 FROM DeterminationAssignment DA
			 JOIN ABSCrop C ON C.ABSCropCode = DA.ABSCropCode
			 JOIN Method M ON M.MethodCode = DA.MethodCode
			 JOIN CropMethod CM ON CM.MethodID = M.MethodID AND CM.ABSCropCode = DA.ABSCropCode
			 JOIN [Platform] P ON P.PlatformID = CM.PlatformID				
			 WHERE CAST(DA.PlannedDate AS DATE) BETWEEN @StartDate AND @EndDate	
			 AND NOT EXISTS 
			 ( 
				    SELECT TD.DetAssignmentID FROM  TestDetAssignment TD
				    JOIN TEST T ON T.TestID = TD.TestID
				    WHERE T.StatusCode >= 200 AND T.PeriodID = @PeriodID AND TD.DetAssignmentID = DA.DetAssignmentID
			 )
			 ORDER BY C.CropCode ASC, DA.MethodCode ASC, P.PlatformDesc ASC, ISNULL(DA.IsLabPriority, 0) DESC, DA.DetAssignmentID ASC;


		  INSERT INTO @tblDAGroups(CropCode,MethodCode,PlatformName,groupRequired, MaxRowToSelect)
			 SELECT 
				    C.CropCode,
				    DA.MethodCode,
				    P.PlatformDesc,
				    groupRequired = CEILING((SUM(M.NrOfSeeds)/92.0) /16),
				    MaxRecordPerPlate = CASE 
										  WHEN  MAX(M.NrOfSeeds)/92.0 > 0 THEN FLOOR(16.0 / (MAX(M.NrOfSeeds)/92.0))
										  ELSE 16 * (MAX(M.NrOfSeeds)/92.0)
									   END
			 FROM DeterminationAssignment DA
			 JOIN ABSCrop C ON C.ABSCropCode = DA.ABSCropCode
			 JOIN Method M ON M.MethodCode = DA.MethodCode
			 JOIN CropMethod CM ON CM.MethodID = M.MethodID AND CM.ABSCropCode = DA.ABSCropCode
			 JOIN [Platform] P ON P.PlatformID = CM.PlatformID							
			 WHERE CAST(DA.PlannedDate AS DATE) BETWEEN @StartDate AND @EndDate
			 AND NOT EXISTS 
			 ( 
				    SELECT TD.DetAssignmentID FROM  TestDetAssignment TD
				    JOIN TEST T ON T.TestID = TD.TestID
				    WHERE T.StatusCode >= 200 AND T.PeriodID = @PeriodID AND TD.DetAssignmentID = DA.DetAssignmentID
			 )
			 GROUP BY C.CropCode, DA.MethodCode, P.PlatformDesc
			 ORDER BY C.CropCode, DA.MethodCode, P.PlatformDesc;

		  SELECT @TotalTestRequired = SUM(groupRequired) FROM @tblDAGroups;
		  SELECT @TotalCreatedTests = COUNT(TestID) FROM Test WHERE PeriodID = @PeriodID AND StatusCode < 200;

		  WHILE(@TotalCreatedTests < @TotalTestRequired)
		  BEGIN
			 INSERT INTO Test(PeriodID,StatusCode)
			 VALUES(@PeriodID,100);
			 SET @TotalCreatedTests = @TotalCreatedTests + 1;
		  END

		  INSERT INTO @tblSeqTest(TestID)
		  SELECT TestID FROM Test  WHERE PeriodID = @PeriodID AND StatusCode < 200 order by TestID;

		  --SELECT * FROM @tblSeqTest;
		  --SELECT * FROM @tblDAGroups;

		  SELECT @TotalGroups = COUNT(ID) FROM @tblDAGroups
		  SET @loopCountGroup = 1;
		  SET @groupLoopCount= 1;

		  WHILE(@loopCountGroup <= @TotalGroups)
		  BEGIN
			 SELECT @CropCode = CropCode, @MethodCode = MethodCode, @PlatformName = PlatformName, @TotalFolderRequired = groupRequired, @NextRows = MaxRowToSelect from @tblDAGroups Where ID = @loopCountGroup;
			 SET @Offset = 0;
			 WHILE(@TotalFolderRequired > 0)
			 BEGIN
				    SELECT @TestID = TestID FROM @tblSeqTest WHERE ID = @groupLoopCount;
					
				    --SELECT * FROM @tblDA WHERE CropCode = @CropCode AND MethodCode = @MethodCode AND PlatformName = @PlatformName ORDER BY ID OFFSET @Offset ROWS FETCH NEXT @NextRows ROWS ONLY

				    MERGE INTO @TblDA T
				    USING
				    (
					   SELECT * FROM @tblDA WHERE CropCode = @CropCode AND MethodCode = @MethodCode AND PlatformName = @PlatformName ORDER BY ID OFFSET @Offset ROWS FETCH NEXT @NextRows ROWS ONLY
				    ) S ON S.ID = T.ID
				    WHEN MATCHED THEN 
				    UPDATE SET T.TestID = @TestID;

				    SET @groupLoopCount = @groupLoopCount + 1;
				    SET @Offset = @Offset + @NextRows ;
				    SET @TotalFolderRequired = @TotalFolderRequired -1;
			 END

			 SET @loopCountGroup = @loopCountGroup + 1;				
		  END
			
		  MERGE INTO TestDetAssignment T
		  USING @TblDA S
		  ON S.DetAssignmentID = T.DetAssignmentID
		  WHEN MATCHED AND T.TestID <> S.TestID THEN UPDATE
		  SET T.TestID = S.TestID
		  WHEN NOT MATCHED THEN
		  INSERT(DetAssignmentID, TestID)
		  VALUES(S.DetAssignmentID, S.TestID);

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
/****** Object:  StoredProcedure [dbo].[PR_GenerateFolderDetails]    Script Date: 1/23/2020 5:39:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
Author					Date			Description
Binod Gurung			2020-jan-23		Transcation isolation level implemented to avoid record lock
-- https://www.mssqltips.com/sqlservertip/4897/handling-transactions-in-nested-sql-server-stored-procedures/
*/
CREATE PROCEDURE [dbo].[PR_GenerateFolderDetails]
(
    @PeriodID INT,
    @IsLabPriority BIT
) AS BEGIN
    SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    DECLARE @TransCount BIT = 0;
    DECLARE @PlateMaxLimit INT = 16;

    BEGIN TRY
	   IF @@TRANCOUNT = 0 BEGIN
		  BEGIN TRANSACTION;
		  SET @TransCount = 1;
	   END
    
	   DECLARE @StartDate DATE, @EndDate DATE;

	   SELECT 
		  @StartDate = StartDate,
		  @EndDate = EndDate
	   FROM [Period] 
	   WHERE PeriodID = @PeriodID;

	   DECLARE @tbl TABLE
	   (
		  ID			   INT IDENTITY(1,1), 
		  CropCode	   NVARCHAR(10),
		  MethodCode	   NVARCHAR(100),
		  PlatformName    NVARCHAR(100),
		  DetAssignmentID INT,
		  NrOfPlates	   DECIMAL(6,2)
	   );

	   --Make a groups based on Folder and other common attributes
	   DECLARE @groups TABLE
	   (
		  CropCode	   NVARCHAR(10),
		  MethodCode	   NVARCHAR(100),
		  PlatformName    NVARCHAR(100),
		  NrOfPlates	   DECIMAL(6,2),
		  NrOfPlateLimit  DECIMAL(6, 2)
	   );

	   WITH CTE (CropCode, MethodCode, PlatformName, NrOfPlates, NrOfPlateLimit) AS
	   (
		  SELECT 
			 C.CropCode,
			 DA.MethodCode, 
			 P.PlatformDesc,
			 V2.NrOfPlates,
			 NrOfPlateLimit = CASE 
							 WHEN @PlateMaxLimit % V2.NrOfPlates = 0 THEN 
								@PlateMaxLimit 
							 ELSE 
								@PlateMaxLimit - (@PlateMaxLimit % V2.NrOfPlates)
						   END
		  FROM DeterminationAssignment DA
		  JOIN ABSCrop C ON C.ABSCropCode = DA.ABSCropCode
		  JOIN TestDetAssignment TDA ON DA.DetAssignmentID = TDA.DetAssignmentID
		  JOIN Test T ON T.TestID = TDA.TestID
		  JOIN Method M ON M.MethodCode = DA.MethodCode
		  JOIN CropMethod CM ON CM.MethodID = M.MethodID AND CM.ABSCropCode = DA.ABSCropCode
		  JOIN [Platform] P ON P.PlatformID = CM.PlatformID
		  JOIN Variety V ON V.VarietyNr = DA.VarietyNr
		  JOIN
		  (
			 SELECT 
				MethodID,
				NrOfPlates = NrOfSeeds/92.0
			 FROM Method
		  ) V2 ON V2.MethodID = M.MethodID
		  WHERE T.PeriodID = @PeriodID
		  --AND ISNULL(DA.IsLabPriority, 0) = @IsLabPriority
	   )
	   INSERT @groups(CropCode, MethodCode, PlatformName, NrOfPlates, NrOfPlateLimit)		
	   SELECT
		  CropCode,
		  MethodCode,
		  PlatformName,    
		  NrOfPlates = SUM(NrOfPlates),
		  NrOfPlateLimit = MAX(NrOfPlateLimit)
	   FROM CTE
	   GROUP BY CropCode, MethodCode, PlatformName;

	   INSERT @tbl(CropCode, MethodCode, PlatformName, DetAssignmentID, NrOfPlates)
	   SELECT 
		  C.CropCode,
		  DA.MethodCode,
		  P.PlatformDesc,
		  DA.DetAssignmentID,
		  M.NrOfSeeds/92.0
	   FROM DeterminationAssignment DA
	   JOIN ABSCrop C ON C.ABSCropCode = DA.ABSCropCode
	   JOIN Method M ON M.MethodCode = DA.MethodCode
	   JOIN CropMethod CM ON CM.MethodID = M.MethodID AND CM.ABSCropCode = DA.ABSCropCode
	   JOIN [Platform] P ON P.PlatformID = CM.PlatformID
	   WHERE CAST(DA.PlannedDate AS DATE) BETWEEN @StartDate AND @EndDate
	   --AND ISNULL(DA.IsLabPriority, 0) = @IsLabPriority
	   AND NOT EXISTS
	   (
		  SELECT 
			 TDA.DetAssignmentID 
		  FROM TestDetAssignment TDA
		  JOIN Test T ON T.TestID = TDA.TestID
		  WHERE TDA.DetAssignmentID = DA.DetAssignmentID AND T.PeriodID = @PeriodID
	   )
	   ORDER BY C.CropCode, DA.MethodCode, P.PlatformDesc, ISNULL(DA.IsLabPriority, 0) DESC;

	   DECLARE 
		  @CropCode			 NVARCHAR(10), 
		  @MethodCode			 NVARCHAR(100), 
		  @PlatformName		 NVARCHAR(100), 
		  @DetAssignmentID		 INT, 
		  @NrOfPlates			 DECIMAL(10, 2),
		  @TotalPlatesPerFolder   DECIMAL(10, 2),
		  @TestID				 INT,
		  @LastFolderSeqNr		 INT,
		  @NrOfPlateLimit		 DECIMAL(6, 2);

	   DECLARE @IDX INT = 1, @CNT INT;

	   SELECT @CNT = COUNT(ID) FROM @tbl;

	   WHILE @IDX <= @CNT BEGIN
		  SET @CropCode = NULL;
		  SET @MethodCode = NULL; 
		  SET @PlatformName = NULL;  
		  SET @DetAssignmentID = NULL; 
		  SET @NrOfPlates = NULL;

		  SET @TotalPlatesPerFolder = NULL;

		  SELECT
			 @CropCode = CropCode,
			 @MethodCode	 = MethodCode,
			 @PlatformName = PlatformName,
			 @DetAssignmentID = DetAssignmentID,
			 @NrOfPlates = NrOfPlates
		  FROM @tbl 
		  WHERE ID = @IDX;

		  SELECT 
			 @TotalPlatesPerFolder = NrOfPlates,
			 @NrOfPlateLimit = NrOfPlateLimit
		  FROM @groups
		  WHERE CropCode = @CropCode
		  AND MethodCode = @MethodCode
		  AND PlatformName = @PlatformName;

		  SET @TotalPlatesPerFolder = ISNULL(@TotalPlatesPerFolder, 0);
		  SET @NrOfPlateLimit = ISNULL(@NrOfPlateLimit, 0);
		  --PRINT '@MethodCode: ' + @MethodCode;
		  --PRINT '@TotalPlatesPerFolder: '
		  --PRINT @TotalPlatesPerFolder;
		  --PRINT '@MaxNrOfPlates: '
		  --PRINT @MaxNrOfPlates

		  --if there is no any such folder, create it
		  IF(@TotalPlatesPerFolder = 0) BEGIN
			 --Label
			 CREATE_NEW_FOLDER:
			 --get last number of existing folders in groups if there are any other created in a period
			 WITH CTE (SeqNr) AS
			 (
				SELECT 
				   CAST(TempName AS INT)
				FROM Test
				WHERE PeriodID = @PeriodID
			 )
			 SELECT @LastFolderSeqNr = ISNULL(MAX(SeqNr), 0) + 1 FROM CTE;
	   
			 INSERT Test(TempName, PeriodID, StatusCode, IsLabPriority)
			 VALUES(CAST(@LastFolderSeqNr AS VARCHAR(10)), @PeriodID, 100, @IsLabPriority);

			 SELECT @TestID = SCOPE_IDENTITY();
	   
			 --add information into temp groups
			 INSERT @groups(CropCode, MethodCode, PlatformName, NrOfPlates, NrOfPlateLimit)
			 VALUES
			 (
				@CropCode, @MethodCode, @PlatformName, @NrOfPlates, 
				CASE 
				    WHEN @PlateMaxLimit % @NrOfPlates = 0 THEN 
					   @PlateMaxLimit 
				    ELSE 
					   @PlateMaxLimit - (@PlateMaxLimit % @NrOfPlates)
				END
			 );
		  END
		  ELSE BEGIN
			 --Folder already available but check if it has already full 16 plates or not.
			 IF((@TotalPlatesPerFolder % @NrOfPlateLimit) = 0) BEGIN
			  -- need to create new folder for the group
				GOTO CREATE_NEW_FOLDER;
			 END
			 ELSE BEGIN
			 --if there is still room to store determinations, get last test id from group
				SELECT 
				    @TestID = MAX(T.TestID) 
				FROM Test T
				JOIN TestDetAssignment TDA ON TDA.TestID = T.TestID
				JOIN DeterminationAssignment DA ON DA.DetAssignmentID = TDA.DetAssignmentID
				JOIN ABSCrop C ON C.ABSCropCode = DA.ABSCropCode
				JOIN Method M ON M.MethodCode = DA.MethodCode
				JOIN CropMethod CM ON CM.ABSCropCode = DA.ABSCropCode AND CM.MethodID = M.MethodID
				JOIN [Platform] P ON P.PlatformID = CM.PlatformID
				WHERE T.PeriodID = @PeriodID
				AND C.CropCode = @CropCode
				AND DA.MethodCode = @MethodCode
				AND P.PlatformDesc = @PlatformName
				--AND ISNULL(DA.IsLabPriority, 0) = @IsLabPriority;	
				
				--update NrOfPlates in a groups
				UPDATE @groups 
				    SET NrOfPlates = NrOfPlates + @NrOfPlates
				WHERE CropCode = @CropCode
				AND MethodCode = @MethodCode
				AND PlatformName = @PlatformName;
			 END			
		  END
		  --Now map test with determination assignments
		  INSERT TestDetAssignment(TestID, DetAssignmentID)
		  VALUES(@TestID, @DetAssignmentID);

		  SET @IDX = @IDX + 1;
	   END

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
/****** Object:  StoredProcedure [dbo].[PR_GetAvailableCapacity_For_AutoPlan_LS]    Script Date: 1/23/2020 5:39:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[PR_GetAvailableCapacity_For_AutoPlan_LS]
(
	@PeriodID				INT
)
AS BEGIN
	DECLARE @PlatformID INT;
	SELECT @PlatformID = PlatformID FROM [Platform] WHERE PlatformCode = 'LS';

	IF(ISNULL(@platformID,0) =0)
	BEGIN
		EXEC PR_ThrowError 'Platform not found.';
		RETURN
	END
	SELECT 
		RC.NrOfPlates AS TotalCapacity,
		CM.UsedFor,
		ABSC.CropCode,
		ABSC.ABSCropCode,
		M.MethodCode,
		M.NrOfSeeds,
		WellsPerPlate = 92
	FROM ReservedCapacity RC
	JOIN CropMethod CM ON CM.CropMethodID = RC.CropMethodID
	JOIN Method M ON M.MethodID = CM.MethodID
	JOIN ABSCrop ABSC ON ABSC.ABSCropCode = CM.ABSCropCode

	WHERE RC.PeriodID = @PeriodID AND CM.PlatformID = @PlatformID
	
	--GROUP BY CropM

END
GO
/****** Object:  StoredProcedure [dbo].[PR_GetBatch]    Script Date: 1/23/2020 5:39:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
Author					Date			Remarks
Krishna Gautam			2020/01/16		Created Stored procedure to fetch data
Krishna Gautam			2020/01/21		Status description is sent instead of status code.
Krishna Gautam			2020/01/21		Column Label change.
Binod Gurung			2020-jan-23		Transcation isolation level implemented to avoid record lock

=================EXAMPLE=============

EXEC PR_GetBatch 
		@PageNr = 1,
		@PageSize = 10,
		@CropCode = NULL,
		@PlatformDesc = NULL,
		@MethodCode = NULL,
		@Plates = NULL,
		@TestName = NULL,
		@StatusCode = NULL,
		@ExpectedWeek = NULL,
		@SampleNr = NULL,
		@BatchNr = NULL,
		@DetAssignmentID = NULL,
		@VarietyNr = NULL
*/

CREATE PROCEDURE [dbo].[PR_GetBatch]
(
	@pageNr INT,
	@PageSize INT,
	@CropCode NVARCHAR(10) =NULL,
	@PlatformDesc NVARCHAR(100) = NULL,
	@MethodCode NVARCHAR(50) = NULL, 
	@Plates NVARCHAR(100) = NULL, 
	@TestName NVARCHAR(100) = NULL,
	@StatusCode NVARCHAR(100) = NULL, 
	@ExpectedWeek NVARCHAR(100) = NULL,
	@SampleNr NVARCHAR(100) = NULL, 
	@BatchNr NVARCHAR(100) = NULL, 
	@DetAssignmentID  NVARCHAR(100) = NULL,
	@VarietyNr NVARCHAR(100) = NULL,
	@QualityClass NVARCHAR(10) = NULL
)
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

	DECLARE @Offset INT;
	DECLARE @Columns TABLE(ColumnID NVARCHAR(100), ColumnName NVARCHAR(100),IsVisible BIT);
	DECLARE @Status TABLE(StatusCode INT, StatusName NVARCHAR(100));

	INSERT INTO @Status(StatusCode, StatusName)
	SELECT StatusCode,StatusName FROM [Status] WHERE StatusTable = 'DeterminationAssignment';

	set @Offset = @PageSize * (@pageNr -1);
	;WITH CTE AS 
	(
		SELECT * FROM 
		(
			SELECT T.TestID, 
				C.CropCode,
				P.PlatformDesc,
				M.MethodCode, 
				Plates = CAST(CAST((M.NrOfSeeds/92.0) as decimal(4,2)) AS NVARCHAR(10)), 
				T.TestName ,
				StatusCode = S.StatusName,
				[ExpectedWeek] = CAST(DATEPART(Week, DA.ExpectedReadyDate) AS NVARCHAR(10)),
				SampleNr = CAST(DA.SampleNr AS NVARCHAR(50)), 
				BatchNr = CAST(DA.BatchNr AS NVARCHAR(50)), 
				DetAssignmentID = CAST(DA.DetAssignmentID AS NVARCHAR(50)) ,
				VarietyNr = CAST(V.VarietyNr  AS NVARCHAR(50)),
				DA.QualityClass
			FROM  Test T 
			JOIN TestDetAssignment TDA ON TDA.TestID = T.TestID
			JOIN DeterminationAssignment DA ON DA.DetAssignmentID = TDA.DetAssignmentID
			JOIN @Status S ON S.StatusCode = DA.StatusCode
			JOIN Variety V ON V.VarietyNr = DA.VarietyNr
			JOIN Method M ON M.MethodCode = DA.MethodCode
			JOIN CropMethod CM ON CM.MethodID = M.MethodID AND CM.ABSCropCode = DA.ABSCropCode
			JOIN ABSCrop C ON C.ABSCropCode = CM.ABSCropCode
			JOIN [Platform] P ON P.PlatformID = CM.PlatformID
		) T
		WHERE 
		(ISNULL(@CropCode,'') = '' OR CropCode like '%'+ @CropCode +'%') AND
		(ISNULL(@PlatformDesc,'') = '' OR PlatformDesc like '%'+ @PlatformDesc +'%') AND
		(ISNULL(@MethodCode,'') = '' OR MethodCode like '%'+ @MethodCode +'%') AND
		(ISNULL(@Plates,'') = '' OR Plates like '%'+ @Plates +'%') AND
		(ISNULL(@TestName,'') = '' OR TestName like '%'+ @TestName +'%') AND
		(ISNULL(@StatusCode,'') = '' OR StatusCode like '%'+ @StatusCode +'%') AND
		(ISNULL(@ExpectedWeek,'') = '' OR ExpectedWeek like '%'+ @ExpectedWeek +'%') AND
		(ISNULL(@SampleNr,'') = '' OR SampleNr like '%'+ @SampleNr +'%') AND
		(ISNULL(@BatchNr,'') = '' OR BatchNr like '%'+ @BatchNr +'%') AND
		(ISNULL(@DetAssignmentID,'') = '' OR DetAssignmentID like '%'+ @DetAssignmentID +'%') AND
		(ISNULL(@VarietyNr,'') = '' OR VarietyNr like '%'+ @VarietyNr +'%') AND
		(ISNULL(@QualityClass,'') = '' OR QualityClass like '%'+ @QualityClass +'%')
	), Count_CTE AS (SELECT COUNT(TestID) AS [TotalRows] FROM CTE)
	SELECT 
	
		CropCode,
		PlatformDesc,
		MethodCode, 
		Plates , 
		TestName ,
		StatusCode, 
		ExpectedWeek,
		SampleNr, 
		BatchNr, 
		DetAssignmentID ,
		VarietyNr,
		QualityClass,
		TotalRows
	FROM CTE,Count_CTE 
	ORDER BY TestID DESC, DetAssignmentID ASC
	OFFSET @Offset ROWS
	FETCH NEXT @PageSize ROWS ONLY


	INSERT INTO @Columns(ColumnID,ColumnName,IsVisible)
	VALUES
	('CropCode','Crop',1),
	('PlatformDesc','Platform',1),
	('MethodCode','Method',1),
	('Plates','#Plates',1),
	('TestName','Folder',1),
	('StatusCode','Status',1),
	('ExpectedWeek','Exp. Wk',1),
	('SampleNr','SampleNr',1),
	('BatchNr','BatchNr',1),
	('DetAssignmentID','Det. Assignment',1),
	('VarietyNr','Var. Name',1),
	('QualityClass','Qlty Class',1)

	SELECT * FROM @Columns;
END
GO
/****** Object:  StoredProcedure [dbo].[PR_GetCapacity]    Script Date: 1/23/2020 5:39:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
	EXEC PR_GetCapacity 2019

*/
CREATE PROCEDURE [dbo].[PR_GetCapacity]
(
	@Year INT = NULL
) AS
BEGIN	
	DECLARE @SQL NVARCHAR(MAX), @PeriodName NVARCHAR(MAX), @Where NVARCHAR(MAX) = '', @ColumnsIDs NVARCHAR(MAX), @ColumnsIDs2 NVARCHAR(MAX);

	DECLARE @ColumnTable TABLE(ColumnID NVARCHAR(MAX), Label NVARCHAR(MAX),[Order] INT, IsVisible BIT,Editable BIT);

	IF(ISNULL(@Year,0)<>0) BEGIN
		SET @Where = 'WHERE Year(P.StartDate) = '+CAST(@Year AS NVARCHAR(MAX))+' OR Year(P.EndDate) = '+CAST(@Year AS NVARCHAR(MAX));
	END

	ELSE
	BEGIN
		SET @Where = '';
	END

	SELECT 
		@ColumnsIDs = COALESCE(@ColumnsIDS+',','') + QUOTENAME(PlatformID),
		@ColumnsIDs2 = COALESCE(@ColumnsIDS2+',','') + 'MAX(' + QUOTENAME(PlatformID) + ') AS ' + QUOTENAME(PlatformID)
	FROM [Platform]
	WHERE StatusCode = 100

	IF(ISNULL(@ColumnsIDs,'') = '') BEGIN
		EXEC PR_ThrowError 'No Platform found.';
		RETURN;
	END


	SET @SQL = N'	
				SELECT P.PeriodID, PeriodName2 AS PeriodName, ' +@ColumnsIDs+ ', T1.Remarks FROM [VW_Period] P
				LEFT JOIN 
				(
					SELECT PeriodID,MAX(Remarks) AS Remarks,'+@ColumnsIDs2+'
					FROM 
					(
						SELECT PlatFormID,Remarks,PeriodID,NrOfPlates FROM Capacity
					)
					SRC
					PIVOT
					(
						MAX(NrOfPlates)
						FOR PlatformID IN ('+@ColumnsIDs+')
					)
					PT
					GROUP BY PeriodID
				) T1
				ON T1.PeriodID = P.PeriodID '
				+@Where +
				' ORDER BY P.PeriodID';
		
	--PRINT @SQL;
	EXEC sp_executesql @SQL;

	INSERT INTO @ColumnTable(ColumnID,Label,[Order],IsVisible,Editable)
	SELECT PlatformID,PlatformDesc,PlatformID + 1,1,1
	FROM [Platform]
	WHERE StatusCode = 100;

	DECLARE @maxOrder INT;
	SELECT @maxOrder = MAX([order]) FROM @ColumnTable

	INSERT INTO @ColumnTable(ColumnID,Label,[Order],IsVisible,Editable)
	VALUES('PeriodID','PeriodID',0,0,0)
	,('PeriodName','PeriodName',1,1,0)
	,('Remarks','Remarks',@maxOrder +1,1,1);

	SELECT * FROM @ColumnTable order by [order]
	
END
GO
/****** Object:  StoredProcedure [dbo].[PR_GetDataForDecisionDetailScreen]    Script Date: 1/23/2020 5:39:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- [PR_GetDataForDecisionDetailScreen] 1444777
CREATE PROCEDURE [dbo].[PR_GetDataForDecisionDetailScreen]
(
    @DetAssignmentID INT
) 
AS 
BEGIN
    SET NOCOUNT ON;
	DECLARE @SQL NVARCHAR(MAX), @Columns NVARCHAR(MAX), @Columns2 NVARCHAR(MAX);

	SET @DetAssignmentID = 1444777;

	SELECT
		@Columns = COALESCE(@Columns + ',', '') + QUOTENAME(MarkerID),
		@Columns2 = COALESCE(@Columns2 + ',', '') + QUOTENAME(MarkerID) + 'AS' + QUOTENAME(MarkerFullName)
	FROM
	(
		SELECT DISTINCT 
		   PR.MarkerID,
		   M.MarkerFullName    
		FROM Pattern P
		JOIN PatternResult PR ON PR.PatternID = P.PatternID
		JOIN Marker M ON M.MarkerID = PR.MarkerID
		WHERE P.DetAssignmentID = @DetAssignmentID
	) C;

	IF(ISNULL(@Columns, '') <> '')
	BEGIN
		SET @SQl = N'SELECT 
			[Pat#] = ROW_NUMBER() OVER (ORDER BY P.NrOfSamples DESC),
			[Sample] = P.NrOfSamples,
			[Sam%] = P.SamplePer,
			[Type:] = P.[Type],
			[Matching Varieties] = P.MatchingVar,
			' + @Columns2 + '
		FROM Pattern P
		JOIN
		(
			SELECT * FROM 
			(
				SELECT 
					P.PatternID,
					PR.MarkerID,
					PR.Score
				FROM Pattern P
				JOIN PatternResult PR ON PR.PatternID = P.PatternID
				WHERE P.DetAssignmentID = @DetAssignmentID
			) V1
			PIVOT
			(
				MAX(Score)
				FOR MarkerID IN(' + @Columns + ')
			) P1
		) P2 ON P2.PatternID = P.PatternID
		ORDER BY P.NrOfSamples DESC';
	END;
	ELSE 
	BEGIN
		SET @SQl = N'SELECT 
						[Pat#] = ROW_NUMBER() OVER (ORDER BY P.NrOfSamples DESC),
						[Sample] = P.NrOfSamples,
						[Sam%] = P.SamplePer,
						[Type:] = P.[Type],
						[Matching Varieties] = P.MatchingVar
					FROM Pattern P
					WHERE P.DetAssignmentID = @DetAssignmentID
					ORDER BY P.NrOfSamples DESC'
	END;

	EXEC sp_executesql @SQL, N'@DetAssignmentID INT', @DetAssignmentID;

END
GO
/****** Object:  StoredProcedure [dbo].[PR_GetDataForDecisionScreen]    Script Date: 1/23/2020 5:39:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- PR_GetDataForDecisionScreen 1568336
CREATE PROCEDURE [dbo].[PR_GetDataForDecisionScreen]
(
    @DetAssignmentID INT
) 
AS 
BEGIN
    SET NOCOUNT ON;

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
		LastExport = CAST (GETDATE() AS DATETIME)
	FROM Test T
	LEFT JOIN Plate P On P.TestID = T.TestID 
	LEFT JOIN Well W ON W.PlateID = P.PlateID
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
/****** Object:  StoredProcedure [dbo].[PR_GetDeclusterResult]    Script Date: 1/23/2020 5:39:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


--EXEC PR_GetDeclusterResult 4792, 1203784
CREATE PROCEDURE [dbo].[PR_GetDeclusterResult]
(
    @PeriodID		    INT,
    @DetAssignmentID    INT
) AS BEGIN
    SET NOCOUNT ON;

    DECLARE @StartDate DATE, @EndDate DATE;

    DECLARE @Variety TVP_Variety;
    DECLARE @Markers TABLE(MarkerID INT, MarkerName NVARCHAR(100), InIMS BIT, DisplayOrder INT);
    DECLARE @Determinations TABLE(DetAssignmentID INT);
    
    DECLARE @SQL NVARCHAR(MAX);
    DECLARE @Columns NVARCHAR(MAX);    
    
    SELECT
	   @StartDate = StartDate,
	   @EndDate = EndDate
    FROM [Period] 
    WHERE PeriodID = @PeriodID;    	      

    INSERT @Variety(VarietyNr, VarietyName, DisplayOrder)
    SELECT DISTINCT
	   V2.VarietyNr, 
	   V2.Shortname,
	   DisplayOrder =  CASE 
					   WHEN V2.VarietyNr = V1.Male THEN 3
					   WHEN V2.VarietyNr = V1.FeMale THEN 2
					   ELSE 1
				    END
    FROM
    (
	   SELECT
		  V.VarietyNr,
		  V.Female,
		  V.Male
	   FROM TestDetAssignment TDA
	   JOIN DeterminationAssignment DA ON DA.DetAssignmentID = TDA.DetAssignmentID
	   JOIN Variety V ON V.VarietyNr = DA.VarietyNr
	   WHERE DA.StatusCode = 300 
	   AND CAST(DA.PlannedDate AS DATE) BETWEEN @StartDate AND @EndDate
	   AND DA.DetAssignmentID = @DetAssignmentID
    ) V1
    JOIN Variety V2 ON V2.VarietyNr IN (V1.VarietyNr, V1.Female, V1.Male);

    INSERT @Determinations(DetAssignmentID)
    SELECT
	   MIN(DA.DetAssignmentID)
    FROM DeterminationAssignment DA
    JOIN @Variety V ON V.VarietyNr = DA.VarietyNr
    WHERE DA.StatusCode = 300 
    AND CAST(DA.PlannedDate AS DATE) BETWEEN @StartDate AND @EndDate
    GROUP BY DA.VarietyNr;
    
    --Prepare markers
    INSERT @Markers(MarkerID, MarkerName, InIMS, DisplayOrder)
	SELECT 
		M.MarkerID,
		M.MarkerFullName,
		M1.InIMS,
		M.MarkerID + 3
	FROM
	(
		SELECT 
			MarkerID,
			MTT.InIMS
		FROM MarkerToBeTested MTT
		JOIN @Determinations D ON D.DetAssignmentID = MTT.DetAssignmentID
		UNION
		SELECT
			MarkerID,
			0
		FROM
		MarkerPerVariety MPV
		JOIN @Variety V1 On V1.VarietyNr = MPV.VarietyNr 
		WHERE MPV.StatusCode = 100
	) M1
    JOIN Marker M ON M.MarkerID = M1.MarkerID

    SELECT 
	   @Columns  = COALESCE(@Columns + ',', '') + QUOTENAME(MarkerID)
    FROM @Markers C
	GROUP BY MarkerID
	ORDER By MarkerID;
	
    SET @Columns = ISNULL(@Columns, '');
	PRINT @Columns;
    SET @SQL = N'SELECT 
	   V.VarietyNr, 
	   V.VarietyName,
	   VarietyType = CASE 
		  WHEN V.DisplayOrder = 1 THEN ''Variety''
		  WHEN V.DisplayOrder = 2 THEN ''Female''
		  WHEN V.DisplayOrder = 3 THEN ''Male''
		  ELSE ''''
	   END ' +
	   CASE WHEN @Columns = '' THEN '' ELSE ', ' + @Columns END + 
    N'FROM @Variety V ' + 
    CASE WHEN @Columns = '' THEN '' ELSE
	   N'LEFT JOIN
	   (
		  SELECT * FROM 
		  (
			  SELECT 
				MVP.VarietyNr,
				MVP.MarkerID,
				[Value] = MVP.AlleleScore
			 FROM MarkerValuePerVariety MVP
			 JOIN @Variety V1 On V1.VarietyNr = MVP.VarietyNr
			 LEFT JOIN DeterminationAssignment DA ON DA.VarietyNr = MVP.VarietyNr
			 LEFT JOIN MarkerToBeTested MTT ON MTT.MarkerID = MVP.MarkerID AND MTT.DetAssignmentID = DA.DetAssignmentID
			 UNION
			 SELECT 
				MPV.VarietyNr,
				MPV.MarkerID,
				[Value] = MPV.ExpectedResult
			 FROM
			 MarkerPerVariety MPV
			 JOIN @Variety V1 On V1.VarietyNr = MPV.VarietyNr
			 WHERE MPV.StatusCode = 100
		  ) V
		  PIVOT
		  (
			 MAX([Value])
			 FOR MarkerID IN(' + @Columns + N')
		  ) P
	   ) M ON M.VarietyNr = V.VarietyNr '  
    END + 
    N'ORDER BY V.DisplayOrder';
	print @SQL;
    EXEC sp_executesql @SQL, N'@Variety TVP_Variety READONLY', @Variety;

	SELECT 
		ColumnID, 
		ColumnLabel, 
		InIMS
	FROM
	(
		SELECT *
		FROM
		(
			VALUES
			('VarietyNr', 'Variety Nr', 0, 0),
			('VarietyName', 'Variety Name', 0, 1),
			('VarietyType', 'Variety Type', 0, 2)
		) V(ColumnID, ColumnLabel, InIMS, [DisplayOrder]  )
		UNION
		SELECT 
			ColumnID = CAST(MarkerID AS VARCHAR(10)), 
			ColumnLabel = MarkerName,
			InIMS,
			DisplayOrder
		FROM @Markers
	) V1
	ORDER BY DisplayOrder
	
END
GO
/****** Object:  StoredProcedure [dbo].[PR_GetDeterminationAssigmentForSetABS]    Script Date: 1/23/2020 5:39:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- PR_GetDeterminationAssigmentForSetABS 4779
CREATE PROCEDURE [dbo].[PR_GetDeterminationAssigmentForSetABS]
(
    @PeriodID INT
) 
AS 
BEGIN
    SET NOCOUNT ON;

	DECLARE @StartDate DATE, @EndDate DATE;
    DECLARE @PlatformID INT = (SELECT PlatformID FROM [Platform] WHERE PlatformCode = 'LS'); --light scanner   

    SELECT
	   @StartDate = StartDate,
	   @EndDate = EndDate
    FROM [Period]
    WHERE PeriodID = @PeriodID;

	SELECT 
		DetAssignmentID,
		2
	FROM DeterminationAssignment DA
	JOIN
    (
	   SELECT
		  AC.ABSCropCode,
		  PM.MethodCode
	   FROM CropMethod CM
	   JOIN ABSCrop AC ON AC.ABSCropCode = CM.ABSCropCode
	   JOIN Method PM ON PM.MethodID = CM.MethodID
	   WHERE CM.PlatformID = @PlatformID
    ) V1 ON V1.ABSCropCode = DA.ABSCropCode AND V1.MethodCode = DA.MethodCode
    JOIN Variety V ON V.VarietyNr = DA.VarietyNr
	WHERE CAST(DA.PlannedDate AS DATE) BETWEEN @StartDate AND @EndDate AND DA.StatusCode IN (200,300)

END
GO
/****** Object:  StoredProcedure [dbo].[PR_GetDeterminationAssigmentOverview]    Script Date: 1/23/2020 5:39:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
Author					Date			Remarks
Binod Gurung			-				-
Krishna Gautam			2020-01-21		Where clause added.
Binod Gurung			2020-jan-23		Transcation isolation level implemented to avoid record lock

=================EXAMPLE=============
-- PR_GetDeterminationAssigmentOverview 4792
*/
CREATE PROCEDURE [dbo].[PR_GetDeterminationAssigmentOverview]
(
    @PeriodID INT
) AS BEGIN
    SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    DECLARE @PlatformID INT = (SELECT PlatformID FROM [Platform] WHERE PlatformCode = 'LS'); --light scanner  

	SELECT 
	   DA.DetAssignmentID,
	   DA.SampleNr,   
	   DA.BatchNr,
	   Article = V.Shortname,
	   'Status' = COALESCE(S.StatusName, CAST(DA.StatusCode AS NVARCHAR(10))),
	   'Exp Ready' = DA.ExpectedReadyDate, 
	   V2.Folder,
	   'Quality Class' = DA.QualityClass
    FROM DeterminationAssignment DA
    JOIN
    (
	   SELECT
		  AC.ABSCropCode,
		  PM.MethodCode
	   FROM CropMethod CM
	   JOIN ABSCrop AC ON AC.ABSCropCode = CM.ABSCropCode
	   JOIN Method PM ON PM.MethodID = CM.MethodID
	   WHERE CM.PlatformID = @PlatformID
    ) V1 ON V1.ABSCropCode = DA.ABSCropCode AND V1.MethodCode = DA.MethodCode
    JOIN Variety V ON V.VarietyNr = DA.VarietyNr
	JOIN
	(
		SELECT W.DetAssignmentID, MAX(T.TestName) AS Folder FROM Test T
		JOIN Plate P ON P.TestID = T.TestID
		JOIN Well W ON W.PlateID = P.PlateID
		--WHERE T.StatusCode >= 500
		GROUP BY W.DetAssignmentID
	) V2 On V2.DetAssignmentID = DA.DetAssignmentID
	join TestDetAssignment TDA ON TDA.DetAssignmentID = DA.DetAssignmentID
	JOIN Test T ON T.TestID = TDA.TestID
	JOIN [Status] S ON S.StatusCode = DA.StatusCode AND S.StatusTable = 'DeterminationAssignment'
	WHERE T.PeriodID = @PeriodID AND DA.StatusCode IN (600,999)

END
GO
/****** Object:  StoredProcedure [dbo].[PR_GetDeterminationAssignments]    Script Date: 1/23/2020 5:39:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
Author					Date			Description
Binod Gurung			2020-jan-23		Transcation isolation level implemented to avoid record lock

===================================Example================================

    DECLARE @UnPlannedDataAsJson NVARCHAR(MAX) = N'[{"DetAssignmentID":1,"MethodCode":"PAC-01","ABSCropCode": "HP","VarietyNr":"21046"}]';
    EXEC PR_GetDeterminationAssignments 4780, @UnPlannedDataAsJson
*/
CREATE PROCEDURE [dbo].[PR_GetDeterminationAssignments]
(
    @PeriodID			   INT,
    @UnPlannedDataAsJson	   NVARCHAR(MAX) = NULL
) 
AS 
BEGIN
    SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    DECLARE @StartDate DATE, @EndDate DATE;
    DECLARE @SQL NVARCHAR(MAX);
    DECLARE @PlatformID INT = (SELECT PlatformID FROM [Platform] WHERE PlatformCode = 'LS'); --light scanner   
    DECLARE @MaxSeqNr INT = 0;
    
    DECLARE @Groups TABLE
    (
	   SlotName	    NVARCHAR(100),
	   ABSCropCode	    NVARCHAR(20), 
	   MethodCode	    NVARCHAR(50), 
	   UsedFor	    NVARCHAR(10),
	   TotalPlates	    INT,
	   NrOfResPlates	    DECIMAL(5,2)
    ); 
    DECLARE @Capacity TABLE
    (
	   ABSCropCode	    NVARCHAR(20), 
	   MethodCode	    NVARCHAR(50), 
	   ResPlates   DECIMAL(5,2)
    );  
    --handle unplanned records if exists
    DECLARE @DeterminationAssignment TABLE
    (
	   DetAssignmentID    INT,
	   SampleNr		  INT,
	   PriorityCode	  INT,
	   MethodCode		  NVARCHAR(25),
	   ABSCropCode		  NVARCHAR(10),
	   VarietyNr		  INT,
	   BatchNr			  INT,
	   RepeatIndicator    BIT,
	   Process			  NVARCHAR(100),
	   ProductStatus	  NVARCHAR(100),
	   Remarks			  NVARCHAR(250),
	   PlannedDate		  DATETIME,
	   UtmostInlayDate    DATETIME,
	   ExpectedReadyDate  DATETIME,
	   ReceiveDate		  DATETIME,
	   ReciprocalProd	  BIT,
	   BioIndicator		  BIT,
	   LogicalClassificationCode	NVARCHAR(20),
	   LocationCode					NVARCHAR(20),
	   IsLabPriority				BIT
    );
    --Prapare output of details records
    DECLARE @Result TABLE
    (
	   SeqNr			  INT,
	   DetAssignmentID    INT,
	   SampleNr		  INT,
	   PriorityCode	  INT,
	   MethodCode		  NVARCHAR(25),
	   ABSCropCode		  NVARCHAR(10),
	   Article		  NVARCHAR(100),
	   VarietyNr		  INT,
	   BatchNr		  INT,
	   RepeatIndicator    BIT,
	   Process		  NVARCHAR(100),
	   ProductStatus	  NVARCHAR(100),
	   Remarks			  NVARCHAR(250),
	   PlannedDate		  DATETIME,
	   UtmostInlayDate    DATETIME,
	   ExpectedReadyDate  DATETIME,
	   IsPlanned		  BIT,
	   UsedFor			NVARCHAR(10),
	   CanEdit			BIT,
	   IsLabPriority	BIT,
	   IsPacComplete	BIT	
    );

    SELECT
	   @StartDate = StartDate,
	   @EndDate = EndDate
    FROM [Period]
    WHERE PeriodID = @PeriodID;

    --Preapre capacities of planned records
    INSERT @Capacity(ABSCropCode, MethodCode, ResPlates)
    SELECT
	   T1.ABSCropCode,
	   T1.MethodCode,
	   NrOfPlates = SUM(T1.NrOfPlates)
    FROM
    (
	   SELECT 
		  V1.ABSCropCode,
		  DA.MethodCode,
		  NrOfPlates = CAST((V1.NrOfSeeds / 92.0) AS DECIMAL(5,2))
	   FROM DeterminationAssignment DA
	   JOIN
	   (
		  SELECT 
			 PM.MethodCode,
			 AC.ABSCropCode,
			 PM.NrOfSeeds
		  FROM Method PM
		  JOIN CropMethod PCM ON PCM.MethodID = PM.MethodID
		  JOIN ABSCrop AC ON AC.ABSCropCode = PCM.ABSCropCode
		  WHERE PCM.PlatformID = @PlatformID
		  AND PM.StatusCode = 100
	   ) V1 ON V1.ABSCropCode = DA.ABSCropCode AND V1.MethodCode = DA.MethodCode
	   WHERE CAST(DA.PlannedDate AS DATE) BETWEEN @StartDate AND @EndDate
    ) T1 
    GROUP BY T1.ABSCropCode, T1.MethodCode;
    
    --Prepare Grops of planned records groups
    INSERT @Groups(SlotName, ABSCropCode, MethodCode, UsedFor, TotalPlates, NrOfResPlates)
    SELECT
	   V1.SlotName,
	   V1.ABSCropCode,
	   V1.MethodCode,
	   V1.UsedFor,
	   V1.TotalPlates,
	   ResPlates = ISNULL(V2.ResPlates, 0)
    FROM
    (
	   SELECT 
		  PC.SlotName,
		  AC.ABSCropCode, 
		  PM.MethodCode,
		  CM.UsedFor,
		  TotalPlates = SUM(PC.NrOfPlates)
	   FROM ReservedCapacity PC
	   JOIN CropMethod CM ON CM.CropMethodID = PC.CropMethodID
	   JOIN ABSCrop AC ON AC.ABSCropCode = CM.ABSCropCode
	   JOIN Method PM ON PM.MethodID = CM.MethodID
	   WHERE CM.PlatformID = @PlatformID AND PC.PeriodID = @PeriodID
	   GROUP BY PC.SlotName, AC.ABSCropCode, PM.MethodCode, CM.UsedFor
    ) V1
    JOIN @Capacity V2 ON V2.ABSCropCode = V1.ABSCropCode AND V2.MethodCode = V1.MethodCode;

    --Get details of planned determinations    
    INSERT @Result
    (
	   SeqNr,
	   DetAssignmentID,	 
	   MethodCode,		
	   ABSCropCode,
	   SampleNr,
	   UtmostInlayDate, 
	   ExpectedReadyDate,
	   PriorityCode,	
	   BatchNr,	
	   RepeatIndicator, 
	   Article,
	   VarietyNr,
	   Process,		
	   ProductStatus,	
	   Remarks, 
	   PlannedDate,	   
	   IsPlanned,		
	   UsedFor,
	   CanEdit,
	   IsLabPriority,
	   IsPacComplete
    )
    SELECT 
	   DA.SeqNr,
	   DA.DetAssignmentID,
	   DA.MethodCode,
	   DA.ABSCropCode,
	   DA.SampleNr,
	   DA.UtmostInlayDate,
	   DA.ExpectedReadyDate, 
	   DA.PriorityCode,	   
	   DA.BatchNr,
	   DA.RepeatIndicator,
	   V.Shortname,
	   V.VarietyNr,
	   DA.Process,
	   DA.ProductStatus,
	   DA.Remarks,
	   DA.PlannedDate,
	   IsPlanned = 1,
	   UsedFor = CASE WHEN V.HybOp = 0 AND V.[Type] = 'P' THEN 'Par' ELSE 'Hyb' END,
	   CASE WHEN DA.StatusCode < 200 THEN 1 ELSE 0 END,
	   ISNULL(DA.IsLabPriority, 0),
	   1 --Pac complete profile true for already planned DA
    FROM DeterminationAssignment DA
    JOIN
    (
	   SELECT
		  AC.ABSCropCode,
		  PM.MethodCode
	   FROM CropMethod CM
	   JOIN ABSCrop AC ON AC.ABSCropCode = CM.ABSCropCode
	   JOIN Method PM ON PM.MethodID = CM.MethodID
	   WHERE CM.PlatformID = @PlatformID
    ) V1 ON V1.ABSCropCode = DA.ABSCropCode AND V1.MethodCode = DA.MethodCode
    JOIN Variety V ON V.VarietyNr = DA.VarietyNr
    WHERE CAST(DA.PlannedDate AS DATE) BETWEEN @StartDate AND @EndDate AND DA.StatusCode <= 200;   
    	 	 
    --Process unplannded records    
    IF(ISNULL(@UnPlannedDataAsJson, '') <> '') BEGIN
	   SELECT 
		  @MaxSeqNr = MAX(SeqNr) 
	   FROM @Result;
	   
	   INSERT @DeterminationAssignment
	   (
		  DetAssignmentID, 
		  SampleNr, 
		  PriorityCode, 
		  MethodCode, 
		  ABSCropCode, 
		  VarietyNr, 
		  BatchNr, 
		  RepeatIndicator, 
		  Process, 
		  ProductStatus, 
		  Remarks,  
		  UtmostInlayDate, 
		  ExpectedReadyDate,
		  ReceiveDate,
		  ReciprocalProd,
		  BioIndicator,
		  LogicalClassificationCode,
		  LocationCode,
		  IsLabPriority,
		  PlannedDate
	   )
	   SELECT *, IsLabPriority = 0, GETDATE() 
	   FROM OPENJSON(@UnPlannedDataAsJson) WITH
	   (
		  DetAssignmentID    INT,
		  SampleNr		  INT,
		  PriorityCode	  INT,
		  MethodCode		  NVARCHAR(25),
		  ABSCropCode		  NVARCHAR(10),
		  VarietyNr		  INT,
		  BatchNr		  INT,
		  RepeatIndicator    BIT,
		  Process		  NVARCHAR(100),
		  ProductStatus	  NVARCHAR(100),
		  Remarks				NVARCHAR(250),
		  UtmostInlayDate   DATETIME,
		  ExpectedReadyDate DATETIME,
		  ReceiveDate		DATETIME,
		  ReciprocalProd	BIT,
		  BioIndicator		BIT,
		  LogicalClassificationCode	NVARCHAR(20),
		  LocationCode				NVARCHAR(20)
	   );
	   
	   --no need to process @Capacity, res plates is always 0 for unplanned records
	   --Prepare Grops of planned records groups
	   INSERT @Groups(SlotName, ABSCropCode, MethodCode, UsedFor, TotalPlates, NrOfResPlates)
	   SELECT
		  V1.SlotName,
		  V1.ABSCropCode,
		  V1.MethodCode,
		  V1.UsedFor,
		  V1.TotalPlates,
		  ResPlates = 0
	   FROM
	   (
		  SELECT 
			 PC.SlotName,
			 AC.ABSCropCode, 
			 PM.MethodCode,
			 CM.UsedFor,
			 TotalPlates = SUM(PC.NrOfPlates)
		  FROM ReservedCapacity PC
		  JOIN CropMethod CM ON CM.CropMethodID = PC.CropMethodID
		  JOIN ABSCrop AC ON AC.ABSCropCode = CM.ABSCropCode
		  JOIN Method PM ON PM.MethodID = CM.MethodID
		  WHERE CM.PlatformID = @PlatformID AND PC.PeriodID = @PeriodID
		  GROUP BY PC.SlotName, AC.ABSCropCode, PM.MethodCode, CM.UsedFor
	   ) V1
	   WHERE NOT EXISTS
	   (
		  SELECT ABSCropCode, MethodCode
		  FROM @Groups
		  WHERE ABSCropCode = V1.ABSCropCode AND MethodCode = V1.MethodCode
	   );

	   --Get details of planned determinations    
	   INSERT @Result
	   (
		  SeqNr,
		  DetAssignmentID,	 
		  MethodCode,		
		  ABSCropCode,
		  SampleNr,
		  UtmostInlayDate, 
		  ExpectedReadyDate,
		  PriorityCode,	
		  BatchNr,	
		  RepeatIndicator, 
		  Article,
		  VarietyNr,
		  Process,		
		  ProductStatus,	
		  Remarks, 
		  PlannedDate,	   
		  IsPlanned,		
		  UsedFor,
		  CanEdit,
		  IsLabPriority,
		  IsPacComplete
	   )
	   SELECT 
		  SeqNr = ROW_NUMBER() OVER(ORDER BY DetAssignmentID) + @MaxSeqNr,
		  DA.DetAssignmentID,
		  DA.MethodCode,
		  DA.ABSCropCode,
		  DA.SampleNr,
		  DA.UtmostInlayDate,
		  DA.ExpectedReadyDate, 
		  DA.PriorityCode,	   
		  DA.BatchNr,
		  DA.RepeatIndicator,
		  V.Shortname,
		  V.VarietyNr,
		  DA.Process,
		  DA.ProductStatus,
		  DA.Remarks,
		  DA.PlannedDate,
		  IsPlanned = 0,
		  UsedFor = CASE WHEN V.HybOp = 0 AND V.[Type] = 'P' THEN 'Par' ELSE 'Hyb' END,
		  CASE WHEN DA.PriorityCode IN(4, 7, 8) THEN 0 ELSE 1 END,
		  0,
		  dbo.FN_IsPacProfileComplete (DA.VarietyNr, @PlatformID, AC.CropCode) --#8068 Check PAC profile complete 
	   FROM @DeterminationAssignment DA
	   JOIN
	   (
		  SELECT
			 AC.ABSCropCode,
			 PM.MethodCode
		  FROM CropMethod CM
		  JOIN ABSCrop AC ON AC.ABSCropCode = CM.ABSCropCode
		  JOIN Method PM ON PM.MethodID = CM.MethodID
		  WHERE CM.PlatformID = @PlatformID
	   ) V1 ON V1.ABSCropCode = DA.ABSCropCode AND V1.MethodCode = DA.MethodCode
	   JOIN ABSCrop AC ON AC.ABSCropCode = DA.ABSCropCode
	   JOIN Variety V ON V.VarietyNr = DA.VarietyNr
	   WHERE NOT EXISTS
	   (
		  SELECT DetAssignmentID 
		  FROM DeterminationAssignment
		  WHERE DetAssignmentID = DA.DetAssignmentID
	   );	   
    END  

    --return groups
    SELECT 
	   * 
    FROM @Groups G
    JOIN
    (
	   SELECT 
		  R.ABSCropCode,
		  R.MethodCode,
		  R.UsedFor,
		  TotalRows = COUNT( R.DetAssignmentID)
	   FROM @Result R
	   GROUP BY R.ABSCropCode, R.MethodCode, R.UsedFor
    ) V ON V.ABSCropCode = G.ABSCropCode AND V.MethodCode = G.MethodCode AND V.UsedFor = G.UsedFor
    WHERE V.TotalRows > 0;

    --return details
    SELECT 
	   DetAssignmentID,	 
	   MethodCode,		
	   ABSCropCode,
	   SampleNr,
	   UtmostInlayDate = FORMAT(UtmostInlayDate, 'dd/MM/yyyy'), 
	   ExpectedReadyDate = FORMAT(ExpectedReadyDate, 'dd/MM/yyyy'),
	   PriorityCode,	
	   BatchNr,	
	   RepeatIndicator, 
	   Article,
	   Process,		
	   ProductStatus,	
	   Remarks, 
	   PlannedDate = FORMAT(PlannedDate, 'dd/MM/yyyy'),
	   IsPlanned,		
	   UsedFor,
	   CanEditPlanning = CanEdit,
	   IsLabPriority,
	   IsPacComplete,
	   VarietyNr
    FROM @Result T
    ORDER BY T.ABSCropCode, T.MethodCode, T.PriorityCode, ExpectedReadyDate;
END
GO
/****** Object:  StoredProcedure [dbo].[PR_GetFolderDetails]    Script Date: 1/23/2020 5:39:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
Author					Date			Description
Binod Gurung			2020-jan-23		Transcation isolation level implemented to avoid record lock										

===================================Example================================

    EXEC PR_GetFolderDetails 4792;
*/
CREATE PROCEDURE [dbo].[PR_GetFolderDetails]
(
    @PeriodID	 INT
) 
AS 
BEGIN
    SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    DECLARE @tbl TABLE
    (
	   DetAssignmentID INT,
	   TestID		    INT,
	   TestName	    NVARCHAR(200),
	   CropCode	    NVARCHAR(10),
	   MethodCode	    NVARCHAR(100),
	   PlatformName    NVARCHAR(100),
	   NrOfPlates	    DECIMAL(6,2),
	   NrOfMarkers	    DECIMAL(6,2),
	   VarietyNr	    INT,
	   VarietyName	    NVARCHAR(200),
	   SampleNr	    INT,
	   IsLabPriority   INT,
	   IsParent	    BIT,
	   TraitMarkers BIT
    );

    INSERT @tbl(DetAssignmentID, TestID, TestName, CropCode, MethodCode, PlatformName, NrOfPlates, NrOfMarkers, VarietyNr, VarietyName, SampleNr, IsLabPriority, IsParent, TraitMarkers)
    SELECT 
	   DA.DetAssignmentID,	   
	   T.TestID,
	   T.TestName,
	   C.CropCode,
	   DA.MethodCode, 
	   P.PlatformDesc,
	   V2.NrOfPlates,
	   V3.NrOfMarkers,
	   V.VarietyNr,
	   V.Shortname,
	   DA.SampleNr,
	   ISNULL(DA.IsLabPriority, 0), --labpriority for folder only
	   CASE WHEN V.HybOp = 0 AND V.[Type] = 'P' THEN 1 ELSE 0 END,
	   TraitMarkers = CAST (CASE WHEN ISNULL(V4.TraitMarker,0) = 0 THEN 0 ELSE 1 END As BIT)
    FROM Test T
    JOIN TestDetAssignment TDA ON TDA.TestID = T.TestID
    JOIN DeterminationAssignment DA ON DA.DetAssignmentID = TDA.DetAssignmentID
    JOIN ABSCrop C ON C.ABSCropCode = DA.ABSCropCode
    JOIN Method M ON M.MethodCode = DA.MethodCode
    JOIN CropMethod CM ON CM.ABSCropCode = DA.ABSCropCode AND CM.MethodID = M.MethodID
    JOIN [Platform] P ON P.PlatformID = CM.PlatformID
    JOIN Variety V ON V.VarietyNr = DA.VarietyNr
    LEFT JOIN
    (
	   SELECT 
		  MethodID,
		  NrOfPlates = NrOfSeeds/92.0
	   FROM Method
    ) V2 ON V2.MethodID = M.MethodID
    LEFT JOIN 
    (
	   SELECT 
		   DetAssignmentID,
		   NrOfMarkers = COUNT(MarkerID)
	   FROM MarkerToBeTested
	   GROUP BY DetAssignmentID
    ) V3 ON V3.DetAssignmentID = DA.DetAssignmentID
	LEFT JOIN 
	(
		SELECT DA.DetAssignmentID, TraitMarker = MAX(MPV.MarkerID) FROM DeterminationAssignment DA
		JOIN Variety V ON V.VarietyNr = DA.VarietyNr
		JOIN MarkerPerVariety MPV ON MPV.VarietyNr = V.VarietyNr
		WHERE MPV.StatusCode = 100
		GROUP BY DetAssignmentID
	) V4 ON V4.DetAssignmentID = DA.DetAssignmentID
    WHERE T.PeriodID = @PeriodID;

    --create groups
    SELECT 
	   V2.TestID,
	   TestName = COALESCE(V2.TestName, 'Folder ' + CAST(ROW_NUMBER() OVER(ORDER BY V2.CropCode, V2.MethodCode) AS VARCHAR)),
	   V2.CropCode,
	   V2.MethodCode,
	   V2.PlatformName,
	   V2.NrOfPlates,
	   V2.NrOfMarkers,
	   TraitMarkers,
	   IsLabPriority = CAST(0 AS BIT)
    FROM
    (
	   SELECT 
		  V.*,
		  T.TestName,
		  TraitMarkers = CAST (CASE WHEN ISNULL(V2.TraitMarker,0) = 0 THEN 0 ELSE 1 END As BIT)
	   FROM
	   (
		  SELECT
			 TestID,
			 CropCode,
			 MethodCode,
			 PlatformName,
			 NrOfPlates = SUM(NrOfPlates),
			 NrOfMarkers = SUM(NrOfMarkers)
		  FROM @tbl
		  GROUP BY TestID, CropCode, MethodCode, PlatformName
	   ) V
	   JOIN Test T ON T.TestID = V.TestID
	   LEFT JOIN
	   (
			SELECT TD.TestID, TraitMarker = MAX(MPV.MarkerID) FROM TestDetAssignment TD
			JOIN DeterminationAssignment DA On DA.DetAssignmentID = TD.DetAssignmentID
			JOIN Variety V ON V.VarietyNr = DA.VarietyNr
			JOIN MarkerPerVariety MPV ON MPV.VarietyNr = V.VarietyNr
			WHERE MPV.StatusCode = 100
			GROUP BY TestID
	   ) V2 On V2.TestID = T.TestID
    ) V2
    ORDER BY V2.CropCode, V2.MethodCode;

    SELECT
	   TestID,
	   TestName = NULL,--just to manage column list in client side.
	   CropCode,
	   MethodCode,
	   PlatformName,
	   DetAssignmentID,
	   NrOfPlates,
	   NrOfMarkers,
	   VarietyName,
	   SampleNr,
	   IsParent = CAST(CASE WHEN DetAssignmentID % 2 = 0 THEN 1 ELSE 0 END AS BIT),
	   IsLabPriority = CAST(IsLabPriority AS BIT),
	   TraitMarkers
    FROM @tbl T

    SELECT 
	   MIN(T2.StatusCode) AS StatusCode
    FROM @tbl T1
    JOIN Test T2 ON T2.TestID = T1.TestID;
END
GO
/****** Object:  StoredProcedure [dbo].[PR_GetInfoForFillPlatesInLIMS]    Script Date: 1/23/2020 5:39:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
Author					Date			Description
Binod Gurung			2019/12/03		Get information for FillPlatesInLIMS
Binod Gurung			2020-jan-23		Transcation isolation level implemented to avoid record lock

===================================Example================================

EXEC PR_GetInfoForFillPlatesInLIMS 4792
*/
CREATE PROCEDURE [dbo].[PR_GetInfoForFillPlatesInLIMS]
(
	@PeriodID INT
)
AS
BEGIN
	
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

	SELECT 
		ISNULL(T.LabPlatePlanID,0),
		ISNULL(T.TestID,0),
		AC.CropCode,
		ISNULL(P.LabPlateID,0),
		ISNULL(P.PlateName,''),
		ISNULL(M.MarkerID,0), 
		M.MarkerFullName,
		PlateColumn = CAST(substring(W.Position,2,2) AS INT),
		PlateRow = substring(W.Position,1,1),
		PlantNr = ISNULL(DA.SampleNr,0),
		PlantName = V.Shortname,
		BreedingStation = 'NLSO' --hard coded : comment in #7257
	FROM Test T
	JOIN Plate P ON P.TestID = T.TestID
	JOIN Well W ON W.PlateID = P.PlateID
	JOIN DeterminationAssignment DA ON DA.DetAssignmentID = W.DetAssignmentID
	JOIN Variety V ON V.VarietyNr = DA.VarietyNr
	JOIN ABSCrop AC ON AC.ABSCropCode = DA.ABSCropCode
	JOIN
	(
		SELECT MTB.MarkerID, DetAssignmentID FROM MarkerToBeTested MTB
		UNION
		SELECT MarkerID, DA.DetAssignmentID FROM MarkerPerVariety MPV
		JOIN DeterminationAssignment DA ON DA.VarietyNr = MPV.VarietyNr
		WHERE MPV.StatusCode = 100
	) MVPV ON MVPV.DetAssignmentID = DA.DetAssignmentID
	JOIN Marker M ON M.MarkerID = MVPV.MarkerID
	WHERE T.PeriodID = @PeriodID

	
END

GO
/****** Object:  StoredProcedure [dbo].[PR_GetInfoForUpdateDA]    Script Date: 1/23/2020 5:39:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Binod Gurung
-- Create date: 2020/01/21
-- Description:	Get information for UpdateDA
-- =============================================
/*
EXEC PR_GetInfoForUpdateDA 1568336
*/
CREATE PROCEDURE [dbo].[PR_GetInfoForUpdateDA]
(
	@DetAssignmentID INT
)
AS
BEGIN
	
	SET NOCOUNT ON;

	SELECT
		DetAssignmentID = Max(DA.DetAssignmentID),
		ValidatedOn		= FORMAT(MAX(ValidatedOn), 'yyyy-MM-dd', 'en-US'),
		Result			= CAST ((MAX(DA.ActualSamples) * 100 / SUM(P.NrOfSamples)) AS DECIMAL),
		QualityClass	= MAX(QualityClass),
		ValidatedBy		= MAX(ValidatedBy)
	FROM DeterminationAssignment DA
	LEFT JOIN Pattern P On P.DetAssignmentID = DA.DetAssignmentID 
	WHERE DA.DetAssignmentID = @DetAssignmentID
	GROUP BY DA.DetAssignmentID
	
END

GO
/****** Object:  StoredProcedure [dbo].[PR_GetMarkerPerVarieties]    Script Date: 1/23/2020 5:39:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- PR_GetMarkerPerVarieties
CREATE PROCEDURE [dbo].[PR_GetMarkerPerVarieties]
AS BEGIN
    SET NOCOUNT ON;

    SELECT 
	   V.CropCode AS 'Crop',
	   MPV.MarkerPerVarID,
	   MPV.MarkerID,
	   V.Shortname AS 'Variety name',
	   MPV.VarietyNr AS 'Variety number',
	   M.MarkerFullName AS 'Trait marker',
	   MPV.ExpectedResult AS 'Expected result', 
	   MPV.Remarks,
	   S.StatusName
    FROM MarkerPerVariety MPV
    JOIN Marker M ON M.MarkerID = MPV.MarkerID
    JOIN Variety V ON V.VarietyNr = MPV.VarietyNr
    JOIN [Status] S ON S.StatusCode = MPV.StatusCode AND S.StatusTable = 'Marker'
    ORDER BY S.StatusCode, M.MarkerName;
END
GO
/****** Object:  StoredProcedure [dbo].[PR_GetMarkers]    Script Date: 1/23/2020 5:39:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- PR_GetMarkers 'SL'
CREATE PROCEDURE [dbo].[PR_GetMarkers]
(
    @MarkerName NVARCHAR(100) = ''
) AS BEGIN
    SET NOCOUNT ON;

    SELECT 
	   M.MarkerID,
	   MarkerName = M.MarkerFullName
    FROM Marker M
    WHERE M.StatusCode = 100 
    AND M.MarkerFullName LIKE '%' + @MarkerName + '%';
END
GO
/****** Object:  StoredProcedure [dbo].[PR_GetMinTestStatusPerPeriod]    Script Date: 1/23/2020 5:39:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- PR_GetMinTestStatusPerPeriod 4779
CREATE PROCEDURE [dbo].[PR_GetMinTestStatusPerPeriod]
(
	@PeriodID INT
) 
AS 
BEGIN
    SET NOCOUNT ON;

    DECLARE @Status INT;

	SELECT MIN(StatusCode) AS StatusCode FROM Test WHERE PeriodID = @PeriodID;

END
GO
/****** Object:  StoredProcedure [dbo].[PR_GetPeriod]    Script Date: 1/23/2020 5:39:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--EXEC PR_GetPeriod 2019
CREATE PROCEDURE [dbo].[PR_GetPeriod]
(
	@Year INT
	
)
AS
BEGIN
	SELECT 
		P.PeriodID, 
		PeriodName = CONCAT(P.PeriodName, FORMAT(P.StartDate, ' (MMM-dd-yy - ', 'en-US' ), FORMAT(P.EndDate, 'MMM-dd-yy)', 'en-US' )),
		[Current] = CAST(CASE WHEN GETDATE() BETWEEN P.StartDate AND P.EndDate THEN 1 ELSE 0 END AS BIT),
		P.StartDate,
		P.EndDate
	FROM [Period] P
	WHERE @Year BETWEEN YEAR(P.StartDate) AND YEAR(P.EndDate)
END
GO
/****** Object:  StoredProcedure [dbo].[PR_GetPlanningCapacitySO_LS]    Script Date: 1/23/2020 5:39:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
Author					Date			Description
Krishna Gautam			2019-Jul-08		Service created to get capacity planning for SO for Lightscanner

===================================Example================================

EXEC PR_GetPlanningCapacitySO_LS 4744
*/

CREATE PROCEDURE [dbo].[PR_GetPlanningCapacitySO_LS]
(
	@PeriodID INT
)
AS 
BEGIN

	DECLARE @Query NVARCHAR(MAX),@Query1 NVARCHAR(MAX),@Columns NVARCHAR(MAX), @MinPeriodID INT,@PlatformID INT;
	DECLARE @Period TABLE(PeriodID INT,PeriodName NVARCHAR(MAX));
	DECLARE @ColumnTable TABLE(ColumnID NVARCHAR(MAX), Label NVARCHAR(MAX),[Order] INT, IsVisible BIT,Editable BIT);

	SELECT @PlatformID = PlatformID 
	FROM Platform WHERE PlatformDesc = 'Lightscanner';

	IF(ISNULL(@PlatformID,0)=0)
	BEGIN
		EXEC PR_ThrowError 'Invalid Platform';
		RETURN
	END
	
	IF NOT EXISTS (SELECT PeriodID FROM [Period] WHERE PeriodID = @PeriodID)
	BEGIN
		EXEC PR_ThrowError 'Invalid Period (Week)';
		RETURN
	END

	INSERT INTO @Period(PeriodID, PeriodName)
	SELECT 
		P.PeriodID,
		Concat('Wk' + RIGHT(P.PeriodName,2), '(',Concat(FORMAT(P.StartDate,'MMMd','en-US'),'-',FORMAT(P.EndDate,'MMMd','en-US')),')') AS PeriodName
	FROM [Period] P 
	WHERE PeriodID BETWEEN @PeriodID - 4 AND @PeriodID +5

	SELECT 
		@Columns = COALESCE(@Columns +',','') + QUOTENAME(PeriodID)
	FROM @Period ORDER BY PeriodID;

	SELECT TOP 1 @MinPeriodID =  PeriodID FROM @Period ORDER BY PeriodID


	IF(ISNULL(@Columns,'') = '')
	BEGIN
		EXEC PR_ThrowError 'No Period (week) found';
		RETURN
	END

	SET @Query = N'SELECT T1.CropMethodID, C.ABSCropCode,PM.MethodCode, UsedFor, '+ @Columns+'
				FROM 
				(
					SELECT 
					   CropMethodID, 
					   MethodID, 
					   ABSCropCode,
					   UsedFor,
					   DisplayOrder
					FROM CropMethod 
				) 
				T1 
				JOIN Method PM ON PM.MethodID = T1.MethodID
				JOIN ABSCrop C ON C.ABSCropCode = T1.ABSCropCode
				LEFT JOIN
				(
					SELECT CropMethodID,'+@Columns+'
					FROM 
					(
						SELECT CropMethodID,PeriodID, NrOfPlates = MAX(NrOfPlates) 
						FROM ReservedCapacity						
						GROUP BY CropMethodID,PeriodID
					) 
					SRC
					PIVOT 
					(
						MAX(NrOfPlates)
						FOR PeriodID IN ('+@Columns+')
					)
					PIV

				) T2 ON T2.CropMethodID = T1.CropMethodID
	
				Order BY T1.UsedFor, T1.DisplayOrder';

	

	EXEC SP_ExecuteSQL @Query ,N'@PlatformID INT', @PlatformID;


	INSERT INTO @ColumnTable(ColumnID,Label,[Order],IsVisible,Editable)
	VALUES
	('CropMethodID','CropMethodID',0,0,0),
	('ABSCropCode','ABS Crop',1,1,0),
	('MethodCode','Method',2,1,0),
	('UsedFor','UsedFor',3,0,0);
	

	INSERT INTO @ColumnTable(ColumnID,Label,[Order],IsVisible,Editable)
	SELECT PeriodID, PeriodName, PeriodID - @MinPeriodID + 4, 1,1 FROM @Period ORDER BY PeriodID

	SELECT * FROM @ColumnTable
	

    DECLARE @tbl RCAggrTableType;
    
    INSERT @tbl (Method, PeriodID, NrOfPlates, DisplayOrder)
    SELECT 'Hybrid Plates' AS Method, PeriodID, NrOfPlates = SUM(NrOfPlates), 1
    FROM ReservedCapacity RC
    JOIN CropMethod PC ON PC.CropMethodID = RC.CropMethodID 
    WHERE PC.UsedFor = 'HYB'
    GROUP BY PeriodID;
    IF(@@ROWCOUNT = 0) BEGIN
	   INSERT @tbl(Method) VALUES('Hybrid Plates');
    END

    INSERT @tbl (Method, PeriodID, NrOfPlates, DisplayOrder)
    SELECT 'Parentline Plates' AS Method, PeriodID, NrOfPlates = SUM(NrOfPlates), 2
    FROM ReservedCapacity RC
    JOIN CropMethod PC ON PC.CropMethodID = RC.CropMethodID 
    WHERE PC.UsedFor = 'par'
    GROUP BY PeriodID;
    IF(@@ROWCOUNT = 0) BEGIN
	   INSERT @tbl(Method) VALUES('Parentline Plates');
    END

    INSERT @tbl (Method, PeriodID, NrOfPlates, DisplayOrder)
    SELECT 'Total Plates' AS Method, PeriodID, NrOfPlates = SUM(NrOfPlates), 3
    FROM ReservedCapacity
    GROUP BY PeriodID
    IF(@@ROWCOUNT = 0) BEGIN
	   INSERT @tbl(Method) VALUES('Total Plates');
    END
    
    INSERT @tbl (Method, PeriodID, NrOfPlates, DisplayOrder)
    SELECT 'Plates Budget' AS Method, PeriodID, NrOfPlates, 4
    FROM Capacity
    WHERE PlatformID = @PlatformID
    IF(@@ROWCOUNT = 0) BEGIN
	   INSERT @tbl(Method) VALUES('Plates Budget');
    END

    SET @Query1 = N'SELECT Method, ' + @Columns + N' 
    FROM
    (
	   SELECT Method, DisplayOrder, ' + @Columns + N' 
	   FROM @tbl SRC
	   PIVOT 
	   (
		  MAX(NrOfPlates)
		  FOR PeriodID IN (' + @Columns + N')
	   ) PIV 
    ) V1 
    ORDER BY DisplayOrder';
    EXEC SP_ExecuteSQL @Query1 , N'@tbl RCAggrTableType READONLY, @PlatformID INT', @tbl, @PlatformID
END
GO
/****** Object:  StoredProcedure [dbo].[PR_GetPlateLabels]    Script Date: 1/23/2020 5:39:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
Author					Date			Remarks
Krishna Gautam			2020/01/10		Created folder structcture based on lab priority and excelude already sent test while preparing folder structure

============ExAMPLE===================
--EXEC PR_GetPlateLabels 4792,NULL
*/

CREATE PROCEDURE [dbo].[PR_GetPlateLabels]
(
	@PeriodID INT,
	@TestID INT
)
AS
BEGIN
	SELECT 'NLSO' AS Country, MAX(C.CropCode), MAX(P.PlateName), MAX(P.LabPlateID)  FROM Plate P
	JOIN Test T ON T.TestID = P.TestID
	JOIN TestDetAssignment TD ON TD.TestID = T.TestID
	JOIN DeterminationAssignment DA ON DA.DetAssignmentID = TD.DetAssignmentID
	JOIN ABSCrop C ON C.ABSCropCode = DA.ABSCropCode
	WHERE (ISNULL(@TestID,0) = 0  OR T.TestID = @TestID) AND  T.PeriodID = @PeriodID
	GROUP BY P.PlateID

END
GO
/****** Object:  StoredProcedure [dbo].[PR_GetPlatesOverview]    Script Date: 1/23/2020 5:39:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
Author					Date			Remarks
Krishna Gautam			2020/01/14		Created Stored procedure to fetch data of provided periodID

=================EXAMPLE=============

EXEC PR_GetPlatesOverview 4792
*/

CREATE PROCEDURE [dbo].[PR_GetPlatesOverview]
(
	@PeriodID INT
)
AS 
BEGIN

	DECLARE @PeriodName NVARCHAR(50);
	DECLARE @TempTBL TABLE (TestID INT, NrOfSeeds INT,PeriodName NVARCHAR(50));
	
	IF NOT EXISTS(SELECT PeriodID FROM [Period] WHERE PeriodID = @PeriodID)
	BEGIN
		EXEC PR_ThrowError 'Invalid PeriodID';
		RETURN;
	END
	
	SELECT @PeriodName = CONCAT(PeriodName, FORMAT(StartDate, ' (MMM-dd-yy - ', 'en-US' ), FORMAT(EndDate, 'MMM-dd-yy)', 'en-US' ))
	FROM [Period] WHERE PeriodID = @PeriodID;

	INSERT INTO @TempTBL(TestID, NrOfSeeds,PeriodName)
		SELECT T.TestID, M.NrOfSeeds, @PeriodName FROM Test T 
		JOIN TestDetAssignment TDA ON T.TestID = TDA.TestID
		JOIN DeterminationAssignment DA ON DA.DetAssignmentID = TDA.DetAssignmentID
		JOIN Method M ON M.MethodCode = DA.MethodCode
		WHERE T.PeriodID = @PeriodID
		GROUP BY T.TestID, NrOfSeeds
	
	SELECT 
		T.FolderNr, 
		T.PlateID, 
		T.PlateNumber,
		Position = CASE WHEN NrOfSeeds = 23 THEN REPLACE(T.Position,'-','+')
						WHEN NrOfSeeds >=92 THEN ''
						ELSE T.Position
					END,
		T.BatchNr, 
		T.SampleNr, 
		PeriodName = @PeriodName,
		ReportType = CASE 
						WHEN NrOfSeeds = 23 THEN 1
						WHEN NrOfSeeds = 46 THEN 2
						WHEN NrOfSeeds >=92 THEN 3
						END
	FROM 
	(
	SELECT 
		FolderNr = MAX(T.TestName),
		W.PlateID,  
		PlateNumber = MAX(P.PlateName) , 
		Position = CONCAT(LEFT(MIN(w.Position),1),'-',LEFT(MAX(w.Position),1)) , 
		BatchNr= Max(DA.BatchNr), 
		SampleNr = MAX(DA.SampleNr), 
		W.DetAssignmentID,
		T.TestID,
		NrOfSeeds = MAX(T1.NrOfSeeds)
	FROM Test T
	JOIN @TempTBL T1 ON T1.TestID = T.TestID
	JOIN plate p ON T.TestID = P.TestID
	JOIN well W on W.PlateID = P.PlateID
	LEFT JOIN DeterminationAssignment DA ON DA.DetAssignmentID = W.DetAssignmentID
	LEFT JOIN Method M ON M.MethodCode = DA.MethodCode	
	WHERE W.Position NOT IN ('B01','D01','F01','H01') AND T.PeriodID = @PeriodID
	GROUP BY T.TestID, W.DetAssignmentID,W.PlateID 
	) T
	ORDER BY NrOfSeeds, T.PlateID, Position

END
GO
/****** Object:  StoredProcedure [dbo].[PR_GetTestInfoForLIMS]    Script Date: 1/23/2020 5:39:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
Author					Date			Description
Binod Gurung			2019/10/22		Pull Test Information for input period for LIMS
Binod Gurung			2020-jan-23		Transcation isolation level implemented to avoid record lock

===================================Example================================

EXEC PR_GetTestInfoForLIMS 4791, 5, 2
*/
CREATE PROCEDURE [dbo].[PR_GetTestInfoForLIMS]
(
	@PeriodID INT,
	@WeekDiff INT,
	@WeekDiffLab INT
)
AS
BEGIN
	
	DECLARE @PlannedDateStart DATETIME, @PlannedDateEnd DATETIME, @ExpectedDateStart DATETIME, @ExpectedDateEnd DATETIME, @PlannedDate DATETIME, @ExpectedDate DATETIME;
	DECLARE @ExpectedDateStartLab DATETIME, @ExpectedDateEndLab DATETIME, @ExpectedDateLab DATETIME;

	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

	SELECT 
		@PlannedDateStart = StartDate, 
		@PlannedDateEnd = EndDate 
	FROM [Period] WHERE PeriodID = @PeriodID;

	SELECT @ExpectedDateStart = DATEADD(WEEK, @WeekDiff, @PlannedDateStart);
	SELECT @ExpectedDateEnd = DATEADD(WEEK, @WeekDiff, @PlannedDateEnd);

	SELECT @ExpectedDateStartLab = DATEADD(WEEK, @WeekDiffLab, @PlannedDateStart);
	SELECT @ExpectedDateEndLab = DATEADD(WEEK, @WeekDiffLab, @PlannedDateEnd);

	-- Planned date is the monday of planned week
	WITH CTE
	AS
	(
		SELECT TOP 1 0 AS N, StartDate FROM [Period] P
			WHERE P.StartDate BETWEEN @PlannedDateStart AND @PlannedDateEnd ORDER BY P.StartDate
		UNION ALL
		SELECT n + 1, DATEADD(Day,1, Startdate) AS D1 
		FROM CTE
		  WHERE n < 6
	)
	SELECT @PlannedDate = CTE.StartDate FROM CTE
	WHERE DATENAME(WEEKDAY,CTE.StartDate) = 'Monday';

	-- Expected date is the friday of expected week
	WITH CTE
	AS
	(
		SELECT TOP 1 0 AS N, StartDate FROM [Period] P
			WHERE P.StartDate BETWEEN @ExpectedDateStart AND @ExpectedDateEnd ORDER BY P.StartDate
		UNION ALL
		SELECT n+1, DATEADD(Day,1, Startdate) AS D1 FROM CTE
			WHERE n<6
	)
	SELECT @ExpectedDate = CTE.StartDate FROM CTE
	WHERE DATENAME(WEEKDAY,CTE.StartDate) = 'Friday';

	WITH CTE
	AS
	(
		SELECT TOP 1 0 AS N, StartDate FROM [Period] P
			WHERE P.StartDate BETWEEN @ExpectedDateStartLab AND @ExpectedDateEndLab ORDER BY P.StartDate
		UNION ALL
		SELECT n+1, DATEADD(Day,1, Startdate) AS D1 FROM CTE
			WHERE n<6
	)
	SELECT @ExpectedDateLab = CTE.StartDate FROM CTE
	WHERE DATENAME(WEEKDAY,CTE.StartDate) = 'Friday';

	SELECT 
	   T1.ContainerType,
	   T1.CountryCode,
	   T1.CropCode,
	   ExpectedDate = FORMAT(T1.ExpectedDate, 'yyyy-MM-dd', 'en-US'),
	   ExpectedWeek = DATEPART(WEEK, T1.ExpectedDate),
	   ExpectedYear = YEAR(T1.ExpectedDate),
	   T1.Isolated,
	   T1.MaterialState,
	   T1.MaterialType,
	   PlannedDate = FORMAT(T1.PlannedDate, 'yyyy-MM-dd', 'en-US'),
	   T1.PlannedWeek,
	   T1.PlannedYear,
	   T1.Remark,
	   T1.RequestID,
	   T1.RequestingSystem,
	   T1.SynchronisationCode,
	   T1.TotalNrOfPlates,
	   T1.TotalNrOfTests
	FROM
	(
	    SELECT 
		    'DPW' AS ContainerType,
		    'NL' AS CountryCode,
		    MAX(V0.CropCode) AS CropCode,
		    ExpectedDate = CASE WHEN ISNULL(MAX(L1.TestID),0) = 0 THEN @ExpectedDate ELSE @ExpectedDateLab END,
		    'N' AS Isolated,	
		    'FRS' AS MaterialState,
		    'SDS' AS MaterialType,
		    PlannedDate =  @PlannedDate,
		    PlannedWeek = DATEPART(WEEK, @PlannedDate),	
		    PlannedYear = YEAR(@PlannedDate),
		    'PAC' AS Remark, 
		    T.TestID	AS RequestID, 
		    'PAC' AS RequestingSystem,
		    'NL' AS SynchronisationCode,
			CAST(CEILING(SUM(ISNULL(V0.PlatesPerRow,0))) AS INT) AS TotalNrOfPlates,
			CAST(CEILING(SUM(ISNULL(TestsPerRow,0))) AS INT) AS TotalNrOfTests
		    
	    FROM
	    (	
		    SELECT 
			    TestID, DA.DetAssignmentID, 
			    (M.NrOfSeeds / 92.0) AS PlatesPerRow,
			    V1.MarkersPerDA,
			    ( (M.NrOfSeeds / 92.0) * V1.MarkersPerDA) + ISNULL(TM.TraitMarkerCount,0) AS TestsPerRow,
			    AC.CropCode
		    FROM TestDetAssignment TDA
		    JOIN DeterminationAssignment DA ON DA.DetAssignmentID = TDA.DetAssignmentID
		    JOIN Method M ON M.MethodCode = DA.MethodCode
		    JOIN CropMethod CM ON CM.MethodID = M.MethodID AND CM.ABSCropCode = DA.ABSCropCode
		    JOIN ABSCrop AC On AC.ABSCropCode = DA.ABSCropCode
		    LEFT JOIN 
		    (
			    SELECT DetAssignmentID, COUNT(DetAssignmentID) AS MarkersPerDA FROM MarkerToBeTested MTBT 
			    GROUP BY DetAssignmentID
		    ) V1 ON V1.DetAssignmentID = DA.DetAssignmentID
			--Add traitmarker count to total number of test
			LEFT JOIN
			(
				SELECT VarietyNr, COUNT(DISTINCT MarkerID) AS TraitMarkerCount FROM MarkerPerVariety MPV
				WHERE MPV.StatusCode = 100
				GROUP BY VarietyNr
			) TM ON TM.VarietyNr = DA.VarietyNr
	    ) V0 
	    JOIN Test T ON T.TestID = V0.TestID
		--Find IsLabPriority on Determination assignment level
		LEFT JOIN 
		(
			SELECT T.TestID FROM Test T
			JOIN Plate P On P.TestID = T.TestID
			JOIN Well W ON W.PlateID = W.PlateID
			JOIN DeterminationAssignment DA ON DA.DetAssignmentID = W.DetAssignmentID
			WHERE ISNULL(DA.IsLabPriority,0) = 1 
		) L1 ON L1.TestID = T.TestID
	    WHERE T.PeriodID = @PeriodID AND T.StatusCode = 150
	    GROUP BY T.TestID, T.IsLabPriority
	) T1;
END

GO
/****** Object:  StoredProcedure [dbo].[PR_GetVarieties]    Script Date: 1/23/2020 5:39:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- PR_GetVarieties 'EK'
CREATE PROCEDURE [dbo].[PR_GetVarieties]
(
    @VarietyName NVARCHAR(100) = ''
) AS BEGIN
    SET NOCOUNT ON;

    SELECT 
	   V.VarietyNr,
	   VarietyName = V.Shortname
    FROM Variety V
    WHERE --V.[Status] = '100' AND 
    V.Shortname LIKE '%' + @VarietyName + '%';
END
GO
/****** Object:  StoredProcedure [dbo].[PR_Ignite_Decluster]    Script Date: 1/23/2020 5:39:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Binod Gurung
-- Create date: 2019/10/18
-- Description:	Procedure to ignite decluster
-- =============================================
/*	
	EXEC [PR_Ignite_Decluster]
*/
CREATE PROCEDURE [dbo].[PR_Ignite_Decluster]
AS
BEGIN

	DECLARE @DetAssignmentID INT, @ReturnVarieties NVARCHAR(MAX), @TestID INT;
	
	SET NOCOUNT ON;
	
	BEGIN TRY
		BEGIN TRANSACTION;

		DECLARE Determination_Cursor CURSOR LOCAL FAST_FORWARD FOR
		SELECT DetAssignmentID FROM DeterminationAssignment DA WHERE DA.StatusCode = 200
		OPEN Determination_Cursor;
		FETCH NEXT FROM Determination_Cursor INTO @DetAssignmentID;
	
		WHILE @@FETCH_STATUS = 0
		BEGIN
			
			EXEC [PR_Decluster] @DetAssignmentID, @ReturnVarieties OUTPUT;

			--update status of determination assignment 
			UPDATE DeterminationAssignment
			SET StatusCode = 300
			WHERE DetAssignmentID = @DetAssignmentID;

			SELECT @TestID = TestID FROM TestDetAssignment WHERE DetAssignmentID = @DetAssignmentID;

			--if all destermination assignments are declustered then update status of Test
			IF NOT EXISTS
			(
				SELECT TD.TestID FROM TestDetAssignment TD
				JOIN DeterminationAssignment DA ON DA.DetAssignmentID = TD.DetAssignmentID
				where DA.StatusCode < 300 AND TD.TestID = @TestID
			)
			BEGIN

				UPDATE Test
				SET StatusCode = 150 --Declustered
				WHERE TestID = @TestID

			END
			
			FETCH NEXT FROM Determination_Cursor INTO @DetAssignmentID;
		END
	
		CLOSE Determination_Cursor;
		DEALLOCATE Determination_Cursor;

		COMMIT;
	END TRY
	BEGIN CATCH
		IF(@@TRANCOUNT > 0)
			ROLLBACK;
		THROW;
	END CATCH
	
END
GO
/****** Object:  StoredProcedure [dbo].[PR_PlanAutoDeterminationAssignments]    Script Date: 1/23/2020 5:39:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
Author					Date			Description
Binod Gurung			2020-jan-23		Transcation isolation level implemented to avoid record lock
										
===================================Example================================

    DECLARE @ABSDataAsJson NVARCHAR(MAX) =  N'[{"DetAssignmentID":1736406,"MethodCode":"PAC-01","ABSCropCode": "SP","VarietyNr":"21063","PriorityCode": 1}]';
    EXEC PR_PlanAutoDeterminationAssignments 4779, @ABSDataAsJson
*/
CREATE PROCEDURE [dbo].[PR_PlanAutoDeterminationAssignments]
(
    @PeriodID		INT,
    @ABSDataAsJson	NVARCHAR(MAX)
) 
AS 
BEGIN
    SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    DECLARE @TransCount BIT = 0;

    DECLARE @ABSCropCode NVARCHAR(10);
    DECLARE @MethodCode	NVARCHAR(25);
    DECLARE @RequiredPlates INT;
    DECLARE @UsedFor NVARCHAR(10);
    DECLARE @PlatesPerMethod	  DECIMAL(5,2);
    DECLARE @RequiredDeterminations INT;
    DECLARE @StartDate DATE, @EndDate DATE;
    DECLARE @IDX INT = 1;
    DECLARE @CNT INT = 0;
    
    SELECT
	   @StartDate = StartDate,
	   @EndDate = EndDate
    FROM [Period]
    WHERE PeriodID = @PeriodID;

    DECLARE @PlatformID INT = (SELECT PlatformID FROM [Platform] WHERE PlatformCode = 'LS'); --light scanner   

    DECLARE @Capacity TABLE
    (
	   UsedFor	    VARCHAR(5), 
	   ABSCropCode	    NVARCHAR(10), 
	   MethodCode	    NVARCHAR(50), 
	   ReservePlates   DECIMAL(5,2)
    );

    DECLARE @Groups TABLE
    (
	   ID		    INT IDENTITY(1, 1),    
	   ABSCropCode	    NVARCHAR(10), 
	   MethodCode	    NVARCHAR(50), 
	   UsedFor	    VARCHAR(5), 
	   ReservePlates   DECIMAL(5,2),
	   TotalPlates	DECIMAL(5,2)
    );

    --handle unplanned records if exists
    DECLARE @DeterminationAssignment TABLE
    (
	   DetAssignmentID	    INT,
	   SampleNr		    INT,
	   PriorityCode	    INT,
	   MethodCode		    NVARCHAR(25),
	   CropCode		    NVARCHAR(10),
	   ABSCropCode		   NVARCHAR(20),
	   VarietyNr		    INT,
	   BatchNr		    INT,
	   RepeatIndicator	    BIT,
	   Process		    NVARCHAR(100),
	   ProductStatus	    NVARCHAR(100),
	   Remarks	    NVARCHAR(250),
	   PlannedDate		   DATE,
	   UtmostInlayDate	    DATE,
	   ExpectedReadyDate   DATE,
	   ReceiveDate		  DATETIME,
	   ReciprocalProd	  BIT,
	   BioIndicator		  BIT,
	   LogicalClassificationCode	NVARCHAR(20),
	   LocationCode					NVARCHAR(20),
	   UsedFor		    NVARCHAR(10)
    );

     BEGIN TRY
	   IF @@TRANCOUNT = 0 BEGIN
		  BEGIN TRANSACTION;
		  SET @TransCount = 1;
	   END

	   --clean already planned records before planning again
	   DELETE DA
	   FROM DeterminationAssignment DA
	   WHERE CAST(DA.PlannedDate AS DATE) BETWEEN @StartDate AND @EndDate
	   AND DA.StatusCode = 100;

	   INSERT @Capacity(UsedFor, ABSCropCode, MethodCode, ReservePlates)
	   SELECT
		  T1.UsedFor,
		  T1.ABSCropCode,
		  T1.MethodCode,
		  NrOfPlates = SUM(T1.NrOfPlates)
	   FROM
	   (
		  SELECT 
			 V1.ABSCropCode,
			 DA.MethodCode,
			 V1.UsedFor,
			 NrOfPlates = CAST((V1.NrOfSeeds / 92.0) AS DECIMAL(5,2))
		  FROM DeterminationAssignment DA
		  JOIN
		  (
			 SELECT 
				PM.MethodCode,
				AC.ABSCropCode,
				PM.NrOfSeeds,
				PCM.UsedFor
			 FROM Method PM
			 JOIN CropMethod PCM ON PCM.MethodID = PM.MethodID
			 JOIN ABSCrop AC ON AC.ABSCropCode = PCM.ABSCropCode
			 WHERE PCM.PlatformID = @PlatformID
			 AND PM.StatusCode = 100
		  ) V1 ON V1.ABSCropCode = DA.ABSCropCode AND V1.MethodCode = DA.MethodCode
		  WHERE CAST(DA.PlannedDate AS DATE) BETWEEN @StartDate AND @EndDate
	   ) T1 
	   GROUP BY T1.ABSCropCode, T1.MethodCode, T1.UsedFor;

	   INSERT INTO @Groups(ABSCropCode, MethodCode, UsedFor, TotalPlates, ReservePlates)
	   SELECT
		  V1.ABSCropCode,
		  V1.MethodCode,
		  V1.UsedFor,
		  ISNULL(V1.TotalPlates, 0),
		  ISNULL(V2.ReservePlates, 0)
	   FROM
	   (
		  SELECT 
			 PC.SlotName,
			 AC.ABSCropCode, 
			 PM.MethodCode,	
			 CM.UsedFor,
			 TotalPlates = SUM(PC.NrOfPlates)
		  FROM ReservedCapacity PC
		  JOIN CropMethod CM ON CM.CropMethodID = PC.CropMethodID
		  JOIN ABSCrop AC ON AC.ABSCropCode = CM.ABSCropCode
		  JOIN Method PM ON PM.MethodID = CM.MethodID
		  WHERE CM.PlatformID = @PlatformID AND PC.PeriodID = @PeriodID
		  GROUP BY PC.SlotName, AC.ABSCropCode, PM.MethodCode, CM.UsedFor
	   ) V1
	   LEFT JOIN @Capacity V2 ON V2.ABSCropCode = V1.ABSCropCode AND V2.MethodCode = V1.MethodCode AND V2.UsedFor = V1.UsedFor;

	   INSERT @DeterminationAssignment
	   (
		    DetAssignmentID, 
		    SampleNr, 
		    PriorityCode, 
		    MethodCode, 
		    ABSCropCode, 
		    VarietyNr, 
		    BatchNr, 
		    RepeatIndicator, 
		    Process, 
		    ProductStatus, 
		    Remarks, 
		    PlannedDate, 
		    UtmostInlayDate, 
		    ExpectedReadyDate,
		    ReceiveDate,
		    ReciprocalProd,
		    BioIndicator,
		    LogicalClassificationCode,
		    LocationCode,
		    UsedFor
	   )
	   SELECT 
		  T1.*,
		  UsedFor = CASE WHEN V.HybOp = 0 AND V.[Type] = 'P' THEN 'Par' ELSE 'Hyb' END
	   FROM OPENJSON(@ABSDataAsJson) WITH
	   (
		    DetAssignmentID	   INT,
		    SampleNr		   INT,
		    PriorityCode	   INT,
		    MethodCode		   NVARCHAR(25),
		    ABSCropCode		   NVARCHAR(10),
		    VarietyNr		   INT,
		    BatchNr		   INT,
		    RepeatIndicator	   BIT,
		    Process		   NVARCHAR(100),
		    ProductStatus	   NVARCHAR(100),
		    Remarks	   NVARCHAR(250),
		    PlannedDate		   DATETIME,
		    UtmostInlayDate	   DATETIME,
		    ExpectedReadyDate   DATETIME,	   
		    ReceiveDate		DATETIME,
		    ReciprocalProd	BIT,
		    BioIndicator		BIT,
		    LogicalClassificationCode	NVARCHAR(20),
		    LocationCode				NVARCHAR(20)
	   ) T1
	   JOIN ABSCrop C ON C.ABSCropCode = T1.ABSCropCode
	   JOIN Variety V ON V.VarietyNr = T1.VarietyNr
	   JOIN Method M ON M.MethodCode = T1.MethodCode
	   WHERE T1.PriorityCode NOT IN(4, 7, 8)
	   AND dbo.FN_IsPacProfileComplete (V.VarietyNr, @PlatformID, C.CropCode) = 1 -- #8068 Only plan if PAC profile complete is true
	   ORDER BY T1.PriorityCode;
    	  
	   SELECT @CNT = COUNT(ID) FROM @Groups;
	   WHILE(@IDX <= @CNT) BEGIN
		  SELECT 
			 @ABSCropCode =  G.ABSCropCode,
			 @MethodCode = G.MethodCode,
			 @RequiredPlates = G.TotalPlates - G.ReservePlates,
			 @UsedFor = G.UsedFor
		  FROM @Groups G
		  WHERE ID = @IDX;
    
		  IF(@RequiredPlates > 0) BEGIN	   
			 SELECT 
				@PlatesPerMethod = CAST((NrOfSeeds / 92.0) AS DECIMAL(5,2))
			 FROM Method 
			 WHERE MethodCode = @MethodCode;

			 SET @RequiredDeterminations = @RequiredPlates / @PlatesPerMethod;

			 --insert records into DeterminationAssignments and calculate required plates again
			 INSERT INTO DeterminationAssignment
			 (
				DetAssignmentID, 
				SampleNr, 
				PriorityCode, 
				MethodCode, 
				ABSCropCode, 
				VarietyNr, 
				BatchNr, 
				RepeatIndicator, 
				Process, 
				ProductStatus, 
				Remarks, 
				PlannedDate, 
				UtmostInlayDate, 
				ExpectedReadyDate,
				StatusCode,
				ReceiveDate,
				ReciprocalProd,
				BioIndicator,
				LogicalClassificationCode,
				LocationCode
			 )
			 SELECT TOP(@RequiredDeterminations) 
				DetAssignmentID, 
				SampleNr, 
				PriorityCode, 
				MethodCode, 
				ABSCropCode, 
				VarietyNr, 
				BatchNr, 
				RepeatIndicator, 
				Process, 
				ProductStatus, 
				Remarks, 
				CASE WHEN CAST(D.PlannedDate AS DATE) BETWEEN @StartDate AND @EndDate THEN D.PlannedDate ELSE @EndDate END,
				UtmostInlayDate, 
				ExpectedReadyDate,
				100,
				ReceiveDate,
				ReciprocalProd,
				BioIndicator,
				LogicalClassificationCode,
				LocationCode
			 FROM @DeterminationAssignment D
			 WHERE D.ABSCropCode = @ABSCropCode 
			 AND D.MethodCode = @MethodCode
			 AND D.UsedFor = @UsedFor
			 AND ISNULL(D.PriorityCode, 0) <> 0 
			 AND NOT EXISTS
			 (
				SELECT 
				    DetAssignmentID 
				FROM DeterminationAssignment
				WHERE DetAssignmentID = D.DetAssignmentID
			 )
			 ORDER BY D.PriorityCode;
			 --now check if plates are fulfilled already with priority	   
			 SET @RequiredPlates = @RequiredPlates - (@@ROWCOUNT * @PlatesPerMethod);
			 --if we still need determinations, get it based on expected ready date here
			 IF(@RequiredPlates > 0 AND @RequiredPlates > @PlatesPerMethod) BEGIN
				--PRINT 'we need more'
				--determine how many determinations required for required plates
				SET @RequiredDeterminations = @RequiredPlates / @PlatesPerMethod;

				INSERT INTO DeterminationAssignment
				(
				    DetAssignmentID, 
				    SampleNr, 
				    PriorityCode, 
				    MethodCode, 
				    ABSCropCode, 
				    VarietyNr, 
				    BatchNr, 
				    RepeatIndicator, 
				    Process, 
				    ProductStatus, 
				    Remarks, 
				    PlannedDate, 
				    UtmostInlayDate, 
				    ExpectedReadyDate,
				    StatusCode,
				    ReceiveDate,
				    ReciprocalProd,
				    BioIndicator,
				    LogicalClassificationCode,
				    LocationCode
				)
				SELECT TOP(@RequiredDeterminations) 
				    DetAssignmentID, 
				    SampleNr, 
				    PriorityCode, 
				    MethodCode, 
				    ABSCropCode, 
				    VarietyNr, 
				    BatchNr, 
				    RepeatIndicator, 
				    Process, 
				    ProductStatus, 
				    Remarks, 
				    CASE WHEN CAST(D.PlannedDate AS DATE) BETWEEN @StartDate AND @EndDate THEN D.PlannedDate ELSE @EndDate END,
				    UtmostInlayDate, 
				    ExpectedReadyDate,
				    100,
				    ReceiveDate,
				    ReciprocalProd,
				    BioIndicator,
				    LogicalClassificationCode,
				    LocationCode
				FROM @DeterminationAssignment D
				WHERE D.ABSCropCode = @ABSCropCode 
				AND D.MethodCode = @MethodCode
				AND D.UsedFor = @UsedFor
				AND ISNULL(PriorityCode, 0) = 0 
				AND NOT EXISTS
				(
				    SELECT 
					   DetAssignmentID 
				    FROM DeterminationAssignment
				    WHERE DetAssignmentID = D.DetAssignmentID
				)
				ORDER BY D.ExpectedReadyDate;
			 END
		  END
		  SET @IDX = @IDX + 1;
	   END

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
/****** Object:  StoredProcedure [dbo].[PR_PlateFilling]    Script Date: 1/23/2020 5:39:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Binod Gurung
-- Create date: 2019-12-02
-- Description:	Platefilling
-- EXEC PR_PlateFilling 331
-- =============================================
CREATE PROCEDURE [dbo].[PR_PlateFilling]
(
	@TestID INT
)
AS
BEGIN
	
	DECLARE @StartRow CHAR(1) = 'A', @EndRow CHAR(1) = 'H', @StartColumn INT = 1, @EndColumn INT = 12, @RowCounter INT = 0, @ColumnCounter INT;
	DECLARE @TempTbl TABLE (Position VARCHAR(5))

	SET NOCOUNT ON;

	BEGIN TRY
		
		BEGIN TRANSACTION;

			--delete existing well in case already exists for sme test/plate
			DELETE W FROM Well W
			JOIN Plate P ON P.PlateID = W.PlateID
			WHERE P.TestID = @TestID;

			SET @RowCounter=Ascii(@StartRow);

			WHILE @RowCounter<=Ascii(@EndRow)	BEGIN
				SET @ColumnCounter = @StartColumn;
				WHILE(@ColumnCounter <= @EndColumn) BEGIN							
					INSERT INTO @TempTbl(Position)
						VALUES(CHAR(@RowCounter) + RIGHT('00'+CAST(@ColumnCounter AS VARCHAR),2))
					SET @ColumnCounter = @ColumnCounter + 1;
				END
				SET @RowCounter=@RowCounter + 1;
			END

			INSERT INTO Well (Position, PlateID, DetAssignmentID)
			SELECT 
				Position,
				T1.PlateID, 		
				CASE WHEN CHARINDEX(Position, 'B01,D01,F01,H01') > 0 THEN NULL ELSE T1.DetAssignmentID END
			FROM @TempTbl
			CROSS JOIN 
			(
				SELECT P.PlateID, DA.DetAssignmentID FROM Plate P
				JOIN TestDetAssignment TD ON TD.TestID = P.TestID
				JOIN DeterminationAssignment DA ON DA.DetAssignmentID = TD.DetAssignmentID
				JOIN Method M ON M.MethodCode = DA.MethodCode WHERE TD.TestID = @TestID 
		
			) T1
			ORDER BY T1.PlateID

			--Update Test info 350
			UPDATE Test 
				SET StatusCode = 350
			WHERE TestID = @TestID;
			
		COMMIT;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK;
		THROW;
	END CATCH

END
GO
/****** Object:  StoredProcedure [dbo].[PR_ProcessAllTestResultSummary]    Script Date: 1/23/2020 5:39:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
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
	   JOIN Test T ON T.TestID = TDA.TestID
	   WHERE ISNULL(W.DetAssignmentID, 0) <> 0
	   AND T.StatusCode = 500
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
/****** Object:  StoredProcedure [dbo].[PR_ProcessTestResultSummary]    Script Date: 1/23/2020 5:39:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--EXEC PR_ProcessTestResultSummary 1444777;
CREATE PROCEDURE [dbo].[PR_ProcessTestResultSummary]
(
    @DetAssignmentID INT
) AS BEGIN
    SET NOCOUNT ON;
    DECLARE @TransCount BIT = 0;
    
    DECLARE @SQL NVARCHAR(MAX), @Columns NVARCHAR(MAX), @Columns2 NVARCHAR(MAX);
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
/****** Object:  StoredProcedure [dbo].[PR_ReceiveResultsinKscoreCallback]    Script Date: 1/23/2020 5:39:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
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
/****** Object:  StoredProcedure [dbo].[PR_ReservePlateplansInLimsCallback]    Script Date: 1/23/2020 5:39:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
Author					Date			Remarks
Binod Gurung			2019/12/13		Created service to create plate when callback sevice from lims is called to PAC.
Krishna Gautam			2020/01/10		Changed logic to solve issue of well assigning to multiple determination

=================EXAMPLE=============
DECLARE @T1 TVP_Plates
INSERT INTO @T1(LIMSPlateID,LIMSPlateName)
VALUES(336,'abc'),(337,'bcd')
EXEC PR_ReservePlateplansInLimsCallback 44,'Test',322,@T1
*/
CREATE PROCEDURE [dbo].[PR_ReservePlateplansInLimsCallback]
(
	@LIMSPlateplanID		INT,
	@TestName				NVARCHAR(100),
	@TestID					INT,
	@TVP_Plates TVP_Plates	READONLY
) AS BEGIN

	DECLARE @LabPlateTable TABLE(LabID INT, LabPlateName NVARCHAR(100));
	DECLARE @StartRow CHAR(1) = 'A', @EndRow CHAR(1) = 'H', @StartColumn INT = 1, @EndColumn INT = 12, @RowCounter INT = 0, @ColumnCounter INT, @PlateCount INT, @Offset INT = 0, @NextRows INT, @DACount INT, @DetAssignmentID INT;
	DECLARE @TempTbl TABLE (Position VARCHAR(5));
	DECLARE @TempPlateTable TABLE(PlateID INT);
	DECLARE @CreatedWell TABLE(ID INT IDENTITY(1,1), WellID INT, PlateID INT, Position NVARCHAR(10), DAID INT,Inserted BIT);
	DECLARE @TblDA TABLE(ID INT IDENTITY(1,1), DAID INT,NrOfSeeds INT);

	SET NOCOUNT ON;
	BEGIN TRY
		
		BEGIN TRANSACTION;

			IF NOT EXISTS (SELECT * FROM TEST WHERE TestID = @TestID AND StatusCode = 200) BEGIN
				EXEC PR_ThrowError 'Invalid RequestID.';
				ROLLBACK;
				RETURN;
			END
			
			DELETE W FROM Well W
			JOIN Plate P ON P.PlateID = W.PlateID
			WHERE P.TestID = @TestID;

			DELETE Plate WHERE TestID = @TestID


			SET @RowCounter=Ascii(@StartRow);

			WHILE @RowCounter<=Ascii(@EndRow)	BEGIN
				SET @ColumnCounter = @StartColumn;
				WHILE(@ColumnCounter <= @EndColumn) BEGIN							
					INSERT INTO @TempTbl(Position)
						VALUES(CHAR(@RowCounter) + RIGHT('00'+CAST(@ColumnCounter AS VARCHAR),2))
					SET @ColumnCounter = @ColumnCounter + 1;
				END
				SET @RowCounter=@RowCounter + 1;
			END


			INSERT INTO @TblDA(DAID, NrOfSeeds)
			SELECT 
				TDA.DetAssignmentID, 
				M.NrOfSeeds 
			FROM Method M
			JOIN DeterminationAssignment DA ON DA.MethodCode = M.MethodCode
			JOIN Variety V ON V.VarietyNr = DA.VarietyNr
			JOIN TestDetAssignment TDA ON TDA.DetAssignmentID = DA.DetAssignmentID
			WHERE TDA.TestID = @TestID
			ORDER BY ISNULL(DA.IsLabPriority, 0) DESC, CASE WHEN V.HybOp = 0 AND V.[Type] = 'P' THEN 1 ELSE 0 END ASC,  DA.DetAssignmentID ASC

			
			INSERT INTO @LabPlateTable (LabID, LabPlateName)
			SELECT LIMSPlateID, LIMSPlateName
			FROM @TVP_Plates;	

			--Insert plate info
			MERGE INTO Plate T
			USING
			(
				SELECT LabID, LabPlateName FROM @LabPlateTable

			) S ON S.LabID = T.LabPlateID
			WHEN NOT MATCHED THEN
			  INSERT(PlateName,LabPlateID,TestID)  
			  VALUES(S.LabPlateName,S.LabID, @TestID)
			  OUTPUT INSERTED.PlateID INTO @TempPlateTable(PlateID);


			 --Create empty well for created plates
			INSERT INTO Well(PlateID, Position)
			OUTPUT INSERTED.WellID, INSERTED.PlateID, INSERTED.Position INTO @CreatedWell(WellID,PlateID,Position)
			SELECT T2.PlateID, T1.Position FROM @TempTbl T1
			CROSS APPLY @TempPlateTable T2
			ORDER BY T2.PlateID;

			DELETE FROM @CreatedWell where Position IN ('B01', 'D01', 'F01', 'H01');

			SET @RowCounter =1;
			SELECT @DACount = COUNT(ID) FROM @TblDA;

			WHILE(@RowCounter <= @DACount)
			BEGIN
				SELECT 
					@NextRows = NrOfSeeds,
					@DetAssignmentID = DAID
				FROM @TblDA WHERE ID = @RowCounter;

				MERGE INTO @CreatedWell T
				USING
				(
					SELECT ID FROM @CreatedWell  ORDER BY ID OFFSET @Offset ROWS FETCH NEXT @NextRows ROWS ONLY
				) S
				ON S.ID = T.ID
				WHEN MATCHED THEN
				UPDATE SET T.DAID = @DetAssignmentID;

				SET @Offset = @Offset + @NextRows;

				SET @RowCounter = @RowCounter + 1;

			END

			MERGE INTO Well T
			USING @CreatedWell S
			ON S.WellID = T.WellID
			WHEN MATCHED
			THEN UPDATE SET T.DetAssignmentID = S.DAID;

			
			--Update Test info
			UPDATE Test 
			SET LabPlatePlanID = @LIMSPlateplanID,
				TestName = @TestName,
				StatusCode = 300
			WHERE TestID = @TestID;

		COMMIT;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK;
		THROW;
	END CATCH
END
GO
/****** Object:  StoredProcedure [dbo].[PR_ReTestDetermination]    Script Date: 1/23/2020 5:39:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
Author					Date			Remarks
Krishna Gautam			2020/01/10		Created service to approve determinationAssignment to re-test.

============ExAMPLE===================
--EXEC PR_ReTestDetermination 125487
*/
CREATE PROCEDURE [dbo].[PR_ReTestDetermination]
(
	@ID INT
)
AS 
BEGIN

	IF NOT EXISTS (SELECT DetAssignmentID FROM DeterminationAssignment WHERE DetAssignmentID = @ID)
	BEGIN
		EXEC PR_ThrowError 'Invalid ID.';
		RETURN
	END

	DELETE TR FROM TestResult TR
	JOIN Well W ON W.WellID = TR.WellID
	WHERE W.DetAssignmentID = @ID;


	UPDATE DeterminationAssignment SET StatusCode = 650
	WHERE DetAssignmentID = @ID;
END
GO
/****** Object:  StoredProcedure [dbo].[PR_SaveCapacity]    Script Date: 1/23/2020 5:39:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
Author					Date			Description
Krishna Gautam			2019-Jul-05		Service created to save pac capacity

===================================Example================================

DECLARE @DataAsJson NVARCHAR(MAX) = N'
[
	{"PeriodID":4744,"PlatformID":"Remarks","value":"Remarks"}
]';
EXEC PR_SaveCapacity @DataAsJson;
*/
CREATE PROCEDURE [dbo].[PR_SaveCapacity]
(
	@Json NVARCHAR(MAX)
)
AS 
BEGIN
	 SET NOCOUNT ON;
	 DECLARE @PlatformID INT;
	 DECLARE @FilledCapacity TABLE (PeriodID INT,PlatformID INT, Val INT);	 

	 BEGIN TRY
		BEGIN TRANSACTION;

			SELECT 
				 @PlatformID = PlatformID 
			FROM [Platform] 
			WHERE PlatformDesc = 'Lightscanner';

			--Fill temptable from Input Json
			INSERT INTO @FilledCapacity(PeriodID, PlatformID, Val)
			SELECT PeriodID, PlatformID, Val
			FROM OPENJSON(@Json) WITH
			(
				PeriodID	INT '$.PeriodID',
				PlatformID	NVARCHAR(MAX) '$.PlatformID',
				Val			NVARCHAR(MAX) '$.Value'
			)
			WHERE ISNUMERIC(PlatformID) = 1;

			--If planned capacity is greater than lab capacity then return error
			IF EXISTS 
			(
				SELECT * FROM @FilledCapacity C
				JOIN
				(
					SELECT FC.PeriodID, FC.PlatformID, SUM(RC.NrOfPlates) AS TotalPlates FROM @FilledCapacity FC 
					JOIN CropMethod CM ON CM.PlatformID = FC.PlatformID
					JOIN ReservedCapacity RC ON RC.CropMethodID = CM.CropMethodID AND RC.PeriodID = FC.PeriodID
					GROUP BY FC.PeriodID, FC.PlatformID
				) T1 ON T1.PeriodID = C.PeriodID AND T1.PlatformID = C.PlatformID
				WHERE T1.TotalPlates > C.Val
			)
			BEGIN
				EXEC PR_ThrowError 'Unable to update lab capacity. More capacity planned already.';
				RETURN
			END	

		
			--update capacity 
			MERGE INTO Capacity T
			USING
			(
				SELECT DISTINCT * FROM OPENJSON(@Json) WITH
				(
					PeriodID INT '$.PeriodID',
					PlatformID NVARCHAR(MAX) '$.PlatformID',
					Val NVARCHAR(MAX) '$.Value'
				) T1
				WHERE ISNUMERIC(PlatformID) = 1

			) S ON S.PeriodID = T.PeriodID AND S.PlatformID = CAST(T.PlatformID AS NVARCHAR(10))
			WHEN NOT MATCHED THEN
			  INSERT(PeriodID,PlatformID,NrOfPlates)  VALUES(S.PeriodID,CAST(S.PlatformID AS INT),CAST(S.val AS INT))
			WHEN MATCHED THEN
			  UPDATE SET T.NrOfPlates = S.val;

			-- Update remarks here
			MERGE INTO Capacity T
			USING
			(
				SELECT * FROM OPENJSON(@Json) WITH
				(
					PeriodID INT '$.PeriodID',
					PlatformID NVARCHAR(MAX) '$.PlatformID',
					Remarks NVARCHAR(MAX) '$.Value'
				) T1
				WHERE PlatformID = 'Remarks'

			) S ON S.PeriodID = T.PeriodID AND T.PlatformID = @PlatformID
			WHEN NOT MATCHED THEN			
				INSERT(PeriodID,PlatformID,NrOfPlates,Remarks)  VALUES(S.PeriodID, @PlatformID, 0, S.Remarks)
			WHEN MATCHED THEN
				UPDATE SET T.Remarks = S.Remarks;

		COMMIT;
	END TRY
	BEGIN CATCH
		ROLLBACK;
		THROW;
	END CATCH
END
GO
/****** Object:  StoredProcedure [dbo].[PR_SaveMarkerPerVarieties]    Script Date: 1/23/2020 5:39:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- PR_SaveMarkerPerVarieties N'[{"MarkerPerVarID":2,"MarkerID":6,"VarietyNr":9008,"Action":"I"}]';
-- PR_SaveMarkerPerVarieties N'[{"MarkerPerVarID":11,"MarkerID":0,"VarietyNr":0,"Action":"a"}]'
CREATE PROCEDURE [dbo].[PR_SaveMarkerPerVarieties]
(
    @DataAsJson NVARCHAR(MAX)
)AS BEGIN
    SET NOCOUNT ON;
    --duplicate validation while adding new and updating existing
    IF EXISTS
    (
	   SELECT T.MarkerID, T.VarietyNr
	   FROM OPENJSON(@DataAsJson) WITH
	   (
		  MarkerPerVarID  INT,
		  MarkerID	   INT,
		  VarietyNr	   INT,
		  [Action]	   CHAR(1)
	   ) T
	   JOIN MarkerPerVariety V ON V.MarkerID = T.MarkerID AND V.VarietyNr = T.VarietyNr
	   WHERE T.[Action] = 'I' OR (T.[Action] = 'U' AND V.MarkerPerVarID <> T.MarkerPerVarID)
    ) BEGIN
	   EXEC PR_ThrowError N'Same record already exits.';
	   RETURN;
    END
    
	MERGE INTO MarkerPerVariety T
	USING
	(
		SELECT T1.MarkerID,T1.MarkerPerVarID,T1.VarietyNr,T1.ExpectedResult,T1.Remarks,T1.[Action] FROM OPENJSON(@DataAsJson) WITH
		(
			MarkerPerVarID	INT,
			MarkerID			INT,
	   		VarietyNr		INT,
			ExpectedResult	NVARCHAR(20),
			Remarks			NVARCHAR(MAX),
			[Action]			CHAR(1)
		) T1

	) S ON T.MarkerPerVarID = S.MarkerPerVarID
	WHEN NOT MATCHED AND S.[Action] = 'I' THEN --Insert data
		INSERT (MarkerID, VarietyNr, StatusCode, ExpectedResult, Remarks)
		VALUES (S.MarkerID, S.VarietyNr, 100, S.ExpectedResult, S.Remarks)
	WHEN MATCHED THEN
		UPDATE SET
			StatusCode = (CASE 
								WHEN S.[Action] = 'A' THEN 100 
								WHEN S.[ACTION] = 'D' THEN 200
								ELSE T.StatusCode END
						),
			T.MarkerID = (CASE 
							WHEN S.[Action] = 'U' THEN S.MarkerID 
							ELSE T.MarkerID END
						),
			T.VarietyNr = (CASE 
							WHEN S.[Action] = 'U' THEN S.VarietyNr 
							ELSE T.VarietyNr END
						),
			T.ExpectedResult = (CASE 
							WHEN S.[Action] = 'U' THEN S.ExpectedResult 
							ELSE T.ExpectedResult END
						),
			T.Remarks = (CASE 
				WHEN S.[Action] = 'U' THEN S.Remarks 
				ELSE T.Remarks END
			);
END
GO
/****** Object:  StoredProcedure [dbo].[PR_SavePlanningCapacitySO_LS]    Script Date: 1/23/2020 5:39:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
Author					Date			Description
Krishna Gautam			2019-Jul-09		Service created to save capacity planning for SO for Lightscanner

===================================Example================================

DECLARE @DataAsJson NVARCHAR(MAX) = N'
[
	{
    "CropMethodID": 95,
    "PeriodID": 4778,
    "Value": 1
  },
	{
    "CropMethodID": 96,
    "PeriodID": 4778,
    "Value": 5
  }
]';
EXEC PR_SavePlanningCapacitySO_LS @DataAsJson;
*/

CREATE PROCEDURE [dbo].[PR_SavePlanningCapacitySO_LS]
(
	@Json NVARCHAR(MAX)
)
AS
BEGIN
	DECLARE @PlatformID INT;
	DECLARE @UpdateCapacity TABLE (CropMethodID INT,PeriodID INT, NrOfPlates INT);
	DECLARE @ExceededCapacityWeek TABLE (PeriodID INT,PeriodName NVARCHAR(MAX));
	DECLARE @RowCount INT;

    INSERT INTO @UpdateCapacity(CropMethodID, PeriodID, NrOfPlates)
    SELECT CropMethodID, PeriodID, NrOfPlates
    FROM OPENJSON(@Json) WITH
    (
	   CropMethodID	 INT '$.CropMethodID',
	   PeriodID	      INT '$.PeriodID',
	   NrOfPlates		 INT	'$.Value'
    ) T1;	  
    --check validation if platform used in this reserve capacity is available in Capacity table
    IF EXISTS
    (
	   SELECT 
		  UC.CropMethodID 
	   FROM @UpdateCapacity UC
	   JOIN CropMethod CM ON CM.CropMethodID = UC.CropMethodID
	   LEFT JOIN Capacity C ON C.PlatformID = CM.PlatformID AND C.PeriodID = UC.PeriodID
	   WHERE C.PlatformID IS NULL
    ) BEGIN
	   EXEC PR_ThrowError 'Insufficient capacity defined in Capacity screen.';
	   RETURN
    END    

	SET NOCOUNT ON;
	 BEGIN TRY
		BEGIN TRANSACTION;		  
		  SELECT 
			 @PlatformID = PlatformID 
		  FROM [Platform] 
		  WHERE PlatformDesc = 'Lightscanner';
		  IF(ISNULL(@platformID, 0) = 0)
		  BEGIN
			 EXEC PR_ThrowError 'Lightscanner platform does not exist.';
			 RETURN
		  END

		  MERGE INTO ReservedCapacity T
		  USING  @UpdateCapacity S ON S.CropMethodID = T.CropMethodID AND S.PeriodID = T.PeriodID
		  WHEN NOT MATCHED THEN 
			 INSERT (CropMethodID,PeriodID,NrOfPlates)				
			 VALUES (S.CropMethodID, PeriodID,S.NrOfPlates)
		  WHEN MATCHED THEN 
			 UPDATE SET NrOFPlates = S.NrOfPlates;

		  INSERT INTO @ExceededCapacityWeek(PeriodID)
		  SELECT PeriodID 
		  FROM 
		  (
			 SELECT RC.PeriodID, SUM(RC.NrOfPlates) AS ReservedCapacity, ISNULL(MAX(PC.NrOfPlates), 0) AS AvailableCapacity  
			 FROM 
			 (
				SELECT PeriodID FROM @UpdateCapacity
				GROUP BY PeriodID
			 ) UC
			 JOIN ReservedCapacity RC ON RC.PeriodID = UC.PeriodID
			 RIGHT JOIN Capacity PC ON PC.PeriodID = UC.PeriodID 
			 WHERE PC.PlatformID = @PlatformID
			 GROUP BY RC.PeriodID
		  ) T
		  WHERE T.ReservedCapacity > T.AvailableCapacity
		  
		  SELECT @RowCount = COUNT(PeriodID) FROM @ExceededCapacityWeek;

		  IF(ISNULL(@RowCount,0) > 0)
		  BEGIN
			
			 MERGE INTO @ExceededCapacityWeek S
			 USING [Period] T ON T.PeriodID = S.PeriodID
			 WHEN MATCHED THEN
				UPDATE SET S.PeriodName = T.PeriodName;

			 SELECT PeriodID,PeriodName FROM @ExceededCapacityWeek;

			 ROLLBACK;
			 RETURN;
		  END
		
		  SELECT PeriodID,PeriodName FROM @ExceededCapacityWeek;		
	COMMIT;
	END TRY
	BEGIN CATCH
		ROLLBACK;
		THROW;
	END CATCH
END

GO
/****** Object:  StoredProcedure [dbo].[PR_ThrowError]    Script Date: 1/23/2020 5:39:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[PR_ThrowError]
(
	@msg NVARCHAR(MAX)
) AS BEGIN
	RAISERROR (60000, 16, 1, @msg);
END
GO
/****** Object:  StoredProcedure [dbo].[PR_UpdateTestStatus]    Script Date: 1/23/2020 5:39:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- PR_UpdateTestStatus '11,22', 200
CREATE PROCEDURE [dbo].[PR_UpdateTestStatus]
(
	@TestIDs	NVARCHAR(100),
    @StatusCode INT
) 
AS 
BEGIN
    SET NOCOUNT ON;

    UPDATE Test
	SET StatusCode = @StatusCode
	WHERE TestID IN (SELECT [value] FROM STRING_SPLIT(@TestIDs, ','))

END
GO
/****** Object:  StoredProcedure [dbo].[PR_ValidateCapacityPerFolder]    Script Date: 1/23/2020 5:39:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
Author					Date			Description
Binod Gurung			2020-jan-23		Transcation isolation level implemented to avoid record lock
										
===================================Example================================
*/
CREATE PROCEDURE [dbo].[PR_ValidateCapacityPerFolder]
(
    @PeriodID	 INT,
    @DataAsJson NVARCHAR(MAX)
) AS BEGIN
    SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
    
    DECLARE @PlatformID INT;
    DECLARE @StartDate DATE, @EndDate DATE;
    DECLARE @DeterminationAssignment TABLE
    (
	   DetAssignmentID	    INT,
	   SampleNr		    INT,
	   PriorityCode	    INT,
	   MethodCode		    NVARCHAR(25),
	   CropCode		    NVARCHAR(10),
	   ABSCropCode		   NVARCHAR(20),
	   VarietyNr		    INT,
	   BatchNr		    INT,
	   RepeatIndicator	    BIT,
	   ProcessNr		    NVARCHAR(100),
	   ProductStatus	    NVARCHAR(100),
	   BatchOutputDesc	    NVARCHAR(250),
	   PlannedDate		   DATE,
	   UtmostInlayDate	    DATE,
	   ExpectedReadyDate   DATE,
	   UsedFor		   NVARCHAR(10)
    );
    DECLARE @Capacity TABLE
    (
	   UsedFor	    VARCHAR(5), 
	   ABSCropCode	    NVARCHAR(10), 
	   MethodCode	    NVARCHAR(50), 
	   ReservePlates   DECIMAL(5,2)
    );
    DECLARE @Groups TABLE
    (
	   ABSCropCode	    NVARCHAR(10), 
	   MethodCode	    NVARCHAR(50), 
	   UsedFor	    VARCHAR(5), 
	   ReservePlates   DECIMAL(5,2),
	   TotalPlates	DECIMAL(5,2)
    );

    SELECT 
	   @StartDate = P.StartDate,
	   @EndDate = P.EndDate
    FROM [Period] P 
    WHERE P.PeriodID = @PeriodID;

    INSERT @DeterminationAssignment
    (
	   DetAssignmentID, 
	   SampleNr, 
	   PriorityCode, 
	   MethodCode, 
	   ABSCropCode, 
	   VarietyNr, 
	   BatchNr, 
	   RepeatIndicator, 
	   ProcessNr, 
	   ProductStatus, 
	   BatchOutputDesc, 
	   PlannedDate, 
	   UtmostInlayDate, 
	   ExpectedReadyDate,
	   UsedFor
    )
    SELECT 
	   S.DetAssignmentID, 
	   S.SampleNr, 
	   S.PriorityCode, 
	   S.MethodCode, 
	   S.ABSCropCode, 
	   S.VarietyNr, 
	   S.BatchNr, 
	   S.RepeatIndicator, 
	   S.ProcessNr, 
	   S.ProductStatus, 
	   S.BatchOutputDesc, 
	   CASE WHEN CAST(S.PlannedDate AS DATE) BETWEEN @StartDate AND @EndDate THEN S.PlannedDate ELSE @EndDate END,
	   S.UtmostInlayDate, 
	   S.ExpectedReadyDate,
	   UsedFor = CASE WHEN V.HybOp = 0 AND V.[Type] = 'P' THEN 'Par' ELSE 'Hyb' END
    FROM OPENJSON(@DataAsJson) WITH
    (
	   DetAssignmentID	   INT,
	   SampleNr		   INT,
	   PriorityCode	   INT,
	   MethodCode		   NVARCHAR(25),
	   ABSCropCode		   NVARCHAR(10),
	   VarietyNr		   INT,
	   BatchNr		   INT,
	   RepeatIndicator	   BIT,
	   ProcessNr		   NVARCHAR(100),
	   ProductStatus	   NVARCHAR(100),
	   BatchOutputDesc	   NVARCHAR(250),
	   PlannedDate		   DATETIME,
	   UtmostInlayDate	   DATETIME,
	   ExpectedReadyDate   DATETIME,
	   [Action]	        CHAR(1)
    ) S
    JOIN Variety V ON V.VarietyNr = S.VarietyNr
    LEFT JOIN DeterminationAssignment DA ON DA.DetAssignmentID = S.DetAssignmentID	   
    WHERE S.[Action] = 'I'
    AND S.PriorityCode NOT IN(4, 7, 8)
    AND DA.DetAssignmentID IS NULL;

    IF @@ROWCOUNT > 0 BEGIN
	   --check validation
	   SELECT 
		  @PlatformID = PlatformID 
	   FROM [Platform] WHERE PlatformCode = 'LS'; --light scanner 

	   INSERT @Capacity(UsedFor, ABSCropCode, MethodCode, ReservePlates)
	   SELECT
		  T1.UsedFor,
		  T1.ABSCropCode,
		  T1.MethodCode,
		  NrOfPlates = SUM(T1.NrOfPlates)
	   FROM
	   (
		  SELECT 
			 V1.ABSCropCode,
			 DA.MethodCode,
			 V1.UsedFor,
			 NrOfPlates = CAST((V1.NrOfSeeds / 92.0) AS DECIMAL(5,2))
		  FROM
		  (
			 SELECT 
				ABSCropCode,
				MethodCode,
				PlannedDate
			 FROM DeterminationAssignment
			 UNION ALL
			 SELECT 
				ABSCropCode,
				MethodCode,
				PlannedDate 
			 FROM @DeterminationAssignment
		  ) DA
		  JOIN
		  (
			 SELECT 
				PM.MethodCode,
				AC.ABSCropCode,
				PM.NrOfSeeds,
				PCM.UsedFor
			 FROM Method PM
			 JOIN CropMethod PCM ON PCM.MethodID = PM.MethodID
			 JOIN ABSCrop AC ON AC.ABSCropCode = PCM.ABSCropCode
			 JOIN @DeterminationAssignment DA2 ON DA2.ABSCropCode = PCM.ABSCropCode AND DA2.MethodCode = PM.MethodCode
			 WHERE PCM.PlatformID = @PlatformID
			 AND PM.StatusCode = 100
		  ) V1 ON V1.ABSCropCode = DA.ABSCropCode AND V1.MethodCode = DA.MethodCode
		  WHERE CAST(DA.PlannedDate AS DATE) BETWEEN @StartDate AND @EndDate
	   ) T1 
	   GROUP BY T1.ABSCropCode, T1.MethodCode, T1.UsedFor;

	   INSERT INTO @Groups(ABSCropCode, MethodCode, UsedFor, TotalPlates, ReservePlates)
	   SELECT
		  V1.ABSCropCode,
		  V1.MethodCode,
		  V1.UsedFor,
		  ISNULL(V1.TotalPlates, 0),
		  ISNULL(V2.ReservePlates, 0)
	   FROM
	   (
		  SELECT 
			 PC.SlotName,
			 AC.ABSCropCode, 
			 PM.MethodCode,	
			 CM.UsedFor,
			 TotalPlates = SUM(PC.NrOfPlates)
		  FROM ReservedCapacity PC
		  JOIN CropMethod CM ON CM.CropMethodID = PC.CropMethodID
		  JOIN ABSCrop AC ON AC.ABSCropCode = CM.ABSCropCode
		  JOIN Method PM ON PM.MethodID = CM.MethodID
		  JOIN @DeterminationAssignment DA ON DA.ABSCropCode = CM.ABSCropCode AND DA.MethodCode = PM.MethodCode
		  WHERE CM.PlatformID = @PlatformID AND PC.PeriodID = @PeriodID
		  GROUP BY PC.SlotName, AC.ABSCropCode, PM.MethodCode, CM.UsedFor
	   ) V1
	   LEFT JOIN @Capacity V2 ON V2.ABSCropCode = V1.ABSCropCode AND V2.MethodCode = V1.MethodCode AND V2.UsedFor = V1.UsedFor;
		  
	   SELECT 
		  ABSCropCode, 
		  MethodCode, 
		  UsedFor,
		  ReservePlates,
		  TotalPlates
	   FROM @Groups
	   WHERE ReservePlates > TotalPlates;
    END	
END
GO
