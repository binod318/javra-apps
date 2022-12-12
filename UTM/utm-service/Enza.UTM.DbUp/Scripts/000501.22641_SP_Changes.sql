
DROP PROCEDURE IF EXISTS [dbo].[PR_LFDISK_AssignMarkers]
GO
/*
Author					Date				Description
KRIAHNA GAUTAM			2021-06-09			#22641:SP created.

====================Example======================
DECLARE @Determinations NVARCHAR(MAX) = '88221';
DECLARE @ColNames NVARCHAR(MAX) --= N'GID, plant name';
DECLARE @Filters NVARCHAR(MAX) --= '[GID] LIKE ''%2250651%'' AND [Plant name] LIKE ''%Test33360-01-01%''';
EXEC PR_LFDISK_AssignMarkers 4562, @Determinations, @ColNames, @Filters;
*/
CREATE PROCEDURE [dbo].[PR_LFDISK_AssignMarkers]
(
    @TestID		    INT,
    @Determinations	    NVARCHAR(MAX),
    @Filters		    NVARCHAR(MAX)
) AS BEGIN
    SET NOCOUNT ON;
    
    DECLARE @FileID INT;
    DECLARE @SQL NVARCHAR(MAX);
    DECLARE @ColumnIDs NVARCHAR(MAX), @ColumnNames NVARCHAR(MAX);
    DECLARE @Samples TABLE(SampleTestID INT);

    SELECT @FileID = FileID FROM Test WHERE TestID = @TestID;

      
    IF(ISNULL(@Filters, '') <> '') BEGIN
		SET @SQL = N'SELECT 
						LDST.SampleTestID 
					FROM [LD_Sample] LDS
					JOIN [LD_SampleTest] LDST ON LDST.SampleID = LDS.SampleID
					WHERE LDST.TestID = @TestID AND '+@Filters;
		
	   INSERT INTO @Samples(SampleTestID)		
	   EXEC sp_executesql @SQL, N'@TestID INT', @TestID;
    END
	--if no filter is applied then apply determination to all sample
    ELSE BEGIN
	   INSERT INTO @Samples(SampleTestID)
	   SELECT 
			LDST.SampleTestID 
		FROM [LD_Sample] LDS
		JOIN [LD_SampleTest] LDST ON LDST.SampleID = LDS.SampleID
		WHERE LDST.TestID = @TestID;
    END

    MERGE INTO LD_SampleTestDetermination T
    USING 
    ( 
	   SELECT 
		  T1.SampleTestID, 
		  D.DeterminationID
	   FROM @Samples T1 
	   CROSS APPLY 
	   (
		  SELECT 
			 DeterminationID  = [Value]
		  FROM string_split(@Determinations, ',') 
		  GROUP BY [Value]
	   ) D 		
    ) S
    ON T.SampleTestID = S.SampleTestID AND T.DeterminationID = S.DeterminationID
    WHEN NOT MATCHED THEN 
	   INSERT(SampleTestID, DeterminationID, StatusCode) 
	   VALUES(S.SampleTestID,S.DeterminationID,100);
END

GO


DROP PROCEDURE IF EXISTS [dbo].[PR_LFDISK_ManageInfo]
GO


/*
    DECLARE @DataAsJson NVARCHAR(MAX) = N'{
	"TestID":123,
	 "SampleInfo": [
	   {
		"SampleTestID": 10,
		"Key": "QRCode",
		"Value": "12",
	   }
	 ]
    }';
    EXEC PR_LFDISK_ManageInfo 4582, @DataAsJson;
*/
CREATE PROCEDURE [dbo].[PR_LFDISK_ManageInfo]
(
    @TestID	 INT,
    @DataAsJson NVARCHAR(MAX)
) AS BEGIN
    SET NOCOUNT ON;

	MERGE INTO [LD_Sample] T
	USING
	(
		SELECT 
			SampleTestID,
			[Value]
		FROM 
		OPENJSON(@DataAsJson) WITH
		(
			SampleTestID INT '$.SampleTestID',
			[Key] NVARCHAR(MAX) '$.Key',
			[Value] NVARCHAR(MAX) '$.Value'
		) T1
		JOIN SampleTest ST ON ST.SampleID = T1.SampleID
		WHERE [Key] = 'QRCode' AND ST.TestID = @TestID
	) S ON S.SampleTestID = T.SampleTestID
	WHEN MATCHED THEN
	UPDATE SET REferenceCode = [Value];


	MERGE INTO LD_SampleTestDetermination T
    USING 
    ( 
		SELECT 
			SampleTestID, 
			DeterminationID = CAST([Key] AS INT), 
			Selected =CAST([Value] AS BIT)
		FROM
		(
			SELECT 
				SampleTestID,
				[key],
				[Value]
			FROM 
			OPENJSON(@DataAsJson) WITH
			(
				SampleTestID INT '$.SampleTestID',
				[Key] NVARCHAR(MAX) '$.Key',
				[Value] NVARCHAR(MAX) '$.Value'
			) T1
	   		WHERE ISNUMERIC(ISNULL(T1.[Key],'')) = 1
		) T2
    ) S
    ON T.SampleTestID = S.SampleTestID AND T.DeterminationID = S.DeterminationID
    WHEN NOT MATCHED THEN 
	   INSERT(SampleTestID, DeterminationID, StatusCode) 
	   VALUES(S.SampleTestID,S.DeterminationID,100)
	WHEN MATCHED AND Selected = 0 THEN
		DELETE;

END
GO



