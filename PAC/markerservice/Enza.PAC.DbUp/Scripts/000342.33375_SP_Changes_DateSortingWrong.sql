DROP PROCEDURE IF EXISTS [dbo].[PR_GetDeterminationAssigmentOverview]
GO


/*
Author					Date			Remarks
Binod Gurung			-				-
Krishna Gautam			2020-01-21		Where clause added.
Binod Gurung			2020-jan-23		Transcation isolation level implemented to avoid record lock
Krishna Gautam			2020-feb-28		(#11099) Pagination, sorting, filtering implemented and changed on logic to show all result without specific period (week).
Binod Gurung			2020-aug-20		Cropcode added and filter in status added
=================EXAMPLE=============

EXEC PR_GetDeterminationAssigmentOverview @PageNr=1,@PageSize=50,@HybridAsParentCrop=N'ON',@ExpectedReadyDate=N'05',@SortBy=N'ExpectedReadyDate',@SortOrder=N'asc'

EXEC PR_GetDeterminationAssigmentOverview @PageNr = 1,
				@PageSize = 10,
				@SortBy = NULL,
				@HybridAsParentCrop = 'ON',
				@SortOrder	= NULL,
				@CropCode  = NULL,
				@DetAssignmentID = NULL,
				@SampleNr = NULL,
				@BatchNr = '19',
				@Shortname	 = NULL,
				@Status	 = NULL,
				@ExpectedReadyDate= NULL,
				@Folder		 = NULL,
				@QualityClass = NULL
*/
CREATE PROCEDURE [dbo].[PR_GetDeterminationAssigmentOverview]
(
    --@PeriodID INT
	@PageNr				INT,
	@PageSize			INT,
	@HybridAsParentCrop	NVARCHAR(10),
	@SortBy				NVARCHAR(100) = NULL,
	@SortOrder			NVARCHAR(20) = NULL,
	@CropCode			NVARCHAR(10) = NULL,
	@DetAssignmentID	NVARCHAR(100) = NULL,
	@SampleNr			NVARCHAR(100) = NULL,
	@BatchNr			NVARCHAR(100) = NULL,
	@Shortname			NVARCHAR(100) = NULL,
	@Status				NVARCHAR(100) = NULL,
	@ExpectedReadyDate	NVARCHAR(100) = NULL,
	@Folder				NVARCHAR(100) = NULL,
	@QualityClass		NVARCHAR(100) = NULL,
	@Plates				NVARCHAR(MAX) = NULL
) AS BEGIN
    SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

	DECLARE @TblColumn TABLE(ColumnLabel VARCHAR(100), ColumnID VARCHAR(100),[Order] INT,IsVisible BIT)
	DECLARE @PlatformID INT = (SELECT PlatformID FROM [Platform] WHERE PlatformCode = 'LS'); --light scanner ;
	DECLARE @Query NVARCHAR(MAX), @Offset INT,@Parameters NVARCHAR(MAX);;

	SET @OffSet = @PageSize * (@pageNr -1);

	INSERT INTO @TblColumn(ColumnLabel,ColumnID,[Order],IsVisible)
	VALUES
	('Crop','CropCode',1,1),
	('Det. Ass#','DetAssignmentID',2,1),
	('Sample#','SampleNr',3,1),
	('Batch#','BatchNr',4,1),
	('Article','Shortname',5,1),
	('Status','Status',6,1),
	('Exp Ready','ExpectedReadyDate',7,1),
	('Folder#','Folder',8,1),
	('Qlty Cls','QualityClass',9,1),
	('Plates','Plates',10,1);

    IF(ISNULL(@SortBy,'') ='')
	BEGIN
		SET @SortBy = 'ExpectedReadyDate'
		SET @SortOrder = 'DESC'
	END
	IF(ISNULL(@SortOrder,'') = '')
	BEGIN
		SET @SortOrder = 'DESC'
	END

	--for sorting on date field
	IF(ISNULL(@SortBy,'') = 'ExpectedReadyDate')
	BEGIN
		SET @SortBy = 'ExpectedReadyDateForSort'
	END
	
	SET @Query = N'
	;WITH CTE AS
	(
		SELECT 
			*
		FROM
		(
			SELECT 
			   V.CropCode,
			   DA.DetAssignmentID,
			   DA.SampleNr,   
			   DA.BatchNr,
			   V.Shortname,
			   [Status] = COALESCE(S.StatusName, CAST(DA.StatusCode AS NVARCHAR(10))),
			   ExpectedReadyDate = FORMAT(DA.ExpectedReadyDate, ''dd/MM/yyyy''), 
			   ExpectedReadyDateForSort = DA.ExpectedReadyDate,
			   V2.Folder,
			   DA.QualityClass,
			   Plates = STUFF 
			   (
				   (
					   SELECT DISTINCT '', '' + PlateName 
					   FROM Plate P 
					   JOIN Well W ON W.PlateID = P.PlateID 
					   WHERE P.TestID = T.TestID AND W.DetAssignmentID = DA.DetAssignmentID 
					   FOR  XML PATH('''')
				   ), 1, 2, ''''
			   ),
			   IsLabPriority = CAST(ISNULL(DA.IsLabPriority,0) AS INT)
			FROM DeterminationAssignment DA
			JOIN
			(
			   SELECT
				  AC.ABSCropCode,
				  PM.MethodCode,
				  CM.UsedFor
			   FROM CropMethod CM
			   JOIN ABSCrop AC ON AC.ABSCropCode = CM.ABSCropCode
			   JOIN Method PM ON PM.MethodID = CM.MethodID
			   WHERE CM.PlatformID = @PlatformID
			) V1 ON V1.ABSCropCode = DA.ABSCropCode AND V1.MethodCode = DA.MethodCode
			JOIN
			(
				SELECT 
					VarietyNr, 
					Shortname,
					CropCode,
					UsedFor = CASE WHEN dbo.FN_IsParent(VarietyNr, @HybridAsParentCrop) = 0 THEN ''Hyb'' ELSE ''Par'' END
				FROM Variety
			) V ON V.VarietyNr = DA.VarietyNr AND V.UsedFor = V1.UsedFor
			JOIN
			(
				SELECT W.DetAssignmentID, MAX(T.TestName) AS Folder 
				FROM Test T
				JOIN Plate P ON P.TestID = T.TestID
				JOIN Well W ON W.PlateID = P.PlateID
				--WHERE T.StatusCode >= 500
				GROUP BY W.DetAssignmentID
			) V2 On V2.DetAssignmentID = DA.DetAssignmentID
			JOIN TestDetAssignment TDA ON TDA.DetAssignmentID = DA.DetAssignmentID
			JOIN Test T ON T.TestID = TDA.TestID
			JOIN [Status] S ON S.StatusCode = DA.StatusCode AND S.StatusTable = ''DeterminationAssignment''
			WHERE DA.StatusCode IN (500,600,650)
		) T
		WHERE		
			(ISNULL(@CropCode,'''') = '''' OR CropCode like ''%''+ @CropCode +''%'') AND	
			(ISNULL(@DetAssignmentID,'''') = '''' OR DetAssignmentID like ''%''+ @DetAssignmentID +''%'') AND
			(ISNULL(@SampleNr,'''') = '''' OR SampleNr like ''%''+ @SampleNr +''%'') AND
			(ISNULL(@BatchNr,'''') = '''' OR BatchNr like ''%''+ @BatchNr +''%'') AND
			(ISNULL(@Shortname,'''') = '''' OR Shortname like ''%''+ @Shortname +''%'') AND
			(ISNULL(@Status,'''') = '''' OR Status like ''%''+ @Status +''%'') AND
			(ISNULL(@ExpectedReadyDate,'''') = '''' OR ExpectedReadyDate like ''%''+ @ExpectedReadyDate +''%'') AND
			(ISNULL(@Folder,'''') = '''' OR Folder like ''%''+ @Folder +''%'') AND
			(ISNULL(@QualityClass,'''') = '''' OR QualityClass like ''%''+ @QualityClass +''%'')
	), Count_CTE AS (SELECT COUNT(DetAssignmentID) AS [TotalRows] FROM CTE)
	SELECT 
		CropCode,
		DetAssignmentID,
		SampleNr,
		BatchNr,
		Shortname,
		[Status],
		ExpectedReadyDate,
		Folder,
		QualityClass,
		Plates,
		IsLabPriority,
		TotalRows
	FROM CTE,Count_CTE 
	ORDER BY ' + QUOTENAME(@SortBy) + ' ' + @SortOrder + N'   
	OFFSET @Offset ROWS
    FETCH NEXT @PageSize ROWS ONLY'

	SET @Parameters = N'@PlatformID INT, @PageNr INT, @PageSize INT, @HybridAsParentCrop NVARCHAR(10), @CropCode NVARCHAR(10), @DetAssignmentID NVARCHAR(100), @SampleNr NVARCHAR(100), @BatchNr NVARCHAR(100), 
	@Shortname NVARCHAR(100), @Status NVARCHAR(100), @ExpectedReadyDate NVARCHAR(100), @Folder NVARCHAR(100), @QualityClass NVARCHAR(100), @OffSet INT';

	SELECT * FROM @TblColumn ORDER BY [Order]

	 EXEC sp_executesql @Query, @Parameters,@PlatformID, @PageNr, @PageSize, @HybridAsParentCrop, @CropCode, @DetAssignmentID, @SampleNr, @BatchNr, @Shortname, @Status,
	   @ExpectedReadyDate, @Folder, @QualityClass, @OffSet;

END
GO


DROP PROCEDURE IF EXISTS [dbo].[PR_GetBatch]
GO


/*
Author					Date			Remarks
Krishna Gautam			2020/01/16		Created Stored procedure to fetch data
Krishna Gautam			2020/01/21		Status description is sent instead of status code.
Krishna Gautam			2020/01/21		Column Label change.
Binod Gurung			2020-jan-23		Transcation isolation level implemented to avoid record lock
Dibya Mani Suvedi		2020-jan-27		Changed VarietyName from VarietyNr to ShortName
Dibya Mani Suvedi		2020-Feb-25		Applied sorting and default sorting for ValidatedOn DESC
Binod Gurung			2020-aug-20		Deviation and Inbred added
Binod Gurung			2022-feb-25		Organic(BioIndicator) column added

=================EXAMPLE=============

exec PR_GetBatch @PageNr=1,@PageSize=50,@HybridAsParentCrop='ON',@CropCode=N'SP',@SortBy=N'',@SortOrder=N''
*/
CREATE PROCEDURE [dbo].[PR_GetBatch]
(
	@PageNr INT,
	@PageSize INT,
	@HybridAsParentCrop	NVARCHAR(10),
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
	@BioIndicator NVARCHAR(10) = NULL,
	@QualityClass NVARCHAR(10) = NULL,
	@Deviation NVARCHAR(100) = NULL,
	@Inbreed NVARCHAR(100) = NULL,
	@ValidatedOn VARCHAR(20) = NULL,
	@SortBy	 NVARCHAR(100) = NULL,
	@SortOrder VARCHAR(20) = NULL
)
AS
BEGIN
	SET NOCOUNT ON;
	SET DATEFORMAT DMY;

	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

	IF(ISNULL(@SortBy, '') = '') BEGIN
	   SET @SortBy = 'ValidatedOn';
	END
	IF(ISNULL(@SortOrder, '') = '') BEGIN
	   SET @SortOrder = 'DESC';
	END
	
	--for sorting on date
	IF(ISNULL(@SortBy, '') = 'ValidatedOn') BEGIN
	   SET @SortBy = 'ValidatedOnForSort';
	END

	DECLARE @Offset INT;
	DECLARE @Columns TABLE(ColumnID NVARCHAR(100), ColumnName NVARCHAR(100),IsVisible BIT, [Order] INT);
	DECLARE @SQL NVARCHAR(MAX), @Parameters NVARCHAR(MAX);

	SET @OffSet = @PageSize * (@pageNr -1);
	
	SET @SQL = N'
	DECLARE @Status TABLE(StatusCode INT, StatusName NVARCHAR(100));
	
	INSERT INTO @Status(StatusCode, StatusName)
	SELECT StatusCode,StatusName FROM [Status] WHERE StatusTable = ''DeterminationAssignment'';

	WITH CTE AS 
	(
		SELECT * FROM 
		(
			SELECT T.TestID, 
				C.CropCode,
				PlatformDesc = P.PlatformCode,
				M.MethodCode, 
				Plates = CAST(CAST((M.NrOfSeeds/92.0) as decimal(4,2)) AS NVARCHAR(10)), 
				T.TestName ,
				StatusCode = S.StatusName,
				[ExpectedWeek] = CONCAT(FORMAT(DATEPART(WEEK, DA.ExpectedReadyDate), ''00''), '' ('', FORMAT(DA.ExpectedReadyDate, ''yyyy''), '')''),
				SampleNr = CAST(DA.SampleNr AS NVARCHAR(50)), 
				BatchNr = CAST(DA.BatchNr AS NVARCHAR(50)), 
				DetAssignmentID = CAST(DA.DetAssignmentID AS NVARCHAR(50)) ,
				VarietyNr = V.ShortName,
				BioIndicator = CASE WHEN ISNULL(DA.BioIndicator,0) = 0 THEN ''No'' ELSE ''Yes'' END,
				DA.QualityClass,
				DA.Deviation,
				DA.Inbreed,
				ValidatedOn = FORMAT(ValidatedOn, ''dd/MM/yyyy''),
				ValidatedOnForSort = ValidatedOn,
				IsLabPriority = CAST(ISNULL(DA.IsLabPriority,0) AS INT)
			FROM  Test T 
			JOIN TestDetAssignment TDA ON TDA.TestID = T.TestID
			JOIN DeterminationAssignment DA ON DA.DetAssignmentID = TDA.DetAssignmentID
			JOIN @Status S ON S.StatusCode = DA.StatusCode
			JOIN Method M ON M.MethodCode = DA.MethodCode
			JOIN CropMethod CM ON CM.MethodID = M.MethodID AND CM.ABSCropCode = DA.ABSCropCode
			JOIN
			(
				SELECT 
					VarietyNr, 
					Shortname,
					UsedFor = CASE WHEN dbo.FN_IsParent(VarietyNr, @HybridAsParentCrop) = 0 THEN ''Hyb'' ELSE ''Par'' END
				FROM Variety
			) V ON V.VarietyNr = DA.VarietyNr AND V.UsedFor = CM.UsedFor
			JOIN ABSCrop C ON C.ABSCropCode = CM.ABSCropCode
			JOIN [Platform] P ON P.PlatformID = CM.PlatformID
		) T
		WHERE 
		(ISNULL(@CropCode,'''') = '''' OR CropCode like ''%''+ @CropCode +''%'') AND
		(ISNULL(@PlatformDesc,'''') = '''' OR PlatformDesc like ''%''+ @PlatformDesc +''%'') AND
		(ISNULL(@MethodCode,'''') = '''' OR MethodCode like ''%''+ @MethodCode +''%'') AND
		(ISNULL(@Plates,'''') = '''' OR Plates like ''%''+ @Plates +''%'') AND
		(ISNULL(@TestName,'''') = '''' OR TestName like ''%''+ @TestName +''%'') AND
		(ISNULL(@StatusCode,'''') = '''' OR StatusCode like ''%''+ @StatusCode +''%'') AND
		(ISNULL(@ExpectedWeek,'''') = '''' OR ExpectedWeek like ''%''+ @ExpectedWeek +''%'') AND
		(ISNULL(@SampleNr,'''') = '''' OR SampleNr like ''%''+ @SampleNr +''%'') AND
		(ISNULL(@BatchNr,'''') = '''' OR BatchNr like ''%''+ @BatchNr +''%'') AND
		(ISNULL(@DetAssignmentID,'''') = '''' OR DetAssignmentID like ''%''+ @DetAssignmentID +''%'') AND
		(ISNULL(@VarietyNr,'''') = '''' OR VarietyNr like ''%''+ @VarietyNr +''%'') AND
		(ISNULL(@BioIndicator,'''') = '''' OR BioIndicator like ''%''+ @BioIndicator +''%'') AND
		(ISNULL(@QualityClass,'''') = '''' OR QualityClass like ''%''+ @QualityClass +''%'') AND
		(ISNULL(@ValidatedOn,'''') = '''' OR ValidatedOn like ''%''+ @ValidatedOn +''%'') AND
		(ISNULL(@Deviation,'''') = '''' OR Deviation like ''%''+ @Deviation +''%'') AND
		(ISNULL(@Inbreed,'''') = '''' OR Inbreed like ''%''+ @Inbreed +''%'')
	), Count_CTE AS (SELECT COUNT(TestID) AS [TotalRows] FROM CTE)
	SELECT 	
		CropCode,
		PlatformDesc,
		MethodCode, 
		Plates , 
		TestName,
		StatusCode, 
		ExpectedWeek,
		SampleNr, 
		BatchNr, 
		DetAssignmentID ,
		VarietyNr,
		BioIndicator,
		QualityClass,
		Deviation,
		Inbreed,
		ValidatedOn,
		IsLabPriority,
		TotalRows
    FROM CTE,Count_CTE 
    ORDER BY ' + QUOTENAME(@SortBy) + ' ' + @SortOrder + N'   
    OFFSET @Offset ROWS
    FETCH NEXT @PageSize ROWS ONLY';

    SET @Parameters = N'@PageNr INT, @PageSize INT, @HybridAsParentCrop NVARCHAR(10), @CropCode NVARCHAR(10), @PlatformDesc NVARCHAR(100), @MethodCode NVARCHAR(50), 
	@Plates NVARCHAR(100), @TestName NVARCHAR(100), @StatusCode NVARCHAR(100), @ExpectedWeek NVARCHAR(100), @SampleNr NVARCHAR(100), 
	@BatchNr NVARCHAR(100), @DetAssignmentID NVARCHAR(100), @VarietyNr NVARCHAR(100), @BioIndicator NVARCHAR(10), @QualityClass NVARCHAR(10), @Deviation NVARCHAR(100), @Inbreed NVARCHAR(100), @ValidatedOn NVARCHAR(20), @OffSet INT';

    EXEC sp_executesql @SQL, @Parameters, @PageNr, @PageSize, @HybridAsParentCrop, @CropCode, @PlatformDesc, @MethodCode, @Plates, @TestName,
	   @StatusCode, @ExpectedWeek, @SampleNr, @BatchNr, @DetAssignmentID, @VarietyNr, @BioIndicator, @QualityClass, @Deviation, @Inbreed, @ValidatedOn, @OffSet;

	INSERT INTO @Columns(ColumnID,ColumnName,IsVisible,[Order])
	VALUES
	('CropCode','Crop',1,1),	
	('ExpectedWeek','Exp. Wk',1,2),
	('ValidatedOn','Approved Date',1,3),
	('SampleNr','SampleNr',1,4),
	('BatchNr','BatchNr',1,5),
	('DetAssignmentID','Det. Assignment',1,6),
	('VarietyNr','Var. Name',1,7),
	('BioIndicator','Organic',1,8),
	('QualityClass','Qlty Class',1,9),
	('Deviation','Deviation',1,10),
	('Inbreed','Inbred',1,11),
	('PlatformDesc','Platform',1,12),
	('MethodCode','Method',1,13),
	('Plates','#Plates',1,14),
	('TestName','Folder',1,15),
	('StatusCode','Status',1,16)

	SELECT * FROM @Columns order by [Order];
END
GO


