DROP PROCEDURE IF EXISTS [dbo].[PR_ReceiveResultsinKscoreCallback]
GO

/*

Author					Date			Remarks
Binod Gurung			-				-
Krishna Gautam			2020/01/20		Change on stored procedure to adjust logic of data is sent to LIMS for retest for specific determination but in response we get all result of that folder back.


============ExAMPLE===================
DECLARE  @DataAsJson NVARCHAR(MAX) = N'[{"LIMSPlateID":21,"MarkerNr":67,"AlleleScore":"0101","Position":"A01"}]'
EXEC PR_ReceiveResultsinKscoreCallback 331, @DataAsJson
*/
CREATE PROCEDURE [dbo].[PR_ReceiveResultsinKscoreCallback]
(
    @RequestID	 INT, --TestID
    @DataAsJson NVARCHAR(MAX)
) AS BEGIN
	DECLARE @Tbl TABLE (WellID INT, MarkerNr INT, AlleleScore NVARCHAR(10), CreationDate DATETIME, DetAssignmentID INT);

    SET NOCOUNT ON;
    BEGIN TRY
	   BEGIN TRANSACTION;

	   INSERT @Tbl
	   SELECT 
			W.WellID,
			T1.MarkerNr, 
			T1.AlleleScore,
			T1.CreationDate,
			W.DetAssignmentID				
		FROM OPENJSON(@DataAsJson) WITH
		(
			LIMSPlateID	INT,
			MarkerNr	INT,
			AlleleScore	NVARCHAR(20),
			Position	NVARCHAR(20),
			CreationDate DATETIME
		) T1
		JOIN Well W ON W.Position = T1.Position 
		JOIN Plate P ON P.PlateID = W.PlateID AND P.LabPlateID = T1.LIMSPlateID 			
		WHERE P.TestID = @RequestID
		GROUP BY W.WellID, T1.MarkerNr, T1.AlleleScore, T1.CreationDate, W.DetAssignmentID

	   --INSERT ONLY Not existed record, because when we re-do the test, then only test result data for selected determination is removed..
	   --rest of the data is already there and we are not allowed to change already existing data.
	   MERGE INTO TestResult T
	   USING @Tbl S ON S.WellID = T.WellID AND S.MarkerNr = T.MarkerID
	   WHEN NOT MATCHED 
	   THEN INSERT(WellID, MarkerID, Score, CreationDate)
	   VALUES(S.WellID, S.MarkerNr,S.AlleleScore, S.CreationDate);
	   	   
	   --update test status
	   UPDATE Test SET StatusCode = 500 WHERE TestID = @RequestID;

	   --update determination assignment status
	   UPDATE DA
		 SET DA.StatusCode = 500
	   FROM DeterminationAssignment DA
	   JOIN TestDetAssignment TDA ON TDA.DetAssignmentID = DA.DetAssignmentID
	   JOIN @Tbl TB ON TB.DetAssignmentID = DA.DetAssignmentID
	   WHERE TDA.TestID = @RequestID	   
	   
	   COMMIT;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
            ROLLBACK;
		THROW;
	END CATCH    
END
GO


