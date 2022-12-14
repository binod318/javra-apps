DROP PROCEDURE IF EXISTS [dbo].[PR_GetMarkerPerVarieties]
GO


/*
Author					Date				Remarks
Binod Gurung			-					-
Krishna Gautam			2020-March-04		Columns is returned from stored procedure

=================EXAMPLE=============
PR_GetMarkerPerVarieties 1, 10, @SortBy = 'ModifiedOn', @SortOrder='DESC'

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
	@ModifiedBy			NVARCHAR(100) = NULL,
	@ModifiedOn			NVARCHAR(100) = NULL,
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
	('Modified By','ModifiedBy',8,1),
	('Modified On','ModifiedOn',9,1),
	('Remarks','Remarks',10,1),
	('Status','StatusName',11,1);
	
	IF (@SortBy = 'ModifiedOn')
		SET @SortBy = 'ModifiedOnForSort';

	IF (ISNULL(@SortBy,'') = '')
		SET @SortQuery = 'ORDER BY StatusName, MarkerFullName';
	ELSE
		SET @SortQuery = 'ORDER BY ' + QUOTENAME(@SortBy) + ' ' + ISNULL(@SortOrder,'');  


	SET @Query = N'
    ;WITH CTE AS
	(
		SELECT * FROM
		(
			SELECT 
			   V.CropCode,
			   MPV.MarkerPerVarID,
			   MPV.MarkerID,
			   V.Shortname,
			   MPV.VarietyNr,
			   M.MarkerFullName,
			   MPV.ExpectedResult, 
			   MPV.ModifiedBy, 
			   ModifiedOn = FORMAT(MPV.ModifiedOn, ''yyyy-MM-dd HH:mm:ss''), 
			   ModifiedOnForSort = MPV.ModifiedOn,
			   MPV.Remarks,
			   S.StatusName
			FROM MarkerPerVariety MPV
			JOIN Marker M ON M.MarkerID = MPV.MarkerID
			JOIN Variety V ON V.VarietyNr = MPV.VarietyNr
			JOIN [Status] S ON S.StatusCode = MPV.StatusCode AND S.StatusTable = ''Marker''
		) T
		WHERE		
			(ISNULL(@CropCode,'''') = '''' OR CropCode like ''%''+ @CropCode +''%'') AND	
			(ISNULL(@Shortname,'''') = '''' OR Shortname like ''%''+ @Shortname +''%'') AND
			(ISNULL(@VarietyNr,'''') = '''' OR VarietyNr like ''%''+ @VarietyNr +''%'') AND
			(ISNULL(@MarkerFullName,'''') = '''' OR MarkerFullName like ''%''+ @MarkerFullName +''%'') AND
			(ISNULL(@ExpectedResult	,'''') = '''' OR ExpectedResult like ''%''+ @ExpectedResult	 +''%'') AND
			(ISNULL(@ModifiedBy	,'''') = '''' OR ModifiedBy like ''%''+ @ModifiedBy	 +''%'') AND
			(ISNULL(@ModifiedOn	,'''') = '''' OR ModifiedOn like ''%''+ @ModifiedOn	 +''%'') AND
			(ISNULL(@Remarks,'''') = '''' OR Remarks like ''%''+ @Remarks +''%'') AND
			(ISNULL(@StatusName,'''') = '''' OR StatusName like ''%''+ @StatusName +''%'') 
	
	), Count_CTE AS (SELECT COUNT(MarkerPerVarID) AS [TotalRows] FROM CTE)
	SELECT 
		CropCode,
		MarkerPerVarID,
		MarkerID,
		Shortname,
		VarietyNr,
		MarkerFullName,
		ExpectedResult,
		ModifiedBy,
		ModifiedOn,
		Remarks,
		StatusName,
		TotalRows
	FROM CTE,Count_CTE 
	'
	+ @SortQuery + ' 
	OFFSET @Offset ROWS
    FETCH NEXT @PageSize ROWS ONLY';

	SET @Parameters = N'@CropCode NVARCHAR(10), @Shortname NVARCHAR(10), @VarietyNr NVARCHAR(100), @MarkerFullName NVARCHAR(100), @ExpectedResult NVARCHAR(100), 
	@ModifiedBy NVARCHAR(100), @ModifiedOn NVARCHAR(100), @Remarks NVARCHAR(100), @StatusName NVARCHAR(100), @OffSet INT, @PageSize INT';

	EXEC sp_executesql @Query, @Parameters, @CropCode, @Shortname, @VarietyNr, @MarkerFullName, @ExpectedResult, @ModifiedBy, @ModifiedOn, @Remarks, @StatusName, @OffSet, @PageSize;

	SELECT * FROM @TblColumn order by [Order];

END
GO


DROP PROCEDURE IF EXISTS [dbo].[PR_SaveMarkerPerVarieties]
GO

-- PR_SaveMarkerPerVarieties N'[{"MarkerPerVarID":2,"MarkerID":6,"VarietyNr":9008,"Action":"I"}]', 'b.gurung@enzazaden.nl';
-- PR_SaveMarkerPerVarieties N'[{"MarkerPerVarID":11,"MarkerID":0,"VarietyNr":0,"Action":"a"}]'
CREATE PROCEDURE [dbo].[PR_SaveMarkerPerVarieties]
(
    @DataAsJson NVARCHAR(MAX),
	@ModifiedBy NVARCHAR(50)
)AS BEGIN
    SET NOCOUNT ON;
    --duplicate validation while adding new and updating existing
    IF EXISTS
    (
	   SELECT T.MarkerID, T.VarietyNr
	   FROM OPENJSON(@DataAsJson) WITH
	   (
		  MarkerPerVarID  INT,
		  MarkerID	   INT,
		  VarietyNr	   INT,
		  [Action]	   CHAR(1)
	   ) T
	   JOIN MarkerPerVariety V ON V.MarkerID = T.MarkerID AND V.VarietyNr = T.VarietyNr
	   WHERE T.[Action] = 'I' OR (T.[Action] = 'U' AND V.MarkerPerVarID <> T.MarkerPerVarID)
    ) BEGIN
	   EXEC PR_ThrowError N'Same record already exits.';
	   RETURN;
    END
    
	MERGE INTO MarkerPerVariety T
	USING
	(
		SELECT T1.MarkerID,T1.MarkerPerVarID,T1.VarietyNr,T1.ExpectedResult,T1.Remarks,T1.[Action] FROM OPENJSON(@DataAsJson) WITH
		(
			MarkerPerVarID	INT,
			MarkerID			INT,
	   		VarietyNr		INT,
			ExpectedResult	NVARCHAR(20),
			Remarks			NVARCHAR(MAX),
			[Action]			CHAR(1)
		) T1

	) S ON T.MarkerPerVarID = S.MarkerPerVarID
	WHEN NOT MATCHED AND S.[Action] = 'I' THEN --Insert data
		INSERT (MarkerID, VarietyNr, StatusCode, ExpectedResult, Remarks, ModifiedBy, ModifiedOn)
		VALUES (S.MarkerID, S.VarietyNr, 100, S.ExpectedResult, S.Remarks, @ModifiedBy, GETUTCDATE())
	WHEN MATCHED THEN
		UPDATE SET
			StatusCode = (CASE 
								WHEN S.[Action] = 'A' THEN 100 
								WHEN S.[ACTION] = 'D' THEN 200
								ELSE T.StatusCode END
						),
			T.MarkerID = (CASE 
							WHEN S.[Action] = 'U' THEN S.MarkerID 
							ELSE T.MarkerID END
						),
			T.VarietyNr = (CASE 
							WHEN S.[Action] = 'U' THEN S.VarietyNr 
							ELSE T.VarietyNr END
						),
			T.ExpectedResult = (CASE 
							WHEN S.[Action] = 'U' THEN S.ExpectedResult 
							ELSE T.ExpectedResult END
						),
			T.Remarks = (CASE 
							WHEN S.[Action] = 'U' THEN S.Remarks 
							ELSE T.Remarks END
						),
			T.ModifiedBy = @ModifiedBy,
			T.ModifiedOn = GETUTCDATE();
END
GO


