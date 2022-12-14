DROP PROCEDURE IF EXISTS [dbo].[PR_GetMarkers]
GO


-- PR_GetMarkers 'LT','L',1
CREATE PROCEDURE [dbo].[PR_GetMarkers]
(
	@CropCode NVARCHAR(10),
    @MarkerName NVARCHAR(100) = '',
	@ShowPacMarkers BIT = NULL
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
	AND ( @ShowPacMarkers = 1 OR M.MarkerID NOT IN (SELECT DISTINCT MarkerID FROM MarkerCropPlatform WHERE CropCode = @CropCode ));
END
GO
