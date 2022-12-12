ALTER PROCEDURE [dbo].[PR_VtoPSync_GetConfigs]
AS BEGIN
	SET NOCOUNT ON;
	SELECT
		[SyncConfigID], 
		[CropCode], 
		[SyncCode], 
		[GermplasmSetID], 
		[GBTHExternalLotFolderID],
		[ABSLotFolderID],
		[Level], 
		[LotNr],
		[SelfingFieldSetID]
	FROM VtoPSyncConfig
END			 

GO

ALTER PROCEDURE [dbo].[PR_VtoPSync_GetConfigs]
AS BEGIN
	SET NOCOUNT ON;
	SELECT
		[SyncConfigID], 
		[CropCode], 
		[SyncCode], 
		[GermplasmSetID], 
		[GBTHExternalLotFolderID],
		[ABSLotFolderID],
		[Level], 
		[LotNr],
		[SelfingFieldSetID]
	FROM VtoPSyncConfig
END			 

GO