DROP PROCEDURE IF EXISTS [dbo].[PR_SavePlanningCapacitySO_LS]
GO

/*
Author					Date			Description
Krishna Gautam			2019-Jul-09		Service created to save capacity planning for SO for Lightscanner

===================================Example================================

DECLARE @DataAsJson NVARCHAR(MAX) = N'
[
	{
    "CropMethodID": 95,
    "PeriodID": 4778,
    "Value": 1
  },
	{
    "CropMethodID": 96,
    "PeriodID": 4778,
    "Value": 5
  }
]';
EXEC PR_SavePlanningCapacitySO_LS @DataAsJson;
*/

CREATE PROCEDURE [dbo].[PR_SavePlanningCapacitySO_LS]
(
	@Json NVARCHAR(MAX)
)
AS
BEGIN
	DECLARE @PlatformID INT;
	DECLARE @UpdateCapacity TABLE (CropMethodID INT,PeriodID INT, NrOfPlates INT);
	DECLARE @ExceededCapacityWeek TABLE (PeriodID INT,PeriodName NVARCHAR(MAX));
	DECLARE @RowCount INT;

    INSERT INTO @UpdateCapacity(CropMethodID, PeriodID, NrOfPlates)
    SELECT CropMethodID, PeriodID, NrOfPlates
    FROM OPENJSON(@Json) WITH
    (
	   CropMethodID	 INT '$.CropMethodID',
	   PeriodID	      INT '$.PeriodID',
	   NrOfPlates		 INT	'$.Value'
    ) T1;	  
    --check validation if platform used in this reserve capacity is available in Capacity table
    IF EXISTS
    (
	   SELECT 
		  UC.CropMethodID 
	   FROM @UpdateCapacity UC
	   JOIN CropMethod CM ON CM.CropMethodID = UC.CropMethodID
	   LEFT JOIN Capacity C ON C.PlatformID = CM.PlatformID AND C.PeriodID = UC.PeriodID
	   WHERE C.PlatformID IS NULL
    ) BEGIN
	   EXEC PR_ThrowError 'Insufficient capacity defined in Capacity screen.';
	   RETURN
    END    

	SET NOCOUNT ON;
	 BEGIN TRY
		BEGIN TRANSACTION;		  
		  SELECT 
			 @PlatformID = PlatformID 
		  FROM [Platform] 
		  WHERE PlatformDesc = 'Lightscanner';
		  IF(ISNULL(@platformID, 0) = 0)
		  BEGIN
			 EXEC PR_ThrowError 'Lightscanner platform does not exist.';
			 RETURN
		  END

		  MERGE INTO ReservedCapacity T
		  USING  @UpdateCapacity S ON S.CropMethodID = T.CropMethodID AND S.PeriodID = T.PeriodID
		  WHEN NOT MATCHED THEN 
			 INSERT (CropMethodID,PeriodID,NrOfPlates)				
			 VALUES (S.CropMethodID, PeriodID,S.NrOfPlates)
		  WHEN MATCHED THEN 
			 UPDATE SET NrOFPlates = S.NrOfPlates;

		  INSERT INTO @ExceededCapacityWeek(PeriodID)
		  SELECT PeriodID 
		  FROM 
		  (
			 SELECT RC.PeriodID, SUM(RC.NrOfPlates) AS ReservedCapacity, ISNULL(MAX(PC.NrOfPlates), 0) AS AvailableCapacity  
			 FROM 
			 (
				SELECT PeriodID FROM @UpdateCapacity
				GROUP BY PeriodID
			 ) UC
			 JOIN ReservedCapacity RC ON RC.PeriodID = UC.PeriodID
			 RIGHT JOIN Capacity PC ON PC.PeriodID = UC.PeriodID 
			 WHERE PC.PlatformID = @PlatformID
			 GROUP BY RC.PeriodID
		  ) T
		  WHERE T.ReservedCapacity > T.AvailableCapacity
		  
		  SELECT @RowCount = COUNT(PeriodID) FROM @ExceededCapacityWeek;

		  IF(ISNULL(@RowCount,0) > 0)
		  BEGIN
			
			 MERGE INTO @ExceededCapacityWeek S
			 USING [Period] T ON T.PeriodID = S.PeriodID
			 WHEN MATCHED THEN
				UPDATE SET S.PeriodName = T.PeriodName;

			 SELECT PeriodID,PeriodName FROM @ExceededCapacityWeek;

			 ROLLBACK;
			 RETURN;
		  END
		
		  SELECT PeriodID,PeriodName FROM @ExceededCapacityWeek;		
	COMMIT;
	END TRY
	BEGIN CATCH
		ROLLBACK;
		THROW;
	END CATCH
END

GO
