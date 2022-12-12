DROP PROCEDURE IF EXISTS [dbo].[PR_LFDISK_GetConfigurationList]
GO


/*
Author					Date			Remarks
-------------------------------------------------------------------------------
Binod Gurung			2021-June-25	#22708: Get configuraitons saved for leaf disk
==================================Example======================================
--EXEC PR_LFDISK_GetConfigurationList  'ON,CF'

*/


CREATE PROCEDURE [dbo].[PR_LFDISK_GetConfigurationList]
(
	@Crops		 NVARCHAR(MAX)
) AS BEGIN
    SET NOCOUNT ON;

    SELECT 
		ID = T.TestID,
		[Name] = TestName,
		F.CropCode,
		T.BreedingStationCode
	FROM Test T
	JOIN [File] F On F.FileID = T.FileID 
	WHERE T.TestTypeID = 9 AND YEAR(T.CreationDate) >= YEAR(GETDATE()) - 1 --AND T.StatusCode = 100

END
GO


