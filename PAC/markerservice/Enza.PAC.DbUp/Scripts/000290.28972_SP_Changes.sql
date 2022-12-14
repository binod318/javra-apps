DROP PROCEDURE IF EXISTS [dbo].[PR_GetVarieties]
GO


-- PR_GetVarieties 'TO','1'
CREATE PROCEDURE [dbo].[PR_GetVarieties]
(
	@CropCode NVARCHAR(10),
    @VarietyName NVARCHAR(100) = ''
) AS BEGIN
    SET NOCOUNT ON;

    SELECT TOP 30
	   V.VarietyNr,
	   VarietyName = V.Shortname
    FROM Variety V
    WHERE V.CropCode = @CropCode AND 
    V.Shortname LIKE '%' + @VarietyName + '%';
END
GO


DROP PROCEDURE IF EXISTS [dbo].[PR_GetMarkers]
GO


-- PR_GetMarkers 'LT','1'
CREATE PROCEDURE [dbo].[PR_GetMarkers]
(
	@CropCode NVARCHAR(10),
    @MarkerName NVARCHAR(100) = ''
) AS BEGIN
    SET NOCOUNT ON;

    SELECT TOP 30
	   M.MarkerID,
	   MarkerName = M.MarkerFullName
    FROM Marker M
    WHERE M.CropCode = @CropCode 
	AND M.StatusCode = 100 
	AND (M.PlatformCode IS NULL OR M.PlatformCode = 'LS')
    AND M.MarkerFullName LIKE '%' + @MarkerName + '%'
	AND M.MarkerID NOT IN (SELECT DISTINCT MarkerID FROM MarkerCropPlatform);
END
GO


DROP PROCEDURE IF EXISTS [dbo].[PR_GetCrop]
GO

CREATE PROCEDURE [dbo].[PR_GetCrop]
AS 
BEGIN
	SELECT CropCode, CropName FROM CropRD
END
GO


