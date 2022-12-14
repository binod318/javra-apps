
DROP PROCEDURE IF EXISTS [dbo].[PR_ReTestDetermination]
GO

/*
Author					Date			Remarks
Krishna Gautam			2020/01/10		Created service to approve determinationAssignment to re-test.

============ExAMPLE===================
--EXEC PR_ReTestDetermination 125487
*/
CREATE PROCEDURE [dbo].[PR_ReTestDetermination]
(
	@ID INT
)
AS 
BEGIN

	DELETE TR FROM TestResult TR
	JOIN Well W ON W.WellID = TR.WellID
	WHERE W.DetAssignmentID = @ID;


	UPDATE DeterminationAssignment SET StatusCode = 650
	WHERE DetAssignmentID = @ID;
END
GO


DROP PROCEDURE IF EXISTS [dbo].[PR_ApproveDetermination]
GO

/*
Author					Date			Remarks
Krishna Gautam			2020/01/10		Created service to approve determinationAssignment to approved.

============ExAMPLE===================
--EXEC PR_ApproveDetermination 125487
*/
CREATE PROCEDURE [dbo].[PR_ApproveDetermination]
(
	@ID INT
)
AS 
BEGIN
	DECLARE @TestID INT;

	SELECT TOP 1 @TestID = TestID FROM TestDetAssignment WHERE DetAssignmentID = @ID;

	UPDATE DeterminationAssignment SET StatusCode = 700
	WHERE DetAssignmentID = @ID;

	IF NOT EXISTS(SELECT * FROM TestDetAssignment TDA JOIN DeterminationAssignment DA ON DA.DetAssignmentID = TDA.TestDetAssignmentID
	WHERE TDA.TestID = @TestID AND DA.StatusCode NOT IN (700,999))
	BEGIN
		UPDATE Test SET StatusCode = 600 WHERE TestID = @TestID;
	END
END
GO


/*

Author					Date			Remarks
Binod Gurung			-				-
Krishna Gautam			2020/01/20		Change on stored procedure to adjust logic of data is sent to LIMS for retest for specific determination but in response we get all result of that folder back.


============ExAMPLE===================
DECLARE  @DataAsJson NVARCHAR(MAX) = N'[{"LIMSPlateID":21,"MarkerNr":67,"AlleleScore":"0101","Position":"A01"}]'
EXEC PR_ReceiveResultsinKscoreCallback 331, @DataAsJson
*/
ALTER PROCEDURE [dbo].[PR_ReceiveResultsinKscoreCallback]
(
    @RequestID	 INT, --TestID
    @DataAsJson NVARCHAR(MAX)
) AS BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
	   BEGIN TRANSACTION;


	   --INSERT ONLY Not existed record, because when we re-do the test, then only test result data for selected determination is removed..
	   --rest of the data is already there and we are not allowed to change already existing data.
	   MERGE INTO TestResult T
	   USING
	   (
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
		   GROUP BY W.WellID, T1.MarkerNr, T1.AlleleScore

	   ) S ON S.WellID = T.WellID AND S.MarkerNr = T.MarkerID
	   WHEN NOT MATCHED 
	   THEN INSERT(WellID, MarkerID, Score)
	   VALUES(S.WellID, S.MarkerNr,S.AlleleScore);
	   	   
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