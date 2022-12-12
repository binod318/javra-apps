
DROP PROCEDURE IF EXISTS [dbo].[PR_SH_GetDeterminations]
GO


/*
Author					Date				Description
KRIAHNA GAUTAM			2021-11-16			#24838:SP created.

=================Example===============
EXEC PR_SH_GetDeterminations 'TO'

*/
CREATE PROCEDURE [dbo].[PR_SH_GetDeterminations]
(	
	@CropCode NVARCHAR(MAX)
)
AS BEGIN
	SET NOCOUNT ON;
	DECLARE @Source NVARCHAR(20);

	SELECT 
		T1.DeterminationID,
		T1.DeterminationName,
		T1.DeterminationAlias,
		ColumnLabel = T1.DeterminationName
	FROM Determination T1	
	JOIN TestTypeDetermination TTD ON TTD.DeterminationID = T1.DeterminationID
	WHERE TTD.TestTypeID = 10
	AND T1.CropCode = @CropCode;
	
END

GO


DROP PROCEDURE IF EXISTS PR_SH_AssignMarkers
GO
/*
Author					Date				Description
KRIAHNA GAUTAM			2021-11-16			#24838:SP created.

====================Example======================
DECLARE @Determinations NVARCHAR(MAX) = '88221';
DECLARE @ColNames NVARCHAR(MAX) --= N'GID, plant name';
DECLARE @Filters NVARCHAR(MAX) --= '[GID] LIKE ''%2250651%'' AND [Plant name] LIKE ''%Test33360-01-01%''';
EXEC PR_SH_AssignMarkers 4562, @Determinations, @ColNames, @Filters;
*/
CREATE PROCEDURE [dbo].[PR_SH_AssignMarkers]
(
    @TestID				INT,
    @Determinations	    NVARCHAR(MAX),
	@SelectedMaterial	NVARCHAR(MAX),
    @Filters		    NVARCHAR(MAX)
) AS BEGIN
    SET NOCOUNT ON;
    
    DECLARE @FileID INT, @StatusCode INT;
    DECLARE @SQL NVARCHAR(MAX);
    DECLARE @ColumnIDs NVARCHAR(MAX), @ColumnNames NVARCHAR(MAX);
    DECLARE @Samples TABLE(SampleTestID INT);

    SELECT @FileID = FileID, @StatusCode = StatusCode FROM Test WHERE TestID = @TestID;

	IF(ISNULL(@StatusCode,0) >=500)
	BEGIN
		EXEC PR_ThrowError 'Cannot assign merker for test which is sent to LIMS.';
		RETURN;
	END

     IF(ISNULL(@SelectedMaterial,'') <> '')
	 BEGIN
		INSERT INTO @Samples(SampleTestID)		
		SELECT [value] FROM string_split(@SelectedMaterial,',');

	 END

    ELSE IF(ISNULL(@Filters, '') <> '') BEGIN
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



DROP PROCEDURE IF EXISTS [dbo].[PR_SH_ManageInfo]
GO


/*
Author					Date				Description
KRIAHNA GAUTAM			2021-11-16			#24838:SP created.

====================Example======================
    DECLARE @DataAsJson NVARCHAR(MAX) = N'{"TestID":12675,"SampleInfo":[{"SampleTestID":512,"Key":"12132","Value":"1"}],"Action":"update","Determinations":[],"SampleIDs":[],"PageNumber":1,"PageSize":3,"TotalRows":0,"Filter":[]}';
    
	EXEC PR_SH_ManageInfo1 4582, @DataAsJson;
*/

CREATE PROCEDURE [dbo].[PR_SH_ManageInfo]
(
    @TestID	 INT,
    @DataAsJson NVARCHAR(MAX)
) AS BEGIN
    SET NOCOUNT ON;

	DECLARE @StatusCode INT;

	SELECT @StatusCode = StatusCode FROM Test WHERE TestID = @TestID;

	IF(ISNULL(@StatusCode,0) >=500)
	BEGIN
		EXEC PR_ThrowError 'Cannot Channge data for test which is sent to LIMS.';
		RETURN;
	END

	MERGE INTO [LD_Sample] T
	USING
	(
		SELECT
			SampleID,
			ReferenceCode = MAX(ReferenceCode),
			SampleName = MAX(SampleName)
		FROM
		(
			SELECT 
				SampleID, 
				ReferenceCode = CASE WHEN [Key] = 'referenceCode' THEN [Value] ELSE NULL END,
				SampleName = CASE WHEN [Key] = 'sampleName' THEN [Value] ELSE NULL END
			FROM
			(
				SELECT 
					S.SampleID,
					[Key],
					[Value]
				FROM 
				OPENJSON(@DataAsJson,'$.SampleInfo') WITH
				(
					SampleTestID INT '$.SampleTestID',
					[Key] NVARCHAR(MAX) '$.Key',
					[Value] NVARCHAR(MAX) '$.Value'
				) T1
				JOIN LD_SampleTest ST ON ST.SampleTestID = T1.SampleTestID
				JOIN LD_sample S ON ST.SampleID = S.SampleID
				WHERE [Key] IN('referenceCode','sampleName') 
				AND ST.TestID = @TestID
			) T2
		) T3
		GROUP BY SampleID
	) S ON S.SampleID = T.SampleID
	WHEN MATCHED THEN
	UPDATE SET 
		ReferenceCode = COALESCE(S.ReferenceCode, T.ReferenceCode), 
		SampleName = COALESCE(S.SampleName, T.SampleName);

	

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
			OPENJSON(@DataAsJson,'$.SampleInfo') WITH
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



DROP PROCEDURE IF EXISTS [dbo].[PR_SH_DeleteSampleTest]
GO

/*
Author					Date			Description
Krishna Gautam			2021/11/16		#24838:SP created.
===================================Example================================
EXEC PR_SH_DeleteSampleTest 12764, '654,646'
*/
CREATE PROCEDURE [dbo].[PR_SH_DeleteSampleTest]
(
	@TestID INT,
	@SelectedMaterial NVARCHAR(MAX)
)
AS
BEGIN

	DECLARE @SampleIDs TABLE(SampleID INT);
	DECLARE @StatusCode INT;

	SELECT @StatusCode = StatusCode FROM Test WHERE TestID = @TestID;

	IF(ISNULL(@StatusCode,0) >=500)
	BEGIN
		EXEC PR_ThrowError 'Cannot Channge data for test which is sent to LIMS.';
		RETURN;
	END

	DELETE ST 
	OUTPUT deleted.SampleID INTO @SampleIDs
	FROM LD_SampleTest ST
	JOIN string_split(@SelectedMaterial,',') T1 ON T1.value = ST.SampleTestID;

	DELETE S FROM LD_Sample S 
	JOIN @SampleIDs T1 ON T1.SampleID = S.SampleID
END
GO


