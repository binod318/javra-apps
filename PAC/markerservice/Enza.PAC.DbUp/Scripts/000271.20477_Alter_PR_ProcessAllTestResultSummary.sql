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
	    
	DECLARE @tbl TABLE(ID INT IDENTITY(1, 1), DetAssignmentID INT, ThresholdA DECIMAL(5,2), ThresholdB DECIMAL(5,2));
	DECLARE @ThresholdA DECIMAL(5,2), @ThresholdB DECIMAL(5,2), @Crop NVARCHAR(10);

	DECLARE @Errors TABLE (DetAssignmentID INT, ErrorMessage NVARCHAR(MAX));
   
	INSERT @tbl(DetAssignmentID, ThresholdA, ThresholdB)
	SELECT 
		W.DetAssignmentID,
		MAX(ISNULL(CCPR.ThresholdA,0)),
		MAX(ISNULL(CCPR.ThresholdB,0))
	FROM TestResult TR
	JOIN Well W ON W.WellID = TR.WellID
	JOIN TestDetAssignment TDA ON TDA.DetAssignmentID = W.DetAssignmentID
	JOIN DeterminationAssignment DA ON DA.DetAssignmentID = TDA.DetAssignmentID
	JOIN ABSCrop AC ON AC.ABSCropCode = DA.ABSCropCode
	LEFT JOIN CalcCriteriaPerCrop CCPR On CCPR.CropCode = AC.CropCode
	WHERE ISNULL(W.DetAssignmentID, 0) <> 0
	AND DA.StatusCode = 500
	AND ISNULL(CCPR.CalcExternalAppl,0) = 0 --Do not trigger calculation for crop that is done from external application
	GROUP BY W.DetAssignmentID;

	DECLARE @DetAssignmentID INT, @ID INT = 1, @Count INT;
	SELECT @Count = COUNT(ID) FROM @tbl;
	WHILE(@ID <= @Count) BEGIN
			
		SELECT 
			@DetAssignmentID = DetAssignmentID,
			@ThresholdA = ThresholdA,
			@ThresholdB = ThresholdB 
		FROM @tbl
		WHERE ID = @ID;

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

		SET @ID = @ID + 1;
	END   

	SELECT DetAssignmentID, ErrorMessage FROM @Errors;

END
GO


