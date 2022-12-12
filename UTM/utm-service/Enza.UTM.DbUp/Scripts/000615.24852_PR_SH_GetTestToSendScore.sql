
/*
=========Changes====================
Changed By			DATE				Description

Krishna Gautam		2021-JAN-03			#24850: Get list of tests eligible to send result to Phenome for seedealth

========Example=============
EXEC PR_SH_GetTestToSendScore

*/


ALTER PROCEDURE [dbo].[PR_SH_GetTestToSendScore]
AS
BEGIN

	SELECT 
		T.TestID,
		F.CropCode, 
		T.BreedingStationCode,
		T.LabPlatePlanName, 
		T.TestName, 
		S.SiteName, 
		T.LDResultSummary,
		T.LotSampleType
	FROM Test T 
	JOIN [File] F ON F.FileID = T.FileID 
	LEFT JOIN SiteLocation S ON S.SiteID = T.SiteID
	WHERE T.StatusCode = 600 AND T.TestTypeID = 10 AND ISNULL(T.LDResultSummary,'') != ''  --Seedhealth

END

GO



/*
EXEC PR_SH_GetScore 14763
*/

ALTER PROCEDURE [dbo].[PR_SH_GetScore]
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
		D.DeterminationName,
		TR.Score, 
		TR.MappingColumn,
		TR.SHTestResultID,
		T.LotSampleType,
		TR.StatusCode
	FROM
	Test T
	JOIN TestMaterial TM ON TM.TestID = T.TestID
	JOIN MaterialLot ML ON ML.MaterialLotID = TM.MaterialID --MaterialID is MaterialLotID in TestMaterial
	JOIN LD_SampleTestMaterial STM ON STM.MaterialLotID = ML.MaterialLotID
	JOIN SHTestResult TR ON T.TestID = TM.TestID AND TR.SampleTestID = STM.SampleTestID
	JOIN Determination D ON D.DeterminationID = TR.DeterminationID
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