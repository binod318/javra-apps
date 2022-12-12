ALTER TABLE EmailConfig
ADD SiteID INT

GO

ALTER TABLE EmailConfig
ADD CONSTRAINT FK_EmailConfigSiteLocation
FOREIGN KEY (SiteID) REFERENCES SiteLocation(SiteID)

GO

DROP PROCEDURE IF EXISTS [dbo].[PR_GetEmailConfigs]
GO


--EXEC PR_GetEmailConfigs 'UTM_SEND_RESULT_EMAIL', '*', '*', '*', 1, 20
--EXEC PR_GetEmailConfigs NULL, NULL, NULL, NULL, 1, 20

CREATE PROCEDURE [dbo].[PR_GetEmailConfigs]
(
	@ConfigGroup	NVARCHAR(100)	= NULL,
	@CropCode		NVARCHAR(10)	= NULL,
    @BrStationCode	NVARCHAR(20)    = NULL,
	@SiteName		NVARCHAR(20)    = NULL,
	@Page			INT,
	@PageSize		INT
) AS BEGIN
	SET NOCOUNT ON;

	DECLARE @Offset INT = @PageSize * (@Page -1);
	
	WITH CTE AS
	(
		SELECT
			E.ConfigID,
			E.ConfigGroup,
			E.CropCode,
			E.Recipients,
            E.BrStationCode,
			E.SiteID,
			S.SiteName
		FROM EmailConfig E
		LEFT JOIN SiteLocation S ON S.SiteID = E.SiteID
		WHERE (ISNULL(@ConfigGroup, '') = '' OR ConfigGroup = @ConfigGroup)
		AND (ISNULL(@CropCode, '') = '' OR CropCode = @CropCode)
        AND (ISNULL(@BrStationCode, '') = '' OR BrStationCode = @BrStationCode)
		AND (ISNULL(@SiteName, '') = '' OR S.SiteName = @SiteName)
	), CTE_COUNT AS 
	(
		SELECT COUNT(ConfigID) AS TotalRows FROM CTE
	)

	SELECT 
		CTE.*,
		CTE_COUNT.TotalRows
	FROM CTE, CTE_COUNT
	ORDER BY ConfigID
	OFFSET @Offset ROWS
	FETCH NEXT @PageSize ROWS ONLY;
END
GO


DROP PROCEDURE IF EXISTS [dbo].[PR_SaveEmailConfig]
GO


/*
	EXEC PR_SaveEmailConfig NULL, 'UTM_SEND_RESULT_EMAIL', 'AN', 'a@gmail.com'
*/
CREATE PROCEDURE [dbo].[PR_SaveEmailConfig]
(
	@ConfigID		INT				= NULL,
	@ConfigGroup	NVARCHAR(100),
	@CropCode		NVARCHAR(10),  
	@Recipients		NVARCHAR(MAX),
    @BrStationCode	NVARCHAR(20),
	@SiteID			INT
) AS BEGIN
	SET NOCOUNT ON;
	
	IF(ISNULL(@ConfigID, 0) = 0 ) BEGIN
		IF EXISTS
		(
			SELECT 
				ConfigID 
			FROM EmailConfig 
			WHERE ConfigGroup	= @ConfigGroup 
			AND CropCode		= @CropCode
            AND BrStationCode	= @BrStationCode
			AND SiteID			= @SiteID
		) BEGIN
			EXEC PR_ThrowError N'Configuration already exists. Please edit configuration instead.';
			RETURN;
		END
		ELSE BEGIN
			INSERT INTO EmailConfig(ConfigGroup, CropCode, Recipients, BrStationCode, SiteID)
			VALUES(@ConfigGroup, @CropCode, @Recipients, @BrStationCode, @SiteID);
		END
	END
	ELSE BEGIN
		UPDATE EmailConfig SET
			CropCode		= @CropCode,
            BrStationCode	= @BrStationCode,
			SiteID			= @SiteID,
			Recipients		= @Recipients
		WHERE ConfigID = @ConfigID;
	END
END
GO


