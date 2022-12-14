/*
=========Changes====================
Changed By			DATE				Description

Krishna Gautam		2020-08-10			#15150: Created Stored Procedure	

========Example=============
EXEC PR_RDT_GetTestToSendScore

*/


ALTER PROCEDURE [dbo].[PR_RDT_GetTestToSendScore]
AS
BEGIN

	SELECT T.TestID,F.CropCode, T.BreedingStationCode,T.LabPlatePlanName, T.TestName, S.SiteName FROM Test T 
	JOIN [File] F ON F.FileID = T.FileID 
	LEFT JOIN SiteLocation S ON S.SiteID = T.SiteID
	WHERE T.StatusCode = 550 AND T.TestTypeID = 8;
END
