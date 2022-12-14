-- EXEC PR_GetFolderDetails 4785
ALTER PROCEDURE [dbo].[PR_GetFolderDetails]
(
    @PeriodID	 INT
) AS BEGIN
    SET NOCOUNT ON;

    DECLARE @tbl TABLE
    (
	   DetAssignmentID INT,
	   TestID		    INT,
	   TestName	    NVARCHAR(200),
	   ABSCropCode	    NVARCHAR(10),
	   MethodCode	    NVARCHAR(100),
	   PlatformName    NVARCHAR(100),
	   NrOfPlates	    DECIMAL(6,2),
	   NrOfMarkers	    DECIMAL(6,2),
	   TraitMarkers    BIT,
	   VarietyName	    NVARCHAR(200),
	   SampleNr	    INT
    );

    INSERT @tbl(DetAssignmentID, TestID, TestName, ABSCropCode, MethodCode, PlatformName, NrOfPlates, NrOfMarkers, TraitMarkers, VarietyName, SampleNr)
    SELECT 
	   DA.DetAssignmentID,	   
	   T.TestID,
	   COALESCE(T.TestName, T.TempName),
	   DA.ABSCropCode,
	   DA.MethodCode, 
	   P.PlatformDesc,
	   V2.NrOfPlates,
	   V3.NrOfMarkers,
	   0,
	   V.Shortname,
	   DA.SampleNr
    FROM Test T
    JOIN TestDetAssignment TDA ON TDA.TestID = T.TestID
    JOIN DeterminationAssignment DA ON DA.DetAssignmentID = TDA.DetAssignmentID
    JOIN Method M ON M.MethodCode = DA.MethodCode
    JOIN CropMethod CM ON CM.ABSCropCode = DA.ABSCropCode AND CM.MethodID = M.MethodID
    JOIN [Platform] P ON P.PlatformID = CM.PlatformID
    JOIN Variety V ON V.VarietyNr = DA.VarietyNr
    LEFT JOIN
    (
	   SELECT 
		  MethodID,
		  NrOfPlates = NrOfSeeds/92.0
	   FROM Method
    ) V2 ON V2.MethodID = M.MethodID
    LEFT JOIN 
    (
	   SELECT 
		   DetAssignmentID,
		   NrOfMarkers = COUNT(MarkerID)
	   FROM MarkerToBeTested
	   GROUP BY DetAssignmentID
    ) V3 ON V3.DetAssignmentID = DA.DetAssignmentID
    WHERE T.PeriodID = @PeriodID;

    --create groups
    SELECT
	   TestID,
	   TestName,
	   ABSCropCode,
	   MethodCode,
	   PlatformName,
	   TraitMarkers,
	   NrOfPlates = SUM(NrOfPlates),
	   NrOfMarkers = SUM(NrOfMarkers)
    FROM @tbl
    GROUP BY TestID, TestName, ABSCropCode, MethodCode, PlatformName, TraitMarkers
    ORDER BY TestName;

    SELECT
	   TestID,
	   TestName,
	   ABSCropCode,
	   MethodCode,
	   PlatformName,
	   TraitMarkers,
	   DetAssignmentID,
	   NrOfPlates,
	   NrOfMarkers,
	   VarietyName,
	   SampleNr
    FROM @tbl;
END
GO