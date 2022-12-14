DROP FUNCTION IF EXISTS [dbo].[FN_IsPacProfileComplete]
GO

-- =============================================
-- Author:		Binod Gurung
-- Create date: 2019/09/05
-- Description:	Function to check if pac profile is comlete for variety or not
-- =============================================
-- SELECT  dbo.FN_IsPacProfileComplete (21047, 8, 'SP')
CREATE FUNCTION [dbo].[FN_IsPacProfileComplete]
(
	@VarietyNr INT,
	@PlatformID INT,
	@CropCode NVARCHAR(5)
)
RETURNS BIT
AS
BEGIN

	DECLARE @ReturnValue BIT;

	IF EXISTS 
	(
		SELECT MCP.MarkerID
		FROM MarkerCropPlatform MCP
		LEFT JOIN MarkerValuePerVariety MVPV ON VarietyNr = @VarietyNr AND MVPV.MarkerID = MCP.MarkerID 
		WHERE PlatformID = @PlatformID AND CropCode = @CropCode AND InMMS = 1 AND VarietyNr IS NULL
	)
		SET @ReturnValue = 0;
	ELSE
		SET @ReturnValue = 1;

	Return @ReturnValue;

END
GO


