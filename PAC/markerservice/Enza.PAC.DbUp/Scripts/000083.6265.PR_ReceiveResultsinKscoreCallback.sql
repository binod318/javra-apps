DROP PROCEDURE IF EXISTS PR_ReceiveResultsinKscoreCallback
GO
/*
    DECLARE  @DataAsJson NVARCHAR(MAX) = N'[{"LIMSPlateID":21,"MarkerNr":67,"AlleleScore":"0101","Position":"A01"}]'
    EXEC PR_ReceiveResultsinKscoreCallback 432, @DataAsJson
*/
CREATE PROCEDURE PR_ReceiveResultsinKscoreCallback
(
    @RequestID	 INT, --TestID
    @DataAsJson NVARCHAR(MAX)
) AS BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
	   BEGIN TRANSACTION;

	   INSERT INTO TestResult(WellID, MarkerID, Score)
	   SELECT 
		  W.WellID,
		  T1.MarkerNr, 
		  T1.AlleleScore				
	   FROM OPENJSON(@DataAsJson) WITH
	   (
		  LIMSPlateID	INT,
		  MarkerNr	INT,
		  AlleleScore	NVARCHAR(20),
		  Position	NVARCHAR(20)
	   ) T1
	   JOIN Well W ON W.Position = T1.Position 
	   JOIN Plate P ON P.PlateID = W.PlateID AND P.LabPlateID = T1.LIMSPlateID 			
	   WHERE P.TestID = @RequestID
	   GROUP BY W.WellID, T1.MarkerNr, T1.AlleleScore;
	   
	   --update test status
	   UPDATE Test SET StatusCode = 500 WHERE TestID = @RequestID;
	   
	   COMMIT;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
            ROLLBACK;
		THROW;
	END CATCH    
END
GO