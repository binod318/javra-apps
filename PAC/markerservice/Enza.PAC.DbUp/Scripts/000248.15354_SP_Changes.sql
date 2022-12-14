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


	EXEC PR_GetDeterminationAssigmentOverview @PageNr = 1,
				@PageSize = 10,
				@SortBy = NULL,
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
	@Plates		     NVARCHAR(MAX) = NULL
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
	('Quality Class','QualityClass',9,1),
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
			   )
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
					UsedFor = CASE WHEN [Type] = ''P'' THEN ''Par'' WHEN HybOp = 1 AND [Type] <> ''P'' THEN ''Hyb'' ELSE '''' END
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
		TotalRows
	FROM CTE,Count_CTE 
	ORDER BY ' + QUOTENAME(@SortBy) + ' ' + @SortOrder + N'   
	OFFSET @Offset ROWS
    FETCH NEXT @PageSize ROWS ONLY'

	SET @Parameters = N'@PlatformID INT, @PageNr INT, @PageSize INT, @CropCode NVARCHAR(10), @DetAssignmentID NVARCHAR(100), @SampleNr NVARCHAR(100), @BatchNr NVARCHAR(100), 
	@Shortname NVARCHAR(100), @Status NVARCHAR(100), @ExpectedReadyDate NVARCHAR(100), @Folder NVARCHAR(100), @QualityClass NVARCHAR(100), @OffSet INT';

	SELECT * FROM @TblColumn ORDER BY [Order]

	 EXEC sp_executesql @Query, @Parameters,@PlatformID, @PageNr, @PageSize, @CropCode, @DetAssignmentID, @SampleNr, @BatchNr, @Shortname, @Status,
	   @ExpectedReadyDate, @Folder, @QualityClass, @OffSet;

END
GO


