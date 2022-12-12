DROP PROCEdURE IF EXISTS PR_LFDISK_AssignMarkers
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
    @ColNames		    NVARCHAR(MAX),
    @Filters		    NVARCHAR(MAX)
) AS BEGIN
    SET NOCOUNT ON;
    
    DECLARE @FileID INT;
    DECLARE @SQL NVARCHAR(MAX);
    DECLARE @ColumnIDs NVARCHAR(MAX), @ColumnNames NVARCHAR(MAX);
    DECLARE @Samples TABLE(SampleTestID INT);

    SELECT @FileID = FileID FROM Test WHERE TestID = @TestID;

      
    IF(ISNULL(@Filters, '') <> '') BEGIN
	   SELECT 
		  @ColumnIDs = COALESCE(@ColumnIDs + ',', '') + QUOTENAME(C2.[ColumnID]),
		  @ColumnNames = COALESCE(@ColumnNames + ',', '') + QUOTENAME(C2.[ColumnID]) + ' AS ' + QUOTENAME(C2.[ColumnName])
	   FROM
	   (
		  SELECT ColumnName = RTRIM(LTRIM([Value]))
		  FROM string_split(@ColNames, ',') 
	   ) C1
	   JOIN
	   (
		  SELECT ColumnID, ColumnName = COALESCE(CAST(TraitID AS VARCHAR(10)), ColumLabel)  
		  FROM [COLUMN]
		  WHERE FileID = @FileID 
	   ) AS C2 ON C2.ColumnName = C1.ColumnName;

	   --For now only sample name is provided to assign determination

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


DROP PROCEDURE IF EXISTS PR_LFDISK_GetDeterminations
GO
/*
Author					Date				Description
KRIAHNA GAUTAM			2021-06-09			#22641:SP created.

=================Example===============
EXEC PR_LFDISK_GetDeterminations 

*/
CREATE PROCEDURE [dbo].[PR_LFDISK_GetDeterminations]
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
	WHERE TTD.TestTypeID = 9
	
END

GO