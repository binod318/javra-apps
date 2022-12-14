/*
Author					Date			Remarks
Krishna Gautam			2020/01/14		Created Stored procedure to fetch data of provided periodID
Binod Gurung			2020-jan-23		Transcation isolation level implemented to avoid record lock
Dibya			    2020-Feb-20		Added received date in column
Dibya			    2020-Feb-27		Added Variety name column in select list
=================EXAMPLE=============

EXEC PR_GetPlatesOverview 4792
*/

ALTER PROCEDURE [dbo].[PR_GetPlatesOverview]
(
	@PeriodID INT
)
AS 
BEGIN

	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
	DECLARE @PeriodName NVARCHAR(50);
	DECLARE @TempTBL TABLE (TestID INT, NrOfSeeds INT,PeriodName NVARCHAR(50));
	
	IF NOT EXISTS(SELECT PeriodID FROM [Period] WHERE PeriodID = @PeriodID)
	BEGIN
		EXEC PR_ThrowError 'Invalid PeriodID';
		RETURN;
	END
	
	SELECT @PeriodName = CONCAT(PeriodName, FORMAT(StartDate, ' (MMM-dd-yy - ', 'en-US' ), FORMAT(EndDate, 'MMM-dd-yy)', 'en-US' ))
	FROM [Period] WHERE PeriodID = @PeriodID;

    INSERT INTO @TempTBL(TestID, NrOfSeeds,PeriodName)
    SELECT T.TestID, M.NrOfSeeds, @PeriodName FROM Test T 
    JOIN TestDetAssignment TDA ON T.TestID = TDA.TestID
    JOIN DeterminationAssignment DA ON DA.DetAssignmentID = TDA.DetAssignmentID
    JOIN Method M ON M.MethodCode = DA.MethodCode
    WHERE T.PeriodID = @PeriodID
    GROUP BY T.TestID, NrOfSeeds;
	
    SELECT 
	   T.FolderNr, 
	   T.PlateID, 
	   T.PlateNumber,
	   Position =  CASE WHEN (T.NrOfSeeds = 23 AND (T.Position IN ('A-B', 'C-D', 'E-F', 'G-H'))) THEN REPLACE(T.Position, '-', '+')
				     WHEN T.NrOfSeeds >=92 THEN ''
				ELSE T.Position
				END,
	   DA.BatchNr, 
	   DA.SampleNr, 
	   PeriodName = @PeriodName,
	   ReportType = CASE 
				    WHEN T.NrOfSeeds = 23 THEN 1
				    WHEN T.NrOfSeeds = 46 THEN 2
				    WHEN T.NrOfSeeds >=92 THEN 3
				END,
	   ReceiveDate = FORMAT(DA.ReceiveDate, 'dd/MM/yyyy', 'en-US'),
	   VarietyName = V.Shortname
	FROM 
	(
	    SELECT 
		    FolderNr = MAX(T.TestName),
		    W.PlateID,  
		    PlateNumber = MAX(P.PlateName) , 
		    Position = CONCAT(LEFT(MIN(w.Position), 1), '-', LEFT(MAX(w.Position), 1)), 
		    W.DetAssignmentID,
		    T.TestID,
		    NrOfSeeds = MAX(T1.NrOfSeeds)
	    FROM Test T
	    JOIN @TempTBL T1 ON T1.TestID = T.TestID
	    JOIN Plate p ON T.TestID = P.TestID
	    JOIN Well W on W.PlateID = P.PlateID	    
	    WHERE W.Position NOT IN ('B01','D01','F01','H01') AND T.PeriodID = @PeriodID
	    GROUP BY T.TestID, W.DetAssignmentID, W.PlateID 
	) T
	LEFT JOIN DeterminationAssignment DA ON DA.DetAssignmentID = T.DetAssignmentID
     LEFT JOIN Method M ON M.MethodCode = DA.MethodCode	
	LEFT JOIN Variety V ON V.VarietyNr = DA.VarietyNr
	ORDER BY T.NrOfSeeds, T.PlateID, Position;
END
GO