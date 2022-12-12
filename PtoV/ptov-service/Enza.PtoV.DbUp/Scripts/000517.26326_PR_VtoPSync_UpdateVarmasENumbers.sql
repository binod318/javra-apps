/*
	==================================================================
	Changed By			DATE				REMARKS
	------------------------------------------------------------------

	Krishna Gautam		April-06-2020		#11892: Changes on SP.
	Krishna Gautam		April-06-2020		#11463: Changes on SP.
	Krishna Gautam		Sep-21	-2021		#26326: Changes on SP to sync varmas status to phenome for inactive variety by changing status from 300 to 350

	==================================================================
 
	 DECLARE @DataAsJson NVARCHAR(MAX) = N'[{"VNr": 12345,"ENr": "54321", "VName": "1700597", "VStatus": "ACT", "VarmasStatus": "PD"}]';  
	 EXEC PR_VtoPSync_UpdateVarmasENumbers @DataAsJson  
*/  
ALTER PROCEDURE [dbo].[PR_VtoPSync_UpdateVarmasENumbers]  
(  
 @DataAsJson  NVARCHAR(MAX)  
)  
AS BEGIN  
 SET NOCOUNT ON;  
 DECLARE @tbl TABLE(GID INT, StatusCode INT); 
 DECLARE @tblData TABLE( VarietyNr INT, ENumber  NVARCHAR(100),  VarietyName NVARCHAR(100) , VarietyStatus NVARCHAR(100) ,VarmasStatus NVARCHAR(50), LotNr INT);
 
 INSERT INTO @tblData (VarietyNr, ENumber, VarietyName, VarietyStatus, VarmasStatus, LotNr)
	 SELECT VarietyNr, ENumber, VarietyName, VarietyStatus, VarmasStatus, LotNr
	  FROM OPENJSON(@DataAsJson)
	  WITH  
	  (  
		   VarietyNr INT    '$.VNr',  
		   ENumber  NVARCHAR(100) '$.ENr',  
		   VarietyName NVARCHAR(100) '$.VName',  
		   VarietyStatus NVARCHAR(100) '$.VStatus',
		   VarmasStatus NVARCHAR(50) '$.VarmasStatus',
		   LotNr INT '$.LotNr'
	  )
	  
   
 UPDATE V SET   
  V.ENumber = T1.ENumber,  
  V.VarietyName = T1.VarietyName,  
  V.StatusCode = CASE   
       WHEN T1.VarietyStatus = 'INACT' AND V.StatusCode <> 300 THEN 350
       WHEN T1.VarietyStatus = 'ACT' THEN  
        CASE   
         WHEN (V.ENumber <> T1.ENumber OR V.VarietyName <> T1.VarietyName) OR (V.StatusCode = 250) THEN 250   
         ELSE 200  
        END  
       ELSE V.StatusCode   
      END --set status to 250 if either Enumber or varietyname is changed.  
	,V.VarmasStatusCode = S.StatusCode
 OUTPUT INSERTED.GID, INSERTED.StatusCode INTO @tbl  
 FROM Variety V
 JOIN RelationPtoV R ON R.GID = V.GID  
 JOIN @tblData T1 ON T1.VarietyNr = R.VarietyNr
 LEFT JOIN [Status] S ON S.StatusName = T1.VarmasStatus AND S.StatusTable = 'VarmasStatus' ;  


 --update relationPtoV table status
 UPDATE R SET   
  R.StatusCode = CASE   
       WHEN  (T1.StatusCode = 200 OR T1.StatusCode = 250) AND R.StatusCode = 200 THEN 100 ELSE R.StatusCode
      END     
 FROM @TblData T
 JOIN Lot L ON L.VarmasLot = T.LotNr
 JOIN RelationPtoV R ON R.GID = L.GID
 JOIN @Tbl T1 ON T1.GID = R.GID;


END  

GO

