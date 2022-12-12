/****** Object:  StoredProcedure [dbo].[PR_SH_SaveSampleTest]    Script Date: 11/18/2021 3:30:53 PM ******/
DROP PROCEDURE IF EXISTS [dbo].[PR_SH_SaveSampleTest]
GO
/****** Object:  StoredProcedure [dbo].[PR_SH_SaveSampleMaterial]    Script Date: 11/18/2021 3:30:53 PM ******/
DROP PROCEDURE IF EXISTS [dbo].[PR_SH_SaveSampleMaterial]
GO
/****** Object:  StoredProcedure [dbo].[PR_SH_ManageInfo]    Script Date: 11/18/2021 3:30:53 PM ******/
DROP PROCEDURE IF EXISTS [dbo].[PR_SH_ManageInfo]
GO
/****** Object:  StoredProcedure [dbo].[PR_SH_ImportMaterials]    Script Date: 11/18/2021 3:30:53 PM ******/
DROP PROCEDURE IF EXISTS [dbo].[PR_SH_ImportMaterials]
GO
/****** Object:  StoredProcedure [dbo].[PR_SH_GetSampleMaterial]    Script Date: 11/18/2021 3:30:53 PM ******/
DROP PROCEDURE IF EXISTS [dbo].[PR_SH_GetSampleMaterial]
GO
/****** Object:  StoredProcedure [dbo].[PR_SH_GetDeterminations]    Script Date: 11/18/2021 3:30:53 PM ******/
DROP PROCEDURE IF EXISTS [dbo].[PR_SH_GetDeterminations]
GO
/****** Object:  StoredProcedure [dbo].[PR_SH_GetDataWithMarker]    Script Date: 11/18/2021 3:30:53 PM ******/
DROP PROCEDURE IF EXISTS [dbo].[PR_SH_GetDataWithMarker]
GO
/****** Object:  StoredProcedure [dbo].[PR_SH_GET_Data]    Script Date: 11/18/2021 3:30:53 PM ******/
DROP PROCEDURE IF EXISTS [dbo].[PR_SH_GET_Data]
GO
/****** Object:  StoredProcedure [dbo].[PR_SH_DeleteSampleTest]    Script Date: 11/18/2021 3:30:53 PM ******/
DROP PROCEDURE IF EXISTS [dbo].[PR_SH_DeleteSampleTest]
GO
/****** Object:  StoredProcedure [dbo].[PR_SH_AssignMarkers]    Script Date: 11/18/2021 3:30:53 PM ******/
DROP PROCEDURE IF EXISTS [dbo].[PR_SH_AssignMarkers]
GO
/****** Object:  StoredProcedure [dbo].[PR_Delete_Test]    Script Date: 11/18/2021 3:30:53 PM ******/
DROP PROCEDURE IF EXISTS [dbo].[PR_Delete_Test]
GO
/****** Object:  StoredProcedure [dbo].[PR_Delete_Test]    Script Date: 11/18/2021 3:30:53 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
Author					Date				Description
Krishna Gautam								Sp Created.
KRIAHNA GAUTAM			2020-March-20		#11673: Allow lab user to delete test which have status In Lims (StatusCode = 500)

=================Example===============

EXEC PR_Delete_Test 4582
*/

