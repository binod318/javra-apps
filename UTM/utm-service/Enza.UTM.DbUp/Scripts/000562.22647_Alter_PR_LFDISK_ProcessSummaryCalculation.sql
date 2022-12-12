DROP PROCEDURE IF EXISTS [dbo].[PR_LFDISK_GETOVERVIEW]
GO



/*
Author					Date				Description
KRIAHNA GAUTAM			2021-06-27			#22645:SP created.

============Example===================
EXEC PR_LFDISK_GETOVERVIEW 'ON',1,100,'',0,1
*/

CREATE PROCEDURE [dbo].[PR_LFDISK_GETOVERVIEW]
(
	
	@Crops NVARCHAR(MAX),
	@PageNumber INT,
	@pageSize INT,
	@Filter NVARCHAR(MAX),
	@ExportToExcel BIT = NULL,
	@Active	BIT  = NULL
)
AS
BEGIN
	
	DECLARE @Query NVARCHAR(MAX), @Offset INT,@CropCodes NVARCHAR(MAX), @SelectColumns NVARCHAR(MAX);
	DECLARE @TblColumn TVP_ColumnDetail;
    CREATE TABLE #Status(StatusCode INT, StatusName NVARCHAR(50));

	INSERT INTO @TblColumn(ColumnID,ColumnLabel,[Order],Visible,DataType,Editable,AllowFilter,AllowSort)
	VALUES
	('TestID','TestID',0,0,'integer',0,0,0),
	('CropCode','Crop',1,1,'string',0,1,0),
	('BreedingStationCode','Br.Station',2,1,'string',0,1,0),
	('TestName','Test Name',3,1,'string',0,1,0),
	('SiteName','Site',4,1,'string',0,1,0),
	('PlannedDate','PlannedDate',5,1,'string',0,1,0),
	('UsedSamples','Used Sample',6,1,'string',0,1,0),
	('ResultSummary','Test Result',7,1,'string',0,1,0),
	('StatusName','Status',8,1,'string',0,1,0),
	('StatusCode','StatusCode',9,0,'string',0,1,0)

	IF(ISNULL(@ExportToExcel,0) = 0)
	BEGIN
		SELECT 
			@SelectColumns = COALESCE(@SelectColumns + ',','') + QUOTENAME(ColumnID) 
		FROM @TblColumn;
	END
	ELSE
	BEGIN
		SELECT 
			@SelectColumns = COALESCE(@SelectColumns + ',','') + QUOTENAME(ColumnID) +' AS ' + QUOTENAME(ColumnLabel)
		FROM @TblColumn
		WHERE ISNULL(Visible,0) = 1;
	END


    INSERT #Status(StatusCode, StatusName)
    SELECT StatusCode, StatusName
    FROM [Status]
    WHERE StatusTable = 'Test';
    IF(@Active IS NOT NULL AND @Active = 0) BEGIN
	   DELETE #Status WHERE StatusCode <> 700;
    END
    ELSE IF (@Active IS NOT NULL AND @Active = 1) BEGIN
	   DELETE #Status WHERE StatusCode = 700;	   
    END

    SELECT @CropCodes = COALESCE(@CropCodes + ',', '') + ''''+ T.[value] +'''' FROM 
	   string_split(@Crops,',') T

    SET @Offset = @PageSize * (@PageNumber -1);

    IF(ISNULL(@Filter,'')<> '') BEGIN
	   SET @Filter = 'WHERE '+@Filter
    END
    ELSE
	   SET @Filter = '';
	   
	SET @Query =	N';WITH CTE AS 
				(
					SELECT '+@SelectColumns+' FROM 
					(
						SELECT 
							T.TestID, 
							T.TestTypeID, 
							--Crop = F.CropCode, 
							F.CropCode,
							--[BreedingStation] = T.BreedingStationCode , 
							T.BreedingStationCode,
							--[Test] = T.TestName,
							T.TestName,
							--[Folder] = T.LabPlatePlanName, 
							T.LabPlatePlanName, 
							T.PlannedDate, 
							--[Status] = Stat.StatusName, 
							Stat.StatusName,
							T1.UsedSamples,
							ResultSummary = T.LDResultSummary,
							T.StatusCode,
							SL.SiteName
						FROM Test T
						JOIN [File] F ON F.FileID = T.FileID
						JOIN #Status Stat ON Stat.StatusCode = T.StatusCode
						JOIN SiteLocation SL ON SL.SiteID = T.SiteID
						LEFT JOIN
						(
							SELECT UsedSamples = COUNT(ST.SampleID), ST.TestID FROM  LD_Sample S
							JOIN LD_SampleTest ST ON ST.SampleID = S.SampleID
							JOIN LD_SampleTestMaterial STM ON STM.SampleTestID = ST.SampleTestID
							GROUP BY ST.TestID	--ST.SampleID												
						) T1 ON T.TestID = T1.TestID
						WHERE T.TestTypeID = 9 AND F.CropCode IN  ('+@CropCodes +') AND T.CreationDate >= DATEADD(YEAR,-1,GetDate())
					) T1 '+@Filter+'
				), COUNT_CTE AS (SELECT COUNT(CropCode) AS TotalRows FROM CTE)
				SELECT CTE.*,
				Count_CTE.[TotalRows] FROM CTE,COUNT_CTE
				ORDER BY CTE.PlannedDate DESC
				OFFSET '+CAST(@offset AS varchar(MAX))+' ROWS
				FETCH NEXT '+CAST (@pageSize AS VARCHAR(MAX))+' ROWS ONLY'

	EXEC sp_executesql @Query;

	SELECT * FROM @TblColumn ORDER BY [Order];

	DROP TABLE #Status

END
GO


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
	SELECT T1.TestID, T2.TestName, T2.LDResultSummary FROM @Tbl T1
	JOIN Test T2 ON T2.TestID = T1.TestID

END
GO


