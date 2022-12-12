/*
Author					Date				Description
KRIAHNA GAUTAM			2021-06-11			#22641:SP created.

============Example===================
EXEC [PR_LFDISK_GetDataWithMarker] 12694, 1, 150, 'SampleName like ''%_%'''
*/
ALTER PROCEDURE [dbo].[PR_LFDISK_GetDataWithMarker]
(
    @TestID INT,
    @Page INT,
    @PageSize INT,
    @Filter NVARCHAR(MAX) = NULL
)
AS BEGIN
    SET NOCOUNT ON;

	DECLARE @totalRowsWithoutFilter INT;

	

    --DECLARE @Columns NVARCHAR(MAX),@ColumnIDs NVARCHAR(MAX), @Columns2 NVARCHAR(MAX), @ColumnID2s NVARCHAR(MAX), @Columns3 NVARCHAR(MAX), @ColumnIDs4 NVARCHAR(MAX);
    DECLARE @Offset INT, @Total INT, @FileID INT, @Query NVARCHAR(MAX),@ImportLevel NVARCHAR(MAX), @CropCode NVARCHAR(MAX);	
    DECLARE @TblColumns TABLE(ColumnID NVARCHAR(MAX), ColumnLabel NVARCHAR(MAX), ColumnType INT, ColumnNr INT, DataType NVARCHAR(MAX), Editable BIT, Visible BIT,AllowFilter BIT);
	DECLARE @DeterminationColumns NVARCHAR(MAX), @DeterminationColumnIDS NVARCHAR(MAX);

    SELECT 
		@FileID = F.FileID,
		@ImportLevel = T.ImportLevel,
		@CropCode = F.CropCode
    FROM [File] F
    JOIN Test T ON T.FileID = F.FileID 
    WHERE T.TestID = @TestID;
	

	SELECT @totalRowsWithoutFilter = COUNT(SampleTestID) FROM LD_SampleTest WHERE TestID = @TestID;

    --Determination columns
    INSERT INTO @TblColumns(ColumnID, ColumnLabel, ColumnType, ColumnNr, DataType, Editable,Visible,AllowFilter)
    SELECT DeterminationID, ColumnLabel, 1, ROW_NUMBER() OVER(ORDER BY DeterminationID), 'boolean', 1, 1,0
    FROM
    (	

		SELECT 
			DeterminationID = CAST(D.DeterminationID AS NVARCHAR(MAX)),
			--CONCAT('D_', D.DeterminationID) AS TraitID,
			ColumnLabel = MAX(D.DeterminationName)
		FROM 
		LD_SampleTestDetermination STD 
		JOIN Determination D ON D.DeterminationID = STD.DeterminationID
		JOIN LD_SampleTest ST ON ST.SampleTestID = STD.SampleTestID		
		WHERE ST.TestID = @TestID
		GROUP BY D.DeterminationID

    ) V1;

   
	
    --get Get Determination Column
    SELECT 
	   @DeterminationColumns  = COALESCE(@DeterminationColumns + ',', '') + QUOTENAME(ColumnID),
	   @DeterminationColumnIDS  = COALESCE(@DeterminationColumnIDS + ',', '') + QUOTENAME(ColumnID)	  
    FROM @TblColumns
    WHERE ColumnType = 1
    GROUP BY ColumnID;

    --If there are no any determination assigned
	IF(ISNULL(@DeterminationColumns,'') = '')
	BEGIN
		SET 
		@Query = ';WITH CTE AS 
					(
						SELECT [Delete] = CASE WHEN ISNULL(T1.SampleTestID,0) = 0 THEN 1 ELSE 0 END, ST.SampleTestID, S.SampleName, S.ReferenceCode, Total = '+ CAST(@totalRowsWithoutFilter AS NVARCHAR(MAX))+' FROM LD_SampleTest ST
						JOIN LD_Sample S ON S.SampleID  = ST.SampleID
						LEFT JOIN
						(
								SELECT SampleTestID FROM 
								LD_SampleTestMaterial
								GROUP BY SampleTestID
						) T1 ON T1.SampleTestID = ST.SampleTestID
						WHERE ST.TestID = @TestID
					';
	END	
	ELSE
	BEGIN
		SET 
			@Query = ';WITH CTE AS 
						(	
							SELECT [Delete] = CASE WHEN (ISNULL(T1.SampleTestID,0) = 0 AND ISNULL(T2.SampleTestID,0) = 0) THEN 1 ELSE 0 END, ST.SampleTestID, S.SampleName, S.ReferenceCode, '+ @DeterminationColumns+', Total = '+ CAST(@totalRowsWithoutFilter AS NVARCHAR(MAX))+' FROM LD_SampleTest ST
							JOIN LD_Sample S ON S.SampleID  = ST.SampleID
							LEFT JOIN 
							(
								SELECT * FROM
								(
									SELECT ST.SampleTestID, STD.DeterminationID FROM LD_SampleTestDetermination STD
									JOIN LD_SampleTest ST ON STD.SampleTestID = ST.SampleTestID
									WHERE ST.TestID = @TestID
								) SRC
								PIVOT
								(
									COUNT(DeterminationID)
									FOR DeterminationID IN ('+@DeterminationColumnIDS+')
								)
								PV

							) T1 ON T1.SampleTestID = ST.SampleTestID
							LEFT JOIN
							(
								SELECT SampleTestID FROM 
								LD_SampleTestMaterial
								GROUP BY SampleTestID
							) T2 ON T2.SampleTestID = ST.SampleTestID
							WHERE ST.TestID = @TestID';
	END

    IF(ISNULL(@Filter, '') <> '') BEGIN
	   SET @Query = @Query + ' AND ' + @Filter
    END
	

    SET @Query = @Query + N'
    ), CTE_COUNT AS (SELECT COUNT([SampleTestID]) AS [TotalRows] FROM CTE)
    SELECT
		CTE.*, 
		CTE_COUNT.TotalRows
    FROM CTE, CTE_COUNT
    ORDER BY SampleTestID
    OFFSET @Offset ROWS
    FETCH NEXT @PageSize ROWS ONLY';

    SET @Offset = @PageSize * (@Page -1);
	
    EXEC sp_executesql @Query,N' @Offset INT, @PageSize INT, @TestID INT', @Offset, @PageSize, @TestID;

	
	--Insert other columns
	INSERT INTO @TblColumns(ColumnID,ColumnLabel,ColumnNr,ColumnType,DataType,Editable,Visible,AllowFilter)
	VALUES
	('SampleTestID','SampleTestID',1,0,'integer',0,0,1),
	('sampleName','Sample',2,0,'string',1,1,1),
	('referenceCode','QRCode',3,0,'string',1,1,1);
    
	DECLARE @ColumnDetail TVP_ColumnDetail;
	--This insert is done to provide same column property to UI.
	INSERT INTO @ColumnDetail(ColumnID,ColumnLabel,AllowFilter,[Order],DataType,Editable,Visible)
		SELECT
			ColumnID,
			ColumnLabel, 	   
			AllowFilter, 
			ColumnNr = ROW_NUMBER() OVER(ORDER BY ColumnType, ColumnNr),
			DataType,
			Editable,
			Visible
		FROM @TblColumns
		ORDER BY ColumnType, ColumnNr;	

	SELECT * FROM @ColumnDetail;
END

GO