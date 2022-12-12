DROP PROCEDURE [dbo].[PR_VtoPSync_GetConfigs]
GO


CREATE PROCEDURE [dbo].[PR_VtoPSync_GetConfigs]
AS BEGIN
	SET NOCOUNT ON;
	SELECT
		[SyncConfigID], 
		VP.[CropCode], 
		[SyncCode], 
		[GermplasmSetID], 
		[GBTHExternalLotFolderID],
		[ABSLotFolderID],
		[Level], 
		[LotNr],
		[SelfingFieldSetID],
		C.[HasOp]
	FROM VtoPSyncConfig VP
	JOIN CropRD C ON C.CropCode = VP.CropCode
	
END			 
GO


