DROP PROCEDURE IF EXISTS [dbo].[PR_SaveCapacity]
GO

/*
Author					Date			Description
Krishna Gautam			2019-Jul-05		Service created to save pac capacity

===================================Example================================

DECLARE @DataAsJson NVARCHAR(MAX) = N'
[
	{"PeriodID":4744,"PlatformID":"Remarks","value":"Remarks"}
]';
EXEC PR_SaveCapacity @DataAsJson;
*/
CREATE PROCEDURE [dbo].[PR_SaveCapacity]
(
	@Json NVARCHAR(MAX)
)
AS 
BEGIN
	 SET NOCOUNT ON;
	 DECLARE @PlatformID INT;
	 DECLARE @FilledCapacity TABLE (PeriodID INT,PlatformID INT, Val INT);	 

	 BEGIN TRY
		BEGIN TRANSACTION;

			SELECT 
				 @PlatformID = PlatformID 
			FROM [Platform] 
			WHERE PlatformDesc = 'Lightscanner';

			--Fill temptable from Input Json
			INSERT INTO @FilledCapacity(PeriodID, PlatformID, Val)
			SELECT PeriodID, PlatformID, Val
			FROM OPENJSON(@Json) WITH
			(
				PeriodID	INT '$.PeriodID',
				PlatformID	NVARCHAR(MAX) '$.PlatformID',
				Val			NVARCHAR(MAX) '$.Value'
			)
			WHERE ISNUMERIC(PlatformID) = 1;

			--If planned capacity is greater than lab capacity then return error
			IF EXISTS 
			(
				SELECT * FROM @FilledCapacity C
				JOIN
				(
					SELECT FC.PeriodID, FC.PlatformID, SUM(RC.NrOfPlates) AS TotalPlates FROM @FilledCapacity FC 
					JOIN CropMethod CM ON CM.PlatformID = FC.PlatformID
					JOIN ReservedCapacity RC ON RC.CropMethodID = CM.CropMethodID AND RC.PeriodID = FC.PeriodID
					GROUP BY FC.PeriodID, FC.PlatformID
				) T1 ON T1.PeriodID = C.PeriodID AND T1.PlatformID = C.PlatformID
				WHERE T1.TotalPlates > C.Val
			)
			BEGIN
				EXEC PR_ThrowError 'Unable to update lab capacity. More capacity planned already.';
				RETURN
			END	

		
			--update capacity 
			MERGE INTO Capacity T
			USING
			(
				SELECT DISTINCT * FROM OPENJSON(@Json) WITH
				(
					PeriodID INT '$.PeriodID',
					PlatformID NVARCHAR(MAX) '$.PlatformID',
					Val NVARCHAR(MAX) '$.Value'
				) T1
				WHERE ISNUMERIC(PlatformID) = 1

			) S ON S.PeriodID = T.PeriodID AND S.PlatformID = CAST(T.PlatformID AS NVARCHAR(10))
			WHEN NOT MATCHED THEN
			  INSERT(PeriodID,PlatformID,NrOfPlates)  VALUES(S.PeriodID,CAST(S.PlatformID AS INT),CAST(S.val AS INT))
			WHEN MATCHED THEN
			  UPDATE SET T.NrOfPlates = S.val;

			-- Update remarks here
			MERGE INTO Capacity T
			USING
			(
				SELECT * FROM OPENJSON(@Json) WITH
				(
					PeriodID INT '$.PeriodID',
					PlatformID NVARCHAR(MAX) '$.PlatformID',
					Remarks NVARCHAR(MAX) '$.Value'
				) T1
				WHERE PlatformID = 'Remarks'

			) S ON S.PeriodID = T.PeriodID AND T.PlatformID = @PlatformID
			WHEN NOT MATCHED THEN			
				INSERT(PeriodID,PlatformID,NrOfPlates,Remarks)  VALUES(S.PeriodID, @PlatformID, 0, S.Remarks)
			WHEN MATCHED THEN
				UPDATE SET T.Remarks = S.Remarks;

		COMMIT;
	END TRY
	BEGIN CATCH
		ROLLBACK;
		THROW;
	END CATCH
END
GO


