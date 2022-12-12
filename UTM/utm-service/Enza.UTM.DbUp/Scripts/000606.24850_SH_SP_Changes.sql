DROP PROCEDURE IF EXISTS [dbo].[PR_LFDISK_ProcessSummaryCalculation]
GO


-- EXEC PR_LFDISK_ProcessSummaryCalculation
CREATE PROCEDURE [dbo].[PR_LFDISK_ProcessSummaryCalculation]
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
			IF (@Scores = '1')
				SET @Result = 'negative';

			--Result is positive when 1 of the sample has result positive(3)
			ELSE IF (CHARINDEX('3',@Scores) > 0)
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
	SELECT T1.TestID, T2.TestName, T2.LDResultSummary, S.SiteName FROM @Tbl T1
	JOIN Test T2 ON T2.TestID = T1.TestID 
	LEFT JOIN SiteLocation S ON S.SiteID = T2.SiteID

END
GO


DROP PROCEDURE IF EXISTS [dbo].[PR_SH_GetScore]
GO

/*
EXEC PR_SH_GetScore 14763
*/

CREATE PROCEDURE [dbo].[PR_SH_GetScore]
(
	@TestID INT
)
AS BEGIN

	DECLARE @CropCode NVARCHAR(10);
	
	SELECT @CropCode = CropCode
	FROM [File] F 
	JOIN Test T ON T.FileID = F.FileID
	WHERE T.TestID = @TestID;	

	SELECT 
		T.TestID, 
		MaterialKey, 
		RefExternal, 
		T1.ColumnLabel,
		T1.DeterminationName,
		TR.Score, 
		TR.MappingColumn,
		T.LDResultSummary
	FROM
	Test T
	JOIN TestMaterial TM ON TM.TestID = T.TestID
	JOIN MaterialLot ML ON ML.MaterialLotID = TM.MaterialID --MaterialID is MaterialLotID in TestMaterial
	JOIN LD_SampleTestMaterial STM ON STM.MaterialLotID = ML.MaterialLotID
	JOIN SHTestResult TR ON T.TestID = TM.TestID AND TR.SampleTestID = STM.SampleTestID
	LEFT JOIN
	(
		SELECT 
			T.TestID,
			T1.ColumnLabel, 
			D.DeterminationName,
			TDR.MappingCol,
			TR.SHTestResultID,
			TR.StatusCode,
			TDR.SHTraitDetResultID
		FROM 
		SHTestResult TR 
		JOIN LD_SampleTest ST ON ST.SampleTestID = TR.SampleTestID
		JOIN Test T ON T.TestID = ST.TestID
		JOIN RelationTraitDetermination RTD ON RTD.DeterminationID = TR.DeterminationID
		JOIN Determination D ON D.DeterminationID = RTD.DeterminationID
		JOIN CropTrait CT ON CT.CropTraitID = RTD.CropTraitID AND CT.CropCode = @CropCode
		JOIN Trait T1 ON T1.TraitID = CT.TraitID		
		JOIN SHTraitDetResult TDR ON 
					TDR.RelationID = RTD.RelationID
					AND T.LotSampleType LIKE '%' + TDR.SampleType +'%'
					AND ISNULL(TDR.MappingCol,'') = ISNULL(TR.MappingColumn,'')
		WHERE  T.TestID = @TestID AND TR.StatusCode IN (100,150, 200)
	) T1 ON T1.SHTestResultID = TR.SHTestResultID
	WHERE T.TestID = @TestID AND T.StatusCode = 600
	
END
GO

DROP PROCEDURE IF EXISTS [dbo].[PR_SH_GetTestToSendScore]
GO

/*
=========Changes====================
Changed By			DATE				Description

Krishna Gautam		2021-JAN-03			#24850: Created Stored Procedure	

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
	LEFT JOIN SiteLocation S ON S.SiteID = T.SiteID
	JOIN [File] F ON F.FileID = T.FileID 
	WHERE T.StatusCode = 600 AND T.TestTypeID = 10; --Seedhealth
END
GO
