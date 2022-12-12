--EXEC PR_GetEmailConfigs 'UTM_SEND_RESULT_EMAIL', '*', '*', '*', 1, 20
--EXEC PR_GetEmailConfigs NULL, NULL, NULL, NULL, 1, 20

ALTER PROCEDURE [dbo].[PR_GetEmailConfigs]
(
	@ConfigGroup	NVARCHAR(100)	= NULL,
	@CropCode		NVARCHAR(10)	= NULL,
    @BrStationCode	NVARCHAR(20)    = NULL,
	@UsedForMenu	NVARCHAR(20)    = NULL,
	@Page			INT,
	@PageSize		INT
) AS BEGIN
	SET NOCOUNT ON;

	DECLARE @Offset INT = @PageSize * (@Page -1);
	
	WITH CTE AS
	(
		SELECT
			E.ConfigID,
			ConfigGroup = MAX(E.ConfigGroup),
			CropCode = MAX(E.CropCode),
			Recipients = MAX(E.Recipients),
            BrStationCode = MAX(E.BrStationCode)
		FROM EmailConfig E
		JOIN EmailConfigPerMenu EM ON EM.ConfigGroup = E.ConfigGroup
		--LEFT JOIN SiteLocation S ON S.SiteID = E.SiteID
		WHERE (ISNULL(@ConfigGroup, '') = '' OR E.ConfigGroup = @ConfigGroup)
		AND (ISNULL(@CropCode, '') = '' OR CropCode = @CropCode)
        AND (ISNULL(@BrStationCode, '') = '' OR BrStationCode = @BrStationCode)
		AND (ISNULL(@UsedForMenu, '') = '' OR EM.Menu = @UsedForMenu)
		GROUP BY E.ConfigID
	), CTE_COUNT AS 
	(
		SELECT COUNT(ConfigID) AS TotalRows FROM CTE
	)

	SELECT 
		CTE.*,
		CTE_COUNT.TotalRows
	FROM CTE, CTE_COUNT
	ORDER BY ConfigGroup,CropCode,BrStationCode
	OFFSET @Offset ROWS
	FETCH NEXT @PageSize ROWS ONLY;
END
