
/*
==================================================================
Changed By			DATE				REMARKS
------------------------------------------------------------------
	
Krishna Gautam		April-06-2020		#11463: Changes on SP.
Krishna Gautam		Oct-16-2020			#16427: Changes on SP.

==================================================================
========================Example===================================
	--PR_VtoPSync_GetVarietyLogs 'NL' , 'ON'
*/ 


ALTER PROCEDURE [dbo].[PR_VtoPSync_GetVarietyLogs]  
(  
	@SyncCode NVARCHAR(10),
	@CropCode NVARCHAR(10) 
)  
AS BEGIN  
 SET NOCOUNT ON;  
   
 SELECT   
	V.VarietyID,  
	V.CropCode,  
	V.GID,  
	V.ENumber,  
	V.VarietyName,  
	ObjectID = CAST(F.ObjectID AS INT),  
	ObjectType = CAST(ISNULL(F.ObjectType, 5) AS INT),
	S.StatusDescription
FROM Variety V
JOIN [Status] S ON S.StatusCode = V.VarmasStatusCode AND S.StatusTable = 'VarmasStatus'
LEFT JOIN [File] F ON F.CropCode = V.CropCode  
WHERE ISNULL(V.ENumber, '') <> ''  
 AND V.StatusCode = 250  
 AND V.SyncCode = @SyncCode
 AND V.CropCode = @CropCode;  
END  

