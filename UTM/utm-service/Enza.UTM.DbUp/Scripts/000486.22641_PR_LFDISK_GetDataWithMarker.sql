DROP PROCEDURE IF EXISTS [PR_LFDISK_GetDataWithMarker]
GO

/*
Author					Date				Description
KRIAHNA GAUTAM			2021-06-11			#22641:SP created.

============Example===================
EXEC [PR_LFDISK_GetDataWithMarker] 4569, 1, 150, ''
*/
CREATE PROCEDURE [dbo].[PR_LFDISK_GetDataWithMarker]
(
    @TestID INT,
    @Page INT,
    @PageSize INT,
    @Filter NVARCHAR(MAX) = NULL
)
AS BEGIN
    SET NOCOUNT ON;

    --DECLARE @Columns NVARCHAR(MAX),@ColumnIDs NVARCHAR(MAX), @Columns2 NVARCHAR(MAX), @ColumnID2s NVARCHAR(MAX), @Columns3 NVARCHAR(MAX), @ColumnIDs4 NVARCHAR(MAX);
    DECLARE @Offset INT, @Total INT, @FileID INT, @Query NVARCHAR(MAX),@ImportLevel NVARCHAR(MAX), @CropCode NVARCHAR(MAX);	
    DECLARE @TblColumns TABLE(ColumnID INT, TraitID VARCHAR(MAX), ColumnLabel NVARCHAR(MAX), ColumnType INT, ColumnNr INT, DataType NVARCHAR(MAX), Updatable BIT, Visible BIT,DisplayColumnType NVARCHAR(MAX));
	DECLARE @DeterminationColumns NVARCHAR(MAX), @DeterminationColumnIDS NVARCHAR(MAX);

    SELECT 
		@FileID = F.FileID,
		@ImportLevel = T.ImportLevel,
		@CropCode = F.CropCode
    FROM [File] F
    JOIN Test T ON T.FileID = F.FileID 
    WHERE T.TestID = @TestID;
	
    --Determination columns
    INSERT INTO @TblColumns(ColumnID, TraitID, ColumnLabel, ColumnType, ColumnNr, DataType, Updatable,Visible,DisplayColumnType)
    SELECT DeterminationID, TraitID, ColumnLabel, 1, ROW_NUMBER() OVER(ORDER BY DeterminationID), 'BIT', 1, 1,'Checkbox'
    FROM
    (	

		SELECT 
			DeterminationID = CAST(D.DeterminationID AS NVARCHAR(MAX)),
			CONCAT('D_', D.DeterminationID) AS TraitID,
			ColumnLabel = D.DeterminationName
		FROM 
		LD_SampleTestDetermination STD 
		JOIN Determination D ON D.DeterminationID = STD.DeterminationID
		JOIN LD_SampleTest ST ON ST.SampleTestID = STD.SampleTestID
		WHERE ST.TestID = @TestID

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
						SELECT ST.SampleTestID, S.SampleName FROM LD_SampleTestDetermination STD
						JOIN LD_SampleTest ST ON ST.SampleTestID = STD.SampleTestID
						JOIN LD_Sample S ON S.SampleID  = ST.SampleID
						WHERE ST.TestID = @TestID
					';
	END	
	ELSE
	BEGIN
		SET 
			@Query = ';WITH CTE AS 
						(	
							SELECT ST.SampleTestID, S.SampleName,'+ @DeterminationColumns+' FROM LD_SampleTestDetermination STD
							JOIN LD_SampleTest ST ON ST.SampleTestID = STD.SampleTestID
							JOIN LD_Sample S ON S.SampleID  = ST.SampleID
							LEFT JOIN 
							(
								SELECT ST.SampleTestID, STD.DeterminationID FROM LD_SampleTestDetermination STD
								JOIN LD_SampleTest ST ON STD.SampleTestID = ST.SampleTestID
								WHERE ST.TestID = @TestID
								PIVOT
								(
									COUNT(DeterminationID)
									FOR DeterminationID IN ('+@DeterminationColumnIDS+')
								)
								PV

							) T1 ON T1.SampleTestID = ST.SampleTestID
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
    ORDER BY SampleName
    OFFSET @Offset ROWS
    FETCH NEXT @PageSize ROWS ONLY';

    SET @Offset = @PageSize * (@Page -1);
    EXEC sp_executesql @Query,N' @Offset INT, @PageSize INT, @TestID INT', @Offset, @PageSize, @TestID;

	--Insert other columns
	INSERT INTO @TblColumns(ColumnID,ColumnLabel,ColumnNr,ColumnType,DataType,TraitID,Updatable,Visible,DisplayColumnType)
	VALUES
	('SampleTestID','SampleTestID',1,0,'INT',NULL,0,0,'Text'),
	('SampleName','Sample Name',2,0,'Text',NULL,0,1,'Text')
    
    SELECT
		ColumnID,
		TraitID, 
		ColumnLabel, 	   
		DisplayColumnType, 
		ColumnNr = ROW_NUMBER() OVER(ORDER BY ColumnType DESC, ColumnNr),
		DataType,
		TraitID,
		Updatable,
		Visible
    FROM @TblColumns
    ORDER BY ColumnType, ColumnNr;	
END

GO