CREATE PROCEDURE [dbo].[PR_Delete_Test]
(
	@TestID INT,
	@ForceDelete BIT = 0,
	@Status INT OUT,
	@PlatePlanName NVARCHAR(MAX) OUT
)
AS BEGIN
	DECLARE @FileID INT, @FileCount INT = 0;
	DECLARE @TestType NVARCHAR(50),@RequiredPlates BIT,@DeterminationRequired BIT;
	IF NOT EXISTS(SELECT TestID FROM Test WHERE TestID = @TestID) BEGIN
		EXEC PR_ThrowError 'Invalid test.';
		RETURN;
	END

	SELECT 
		@Status = ISNULL(T.StatusCode,0),
		@PlatePlanName = ISNULL(T.LabPlatePlanName,''),
		@FileID = ISNULL(T.FileID,0),
		@TestType = TT.TestTypeCode,
		@RequiredPlates = CASE WHEN ISNULL(TT.PlateTypeID,0) = 0 THEN 0 ELSE 1 END,
		@DeterminationRequired = CASE WHEN ISNULL(TT.DeterminationRequired,0) = 0 THEN 0 ELSE 1 END
	FROM Test T 
	JOIN TestType TT ON TT.TestTypeID = T.TestTypeID
	WHERE T.TestID = @TestID;

	IF(ISNULL(@ForceDelete,0) = 0 AND @Status > 400) BEGIN
		EXEC PR_ThrowError 'Cannot delete test which is sent to LIMS.';
		RETURN;
	END

	IF(ISNULL(@ForceDelete,0) = 0 AND @Status > 100 AND @TestType = 'RDT') BEGIN
		EXEC PR_ThrowError 'Cannot delete test which is sent to LIMS.';
		RETURN;
	END

	IF(ISNULL(@ForceDelete,0) = 1 AND @Status > 500) BEGIN
		EXEC PR_ThrowError 'Cannot delete test having result from LIMS';
		RETURN;
	END
	
	SET NOCOUNT ON;
	BEGIN TRY
		BEGIN TRANSACTION;
		
		IF(@TestType = 'C&T') BEGIN

			WHILE 1 =1
			BEGIN
				DELETE TOP (15000) I
				FROM CnTInfo I
				JOIN [Row] R ON R.RowID = I.RowID
				JOIN [File] F ON F.FileID = R.FileID
				JOIN Test T ON T.FileID = F.FileID
				WHERE T.TestID = @TestID;

				IF @@ROWCOUNT < 15000
				BREAK;
			END
		END
		--RDT
		IF(@TestType = 'RDT') BEGIN

			WHILE 1 =1
			BEGIN
				DELETE TOP (15000) TM
				FROM TestMaterial TM
				WHERE TM.TestID = @TestID;
				IF @@ROWCOUNT < 15000
				BREAK;
			END
		END
		
		IF(@RequiredPlates = 1)
		BEGIN
			--delete from testmaterialdeterminationwell
			DELETE TMDW
			FROM TestMaterialDeterminationWell TMDW
			JOIN Well W ON W.WellID = TMDW.WellID
			JOIN Plate P ON P.PlateID = W.PlateID
			WHERE P.TestID = @TestID;

			--delete from well
			DELETE W
			FROM Well W 
			JOIN Plate P ON P.PlateID = W.PlateID
			WHERE P.TestID = @TestID;

			--delete from Plate
			DELETE Plate WHERE TestID = @TestID;
		END
		--delete from slottest
		DELETE SlotTest WHERE TestID = @TestID;

		--delete from testmaterialdetermination
		IF(@DeterminationRequired = 1)
		BEGIN
			
			WHILE 1=1
			BEGIN
				DELETE TOP (15000) TestMaterialDetermination WHERE TestID = @TestID				
				IF @@ROWCOUNT < 15000
				BREAK;
			END

			
		END
		
		IF(@TestType = 'S2S')
		BEGIN
			--delete Donor info for S2S 
			
			WHILE 1=1
			BEGIN
				DELETE TOP (15000) SD 
				FROM Test T 
				JOIN [Row] R ON R.FileID = T.FileID
				JOIN S2SDonorInfo SD ON SD.RowID = R.RowID
				WHERE T.TestID = @TestID

				IF @@ROWCOUNT < 15000
				BREAK;
			END
			
						
			WHILE 1=1
			BEGIN
				--delete marker score
				DELETE TOP(15000) FROM S2SDonorMarkerScore WHERE TestID = @TestID

				IF @@ROWCOUNT < 15000
				BREAK;
			END

			
		END

		IF(@TestType = 'LDISK' OR @TestType = 'Seedhealth')
		BEGIN
			

			--DELETE SampleTestDetermination
			DELETE  STD FROM Test T 
			JOIN LD_SampleTest ST ON ST.TestID = T.TestID
			JOIN LD_SampleTestDetermination STD ON STD.SampleTestID = ST.SampleTestID				
			WHERE T.TestID = @TestID

				
			--DELETE sampletestmaterial
			DELETE  STM FROM Test T 
			JOIN LD_SampleTest ST ON ST.TestID = T.TestID
			JOIN LD_SampleTestMaterial STM ON STM.SampleTestID = ST.SampleTestID				
			WHERE T.TestID = @TestID

			DECLARE @Deleted TABLE(ID INT);
			--DELETE sampletest
			DELETE FROM LD_SampleTest 
			OUTPUT DELETED.SampleID INTO @Deleted
			WHERE TestID = @TestID

			--delete sample
			DELETE S FROM [LD_Sample] S
			JOIN @Deleted T ON S.SampleID = T.ID;

			--Delete materialPlant
			IF(@TestType = 'LDISK')
			BEGIN				
				DELETE MP FROM LD_MaterialPlant MP
				JOIN TestMaterial TM ON TM.TestMaterialID = MP.TestMaterialID
				WHERE TM.TestID = @TestID;
			END
			--delete testmaterial
			DELETE FROM TestMaterial WHERE TestID = @TestID;

			SELECT @FileCount = Count(TestID)  FROM Test WHERE FileID = @FileID AND testID <> @TestID;

		END
		--delete test
		DELETE Test WHERE TestID = @TestID

		--Delete file, cell, row, column if that file is not used for more than 1 tests.
		IF(ISNULl(@FileCount,0) = 0)
		BEGIN
			WHILE 1= 1 
			BEGIN
				--delete cell
				DELETE TOP (15000) C FROM Cell C 
				JOIN [Row] R ON R.RowID = C.RowID
				WHERE R.FileID = @FileID
			
				IF @@ROWCOUNT < 15000
				BREAK;
			END
			--delete column
			DELETE [Column] WHERE FileID = @FileID

			--delete row
			DELETE [Row] WHERE FileID = @FileID

			--delete file
			DELETE [File] WHERE FileID = @FileID
			END

		COMMIT;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
            ROLLBACK;
		THROW;
	END CATCH


	
END

