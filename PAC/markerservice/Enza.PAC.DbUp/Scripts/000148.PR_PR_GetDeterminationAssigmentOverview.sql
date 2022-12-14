DROP PROCEDURE IF EXISTS [dbo].[PR_GetDeterminationAssigmentOverview]
GO

/*
Author					Date			Remarks
Binod Gurung			-				-
Krishna Gautam			2020-01-21		Where clause added.
Binod Gurung			2020-jan-23		Transcation isolation level implemented to avoid record lock

=================EXAMPLE=============
-- PR_GetDeterminationAssigmentOverview 4792
*/
CREATE PROCEDURE [dbo].[PR_GetDeterminationAssigmentOverview]
(
    @PeriodID INT
) AS BEGIN
    SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    DECLARE @PlatformID INT = (SELECT PlatformID FROM [Platform] WHERE PlatformCode = 'LS'); --light scanner  

	SELECT 
	   DA.DetAssignmentID,
	   DA.SampleNr,   
	   DA.BatchNr,
	   Article = V.Shortname,
	   'Status' = COALESCE(S.StatusName, CAST(DA.StatusCode AS NVARCHAR(10))),
	   'Exp Ready' = FORMAT(DA.ExpectedReadyDate, 'yyyy-MM-dd', 'en-US'), 
	   V2.Folder,
	   'Quality Class' = DA.QualityClass
    FROM DeterminationAssignment DA
    JOIN
    (
	   SELECT
		  AC.ABSCropCode,
		  PM.MethodCode
	   FROM CropMethod CM
	   JOIN ABSCrop AC ON AC.ABSCropCode = CM.ABSCropCode
	   JOIN Method PM ON PM.MethodID = CM.MethodID
	   WHERE CM.PlatformID = @PlatformID
    ) V1 ON V1.ABSCropCode = DA.ABSCropCode AND V1.MethodCode = DA.MethodCode
    JOIN Variety V ON V.VarietyNr = DA.VarietyNr
	JOIN
	(
		SELECT W.DetAssignmentID, MAX(T.TestName) AS Folder FROM Test T
		JOIN Plate P ON P.TestID = T.TestID
		JOIN Well W ON W.PlateID = P.PlateID
		--WHERE T.StatusCode >= 500
		GROUP BY W.DetAssignmentID
	) V2 On V2.DetAssignmentID = DA.DetAssignmentID
	join TestDetAssignment TDA ON TDA.DetAssignmentID = DA.DetAssignmentID
	JOIN Test T ON T.TestID = TDA.TestID
	JOIN [Status] S ON S.StatusCode = DA.StatusCode AND S.StatusTable = 'DeterminationAssignment'
	WHERE T.PeriodID = @PeriodID AND DA.StatusCode IN (600,999)

END
GO


