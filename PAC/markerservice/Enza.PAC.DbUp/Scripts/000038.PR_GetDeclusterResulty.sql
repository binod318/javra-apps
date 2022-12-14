DROP PROCEDURE IF EXISTS PR_GetDeclusterResult
GO

--EXEC PR_GetDeclusterResult 4780
CREATE PROCEDURE PR_GetDeclusterResult
(
    @PeriodID INT
) AS BEGIN
    SET NOCOUNT ON;

    DECLARE @SQL NVARCHAR(MAX);
    DECLARE @Columns NVARCHAR(MAX);
    DECLARE @Variety TVP_Variety;
    DECLARE @Markers TABLE(MarkerID INT, MarkerName NVARCHAR(100), InIMS BIT);

    INSERT @Variety(DetAssignmentID, VarietyNr, VarietyName, Female, Male) 
    SELECT
	   DA.DetAssignmentID,
	   V.VarietyNr,
	   V.Shortname,
	   V.Female, 
	   V.Male
    FROM Test T
    JOIN TestDetAssignment TDA ON TDA.TestID = T.TestID
    JOIN DeterminationAssignment DA ON DA.DetAssignmentID = TDA.DetAssignmentID
    JOIN Variety V ON V.VarietyNr = DA.VarietyNr
    WHERE DA.StatusCode = 300 AND 
    T.PeriodID = @PeriodID;

    INSERT @Markers(MarkerID, MarkerName, InIMS)
    SELECT DISTINCT
	   M.MarkerID,
	   M.MarkerName,
	   MTT.InIMS
    FROM MarkerToBeTested MTT
    JOIN @Variety V ON V.DetAssignmentID = MTT.DetAssignmentID
    JOIN Marker M ON M.MarkerID = MTT.MarkerID

    SELECT 
	   @Columns  = COALESCE(@Columns + ',', '') + QUOTENAME(MarkerID)
    FROM @Markers C;

    SET @Columns = ISNULL(@Columns, '');

    SET @SQL = N'WITH CTE(DetAssignmentID, VarietyNr, VarietyName,  Female, Male, VarietyType, ParentVarietyNr) AS 
    (
	   SELECT 
		  V.DetAssignmentID,
		  V.VarietyNr,
		  V.VarietyName,
		  V.Female,
		  V.Male,
		  VarietyType = ''H'',
		  ParentVarietyNr = NULL 
	   FROM @Variety V
	   UNION ALL
	   SELECT 
		  V.DetAssignmentID,
		  V.VarietyNr,
		  V.VarietyName,
		  V.Female,
		  V.Male,
		  VarietyType = ''F'',
		  CTE.VarietyNr
	   FROM @Variety V
	   JOIN CTE ON CTE.Female = V.VarietyNr
	   UNION ALL
	   SELECT 
		  V.DetAssignmentID,
		  V.VarietyNr,
		  V.VarietyName,
		  V.Female,
		  V.Male,
		  VarietyType = ''M'',
		  CTE.VarietyNr
	   FROM @Variety V
	   JOIN CTE ON CTE.Male = V.VarietyNr
    )
    SELECT DISTINCT
	   CTE.DetAssignmentID,
	   CTE.VarietyNr, 
	   CTE.VarietyName,
	   CTE.ParentVarietynr, 
	   CTE.VarietyType ' +
	   CASE WHEN @Columns = '' THEN '' ELSE ', ' + @Columns END + 
    N'FROM CTE ' + 
    CASE WHEN @Columns = '' THEN '' ELSE
	   N'LEFT JOIN
	   (
		  SELECT * FROM 
		  (
			 SELECT 
				DA.DetAssignmentID,
				MTT.MarkerID,
				[Value] = MVP.AlleleScore
			 FROM MarkerToBeTested MTT
			 JOIN DeterminationAssignment DA ON DA.DetAssignmentID = MTT.DetAssignmentID
			 JOIN MarkerValuePerVariety MVP ON MVP.VarietyNr = DA.VarietyNr AND MVP.MarkerID = MTT.MarkerID
		  ) V
		  PIVOT
		  (
			 MAX([Value])
			 FOR MarkerID IN(' + @Columns + N')
		  ) P
	   ) M ON M.DetAssignmentID = CTE.DetAssignmentID '  
    END;

    EXEC sp_executesql @SQL, N'@Variety TVP_Variety READONLY', @Variety;

    SELECT 
	   ColumnID = MarkerID, 
	   ColumnLabel = MarkerName,
	   InIMS
    FROM @Markers;
END
GO