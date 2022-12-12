
/*
	EXEC PR_Remove_UnMappedColumns 'TO', N'[{"TraitID":1,"ColumnLabel":"Column1"},{"TraitID":1,"ColumnLabel":"Column2"}]';
*/
ALTER PROCEDURE [dbo].[PR_Remove_UnMappedColumns]
(
	@CropCode	NVARCHAR(4),
	@DataAsJson NVARCHAR(MAX)
) AS BEGIN
	SET NOCOUNT ON;

	DECLARE @FileID INT;
	DECLARE @InvalidColumns NVARCHAR(MAX);
	DECLARE @tbl TABLE(TraitID INT, ColumnLabel NVARCHAR(200));

	SELECT 
		@FileID = FileID 
	FROM [File] 
	WHERE CropCode = @CropCode;
	
	IF(ISNULL(@FileID, 0) = 0) BEGIN
		EXEC PR_ThrowError 'Invalid file name.';
		RETURN;
	END

	INSERT INTO @tbl(TraitID, ColumnLabel)
	SELECT 
		TraitID, 
		ColumnLabel
	FROM OPENJSON(@DataAsJson) WITH
	(
		TraitID		INT				'$.TraitID',
		ColumnLabel	NVARCHAR(200)	'$.ColumnLabel'
	);
	--validate if trait and column label are not empty
	IF EXISTS(SELECT TraitID FROM @tbl WHERE ISNULL(TraitID, 0) = 0 OR ISNULL(ColumnLabel, '') = '') BEGIN
		EXEC PR_ThrowError 'Found invalid columns in the delete list.';
		RETURN;
	END

	IF EXISTS
	(
		SELECT 
			RTS.CropTraitID 
		FROM RelationTraitScreening RTS 
		JOIN CropTrait CT ON CT.CropTraitID = RTS.CropTraitID
		JOIN Trait T ON T.TraitID = CT.TraitID
		JOIN @tbl C ON C.ColumnLabel = T.ColumnLabel
		WHERE CT.CropCode = @CropCode
	) BEGIN
		EXEC PR_ThrowError 'Column is already linked with screening field. Contact application administrator to map the value(s).';
		RETURN;
	END

	BEGIN TRY
		BEGIN TRANSACTION;
			
		DELETE C FROM Cell C
		JOIN [Column] C1 ON C1.ColumnID = C.ColumnID
		JOIN @tbl C2 ON C2.TraitID = C1.TraitID AND C2.ColumnLabel = C1.ColumLabel
		WHERE C1.FileID = @FileID;
		
		DELETE C 
		FROM [Column] C
		JOIN @tbl C2 ON C2.TraitID = C.TraitID AND C2.ColumnLabel = C.ColumLabel
		WHERE FileID = @FileID;

		UPDATE C
		SET C.ColumnNr = C1.NewColNr
		FROM [Column] C
		JOIN 
		(
			SELECT 
				*,
				ROW_NUMBER() OVER (ORDER BY ColumnNr) AS NewColNr 
			FROM [Column]
			WHERE FileID = @FileID			
		) C1 ON C1.TraitID = C.TraitID AND C1.ColumLabel = C.ColumLabel
		WHERE C.FileID = @FileID;	
		
		COMMIT TRANSACTION;  	
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION; 
		THROW; 
	END CATCH

END
