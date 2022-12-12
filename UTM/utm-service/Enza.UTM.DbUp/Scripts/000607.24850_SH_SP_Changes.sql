DROP PROCEDURE IF EXISTS [dbo].[PR_SH_UpdateTestResultStatus]
GO

CREATE PROCEDURE [dbo].[PR_SH_UpdateTestResultStatus]
(
	@TestID INT,
	@TestResultIDs NVARCHAR(MAX),
	@StatusCode INT
)
AS 
BEGIN
	DECLARE @AllSent BIT;

	UPDATE R 
		SET R.StatusCode = @StatusCode 
	FROM SHTestResult R
	JOIN string_split(@TestResultIDs,',') T1 ON ISNULL(CAST(T1.[value] AS INT),0) = R.SHTestResultID

END
GO


DROP PROCEDURE IF EXISTS [dbo].[PR_SH_GetScore]
GO



/*
EXEC PR_SH_GetScore 14763
*/

CREATE PROCEDURE [dbo].[PR_SH_GetScore]
(
	@TestID INT
)
AS BEGIN

	DECLARE @CropCode NVARCHAR(10);
	
	SELECT @CropCode = CropCode
	FROM [File] F 
	JOIN Test T ON T.FileID = F.FileID
	WHERE T.TestID = @TestID;	

	SELECT 
		T.TestID, 
		MaterialKey, 
		RefExternal, 
		T1.ColumnLabel,
		T1.DeterminationName,
		TR.Score, 
		TR.MappingColumn,
		TR.SHTestResultID
	FROM
	Test T
	JOIN TestMaterial TM ON TM.TestID = T.TestID
	JOIN MaterialLot ML ON ML.MaterialLotID = TM.MaterialID --MaterialID is MaterialLotID in TestMaterial
	JOIN LD_SampleTestMaterial STM ON STM.MaterialLotID = ML.MaterialLotID
	JOIN SHTestResult TR ON T.TestID = TM.TestID AND TR.SampleTestID = STM.SampleTestID
	LEFT JOIN
	(
		SELECT 
			T.TestID,
			T1.ColumnLabel, 
			D.DeterminationName,
			TDR.MappingCol,
			TR.SHTestResultID,
			TR.StatusCode,
			TDR.SHTraitDetResultID
		FROM SHTestResult TR 
		JOIN LD_SampleTest ST ON ST.SampleTestID = TR.SampleTestID
		JOIN Test T ON T.TestID = ST.TestID
		JOIN RelationTraitDetermination RTD ON RTD.DeterminationID = TR.DeterminationID
		JOIN Determination D ON D.DeterminationID = RTD.DeterminationID
		JOIN CropTrait CT ON CT.CropTraitID = RTD.CropTraitID AND CT.CropCode = @CropCode
		JOIN Trait T1 ON T1.TraitID = CT.TraitID		
		JOIN SHTraitDetResult TDR ON 
					TDR.RelationID = RTD.RelationID
					AND T.LotSampleType LIKE '%' + TDR.SampleType +'%'
					AND ISNULL(TDR.MappingCol,'') = ISNULL(TR.MappingColumn,'')
		WHERE  T.TestID = @TestID 
	) T1 ON T1.SHTestResultID = TR.SHTestResultID
	WHERE T.TestID = @TestID AND T.StatusCode = 600 AND TR.StatusCode IN (100,150,200)
	
END
GO


