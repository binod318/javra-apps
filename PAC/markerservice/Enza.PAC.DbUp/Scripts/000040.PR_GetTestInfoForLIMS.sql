DROP PROCEDURE IF EXISTS [dbo].[PR_GetTestInfoForLIMS]
GO

-- =============================================
-- Author:		Binod Gurung
-- Create date: 2019/10/22
-- Description:	Pull Test Information for input period for LIMS
-- =============================================
/*
EXEC PR_GetTestInfoForLIMS 4780
*/
CREATE PROCEDURE [dbo].[PR_GetTestInfoForLIMS]
(
	@PeriodID INT
)
AS
BEGIN
	
	SET NOCOUNT ON;

	SELECT 
		'DPW'													AS ContainerType,
		'NL'													AS CountryCode,
		MAX(V0.CropCode)										AS CropCode,
		CONVERT(varchar(50), GETDATE(), 127)					AS ExpectedDate,
		ExpectedWeek = DATEPART(WEEK, GETDATE()),	
		ExpectedYear = YEAR(GETDATE()),
		'N'														AS Isolated,	
		'FRS'													AS MaterialState,
		'SDS'													AS MaterialType,
		CONVERT(varchar(50), GETDATE(), 127)					AS PlannedDate, 
		PlannedWeek = DATEPART(WEEK, GETDATE()),	
		PlannedYear = YEAR(GETDATE()),
		'TestRemarks'											AS Remark, 
		T.TestID												AS RequestID, 
		'PAC'													AS RequestingSystem,
		'NL'													AS SynchronisationCode,
		CAST(ROUND(SUM(ISNULL(V0.PlatesPerRow,0)),0) AS INT)	AS TotalNrOfPlates , 
		CAST(ROUND(SUM(ISNULL(TestsPerRow,0)),0) AS INT)		AS TotalNrOfTests  
	FROM
	(	
		SELECT 
			TestID, DA.DetAssignmentID, 
			(M.NrOfSeeds / 92.0) AS PlatesPerRow,
			V1.MarkersPerDA,
			( (M.NrOfSeeds / 92.0) * V1.MarkersPerDA) AS TestsPerRow,
			AC.CropCode
		FROM TestDetAssignment TDA
		JOIN DeterminationAssignment DA ON DA.DetAssignmentID = TDA.DetAssignmentID
		JOIN Method M ON M.MethodCode = DA.MethodCode
		JOIN CropMethod CM ON CM.MethodID = M.MethodID AND CM.ABSCropCode = DA.ABSCropCode
		JOIN ABSCrop AC On AC.ABSCropCode = DA.ABSCropCode
		LEFT JOIN 
		(
			SELECT DetAssignmentID, COUNT(DetAssignmentID) AS MarkersPerDA FROM MarkerToBeTested MTBT 
			GROUP BY DetAssignmentID
		) V1 ON V1.DetAssignmentID = DA.DetAssignmentID
	) V0 
	JOIN Test T ON T.TestID = V0.TestID
	WHERE PeriodID = @PeriodID
	GROUP BY T.TestID

END

GO
