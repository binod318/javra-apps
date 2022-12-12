DROP PROCEDURE IF EXISTS PR_RDT_GetMaterialForUpload
GO



--EXEC PR_RDT_GetMaterialForUpload 10636;
CREATE PROCEDURE [dbo].[PR_RDT_GetMaterialForUpload]
(
	@TestID		INT
) AS BEGIN
	SET NOCOUNT ON;
	DECLARE @ImportType NVARCHAR(50);

	IF NOT EXISTS(SELECT TestID FROM Test WHERE TestID = @TestID)
	BEGIN
		EXEC PR_ThrowError N'Invalid test.';
		RETURN;
	END

	IF NOT EXISTS(SELECT TestID FROM Test WHERE TestID = @TestID AND StatusCode = 100)
	BEGIN
		EXEC PR_ThrowError N'Invalid test status.';
		RETURN;
	END

	IF EXISTS(SELECT TestID FROM TestMaterialDetermination WHERE TestID = @TestID AND ISNULL(ExpectedDate,'') = '')
	BEGIN
		EXEC PR_ThrowError N'Expected result date cannot be empty. Please fill for all selected materials !';
		RETURN;
	END
	
	--If List type is imported then check for materialstatus
	SELECT @ImportType = ImportLevel FROM Test WHERE TestID = @TestID;

	IF @ImportType = 'LIST'
	BEGIN

		IF EXISTS 
		( 
			SELECT * FROM TestMaterial TM
			JOIN TestMaterialDetermination TMD ON TMD.TestID = TM.TestID AND TMD.MaterialID = TM.MaterialID 
			WHERE TM.TestID = @TestID AND ISNULL(MaterialStatus,'') = '' 
		)
		BEGIN
			EXEC PR_ThrowError N'Material Status cannot be empty. Please fill for all selected materials !';
			RETURN;
		END;
	END;
		
	SELECT
		F.CropCode AS 'Crop',
		T.BreedingStationCode AS 'BrStation',
		T.CountryCode AS 'Country',
		T.ImportLevel AS 'Level',
		TT.TestTypeCode AS 'TestType',
		T.TestID AS 'RequestID',
		'UTM' AS 'RequestingSystem',
		D.OriginID, --TMD.DeterminationID,
		M.MaterialID,
		M.MaterialKey,
		TMD.ExpectedDate AS 'ExpectedResultDate',
		TM.MaterialStatus,
		SL.SiteName AS 'Site',
		T3.MaterialKey AS 'PlantID',
		CAST (ISNULL(T3.[Plant name],'') AS NVARCHAR(50)) AS 'PlantName',
		CAST (T3.GID AS INT) AS 'GID',
		ISNULL(T3.[E-number], '') AS 'ENumber',
		ISNULL(T3.MasterNr, '') AS 'MasterNr',
		ISNULL(T3.lotNr,'') AS 'LotNumber' 
	FROM Test T
	JOIN SiteLocation SL ON SL.SiteID = T.SiteID
	JOIN TestType TT ON TT.TestTypeID = T.TestTypeID
	JOIN [File] F ON F.FileID = T.FileID
	JOIN [Row] R ON R.FileID = F.FileID
	JOIN Material M ON M.MaterialKey = R.MaterialKey
	JOIN TestMaterialDetermination TMD ON TMD.TestID = T.TestID AND TMD.MaterialID = M.MaterialID
	JOIN Determination D ON D.DeterminationID = TMD.DeterminationID
	JOIN
	(
		SELECT T2.MaterialKey, T2.[Plant name], T2.[GID], T2.lotNr, T2.[E-number],T2.MasterNr, T2.TestID
			FROM
			(
				SELECT 
					T.TestID,
					R.MaterialKey,
					C.ColumLabel,
					CellValue = CL.[Value]
				FROM [File] F
				JOIN [Row] R ON R.FileID = F.FileID
				JOIN [Column] C ON C.FileID = F.FileID
				JOIN Test T ON T.FileID = F.FileID
				LEFT JOIN [Cell] CL ON CL.RowID = R.RowID AND CL.ColumnID = C.ColumnID
				WHERE C.ColumLabel IN('Plant name','GID', 'lotNr', 'E-number', 'MasterNr')
			) T1
			PIVOT
			(
				Max(CellValue)
				FOR [ColumLabel] IN ([Plant name], [GID], [lotNr],[E-number],[MasterNr])
			) T2
	) T3 ON T3.MaterialKey = M.MaterialKey AND T3.TestID = T.TestID
	LEFT JOIN TestMaterial TM ON TM.TestID = T.TestID AND TM.MaterialID = M.MaterialID --This left join is only needed if material imported is from list level.	
	WHERE T.TestID = @TestID

END

GO