/*
	==================================================================
	Changed By			DATE				REMARKS
	------------------------------------------------------------------

	Krishna Gautam		April-06-2020		#11892: Changes on SP.
	Krishna Gautam		April-06-2020		#11463: Changes on SP.
	Krishna Gautam		Sep-21	-2021		#26326: Changes on SP to sync varmas status to phenome for inactive variety by changing status from 300 to 350

	==================================================================
 
	 DECLARE @DataAsJson NVARCHAR(MAX) = N'[{"VNr": 12345,"ENr": "54321", "VName": "1700597", "VStatus": "ACT", "VarmasStatus": "PD"}]';  
	 EXEC PR_VtoPSync_UpdateVarmasENumbers @DataAsJson  
*/  
ALTER PROCEDURE [dbo].[PR_VtoPSync_UpdateVarmasENumbers]  
(  
 @DataAsJson  NVARCHAR(MAX)  
)  
AS BEGIN  
 SET NOCOUNT ON;  
 DECLARE @tbl TABLE(GID INT, StatusCode INT); 
 DECLARE @tblData TABLE( VarietyNr INT, ENumber  NVARCHAR(100),  VarietyName NVARCHAR(100) , VarietyStatus NVARCHAR(100) ,VarmasStatus NVARCHAR(50), LotNr INT);
 
 INSERT INTO @tblData (VarietyNr, ENumber, VarietyName, VarietyStatus, VarmasStatus, LotNr)
	 SELECT VarietyNr, ENumber, VarietyName, VarietyStatus, VarmasStatus, LotNr
	  FROM OPENJSON(@DataAsJson)
	  WITH  
	  (  
		   VarietyNr INT    '$.VNr',  
		   ENumber  NVARCHAR(100) '$.ENr',  
		   VarietyName NVARCHAR(100) '$.VName',  
		   VarietyStatus NVARCHAR(100) '$.VStatus',
		   VarmasStatus NVARCHAR(50) '$.VarmasStatus',
		   LotNr INT '$.LotNr'
	  )
	  
   
 UPDATE V SET   
  V.ENumber = T1.ENumber,  
  V.VarietyName = T1.VarietyName,  
  V.StatusCode = CASE   
       WHEN T1.VarietyStatus = 'INACT' AND V.StatusCode <> 300 THEN 350
       WHEN T1.VarietyStatus = 'ACT' THEN  
        CASE   
         WHEN (V.ENumber <> T1.ENumber OR V.VarietyName <> T1.VarietyName) OR (V.StatusCode = 250) THEN 250   
         ELSE 200  
        END  
       ELSE V.StatusCode   
      END --set status to 250 if either Enumber or varietyname is changed.  
	,V.VarmasStatusCode = S.StatusCode
 OUTPUT INSERTED.GID, INSERTED.StatusCode INTO @tbl  
 FROM Variety V
 JOIN RelationPtoV R ON R.GID = V.GID  
 JOIN @tblData T1 ON T1.VarietyNr = R.VarietyNr
 LEFT JOIN [Status] S ON S.StatusName = T1.VarmasStatus AND S.StatusTable = 'VarmasStatus' ;  


 --update relationPtoV table status
 UPDATE R SET   
  R.StatusCode = CASE   
       WHEN  (T1.StatusCode = 200 OR T1.StatusCode = 250) AND R.StatusCode = 200 THEN 100 ELSE R.StatusCode
      END     
 FROM @TblData T
 JOIN Lot L ON L.VarmasLot = T.LotNr
 JOIN RelationPtoV R ON R.GID = L.GID
 JOIN @Tbl T1 ON T1.GID = R.GID;


END  

GO

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
	S.StatusDescription,
	V.GenerationCode
FROM Variety V
JOIN [Status] S ON S.StatusCode = V.VarmasStatusCode AND S.StatusTable = 'VarmasStatus'
LEFT JOIN [File] F ON F.CropCode = V.CropCode  
WHERE ISNULL(V.ENumber, '') <> ''  
 AND V.StatusCode IN( 250 , 350) 
 AND V.SyncCode = @SyncCode
 AND V.CropCode = @CropCode;  
END  

GO

