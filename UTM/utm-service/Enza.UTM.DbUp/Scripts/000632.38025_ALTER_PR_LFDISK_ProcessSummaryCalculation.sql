 /*
	Author					Date			Description
-------------------------------------------------------------------
	Binod Gurung							Stored procedure created
	Krishna Gautam			2022-05-24		#38025: Send crop code and breeding station for email sending process
-------------------------------------------------------------------
==============================Example==============================
--EXEC PR_LFDISK_ProcessSummaryCalculation
*/
 
ALTER PROCEDURE [dbo].[PR_LFDISK_ProcessSummaryCalculation]
AS 
BEGIN
    SET NOCOUNT ON;
	    
	DECLARE @Tbl TABLE(ID INT IDENTITY(1, 1), TestID INT);
	DECLARE @Scores NVARCHAR(MAX), @Result NVARCHAR(100);

	DECLARE @Errors TABLE (TestID INT, ErrorMessage NVARCHAR(MAX));
   
	INSERT @Tbl(TestID)
	SELECT TestID FROM Test
	WHERE TestTypeID = 9 AND StatusCode = 600

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
						FROM LD_TestResult TR1
						JOIN LD_SampleTest ST1 ON ST1.SampleTestID = TR1.SampleTestID  
						WHERE ST1.TestID = ST2.TestID
						FOR XML PATH('')  
					 ),1,1,''  
				)  
			FROM LD_TestResult TR2
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

	--return testinfo
	SELECT T1.TestID, T2.TestName, T2.LDResultSummary, S.SiteName, F.CropCode, T2.BreedingStationCode FROM @Tbl T1
	JOIN Test T2 ON T2.TestID = T1.TestID 
	JOIN [File] F ON F.FileID = T2.FileID
	LEFT JOIN SiteLocation S ON S.SiteID = T2.SiteID

END

