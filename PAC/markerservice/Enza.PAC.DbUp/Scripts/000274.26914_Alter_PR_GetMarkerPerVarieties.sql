DROP PROCEDURE IF EXISTS [dbo].[PR_GetMarkerPerVarieties]
GO


/*
Author					Date				Remarks
Binod Gurung			-					-
Krishna Gautam			2020-March-04		Columns is returned from stored procedure

=================EXAMPLE=============
PR_GetMarkerPerVarieties 1, 10, @SortBy = 'MarkerFullName', @Remarks = 'tt'

*/
CREATE PROCEDURE [dbo].[PR_GetMarkerPerVarieties]
(
	@PageNr				INT,
	@PageSize			INT,
	@SortBy				NVARCHAR(100) = NULL,
	@SortOrder			NVARCHAR(20) = NULL,
	@CropCode			NVARCHAR(10) = NULL,
	@Shortname			NVARCHAR(100) = NULL,
	@VarietyNr			NVARCHAR(100) = NULL,
	@MarkerFullName		NVARCHAR(100) = NULL,
	@ExpectedResult		NVARCHAR(100) = NULL,
	@Remarks			NVARCHAR(100) = NULL,
	@StatusName			NVARCHAR(100) = NULL
)
AS BEGIN
    SET NOCOUNT ON;

	DECLARE @TblColumn TABLE(ColumnLabel VARCHAR(100), ColumnID VARCHAR(100),[Order] INT,IsVisible BIT);
	DECLARE @Offset INT, @Query NVARCHAR(MAX), @SortQuery NVARCHAR(MAX), @Parameters NVARCHAR(MAX);

	SET @OffSet = @PageSize * (@pageNr -1);

	INSERT INTO @TblColumn(ColumnLabel,ColumnID,[Order],IsVisible)
	VALUES
	('Crop','CropCode',1,1),
	('MarkerPerVarID','MarkerPerVarID',2,0),
	('MarkerID','MarkerID',3,0),
	('Variety name','Shortname',4,1),
	('Variety number','VarietyNr',5,1),
	('Trait marker','MarkerFullName',6,1),
	('Expected result','ExpectedResult',7,1),
	('Remarks','Remarks',8,1),
	('Status','StatusName',9,1);

	IF (ISNULL(@SortBy,'') = '')
		SET @SortQuery = 'ORDER BY StatusName, MarkerFullName';
	ELSE
		SET @SortQuery = 'ORDER BY ' + QUOTENAME(@SortBy) + ' ' + ISNULL(@SortOrder,'');  

	SET @Query = N'
    ;WITH CTE AS
	(
	SELECT 
	   V.CropCode,
	   MPV.MarkerPerVarID,
	   MPV.MarkerID,
	   V.Shortname,
	   MPV.VarietyNr,
	   M.MarkerFullName,
	   MPV.ExpectedResult, 
	   MPV.Remarks,
	   S.StatusName
    FROM MarkerPerVariety MPV
    JOIN Marker M ON M.MarkerID = MPV.MarkerID
    JOIN Variety V ON V.VarietyNr = MPV.VarietyNr
    JOIN [Status] S ON S.StatusCode = MPV.StatusCode AND S.StatusTable = ''Marker''
	WHERE		
			(ISNULL(@CropCode,'''') = '''' OR V.CropCode like ''%''+ @CropCode +''%'') AND	
			(ISNULL(@Shortname,'''') = '''' OR V.Shortname like ''%''+ @Shortname +''%'') AND
			(ISNULL(@VarietyNr,'''') = '''' OR MPV.VarietyNr like ''%''+ @VarietyNr +''%'') AND
			(ISNULL(@MarkerFullName,'''') = '''' OR M.MarkerFullName like ''%''+ @MarkerFullName +''%'') AND
			(ISNULL(@ExpectedResult	,'''') = '''' OR MPV.ExpectedResult like ''%''+ @ExpectedResult	 +''%'') AND
			(ISNULL(@Remarks,'''') = '''' OR MPV.Remarks like ''%''+ @Remarks +''%'') AND
			(ISNULL(@StatusName,'''') = '''' OR S.StatusName like ''%''+ @StatusName +''%'') 
	
	), Count_CTE AS (SELECT COUNT(MarkerPerVarID) AS [TotalRows] FROM CTE)
	SELECT 
		CropCode,
		MarkerPerVarID,
		MarkerID,
		Shortname,
		VarietyNr,
		MarkerFullName,
		ExpectedResult,
		Remarks,
		StatusName,
		TotalRows
	FROM CTE,Count_CTE 
	'
	+ @SortQuery + ' 
	OFFSET @Offset ROWS
    FETCH NEXT @PageSize ROWS ONLY';

	SET @Parameters = N'@CropCode NVARCHAR(10), @Shortname NVARCHAR(10), @VarietyNr NVARCHAR(100), @MarkerFullName NVARCHAR(100), @ExpectedResult NVARCHAR(100), 
	@Remarks NVARCHAR(100), @StatusName NVARCHAR(100), @OffSet INT, @PageSize INT';

	EXEC sp_executesql @Query, @Parameters, @CropCode, @Shortname, @VarietyNr, @MarkerFullName, @ExpectedResult, @Remarks, @StatusName, @OffSet, @PageSize;

	SELECT * FROM @TblColumn order by [Order];

END
GO


