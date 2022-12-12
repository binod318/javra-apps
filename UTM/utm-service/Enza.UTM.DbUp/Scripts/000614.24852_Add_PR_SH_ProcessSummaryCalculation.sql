DROP PROCEDURE IF EXISTS [dbo].[PR_SH_ProcessSummaryCalculation]
GO

/*
=========Changes====================
Changed By			DATE				Description
Binod Gurung		2022-02-18			Calculate summary for seedhealth

========Example=============
EXEC PR_SH_ProcessSummaryCalculation

*/

CREATE PROCEDURE [dbo].[PR_SH_ProcessSummaryCalculation]
AS 
BEGIN
    SET NOCOUNT ON;
	    
	DECLARE @Tbl TABLE(ID INT IDENTITY(1, 1), TestID INT);
	DECLARE @Scores NVARCHAR(MAX), @Result NVARCHAR(100);

	DECLARE @Errors TABLE (TestID INT, ErrorMessage NVARCHAR(MAX));
   
	INSERT @Tbl(TestID)
	SELECT TestID FROM Test
	WHERE TestTypeID = 10 AND StatusCode = 600 --seedhealth

	DECLARE @TestID INT, @ID INT = 1, @Count INT;
	SELECT @Count = COUNT(ID) FROM @Tbl;
	WHILE(@ID <= @Count) BEGIN
			
		SELECT 
			@TestID = TestID 
		FROM @Tbl
		WHERE ID = @ID;

		BEGIN TRY
		BEGIN TRANSACTION;
						
			SELECT
				@Scores=STUFF  
				(  
					 (  
						SELECT DISTINCT ', ' + ISNULL(Score,'')   
						FROM SHTestResult TR1
						JOIN LD_SampleTest ST1 ON ST1.SampleTestID = TR1.SampleTestID  
						WHERE ST1.TestID = ST2.TestID
						FOR XML PATH('')  
					 ),1,1,''  
				)  
			FROM SHTestResult TR2
			JOIN LD_SampleTest ST2 ON ST2.SampleTestID = TR2.SampleTestID
			WHERE ST2.TestID = @TestID 
			GROUP BY TestID 

			SET @Scores = LTRIM(RTRIM(@Scores));
			
			--Result is negative when all results have score negative(1)
			IF (@Scores = '1' OR @Scores = 'negative')
				SET @Result = 'negative';

			--Result is positive when 1 of the sample has result positive(3)
			ELSE IF (CHARINDEX('3',@Scores) > 0 OR CHARINDEX('positive',@Scores) > 0)
				SET @Result = 'positive';

			--Result is negative+missing when the most have a negative score and some scores are missing or have no score(4/empty/null)
			ELSE 
				SET @Result = 'negative+missing';

			--update test
			UPDATE Test
			SET LDResultSummary = @Result
			WHERE TestID = @TestID

		COMMIT;
		END TRY
		BEGIN CATCH

			--Store exceptions
			INSERT @Errors(TestID, ErrorMessage)
			SELECT @TestID, ERROR_MESSAGE(); 

			IF @@TRANCOUNT > 0
				ROLLBACK;

		END CATCH

		SET @ID = @ID + 1;
	END   

	SELECT TestID, ErrorMessage FROM @Errors;

END
GO


DROP PROCEDURE IF EXISTS [dbo].[PR_SH_GetTestToSendScore]
GO


/*
=========Changes====================
Changed By			DATE				Description

Krishna Gautam		2021-JAN-03			#24850: Get list of tests eligible to send result to Phenome for seedealth

========Example=============
EXEC PR_SH_GetTestToSendScore

*/


CREATE PROCEDURE [dbo].[PR_SH_GetTestToSendScore]
AS
BEGIN

	SELECT 
		T.TestID,
		F.CropCode, 
		T.BreedingStationCode,
		T.LabPlatePlanName, 
		T.TestName, 
		S.SiteName, 
		T.LDResultSummary 
	FROM Test T 
	JOIN [File] F ON F.FileID = T.FileID 
	LEFT JOIN SiteLocation S ON S.SiteID = T.SiteID
	WHERE T.StatusCode = 600 AND T.TestTypeID = 10 AND ISNULL(T.LDResultSummary,'') != ''  --Seedhealth

END
GO