GO
/****** Object:  StoredProcedure [dbo].[PR_SH_AssignMarkers]    Script Date: 11/18/2021 3:30:53 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
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
/****** Object:  StoredProcedure [dbo].[PR_SH_DeleteSampleTest]    Script Date: 11/18/2021 3:30:53 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
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
/****** Object:  StoredProcedure [dbo].[PR_SH_GET_Data]    Script Date: 11/18/2021 3:30:53 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


/*
Author							Date				Description
Krishna Gautam					2021/11/01			Data for first tab
=================Example===============
EXEC PR_SH_GET_Data 56,'KATHMANDU\dsuvedi', 1, 3, '[Lotnr]   LIKE  ''%9%''   and [Crop]   LIKE  ''%LT%'''
EXEC PR_SH_GET_Data 13754, 1, 100, ''
EXEC PR_SH_GET_Data 12669, 1, 100, ''
EXEC PR_SH_GET_Data 12700, 1, 100, '[Plant name]   LIKE  ''%401%'''
*/
CREATE PROCEDURE [dbo].[PR_SH_GET_Data]
(
	@TestID INT,
	@Page INT,
	@PageSize INT,
	@FilterQuery NVARCHAR(MAX) = NULL
)
AS BEGIN
	SET NOCOUNT ON;
	DECLARE @FileID INT;
	DECLARE @FilterClause NVARCHAR(MAX);
	DECLARE @Offset INT;
	DECLARE @Query NVARCHAR(MAX);
	DECLARE @Columns2 NVARCHAR(MAX)
	DECLARE @Columns NVARCHAR(MAX);	
	DECLARE @ColumnIDs NVARCHAR(MAX);
	DECLARE @Source VARCHAR(20), @PlantsColID INT, @PlantsOrder INT, @ImportLevel NVARCHAR(20);

	DECLARE @TotalRowsWithoutFilter VARCHAR(10);

	--DECLARE @ColumnTable TABLE(ColumnID NVARCHAR(MAX), TraitID INT, ColumnLabel NVARCHAR(MAX),[Order] INT, IsVisible BIT, Editable BIT, DataType NVARCHAR(MAX));
	DECLARE @ColumnTable TVP_ColumnDetail;
	

	SELECT @ImportLevel = ImportLevel FROM Test WHERE TestID = @TestID

	IF(ISNULL(@FilterQuery,'')<>'')
	BEGIN
		SET @FilterClause = ' AND '+ @FilterQuery
	END
	ELSE
	BEGIN
		SET @FilterClause = '';
	END

	SET @Offset = @PageSize * (@Page -1);

	SELECT @totalRowsWithoutFilter = CAST( COUNT(RowID) AS VARCHAR(10)) FROM [Row] R
	JOIN [File] F ON F.FileID = R.FileID
	JOIN [Test] T ON T.FileID = F.FileID
	WHERE T.TestID = @TestID;

	--get file id based on testid
	SELECT 
	   @FileID = FileID,
	   @Source = RequestingSystem
	FROM Test 
	WHERE TestID = @TestID;

	IF(ISNULL(@FileID, 0) = 0) BEGIN
		EXEC PR_ThrowError 'Invalid file or test.';
		RETURN;
	END
	
	--INSERT @ColumnTable(ColumnID, TraitID, ColumnLabel, DataType, Editable, IsVisible, [Order])
	INSERT INTO @ColumnTable(ColumnID,TraitID,ColumnLabel, DataType,Editable, Visible, [Order],AllowFilter,AllowSort,Width)
	SELECT 
	   ColumnID, 
	   TraitID,
	   ColumLabel,
	   DataType, 
	   0, 
	   1,
	   ColumnNr,
	   1,
	   0,
	   100
	FROM [Column] 
	WHERE FileID = @FileID;
	
	SELECT 
		@Columns  = COALESCE(@Columns + ',', '') +QUOTENAME(MAX(ColumnID)) +' AS ' + ISNULL(QUOTENAME(TraitID), QUOTENAME(ColumnLabel)),
		@Columns2  = COALESCE(@Columns2 + ',', '') + ISNULL(QUOTENAME(TraitID), QUOTENAME(ColumnLabel)),
		@ColumnIDs  = COALESCE(@ColumnIDs + ',', '') + QUOTENAME(MAX(ColumnID))
	FROM @ColumnTable
	GROUP BY ColumnLabel,TraitID

	IF(ISNULL(@Columns, '') = '') BEGIN
		EXEC PR_ThrowError 'At lease 1 columns should be specified';
		RETURN;
	END

	SET @Query = N' ;WITH CTE AS 
	(
		SELECT R.RowID, R.MaterialKey, MaterialID = M.MaterialLotID, R.[RowNr], Total = '''+ @TotalRowsWithoutFilter +''', ' + @Columns2 + ' 
		FROM [ROW] R 
		JOIN MaterialLot M ON M.MaterialKey = R.MaterialKey
		LEFT JOIN 
		(
			SELECT PT.[RowID], ' + @Columns + ' 
			FROM
			(
				SELECT *
				FROM 
				(
					SELECT * FROM dbo.VW_IX_Cell
					WHERE FileID = @FileID
					AND ISNULL([Value],'''')<>'''' 
				) SRC
				PIVOT
				(
					Max([Value])
					FOR [ColumnID] IN (' + @ColumnIDs + ')
				) PIV
			) AS PT 					
		) AS T1	ON R.[RowID] = T1.RowID  					
		WHERE R.FileID = @FileID ' + @FilterClause + '
	), Count_CTE AS (SELECT COUNT([RowID]) AS [TotalRows] FROM CTE) 					
	SELECT CTE.RowID, CTE.MaterialID, CTE.MaterialKey, ' 
	+ CASE WHEN @ImportLevel = 'CROSSES/SELECTION' THEN '#plants = CTE.NrOfPlants, ' ELSE '' END
	+ @Columns2 + ', Count_CTE.[TotalRows], CTE.Total FROM CTE, COUNT_CTE
	ORDER BY CTE.[RowNr]
	OFFSET ' + CAST(@Offset AS NVARCHAR) + ' ROWS
	FETCH NEXT ' + CAST (@PageSize AS NVARCHAR) + ' ROWS ONLY
	OPTION (USE HINT ( ''FORCE_LEGACY_CARDINALITY_ESTIMATION'' ))';				
	
	PRINT @Query;

	EXEC sp_executesql @Query, N'@FileID INT', @FileID;	
	
	

	SELECT 
		ColumnID,
		TraitID, 
		ColumnLabel,
		DataType = CASE WHEN DataType = 'NVARCHAR(255)' THEN 'String' ELSE DataType END,
		Editable,
		Visible,
		[Order], 
		AllowFilter,
		AllowSort,
		Width
	FROM @ColumnTable ORDER By [Order];

END

GO
/****** Object:  StoredProcedure [dbo].[PR_SH_GetDataWithMarker]    Script Date: 11/18/2021 3:30:53 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
Author					Date				Description
KRIAHNA GAUTAM			2021-11-16			#22641:SP created.

============Example===================
EXEC [PR_SH_GetDataWithMarker] 13793, 1, 150, ''
EXEC [PR_SH_GetDataWithMarker] 13793, 1, 150, 'SampleName like ''%_%'''
*/
CREATE PROCEDURE [dbo].[PR_SH_GetDataWithMarker]
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
    DECLARE @TblColumns TABLE(ColumnID NVARCHAR(MAX), ColumnLabel NVARCHAR(MAX), ColumnType INT, ColumnNr INT, DataType NVARCHAR(MAX), Editable BIT, Visible BIT,AllowFilter BIT,Width INT);
	DECLARE @DeterminationColumns NVARCHAR(MAX), @DeterminationColumnIDS NVARCHAR(MAX), @Editable BIT,  @SampleType NVARCHAR(MAX);

    SELECT 
		@FileID = F.FileID,
		@ImportLevel = T.ImportLevel,
		@CropCode = F.CropCode,
		 @SampleType = LotSampleType,
		@Editable = CASE WHEN T.StatusCode >= 500 THEN 0 ELSE 1 END
    FROM [File] F
    JOIN Test T ON T.FileID = F.FileID 
    WHERE T.TestID = @TestID;
	

	SELECT @totalRowsWithoutFilter = COUNT(SampleTestID) FROM LD_SampleTest WHERE TestID = @TestID;

    --Determination columns
    INSERT INTO @TblColumns(ColumnID, ColumnLabel, ColumnType, ColumnNr, DataType, Editable,Visible,AllowFilter,Width)
    SELECT DeterminationID, ColumnLabel, 1, ROW_NUMBER() OVER(ORDER BY DeterminationID), 'boolean', @Editable, 1,0,100
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
						SELECT 
							[Delete] = CASE 
											WHEN '+  CAST(@Editable AS NVARCHAR(MAX)) +' = 0 THEN 0
											WHEN (ISNULL(T1.SampleTestID,0) = 0 AND @SampleType = ''seedcluster'') THEN 1
											ELSE 0 
										END,
							ST.SampleTestID, 
							S.SampleName, 
							S.ReferenceCode, 
							Total = '+ CAST(@totalRowsWithoutFilter AS NVARCHAR(MAX))+' 
						FROM LD_SampleTest ST
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
							SELECT 
								[Delete] = CASE 
												WHEN '+  CAST(@Editable AS NVARCHAR(MAX)) +' = 0 THEN 0
												WHEN (ISNULL(T1.SampleTestID,0) = 0 AND @SampleType = ''seedcluster'') THEN 1 
												ELSE 0 
											END,
								ST.SampleTestID, 
								S.SampleName, 
								S.ReferenceCode, 
								'+ @DeterminationColumns+', 
								Total = '+ CAST(@totalRowsWithoutFilter AS NVARCHAR(MAX))+' 
							FROM LD_SampleTest ST
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
	
	PRINT @Query;
    EXEC sp_executesql @Query,N' @Offset INT, @PageSize INT, @TestID INT,  @SampleType NVARCHAR(MAX)', @Offset, @PageSize, @TestID, @SampleType;

	
	--Insert other columns
	INSERT INTO @TblColumns(ColumnID,ColumnLabel,ColumnNr,ColumnType,DataType,Editable,Visible,AllowFilter,Width)
	VALUES
	('SampleTestID','SampleTestID',1,0,'integer',0,0,1,10),
	('sampleName','Sample',2,0,'string',@Editable,1,1,150),
	('referenceCode','QRCode',3,0,'string',@Editable,1,1,100);
    
	DECLARE @ColumnDetail TVP_ColumnDetail;
	--This insert is done to provide same column property to UI.
	INSERT INTO @ColumnDetail(ColumnID,ColumnLabel,AllowFilter,[Order],DataType,Editable,Visible,Width)
		SELECT
			ColumnID,
			ColumnLabel, 	   
			AllowFilter, 
			ColumnNr = ROW_NUMBER() OVER(ORDER BY ColumnType, ColumnNr),
			DataType,
			Editable,
			Visible,
			Width
		FROM @TblColumns
		ORDER BY ColumnType, ColumnNr;	

	SELECT * FROM @ColumnDetail;
END
GO
/****** Object:  StoredProcedure [dbo].[PR_SH_GetDeterminations]    Script Date: 11/18/2021 3:30:53 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
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
/****** Object:  StoredProcedure [dbo].[PR_SH_GetSampleMaterial]    Script Date: 11/18/2021 3:30:53 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
Author					Date			Description
Binod Gurung			2021/06/08		Get sample plot information for selected test
===================================Example================================
EXEC [PR_SH_GetSampleMaterial] 13793,1,100,''
EXEC [PR_SH_GetSampleMaterial] 12692,1,100,'SampleName like ''%_%''',20
*/
CREATE PROCEDURE [dbo].[PR_SH_GetSampleMaterial]
(
	@TestID INT,
	@Page INT,
	@PageSize INT,
	@FilterQuery NVARCHAR(MAX)
)
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @ReCalculate BIT, @ImportLevel NVARCHAR(20), @Offset INT, @TotalRowsWithoutFilter NVARCHAR(MAX);
	DECLARE @ColumnTable TVP_ColumnDetail;
	--DECLARE @RequiredColumns NVARCHAR(MAX), @RequiredColumns1 NVARCHAR(MAX);
	DECLARE @Query NVARCHAR(MAX), @Editable BIT, @SampleType NVARCHAR(MAX);

	IF NOT EXISTS (SELECT TestID FROM Test WHERE TestID = @TestID AND TestTypeID = 10)
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

	SELECT @ReCalculate = RearrangePlateFilling, @ImportLevel = ImportLevel, @SampleType = LotSampleType, @Editable = CASE WHEN StatusCode >= 500 THEN 0 ELSE 1 END FROM Test WHERE TestID = @TestID

	
	
	--now get total rows without filter value after recalculating.
	SELECT 
		@TotalRowsWithoutFilter = CAST(COUNT(ST.SampleID) AS NVARCHAR(MAX)) 
	FROM [LD_Sample] S
	JOIN [LD_SampleTest] ST ON ST.SampleID = S.SampleID
	JOIN Test T ON T.TestID = ST.TestID
	JOIN [File] F ON F.FileID = T.FileID	
	LEFT JOIN [LD_SampleTestMaterial] STM ON STM.SampleTestID = ST.SampleTestID
	LEFT JOIN [TestMaterial] TM ON TM.MaterialID = STM.MaterialLotID AND TM.TestID = ST.TestID
	LEFT JOIN [MaterialLot] M ON M.MaterialLotID = TM.MaterialID
	
	WHERE ST.TestID = @TestID AND T.TestID = @TestID

	INSERT @ColumnTable(ColumnID, ColumnLabel, [Order], Visible,AllowFilter,DataType,Editable,Width)
	VALUES  ('SampleID', 'SampleID', 0, 0 ,0, 'integer', 0,10),			
			('SampleName', 'Sample', 1, 1, 1, 'string', 0, 150),
			('MaterialID', 'MaterialID', 2, 1 ,1, 'integer', 0,150);

	

	SET @Query = ';WITH CTE AS
	(

		
	SELECT		
		[Delete] = CASE 
					WHEN '+  CAST(@Editable AS NVARCHAR(MAX)) +' = 0 THEN 0
					WHEN (ISNULL(STM.SampleTestID,0) <> 0 AND @SampleType = ''seedcluster'') THEN 1 
					ELSE 0
				  END,
		S.SampleID,
		MaterialID = M.MaterialLotID,
		S.SampleName,		
		Total = '+@TotalRowsWithoutFilter+' 
	FROM [LD_Sample] S
	JOIN [LD_SampleTest] ST ON ST.SampleID = S.SampleID
	JOIN Test T ON T.TestID = ST.TestID
	JOIN [File] F ON F.FileID = T.FileID	
	LEFT JOIN [LD_SampleTestMaterial] STM ON STM.SampleTestID = ST.SampleTestID
	LEFT JOIN [TestMaterial] TM ON TM.MaterialID = STM.MaterialLotID AND TM.TestID = ST.TestID
	LEFT JOIN [MaterialLot] M ON M.MaterialLotID = TM.MaterialID
	
	
	
	WHERE ST.TestID = @TestID AND  T.TestID = @TestID '+@FilterQuery+' ), Count_CTE AS (SELECT COUNT([SampleID]) AS [TotalRows] FROM CTE) 

	SELECT CTE.*, Count_CTE.[TotalRows] FROM CTE, COUNT_CTE
	ORDER BY CTE.[SampleID]
	OFFSET ' + CAST(@Offset AS NVARCHAR) + ' ROWS
	FETCH NEXT ' + CAST (@PageSize AS NVARCHAR) + ' ROWS ONLY'

	
	PRINT @Query;
	EXEC sp_executesql @Query, N'@TestID INT, @SampleType NVARCHAR(MAX)', @TestID, @SampleType;	

	

	SELECT * FROM @ColumnTable ORDER BY [Order]


END
GO
/****** Object:  StoredProcedure [dbo].[PR_SH_ImportMaterials]    Script Date: 11/18/2021 3:30:53 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
=========Changes====================
Changed By			DATE				Description
Krishna Gautam		2021/11/01			#22628 : Import screen for Seed health

========Example=============

*/

CREATE PROCEDURE [dbo].[PR_SH_ImportMaterials]
(
	@TestID						INT OUTPUT,
	@CropCode					NVARCHAR(10),
	@BrStationCode				NVARCHAR(10),
	@SyncCode					NVARCHAR(10),
	@CountryCode				NVARCHAR(10),
	@UserID						NVARCHAR(100),
	--@TestProtocolID				INT,
	@TestName					NVARCHAR(200),
	@Source						NVARCHAR(50) = 'Phenome',
	@ObjectID					NVARCHAR(100),
	@ImportLevel				NVARCHAR(20),
	@TVPColumns TVP_Column		READONLY,
	@TVPRow TVP_Row				READONLY,
	@TVPCell TVP_Cell			READONLY,
	@FileID						INT,
	@PlannedDate				DATETIME,
	@MaterialTypeID				INT,
	@SiteID						INT = NULL,
	@SampleType					NVARCHAR(MAX)
)
AS BEGIN
    SET NOCOUNT ON;

    DECLARE @SQL NVARCHAR(MAX);
    --DECLARE @TblInsertedMaterial TABLE(MaterialID INT, TestID INT);
	DECLARE @TestTypeID INT = 10;

    BEGIN TRY
	   BEGIN TRANSACTION;
	   DECLARE @TblInsertedMaterial TABLE(ID INT IDENTITY(1,1), MaterialLotID INT, TestID INT);
	   DECLARE @CreatedSample TABLE (ID INT IDENTITY(1,1), SampleID INT);
	   DECLARE @CreatedSampleTest TABLE(ID INT IDENTITY(1,1), SampleTestID INT);
	   DECLARE @SampleTestID INT;

	   --import data as new test/file
	   IF(ISNULL(@FileID, 0) = 0) 
	   BEGIN

			IF EXISTS(SELECT FileTitle FROM [File] F 
				JOIN Test T ON T.FileID = F.FileID WHERE T.BreedingStationCode = @BrStationCode AND F.CropCode = @CropCode AND F.FileTitle =@TestName) 
			BEGIN
				EXEC PR_ThrowError 'File already exists.';
				RETURN;
			END

			--validation for siteID
			IF NOT EXISTS(SELECT SiteID FROM [SiteLocation] WHERE SiteID = @SiteID )
			BEGIN
				EXEC PR_ThrowError 'Invalid site location.';
				RETURN;
			END

			IF(ISNULL(@TestTypeID,0) <> 10) 
			BEGIN
				EXEC PR_ThrowError 'Invalid test type ID.';
				RETURN;
			END
		  DECLARE @RowData TABLE([RowID] int, [RowNr] int);
		  DECLARE @ColumnData TABLE([ColumnID] int,[ColumnNr] int);

		  INSERT INTO [FILE] ([CropCode],[FileTitle],[UserID],[ImportDateTime])
		  VALUES(@CropCode, @TestName, @UserID, GETUTCDATE());
		  --Get Last inserted fileid
		  SELECT @FileID = SCOPE_IDENTITY();

		  INSERT INTO [Row] ([RowNr], [MaterialKey], [FileID], NrOfSamples)
		  OUTPUT INSERTED.[RowID],INSERTED.[RowNr] INTO @RowData
		  SELECT T.RowNr,T.MaterialKey,@FileID, 1 
		  FROM @TVPRow T
		  ORDER BY T.RowNr;

		  INSERT INTO [Column] ([ColumnNr], [TraitID], [ColumLabel], [FileID], [DataType])
		  OUTPUT INSERTED.[ColumnID], INSERTED.[ColumnNr] INTO @ColumnData
		  SELECT T.[ColumnNr], T1.[TraitID], T.[ColumLabel], @FileID, T.[DataType] 
		  FROM @TVPColumns T
		  LEFT JOIN 
		  (
			 SELECT CT.TraitID,T.TraitName, T.ColumnLabel
			 FROM Trait T 
			 JOIN CropTrait CT ON CT.TraitID = T.TraitID
			 WHERE CT.CropCode = @CropCode AND T.Property = 0
		  )
		  T1 ON T1.ColumnLabel = T.ColumLabel

		  INSERT INTO [Cell] ( [RowID], [ColumnID], [Value])
		  SELECT [RowID], [ColumnID], [Value] 
		  FROM @TVPCell T1
		  JOIN @RowData T2 ON T2.RowNr = T1.RowNr
		  JOIN @ColumnData T3 ON T3.ColumnNr = T1.ColumnNr
		  WHERE ISNULL(T1.[Value],'')<>'';	

		  --CREATE TEST
		  INSERT INTO [Test]([TestTypeID],[FileID],[RequestingSystem],[RequestingUser],[TestName],[CreationDate],[StatusCode],[BreedingStationCode],
		  [SyncCode], [ImportLevel], CountryCode, TestProtocolID, PlannedDate, MaterialTypeID,SiteID, LotSampleType)
		  VALUES(@TestTypeID, @FileID, @Source, @UserID, @TestName, GETUTCDATE(), 100, @BrStationCode, 
		  @SyncCode, @ImportLevel, @CountryCode, NULL, @PlannedDate, NULL , @SiteID, @SampleType);
		  --Get Last inserted testid
		  SELECT @TestID = SCOPE_IDENTITY();

		  --CREATE Materials if not already created

		  MERGE INTO MaterialLot T 
			 USING
			 (
				    SELECT R.MaterialKey
				    FROM @TVPRow R
				    --JOIN @TVPList L ON R.GID = L.GID --AND R.EntryCode = L.EntryCode
				    GROUP BY R.MaterialKey
			 ) S	ON S.MaterialKey = T.MaterialKey
		  WHEN NOT MATCHED THEN 
				    INSERT(MaterialType, MaterialKey,CropCode,RefExternal,BreedingStationCode)
				    VALUES (@ImportLevel, S.MaterialKey, @CropCode, @ObjectID, @BrStationCode)
		 WHEN MATCHED THEN --AND ISNULL(S.MaterialKey,0) <> ISNULL(T.OriginrowID,0)
				    UPDATE  SET T.RefExternal = @ObjectID ,BreedingStationCode = @BrStationCode
		 OUTPUT INSERTED.MaterialLotID, @TestID INTO @TblInsertedMaterial(MaterialLotID, TestID);
		

		--Merge data in testmaterial table
		MERGE INTO TestMaterial T
		USING 
		(
			SELECT * FROM @TblInsertedMaterial
		) S ON S.MaterialLotID = T.MaterialID AND S.TestID = T.TestID
		WHEN NOT MATCHED THEN 
			INSERT(TestID,MaterialID)
			VALUES(@TestID,S.MaterialLotID);

		--Add material to sample based on SampleType
		IF(ISNULL(@SampleType,'') = 'fruit')
		BEGIN
			--Create sample
			INSERT INTO LD_Sample(SampleName)
			OUTPUT inserted.SampleID INTO @CreatedSample(SampleID)
			VALUES('Sample1');

			--assign sample to test
			INSERT INTO LD_SampleTest(SampleID,TestID)
			OUTPUT INSERTED.SampleTestID INTO @CreatedSampleTest(SampleTestID)
			SELECT SampleID, @TestID FROM @CreatedSample;

			SELECT @SampleTestID = SampleTestID FROM @CreatedSampleTest;

			--add material to sample
			INSERT INTO LD_SampleTestMaterial(SampleTestID, MaterialLotID)
			SELECT @SampleTestID, MaterialLotID FROM @TblInsertedMaterial;
			
			
		END
		ELSE IF (ISNULL(@SampleType,'') = 'seedsample')
		BEGIN
			--Create sample
			INSERT INTO LD_Sample(SampleName)
			OUTPUT inserted.SampleID INTO @CreatedSample(SampleID)
			SELECT SampleName = CONCAT('Sample',ID) FROM @TblInsertedMaterial;

			--Assign sample to test
			INSERT INTO LD_SampleTest(SampleID,TestID)
			OUTPUT inserted.SampleTestID INTO @CreatedSampleTest(SampleTestID)
			SELECT SampleID, @TestID FROM @CreatedSample;

			--add material to sample
			INSERT INTO LD_SampleTestMaterial(SampleTestID, MaterialLotID)
			SELECT 
				ST.SampleTestID, 
				M.MaterialLotID 
			FROM @TblInsertedMaterial M
			JOIN @CreatedSampleTest ST ON ST.ID = M.ID;

		END



		END
		--import data to existing test/file
		ELSE BEGIN
			DECLARE @importtype NVARCHAR(MAX)='';

			IF NOT EXISTS (SELECT * FROM [File] WHERE FileID = @FileID)
			BEGIN
				EXEC PR_ThrowError 'Invalid FileID.';
				RETURN;
			END
			

			--SELECT * FROM Test
			DECLARE @TempTVP_Cell TVP_Cell, @TempTVP_Column TVP_Column, @TempTVP_Row TVP_Row, @TVP_Material TVP_Material, @TVP_Well TVP_Material,
			@TVP_MaterialWithWell TVP_TMDW;
			DECLARE @LastRowNr INT =0, @LastColumnNr INT = 0,@PlatesCreated INT,@PlatesRequired INT,@WellsPerPlate INT,@LastPlateID INT,
			@PlateID INT,@TotalRows INT,@AssignedWellTypeID INT, @EmptyWellTypeID INT,@TotalMaterial INT;
			
			DECLARE @NewColumns TABLE([ColumnNr] INT,[TraitID] INT,[ColumLabel] NVARCHAR(100), [DataType] VARCHAR(15),[NewColumnNr] INT);
			DECLARE @TempRow TABLE (RowNr INT IDENTITY(1,1),MaterialKey NVARCHAR(MAX));
			DECLARE @BridgeColumnTable AS TABLE(OldColNr INT, NewColNr INT);
			DECLARE @RowData1 TABLE(RowNr INT,RowID INT,MaterialKey NVARCHAR(MAX));
			DECLARE @BridgeRowTable AS TABLE(OldRowNr INT, NewRowNr INT);
			DECLARE @StatusCode INT;
			DECLARE @CropCode1 NVARCHAR(10),@BreedingStationCode1 NVARCHAR(10),@SyncCode1 NVARCHAR(2);

			SELECT 
				@CropCode1 = F.CropCode,
				@BreedingStationCode1 = T.BreedingStationCode,
				@SyncCode1 = T.SyncCode,
				@TestTypeID = T.TestTypeID,
				@UserID = T.RequestingUser,
				@TestName = T.TestName,
				@Source = T.RequestingSystem,
				@TestID = T.TestID,
				--@TestProtocolID = T.TestProtocolID,
				@PlannedDate = T.PlannedDate,
				@MaterialTypeID = T.MaterialTypeID
			FROM [File] F
			JOIN Test T ON T.FileID = F.FileID
			WHERE F.FileID = @FileID

			SELECT @StatusCode = Statuscode FROM Test WHERE TestID = @TestID;
			IF(@StatusCode >= 200) BEGIN
				EXEC PR_ThrowError 'Cannot import material to this test after plate is requested on LIMS.';
				RETURN;
			END
	
			IF(ISNULL(@CropCode1,'') <> ISNULL(@CropCode,'')) BEGIN
				EXEC PR_ThrowError 'Cannot import material with different crop  to this test.';
				RETURN;
			END

			INSERT INTO @TempTVP_Cell(RowNr,ColumnNr,[Value])
			SELECT RowNr,ColumnNr,[Value] FROM @TVPCell

			INSERT INTO @TempTVP_Column(ColumnNr,ColumLabel,DataType,TraitID)
			SELECT ColumnNr,ColumLabel,DataType,TraitID FROM @TVPColumns;

			INSERT INTO @TempTVP_Row(RowNr,MaterialKey)
			SELECT RowNr,Materialkey FROM @TVPRow;

			--get maximum column number inserted in column table.
			SELECT @LastColumnNr = ISNULL(MAX(ColumnNr), 0)
			FROM [Column] 
			WHERE FileID = @FileID;
			
			--get maximum row number inserted on row table.
			SELECT @LastRowNr = ISNULL(MAX(RowNr),0)
			FROM [Row] R 
			WHERE FileID = @FileID;

			SET @LastRowNr = @LastRowNr + 1;
			SET @LastColumnNr = @LastColumnNr + 1;
			--get only new columns which are not imported already
			INSERT INTO @NewColumns (ColumnNr, TraitID, ColumLabel, DataType, NewColumnNr)
			 SELECT 
				    ColumnNr,
				    TraitID, 
				    ColumLabel, 
				    DataType,
				    ROW_NUMBER() OVER(ORDER BY ColumnNr) + @LastColumnNr
			 FROM @TVPColumns T1
			 WHERE NOT EXISTS
			 (
				    SELECT ColumnID 
				    FROM [Column] C 
				    WHERE C.ColumLabel = T1.ColumLabel AND C.FileID = @FileID
			 )
			 ORDER BY T1.ColumnNr;

			 --insert into new temp row table
			 INSERT INTO @TempRow(MaterialKey)
			 SELECT T1.MaterialKey FROM @TempTVP_Row T1
			 WHERE NOT EXISTS
			 (
				    SELECT R1.MaterialKey FROM [Row] R1 
				    WHERE R1.FileID = @FileID AND T1.MaterialKey = R1.MaterialKey
			 )
			 ORDER BY T1.RowNr;

			 --now insert into row table if material is not availale 
			 INSERT INTO [Row] ( [RowNr], [MaterialKey], [FileID], NrOfSamples)
			 OUTPUT INSERTED.[RowID],INSERTED.[RowNr],INSERTED.MaterialKey INTO @RowData1(RowID, RowNr, MaterialKey)
			 SELECT T.RowNr+ @LastRowNr,T.MaterialKey,@FileID, 1 FROM @TempRow T
			 ORDER BY T.RowNr;

			 --now insert new columns if available which are not already available on table
			 INSERT INTO [Column] ([ColumnNr], [TraitID], [ColumLabel], [FileID], [DataType])
			 SELECT T1.[NewColumnNr], T.[TraitID], T1.[ColumLabel], @FileID, T1.[DataType] 
			 FROM @NewColumns T1
			 LEFT JOIN 
			 (
				    SELECT CT.TraitID,T.TraitName, T.ColumnLabel
				    FROM Trait T 
				    JOIN CropTrait CT ON CT.TraitID = T.TraitID
				    WHERE CT.CropCode = @CropCode AND T.Property = 0
			 )
			 T ON T.ColumnLabel = T1.ColumLabel;

			 INSERT INTO @BridgeColumnTable(OldColNr,NewColNr)
			 SELECT T.ColumnNr,C.ColumnNr FROM 
			 [Column] C
			 JOIN @TempTVP_Column T ON T.ColumLabel = C.ColumLabel
			 WHERE C.FileID = @FileID;

			 INSERT INTO @ColumnData(ColumnID,ColumnNr)
			 SELECT ColumnID, ColumnNr FROM [Column] 
			 WHERE FileID = @FileID;

			 --update this to match previous column with new one if column order changed or new columns inserted.
			 UPDATE T1 SET 
				    T1.ColumnNr = T2.NewColNr
			 FROM @TempTVP_Cell T1
			 JOIN @BridgeColumnTable T2 ON T1.ColumnNr = T2.OldColNr;

			 --update row number if new row added which are already present for that file or completely new row are available on  SP Parameter TVP_ROw
			 INSERT INTO @BridgeRowTable(NewRowNr,OldRowNr)
			 SELECT T1.RowNr,T2.RowNr FROM @RowData1 T1
			 JOIN @TVPRow T2 ON T1.MaterialKey = T2.MaterialKey;

			 UPDATE T1 SET
				    T1.RowNr = T2.NewRowNr
			 FROM @TempTVP_Cell T1
			 JOIN @BridgeRowTable T2 ON T1.RowNr = T2.OldRowNr;

			 INSERT INTO [Cell] ( [RowID], [ColumnID], [Value])
			 SELECT T2.[RowID], T3.[ColumnID], T1.[Value] 
			 FROM @TempTVP_Cell T1
			 JOIN @RowData1 T2 ON T2.RowNr = T1.RowNr
			 JOIN @ColumnData T3 ON T3.ColumnNr = T1.ColumnNr
			 WHERE ISNULL(T1.[Value], '') <> '';

			 --Merge into material
			 MERGE INTO MaterialLot T 
				USING
				(
					SELECT R.MaterialKey
					FROM @TVPRow R
					GROUP BY R.MaterialKey
				) S	ON S.MaterialKey = T.MaterialKey
				WHEN NOT MATCHED THEN 
					INSERT(MaterialType, MaterialKey, CropCode,RefExternal, BreedingStationCode)
					VALUES (@ImportLevel, S.MaterialKey, @CropCode,@ObjectID, @BrStationCode)
				WHEN MATCHED THEN 
				    UPDATE  SET T.RefExternal = @ObjectID, BreedingStationCode= @BrStationCode
					OUTPUT INSERTED.MaterialLotID, @TestID INTO @TblInsertedMaterial(MaterialLotID, TestID);

				--Merge data in testmaterial table
				MERGE INTO TestMaterial T
				USING 
				(
					SELECT * FROM @TblInsertedMaterial
				) S ON S.MaterialLotID = T.MaterialID AND S.TestID = T.TestID
				WHEN NOT MATCHED THEN 
					INSERT(TestID,MaterialID)
					VALUES(@TestID,S.MaterialLotID);



				--need to add logic of creating sample and adding material to created sample




			END



		COMMIT;
	END TRY
	BEGIN CATCH
	   IF @@TRANCOUNT > 0 
		ROLLBACK;
	   THROW;
	END CATCH
END
GO
/****** Object:  StoredProcedure [dbo].[PR_SH_ManageInfo]    Script Date: 11/18/2021 3:30:53 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
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
/****** Object:  StoredProcedure [dbo].[PR_SH_SaveSampleMaterial]    Script Date: 11/18/2021 3:30:53 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
Author					Date			Description
Krishna Gautam			2021/11/11		Save lots to sample
===================================Example================================
EXEC [PR_SH_SaveSampleMaterial] 4556, ''
*/
CREATE PROCEDURE [dbo].[PR_SH_SaveSampleMaterial]
(
	@TestID INT,
	@Json NVARCHAR(MAX),
	@Action NVARCHAR(MAX)
)
AS
BEGIN
	
	SET NOCOUNT ON;
	DECLARE @ImportLevel NVARCHAR(20);	
	DECLARE @Material TABLE(SampleID INT, MaterialLotID INT);
	
	IF NOT EXISTS (SELECT TestID FROM Test WHERE TestID = @TestID AND TestTypeID = 10)
	BEGIN
		EXEC PR_ThrowError N'Invalid Test.';
		RETURN;
	END

	
	--ADD material to sample
	IF(ISNULL(@Action,'') = 'Add')
	BEGIN
		--Here MaterialID refers to MaterialLotID
		INSERT @Material(SampleID, MaterialLotID)
		SELECT SampleID, MaterialID
				FROM OPENJSON(@Json) WITH
				(
					SampleID	INT '$.SampleID',
					MaterialID	NVARCHAR(MAX) '$.MaterialID'
				)

		--Merge into SampleTestMaterial
		MERGE INTO LD_SampleTestMaterial T
		USING
		(
			SELECT 
				M.MaterialLotID,
				ST.SampleTestID
			FROM @Material M
			JOIN TestMaterial TM ON TM.MaterialID = M.MaterialLotID AND TM.TestID = @TestID 
			JOIN LD_SampleTest ST ON ST.SampleID = M.SampleID

		) S ON T.MaterialLotID = S.MaterialLotID AND T.SampleTestID = S.SampleTestID
		WHEN NOT MATCHED THEN
		INSERT (SampleTestID,MaterialLotID)
		VALUES(S.SampleTestID, S.MaterialLotID);
	END
	

	ELSE IF(ISNULL(@Action,'') = 'Remove')
	BEGIN
		--here sampleID is SampleTestID
		INSERT @Material(SampleID, MaterialLotID)
		SELECT SampleID, MaterialID
				FROM OPENJSON(@Json) WITH
				(
					SampleID	INT '$.SampleID',
					MaterialID	NVARCHAR(MAX) '$.MaterialID'
				)

		--delete data
		MERGE INTO LD_SampleTestMaterial T
		USING
		(
			SELECT				
				M.MaterialLotID,
				ST.SampleTestID
			FROM @Material M				
			JOIN TestMaterial TM ON TM.MaterialID = M.MaterialLotID AND TM.TestID = @TestID			
			JOIN LD_SampleTest ST ON ST.SampleID = M.SampleID


		) S ON T.MaterialLotID = S.MaterialLotID AND T.SampleTestID = S.SampleTestID
		WHEN MATCHED THEN
		DELETE;
		
	END

END
GO
/****** Object:  StoredProcedure [dbo].[PR_SH_SaveSampleTest]    Script Date: 11/18/2021 3:30:53 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
Author					Date			Description
Krishna Gautam			2021/11/11		#25025: Stored procedure created.
===================================Example================================
EXEC [PR_SH_SaveSampleTest] 12701, 'PSample',5
*/
CREATE PROCEDURE [dbo].[PR_SH_SaveSampleTest]
(
	@TestID INT,
	@SampleName NVARCHAR(150),
	@NrOfSamples INT,
	@SampleID INT = NULL
)
AS
BEGIN
	
	SET NOCOUNT ON;
	DECLARE @Sample TABLE(ID INT);
	DECLARE @ExistingSample TABLE(SampleID INT, SampleName NVARCHAR(MAX));
	DECLARE @SampleToCreate TABLE(SampleName NVARCHAR(MAX));
	DECLARE @CustName NVARCHAR(50), @Counter INT = 1, @StatusCode INT;
	DECLARE @DuplicateNameFound BIT;
	
	IF NOT EXISTS (SELECT TestID FROM Test WHERE TestID = @TestID )
	BEGIN
		EXEC PR_ThrowError N'Invalid Test.';
		RETURN;
	END

	SELECT @StatusCode = StatusCode FROM Test WHERE TestID = @TestID;

	IF(ISNULL(@StatusCode,0) >=500)
	BEGIN
		EXEC PR_ThrowError 'Cannot save sample for test which is sent to LIMS.';
		RETURN;
	END
	--get name for number of samples
	IF(ISNULL(@SampleID,0) = 0)
	BEGIN
		--get already existing samples
		INSERT INTO @ExistingSample(SampleID, SampleName)
		SELECT 
			S.SampleID,
			S.SampleName 
		FROM LD_Sample S
		JOIN LD_SampleTest ST ON S.SampleID = ST.SampleID
		WHERE ST.TestID  = @TestID

		IF(@NrOfSamples <=1)
		BEGIN
			
			SET @CustName = @SampleName;
			SELECT @DuplicateNameFound = CASE WHEN ISNULL(COUNT(SampleID),0) > 0 THEN 1 ELSE 0 END  FROM @ExistingSample WHERE SampleName = @CustName;
			WHILE(ISNULL(@DuplicateNameFound,0) <> 0)
			BEGIN
			
				IF(@NrOfSamples >=1000)
					RETURN;
				IF(@NrOfSamples >= 100)
					SET @CustName = @SampleName + '-' + RIGHT('000'+CAST(@Counter AS NVARCHAR(10)),3);
				ELSE IF(@NrOfSamples >= 10)
					SET @CustName = @SampleName + '-' + RIGHT('00'+CAST(@Counter AS NVARCHAR(10)),2);
				ELSE
					SET @CustName = @SampleName + '-' + CAST(@Counter AS NVARCHAR(10));
				--get name with counter value
				SELECT @DuplicateNameFound = CASE WHEN ISNULL(COUNT(SampleID),0) > 0 THEN 1 ELSE 0 END  FROM @ExistingSample WHERE SampleName = @CustName;
				--increase counter after that.
				SET @Counter = @Counter + 1;
			END
			INSERT INTO @SampleToCreate(SampleName)
			Values(@CustName);

		END
		--When more than 1 material required
		ELSE
		BEGIN
			--this loop is necessary for avoiding same name
			WHILE ( @Counter <= @NrOfSamples)
			BEGIN	
				SET @DuplicateNameFound = 1;
				WHILE(ISNULL(@DuplicateNameFound,0) <> 0)
				BEGIN
					IF(@Counter >=1000)
						RETURN;

					SET @CustName = @SampleName + '-' + CAST(@Counter AS NVARCHAR(10));

					--Check if same name exists if exists then increase the sample name
				
					SELECT @DuplicateNameFound = CASE WHEN ISNULL(COUNT(SampleID),0) > 0 THEN 1 ELSE 0 END  FROM @ExistingSample WHERE SampleName = @CustName;
					IF(ISNULL(@DuplicateNameFound,0) <> 0)
					BEGIN
						--increase both counter to get new name
						SET @Counter  = @Counter  + 1
						SET @NrOfSamples = @NrOfSamples +1;
					END
				END

				INSERT INTO @SampleToCreate(SampleName)
				Values(@CustName);
				SET @Counter  = @Counter  + 1
			END
		END
		INSERT INTO LD_Sample(SampleName)
		OUTPUT inserted.SampleID INTO @Sample
		SELECT SampleName FROM @SampleToCreate;

		INSERT INTO LD_SampleTest(SampleID,TestID)
		SELECT ID, @TestID FROM @Sample;

	END
	--rename sample name
	ELSE
	BEGIN
		
		--delete sample from sample test
		DELETE ST FROM LD_SampleTest ST
		JOIN LD_Sample S ON S.SampleID = ST.SampleID
		WHERE S.SampleID = @SampleID;

		--delete sample
		DELETE LD_Sample WHERE SampleID = @SampleID;
	END

END
GO
