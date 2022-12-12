
--EXEC PR_GetEmailConfigs 'UTM_SEND_RESULT_EMAIL', '*', '*', '*', 1, 20
--EXEC PR_GetEmailConfigs NULL, NULL, NULL, NULL, '[cropcode]   LIKE  ''%on%''', 1, 20

--EXEC PR_GetEmailConfigs NULL, NULL, NULL, 'rdt', NULL, 1, 20
--EXEC PR_GetEmailConfigs '', '', '', '', '', 1, 20

ALTER PROCEDURE [dbo].[PR_GetEmailConfigs]
(
	@ConfigGroup	NVARCHAR(100)	= NULL,
	@CropCode		NVARCHAR(10)	= NULL,
    @BrStationCode	NVARCHAR(20)    = NULL,
	@UsedForMenu	NVARCHAR(20)    = NULL,
	@Filter			NVARCHAR(MAX)   = NULL,
	@Page			INT,
	@PageSize		INT
) AS BEGIN
	SET NOCOUNT ON;

	DECLARE @Query NVARCHAR(MAX) = '', @FilterString NVARCHAR(MAX) = '';
	DECLARE @Offset INT = @PageSize * (@Page -1);
	
	
	
	IF(ISNULL(@Filter,'') <> '')
	BEGIN
		SET @FilterString = ' AND '+@Filter;
	END


	SET @Query = ';WITH CTE AS
	(
		SELECT
			E.ConfigID,
			ConfigGroup = MAX(E.ConfigGroup),
			CropCode = MAX(E.CropCode),
			Recipients = MAX(E.Recipients),
            BrStationCode = MAX(E.BrStationCode)
		FROM EmailConfig E
		JOIN EmailConfigPerMenu EM ON EM.ConfigGroup = E.ConfigGroup		
		WHERE 
		COALESCE(@ConfigGroup, E.ConfigGroup,'''') = COALESCE(E.ConfigGroup, '''')
		AND COALESCE(@CropCode, E.CropCode,'''') = COALESCE(E.CropCode, '''')
		AND COALESCE(@BrStationCode, E.BrStationCode, '''') = COALESCE(E.BrStationCode, '''')
		AND COALESCE(@UsedForMenu, EM.Menu, '''') = COALESCE(EM.Menu, '''')
		
		'+@FilterString+'
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
	FETCH NEXT @PageSize ROWS ONLY;';

	--PRINT @Query;
	EXEC sp_executesql @Query , N'@ConfigGroup NVARCHAR(MAX), @CropCode NVARCHAR(MAX), @BrStationCode NVARCHAR(MAX), @UsedForMenu NVARCHAR(MAX), @Offset INT, @PageSize INT', @ConfigGroup, @CropCode, @BrStationCode, @UsedForMenu, @Offset, @PageSize;


	--WITH CTE AS
	--(
	--	SELECT
	--		E.ConfigID,
	--		ConfigGroup = MAX(E.ConfigGroup),
	--		CropCode = MAX(E.CropCode),
	--		Recipients = MAX(E.Recipients),
 --           BrStationCode = MAX(E.BrStationCode)
	--	FROM EmailConfig E
	--	JOIN EmailConfigPerMenu EM ON EM.ConfigGroup = E.ConfigGroup
	--	--LEFT JOIN SiteLocation S ON S.SiteID = E.SiteID
	--	WHERE 
	--	(ISNULL(@ConfigGroup, '') = '' OR E.ConfigGroup = @ConfigGroup)
	--	--COALESCE(@ConfigGroup,E.ConfigGroup) = E.ConfigGroup
	--	--AND (ISNULL(@CropCode, '') = '' OR CropCode = @CropCode)
	--	AND COALESCE(@CropCode, E.CropCode) = E.CropCode
 --       AND (ISNULL(@BrStationCode, '') = '' OR BrStationCode = @BrStationCode)
	--	AND (ISNULL(@UsedForMenu, '') = '' OR EM.Menu = @UsedForMenu)
	--	GROUP BY E.ConfigID
	--), CTE_COUNT AS 
	--(
	--	SELECT COUNT(ConfigID) AS TotalRows FROM CTE
	--)

	--SELECT 
	--	CTE.*,
	--	CTE_COUNT.TotalRows
	--FROM CTE, CTE_COUNT
	--ORDER BY ConfigGroup,CropCode,BrStationCode
	--OFFSET @Offset ROWS
	--FETCH NEXT @PageSize ROWS ONLY;
END
