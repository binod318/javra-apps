/*
Author					Date			Description
Binod Gurung			2020-jan-23		Transcation isolation level implemented to avoid record lock	
Krishna Gautam			2020/02/19		Calculation of nr of marker is done per plate on group level.
Dibya			    2020/02/20		     Made #plates as absolute number.

===================================Example================================

    EXEC PR_GetFolderDetails 4792;
	
*/
ALTER PROCEDURE [dbo].[PR_GetFolderDetails]
(
    @PeriodID	 INT
) 
AS 
BEGIN
    SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    DECLARE @tbl TABLE
    (
		ID INT IDENTITY(1,1),
	   DetAssignmentID INT,
	   TestID		    INT,
	   TestName	    NVARCHAR(200),
	   CropCode	    NVARCHAR(10),
	   MethodCode	    NVARCHAR(100),
	   PlatformName    NVARCHAR(100),
	   NrOfPlates	    DECIMAL(6,2),
	   NrOfMarkers	    DECIMAL(6,2),
	   VarietyNr	    INT,
	   VarietyName	    NVARCHAR(200),
	   SampleNr	    INT,
	   IsLabPriority   INT,
	   IsParent	    BIT,
	   TraitMarkers BIT,
	   Markers VARCHAR(MAX),
	   TempPlateID INT
    );
	
    INSERT @tbl(DetAssignmentID, TestID, TestName, CropCode, MethodCode, PlatformName, NrOfPlates, NrOfMarkers, VarietyNr, VarietyName, SampleNr, IsLabPriority, IsParent, TraitMarkers,Markers,TempPlateID)
    SELECT 
	   DA.DetAssignmentID,	   
	   T.TestID,
	   T.TestName,
	   C.CropCode,
	   DA.MethodCode, 
	   P.PlatformDesc,
	   V2.NrOfPlates,
	   CASE WHEN NrOfPlates >=1 THEN V3.NrOfMarkers * NrOfPlates ELSE NrOfMarkers END,
	   V.VarietyNr,
	   V.Shortname,
	   DA.SampleNr,
	   ISNULL(DA.IsLabPriority, 0),
	   CASE WHEN V.HybOp = 0 AND V.[Type] = 'P' THEN 1 ELSE 0 END,
	   TraitMarkers = CAST (CASE WHEN ISNULL(V4.TraitMarker,0) = 0 THEN 0 ELSE 1 END As BIT),
	   Markers = STUFF((SELECT DISTINCT ',', + CAST(MTT.MarkerID AS NVARCHAR(50))
							FROM MarkerToBeTested MTT
							WHERE MTT.DetAssignmentID =  DA.DetAssignmentID
							FOR XML PATH('')
						),1,1,''),
		TempPlateID = CEILING(SUM(ISNULL(NrOfPlates,0)) OVER (Partition by T.Testid Order by C.CropCode ASC, DA.MethodCode ASC, P.PlatformDesc ASC, ISNULL(DA.IsLabPriority, 0) DESC, CASE WHEN V.HybOp = 0 AND V.[Type] = 'P' THEN 1 ELSE 0 END DESC, DA.DetAssignmentID ASC) /1)
		
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
		   NrOfMarkers = COUNT( DISTINCT MarkerID)
	   FROM MarkerToBeTested
	   GROUP BY DetAssignmentID
    ) V3 ON V3.DetAssignmentID = DA.DetAssignmentID
	LEFT JOIN 
	(
		SELECT DA.DetAssignmentID, TraitMarker = MAX(MPV.MarkerID) FROM DeterminationAssignment DA
		JOIN Variety V ON V.VarietyNr = DA.VarietyNr
		JOIN MarkerPerVariety MPV ON MPV.VarietyNr = V.VarietyNr
		WHERE MPV.StatusCode = 100
		GROUP BY DetAssignmentID
	) V4 ON V4.DetAssignmentID = DA.DetAssignmentID
    WHERE T.PeriodID = @PeriodID
	ORDER BY C.CropCode ASC, DA.MethodCode ASC, P.PlatformDesc ASC, ISNULL(DA.IsLabPriority, 0) DESC, CASE WHEN V.HybOp = 0 AND V.[Type] = 'P' THEN 1 ELSE 0 END DESC, DA.DetAssignmentID ASC

	

    --create groups
    SELECT 
	   V2.TestID,
	   TestName = COALESCE(V2.TestName, 'Folder ' + CAST(ROW_NUMBER() OVER(ORDER BY V2.CropCode, V2.MethodCode) AS VARCHAR)),
	   V2.CropCode,
	   V2.MethodCode,
	   V2.PlatformName,
	   NrOfPlates = CEILING(V2.NrOfPlates), --making absolute number for plates
	   NrOfMarkers = T1.TotalMarkers,
	   TraitMarkers,
	   IsLabPriority --CAST(0 AS BIT)
    FROM
    (
	   SELECT 
		  V.*,
		  T.TestName,
		  TraitMarkers = CAST (CASE WHEN ISNULL(V2.TraitMarker,0) = 0 THEN 0 ELSE 1 END As BIT)
	   FROM
	   (
		  SELECT
			 TestID,
			 CropCode,
			 MethodCode,
			 PlatformName,
			 NrOfPlates = SUM(NrOfPlates),
			 NrOfMarkers = SUM(NrOfMarkers),
			 IsLabPriority = CAST( MAX(IsLabPriority) AS BIT)
		  FROM @tbl
		  GROUP BY TestID, CropCode, MethodCode, PlatformName
	   ) V
	   JOIN Test T ON T.TestID = V.TestID
	   LEFT JOIN
	   (
			SELECT TD.TestID, TraitMarker = MAX(MPV.MarkerID) FROM TestDetAssignment TD
			JOIN DeterminationAssignment DA On DA.DetAssignmentID = TD.DetAssignmentID
			JOIN Variety V ON V.VarietyNr = DA.VarietyNr
			JOIN MarkerPerVariety MPV ON MPV.VarietyNr = V.VarietyNr
			WHERE MPV.StatusCode = 100
			GROUP BY TestID
	   ) V2 On V2.TestID = T.TestID
    ) V2
	JOIN 
	(
		SELECT TestID, TotalMarkers = SUM(TotalMarkers)
		FROM 
		(
			SELECT TestID,
				TotalMarkers = CASE 
									WHEN NrOfPlates >=1 THEN NrOfPlates * COUNT(DISTINCT [Value]) 
									ELSE COUNT(DISTINCT [Value]) END 
			FROM 
			(
				SELECT TempPlateID, TestID, NrOFPlates = MAX(NrOfPlates), TotalMarkers = ISNULL(STUFF(
										(SELECT DISTINCT  ',' + Markers
											FROM @tbl T1 WHERE  T1.TempPlateID = T2.TempPlateID AND T1.TestID = T2.TestID
											FOR XML PATH('')
										),1,1,''),'')
										FROM @tbl T2 
										GROUP BY TestID, TempPlateID
			)T
			OUTER APPLY 
			( 
				SELECT [Value] FROM string_split(TotalMarkers,',')
				WHERE ISNULL([Value],'') <> ''
			) T1
			GROUP BY T.TestID, T.TempPlateID,T.TotalMarkers,T.NrOFPlates
		) T1 GROUP BY TestID
	) T1
	ON T1.TestID = V2.TestID
	ORDER BY CropCode, MethodCode

    SELECT
	   T.TestID,
	   TestName = NULL,--just to manage column list in client side.
	   CropCode,
	   MethodCode,
	   PlatformName,
	   DetAssignmentID,
	   NrOfPlates,
	   NrOfMarkers,
	   VarietyName,
	   SampleNr,
	   IsParent = CAST(CASE WHEN DetAssignmentID % 2 = 0 THEN 1 ELSE 0 END AS BIT),
	   IsLabPriority = CAST(IsLabPriority AS BIT),
	   TraitMarkers
    FROM @tbl T
	
	ORDER BY CropCode ASC, MethodCode ASC, PlatformName ASC, ISNULL(IsLabPriority, 0) DESC, IsParent desc, DetAssignmentID ASC;


    SELECT 
	   MIN(T2.StatusCode) AS StatusCode
    FROM @tbl T1
    JOIN Test T2 ON T2.TestID = T1.TestID;

END
