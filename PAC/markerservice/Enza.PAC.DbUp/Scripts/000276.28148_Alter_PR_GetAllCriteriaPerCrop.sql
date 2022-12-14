DROP PROCEDURE IF EXISTS [dbo].[PR_GETAllCriteriaPerCrop]
GO

DROP PROCEDURE IF EXISTS [dbo].[PR_GetAllCriteriaPerCrop]
GO


/*
Author					Date				Remarks
Binod Gurung			2021-10-29			Get all data for criteria per crop

=================EXAMPLE=============
EXEC PR_GetAllCriteriaPerCrop 1,20 ,@CalcExternalAppHybrid='True'

*/
CREATE PROCEDURE [dbo].[PR_GetAllCriteriaPerCrop]
(
	@PageNr					INT,
	@PageSize				INT,
	@SortBy					NVARCHAR(100) = NULL,
	@SortOrder				NVARCHAR(20) = NULL,
	@CropCode				NVARCHAR(10) = NULL,
	@ThresholdA				NVARCHAR(100) = NULL,
	@ThresholdB				NVARCHAR(100) = NULL,
	@CalcExternalAppHybrid	NVARCHAR(100) = NULL,
	@CalcExternalAppParent	NVARCHAR(100) = NULL
)
AS BEGIN
    SET NOCOUNT ON;

	DECLARE @TblColumn TABLE(ColumnLabel VARCHAR(100), ColumnID VARCHAR(100),[Order] INT,IsVisible BIT);
	DECLARE @Offset INT, @Query NVARCHAR(MAX), @SortQuery NVARCHAR(MAX), @Parameters NVARCHAR(MAX);

	SET @OffSet = @PageSize * (@pageNr -1);

	--Convert value fot BIT 
	IF (@CalcExternalAppHybrid = 'True' OR @CalcExternalAppHybrid = 'yes')
		SET @CalcExternalAppHybrid = '1';
	ELSE IF (@CalcExternalAppHybrid = 'False' OR @CalcExternalAppHybrid = 'no')
		SET @CalcExternalAppHybrid = '0';

	IF (@CalcExternalAppParent = 'True' OR @CalcExternalAppParent = 'yes')
		SET @CalcExternalAppParent = '1';
	ELSE IF (@CalcExternalAppParent = 'False' OR @CalcExternalAppParent = 'no')
		SET @CalcExternalAppParent = '0';

	INSERT INTO @TblColumn(ColumnLabel,ColumnID,[Order],IsVisible)
	VALUES
	('Crop','CropCode',1,1),
	('ThresholdA','ThresholdA',2,1),
	('ThresholdB','ThresholdB',3,1),
	('Calculate External Hybrid','CalcExternalAppHybrid',4,1),
	('Calculate External Parent','CalcExternalAppParent',5,1);

	IF (ISNULL(@SortBy,'') = '')
		SET @SortQuery = 'ORDER BY CropCode';
	ELSE
		SET @SortQuery = 'ORDER BY ' + QUOTENAME(@SortBy) + ' ' + ISNULL(@SortOrder,'');  

	SET @Query = N'
    ;WITH CTE AS
	(
		SELECT 
			CropCode,
			ThresholdA,
			ThresholdB,
			CalcExternalAppHybrid = CASE WHEN ISNULL(CalcExternalAppHybrid,''false'') = ''false'' THEN ''False'' ELSE ''True'' END,
			CalcExternalAppParent = CASE WHEN ISNULL(CalcExternalAppParent,''false'') = ''false'' THEN ''False'' ELSE ''True'' END
		FROM CalcCriteriaPerCrop
		WHERE		
				(ISNULL(@CropCode,'''') = '''' OR CropCode like ''%''+ @CropCode +''%'') AND	
				(ISNULL(@ThresholdA,'''') = '''' OR ThresholdA like ''%''+ @ThresholdA +''%'') AND
				(ISNULL(@ThresholdB,'''') = '''' OR ThresholdB like ''%''+ @ThresholdA +''%'') AND
				(ISNULL(@CalcExternalAppHybrid,'''') = '''' OR CalcExternalAppHybrid like ''%''+ @CalcExternalAppHybrid +''%'') AND
				(ISNULL(@CalcExternalAppParent,'''') = '''' OR CalcExternalAppParent like ''%''+ @CalcExternalAppParent	+''%'')
	
	), Count_CTE AS (SELECT COUNT(CropCode) AS [TotalRows] FROM CTE)
	SELECT 
		CropCode,
		ThresholdA,
		ThresholdB,
		CalcExternalAppHybrid,
		CalcExternalAppParent,
		TotalRows
	FROM CTE,Count_CTE 
	' + @SortQuery + ' 
	OFFSET @Offset ROWS
    FETCH NEXT @PageSize ROWS ONLY';

	SET @Parameters = N'@CropCode NVARCHAR(10), @ThresholdA NVARCHAR(100), @ThresholdB NVARCHAR(100), @CalcExternalAppHybrid NVARCHAR(100), @CalcExternalAppParent NVARCHAR(100), @OffSet INT, @PageSize INT';

	EXEC sp_executesql @Query, @Parameters, @CropCode, @ThresholdA, @ThresholdB, @CalcExternalAppHybrid, @CalcExternalAppParent, @OffSet, @PageSize;

	SELECT * FROM @TblColumn order by [Order];

	SELECT CropCode FROM CropRD ORDER BY CropCode;

END
GO