DROP PROCEDURE IF EXISTS [dbo].[PR_LFDISK_GetSampleMaterial]
GO

/*
Author					Date			Description
Binod Gurung			2021/06/08		Get sample plot information for selected test
===================================Example================================
EXEC [PR_LFDISK_GetSampleMaterial] 12655,1,100,'',20
*/
CREATE PROCEDURE [dbo].[PR_LFDISK_GetSampleMaterial]
(
	@TestID INT,
	@Page INT,
	@PageSize INT,
	@FilterQuery NVARCHAR(MAX),
	@TotalPlantsInSample INT = NULL
)
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @ReCalculate BIT, @ImportLevel NVARCHAR(20), @Offset INT;
	DECLARE @ColumnTable TABLE(ColumnID NVARCHAR(MAX), Label NVARCHAR(MAX),[Order] INT, IsVisible BIT);
	DECLARE @RequiredColumns NVARCHAR(MAX), @RequiredColumns1 NVARCHAR(MAX)

	DECLARE @Query NVARCHAR(MAX);

	IF NOT EXISTS (SELECT TestID FROM Test WHERE TestID = @TestID AND TestTypeID = 9)
	BEGIN
		EXEC PR_ThrowError N'Invalid Test.';
		RETURN;
	END

	IF(ISNULL(@FilterQuery,'') <> '')
	BEGIN
		SET @FilterQuery = ' AND '+ @FilterQuery ;
	END
	ELSE
	BEGIN
		SET @FilterQuery = ''; 
	END

	SET @Offset = @PageSize * (@Page -1);

	SELECT @ReCalculate = RearrangePlateFilling, @ImportLevel = ImportLevel FROM Test WHERE TestID = @TestID

	--Automatic calculate platefilling for Selection/Crosses
	IF(@ImportLevel = 'CROSSES/SELECTION' AND ISNULL(@ReCalculate,1) = 1 )
		EXEC PR_LFDISK_Calculate_Sample_Filling @TestID, @TotalPlantsInSample;

	INSERT @ColumnTable(ColumnID, Label, [Order], IsVisible)
	VALUES  ('SampleID', 'SampleID', 0, 0),
			('SampleName', 'Sample', 1, 1);

	IF(@ImportLevel = 'PLOT')
	BEGIN
		INSERT @ColumnTable(ColumnID, Label, [Order], IsVisible)
		VALUES  
		('FEID', 'FEID', 2, 1),
		('Plot name', 'Plot name', 3, 1);
	END
	ELSE
	BEGIN
		INSERT @ColumnTable(ColumnID, Label, [Order], IsVisible)
		VALUES  
		('GID', 'GID', 2, 1),
		('Origin', 'Origin', 3, 1),
		('Female code', 'Female code', 4, 1);
		
	END

	SELECT 
		@RequiredColumns = COALESCE(@RequiredColumns + ',', '') + QUOTENAME(ColumnID),
		@RequiredColumns1 = COALESCE(@RequiredColumns1 + ',', '') + QUOTENAME(ColumnID,'''')
	FROM @ColumnTable WHERE [Order] >= 2;

	SET @Query = ';WITH CTE AS
	(

		
	SELECT 
		S.SampleID,
		S.SampleName,
		'+@RequiredColumns+'
	FROM [LD_Sample] S
	JOIN [LD_SampleTest] ST ON ST.SampleID = S.SampleID
	JOIN Test T ON T.TestID = ST.TestID
	JOIN [File] F ON F.FileID = T.FileID
	LEFT JOIN [LD_SampleTestMaterial] STM ON STM.SampleTestID = ST.SampleTestID
	LEFT JOIN [LD_MaterialPlant] MP On MP.MaterialPlantID = STM.MaterialPlantID
	LEFT JOIN [Material] M ON M.MaterialID = MP.MaterialID
	LEFT JOIN [Row] R ON R.MaterialKey = M.MaterialKey AND R.FileID = F.FileID
	LEFT JOIN
	(
		SELECT T2.MaterialKey,  '+@RequiredColumns+', T2.TestID
			FROM
			(
				SELECT 
					T.TestID,
					R.MaterialKey,
					C.ColumLabel,
					CellValue = CL.[Value]
				FROM [File] F
				JOIN [Row] R ON R.FileID = F.FileID
				JOIN [Column] C ON C.FileID = F.FileID
				JOIN Test T ON T.FileID = F.FileID
				LEFT JOIN [Cell] CL ON CL.RowID = R.RowID AND CL.ColumnID = C.ColumnID
				WHERE T.TestID = @TestID --AND C.ColumLabel IN('+@RequiredColumns1+')
			) T1
			PIVOT
			(
				Max(CellValue)
				FOR [ColumLabel] IN ('+@RequiredColumns+')
			) T2
	) T3 ON T3.MaterialKey = M.MaterialKey AND T3.TestID = ST.TestID
	WHERE ST.TestID = @TestID '+@FilterQuery+' ), Count_CTE AS (SELECT COUNT([SampleID]) AS [TotalRows] FROM CTE) 

	SELECT CTE.*, Count_CTE.[TotalRows] FROM CTE, COUNT_CTE
	ORDER BY CTE.[SampleID]
	OFFSET ' + CAST(@Offset AS NVARCHAR) + ' ROWS
	FETCH NEXT ' + CAST (@PageSize AS NVARCHAR) + ' ROWS ONLY'

	
	EXEC sp_executesql @Query, N'@TestID INT', @TestID;	

	SELECT * FROM @ColumnTable ORDER BY [Order]


END
GO


