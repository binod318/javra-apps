
/*
    EXEC PR_GetFolderDetails 4792;
*/
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
	   CropCode	    NVARCHAR(10),
	   MethodCode	    NVARCHAR(100),
	   PlatformName    NVARCHAR(100),
	   NrOfPlates	    DECIMAL(6,2),
	   NrOfMarkers	    DECIMAL(6,2),
	   VarietyName	    NVARCHAR(200),
	   SampleNr	    INT,
	   IsLabPriority	    BIT
    );

    INSERT @tbl(DetAssignmentID, TestID, TestName, CropCode, MethodCode, PlatformName, NrOfPlates, NrOfMarkers, VarietyName, SampleNr, IsLabPriority)
    SELECT 
	   DA.DetAssignmentID,	   
	   T.TestID,
	   COALESCE(T.TestName, T.TempName),
	   C.CropCode,
	   DA.MethodCode, 
	   P.PlatformDesc,
	   V2.NrOfPlates,
	   V3.NrOfMarkers,
	   V.Shortname,
	   DA.SampleNr,
	   ISNULL(DA.IsLabPriority, 0)
    FROM Test T
    JOIN TestDetAssignment TDA ON TDA.TestID = T.TestID
    JOIN DeterminationAssignment DA ON DA.DetAssignmentID = TDA.DetAssignmentID
    JOIN ABSCrop C ON C.ABSCropCode = DA.ABSCropCode
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
	   CropCode,
	   MethodCode,
	   PlatformName,
	   NrOfPlates,
	   NrOfMarkers
    FROM
    (
	   SELECT 
		  V.*,
		  TempName = CAST(RIGHT(TestName, PATINDEX('%[^0-9]%', REVERSE(TestName)) - 1) AS INT)
	   FROM
	   (
		  SELECT
			 TestID,
			 TestName,
			 CropCode,
			 MethodCode,
			 PlatformName,
			 NrOfPlates = SUM(NrOfPlates),
			 NrOfMarkers = SUM(NrOfMarkers)
		  FROM @tbl
		  GROUP BY TestID, TestName, CropCode, MethodCode, PlatformName
	   ) V
    ) V2
    ORDER BY V2.TempName;

    SELECT
	   TestID,
	   TestName,
	   CropCode,
	   MethodCode,
	   PlatformName,
	   DetAssignmentID,
	   NrOfPlates,
	   NrOfMarkers,
	   VarietyName,
	   SampleNr,
	   IsLabPriority
    FROM @tbl;

    SELECT 
	   MIN(T2.StatusCode) AS StatusCode
    FROM @tbl T1
    JOIN Test T2 ON T2.TestID = T1.TestID;
END
GO