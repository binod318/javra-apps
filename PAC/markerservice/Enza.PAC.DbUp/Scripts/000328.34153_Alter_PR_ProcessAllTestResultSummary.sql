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
	   OR (UsedFor = 'Op' AND (ISNULL(CC.CalcExternalAppParent,0) = 0 OR ISNULL(CC.CalcExternalAppHybrid,0) = 0))
	--If Hybrid do not trigger calculation if CalcExternalAppHybrid = 1, if Parent do not trigger calculation if CalcExternalAppParent = 1, For OP (LT)

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


