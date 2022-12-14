DROP PROCEDURE IF EXISTS [dbo].[PR_GetNrOFPlatesAndTests]
GO



/*
Author					Date			Description
Binod Gurung			2020-jan-23		Transcation isolation level implemented to avoid record lock	
Krishna Gautam			2020/02/19		Calculation of nr of marker is done per plate on group level.
Dibya					2020/02/20		Made #plates as absolute number.
Binod Gurung			2022-may-09		FN_IsParent function used for parent check
===================================Example================================

    EXEC [PR_GetNrOFPlatesAndTests] 4796, 'ON', NULL;
	
*/
CREATE PROCEDURE [dbo].[PR_GetNrOFPlatesAndTests]
(
    @PeriodID	 INT,
	@HybridAsParentCrop		NVARCHAR(10),
	@StatusCode	 INT = NULL
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
	DetAssignmentID,
	TestID,
	TestName,
	CropCode,
	MethodCode, 
	PlatformDesc,
	NrOfPlates,
	NrOfMarkers,
	VarietyNr,
	Shortname,
	SampleNr,
	IsLabPriority,
	Prio,
	TraitMarkers,
	Markers = ISNULL(Markers,'') + ',' + ISNULL(Markers1,''),  --COALESCE( Markers1 +',', Markers),
	TempPlateID
	FROM 
	(
	
	SELECT 
	   DA.DetAssignmentID,	   
	   T.TestID,
	   T.TestName,
	   C.CropCode,
	   DA.MethodCode, 
	   P.PlatformDesc,
	   V2.NrOfPlates,
	   NrOfMarkers =  CASE WHEN NrOfPlates >=1 THEN V3.NrOfMarkers * NrOfPlates ELSE NrOfMarkers END,
	   V.VarietyNr,
	   V.Shortname,
	   DA.SampleNr,
	   IsLabPriority = ISNULL(DA.IsLabPriority, 0),
	   Prio = dbo.FN_IsParent(V.VarietyNr, @HybridAsParentCrop),
	   TraitMarkers = CAST (CASE WHEN ISNULL(V4.TraitMarker,0) = 0 THEN 0 ELSE 1 END As BIT),
	   Markers = STUFF((SELECT DISTINCT ',', + CAST(MTT.MarkerID AS NVARCHAR(50) )
							FROM
							MarkerToBeTested MTT
							WHERE MTT.DetAssignmentID =  DA.DetAssignmentID
							FOR XML PATH('')
						),1,1,''),
		Markers1 = STUFF((SELECT DISTINCT ',', + CAST(MTT.MarkerID AS NVARCHAR(50))
							FROM
							(
								SELECT DA.DetAssignmentID, MarkerID FROM MarkerPerVariety MPV
								JOIN Variety V ON V.VarietyNr = MPV.VarietyNr
								JOIN DeterminationAssignment DA ON DA.VarietyNr = V.VarietyNr
								WHERE MPV.StatusCode = 100

							)MTT
							WHERE MTT.DetAssignmentID =  DA.DetAssignmentID
							FOR XML PATH('')
						),1,1,''),
		TempPlateID = CEILING(SUM(ISNULL(NrOfPlates,0)) OVER (Partition by T.Testid Order by C.CropCode ASC, DA.MethodCode ASC, P.PlatformDesc ASC, ISNULL(DA.IsLabPriority, 0) DESC, CASE WHEN V.[Type] = 'P' THEN 1 ELSE 0 END DESC, DA.DetAssignmentID ASC) /1),
		Plates = STUFF((SELECT DISTINCT ', ' + PlateName 
							FROM 
							(
								SELECT 
									DA.DetAssignmentID,
									PlateName = MAX(P.PlateName) 
								FROM DeterminationAssignment DA
								JOIN Well W ON W.DetAssignmentID =DA.DetAssignmentID
								JOIN Plate p ON p.PlateID = W.PlateID
								--WHERE T.PeriodID = @PeriodID
								GROUP BY Da.DetAssignmentID, P.PlateID

							)P1
							
						WHERE P1.DetAssignmentID = DA.DetAssignmentID
						--GROUP BY P1.DetAssignmentID,P1.PlateName
					FOR XML PATH('')
					),1,1,'')
		
    FROM Test T
    JOIN TestDetAssignment TDA ON TDA.TestID = T.TestID
    JOIN DeterminationAssignment DA ON DA.DetAssignmentID = TDA.DetAssignmentID
    JOIN ABSCrop C ON C.ABSCropCode = DA.ABSCropCode
    JOIN Method M ON M.MethodCode = DA.MethodCode
    JOIN CropMethod CM ON CM.ABSCropCode = DA.ABSCropCode AND CM.MethodID = M.MethodID
    JOIN [Platform] P ON P.PlatformID = CM.PlatformID
	--handle if same method is used for hybrid and parent
    JOIN
	(
		SELECT 
			VarietyNr, 
			Shortname,
			[Type],
			UsedFor = CASE WHEN dbo.FN_IsParent(VarietyNr, @HybridAsParentCrop) = 0 THEN 'Hyb' ELSE 'Par' END
		FROM Variety
	) V ON V.VarietyNr = DA.VarietyNr AND V.UsedFor = CM.UsedFor
    LEFT JOIN
    (
	   SELECT 
		  MethodID,
		  NrOfPlates = NrOfSeeds/92.0
	   FROM Method
    ) V2 ON V2.MethodID = M.MethodID
    LEFT JOIN 
    (
		SELECT DetAssignmentID, NrOfMarkers = COUNT(MarkerID) FROM
		(
			SELECT DetAssignmentID, MarkerID FROM
			MarkerToBeTested
			UNION
			(
				SELECT DA.DetAssignmentID, MPV.MarkerID FROM DeterminationAssignment DA
				JOIN Variety V ON V.VarietyNr = DA.VarietyNr
				JOIN MarkerPerVariety MPV ON MPV.VarietyNr = V.VarietyNr
				WHERE MPV.StatusCode = 100
			)
		) D
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
	WHERE (ISNULL(@PeriodID,0) = 0 OR T.PeriodID = @PeriodID)
	) T1
	ORDER BY T1.CropCode ASC, T1.MethodCode ASC, T1.PlatformDesc ASC, ISNULL(T1.IsLabPriority, 0) DESC, Prio DESC, T1.DetAssignmentID ASC
		
    --create groups
    SELECT 
	   V2.TestID,
	   NrOfPlates = CEILING(V2.NrOfPlates), --making absolute number for plates
	   NrOfMarkers = T1.TotalMarkers,
	   IsLabPriority
    FROM
    (
	   SELECT
			TestID,
			NrOfPlates = SUM(NrOfPlates),
			NrOfMarkers = SUM(NrOfMarkers),
			IsLabPriority = CAST( MAX(IsLabPriority) AS BIT)
		FROM @tbl
		GROUP BY TestID, CropCode, MethodCode, PlatformName   
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
    
END
GO


DROP PROCEDURE IF EXISTS [dbo].[PR_GetTestInfoForLIMS]
GO


/*
Author					Date			Description
Binod Gurung			2019/10/22		Pull Test Information for input period for LIMS
Binod Gurung			2020-jan-23		Transcation isolation level implemented to avoid record lock
Binod Gurung			2021-dec-17		Expected Week and Planned Week is used from Period table not from DATEPART(WEEK) function because it doesn't match
Binod Gurung			2022-jan-03		Material type value now used from criteripercrop table, before it was hardcoded [#30582]
Binod Gurung			2022-may-09		FN_IsParent function used for parent check [#34494]

===================================Example================================

EXEC PR_GetTestInfoForLIMS 4805, 'ON'
EXEC PR_GetTestInfoForLIMS 0, 'ON'
*/
CREATE PROCEDURE [dbo].[PR_GetTestInfoForLIMS]
(
	@PeriodID INT,
	@HybridAsParentCrop		NVARCHAR(10)
)
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

	DECLARE @TestPlates TABLE (TestID INT, NrOfPlates INT, NrOfMarkes INT, IsLabPrioity BIT);
	
	INSERT @TestPlates (TestID, NrOfPlates, NrOfMarkes, IsLabPrioity)
	EXEC PR_GetNrOFPlatesAndTests @PeriodID, @HybridAsParentCrop, 150;

	SELECT 
	   T1.ContainerType,
	   T1.CountryCode,
	   T1.CropCode,
	   ExpectedDate = FORMAT(T1.ExpectedDate, 'yyyy-MM-dd', 'en-US'),
	   ExpectedWeek = CAST (SUBSTRING(P1.PeriodName, CHARINDEX(' ', P1.PeriodName) + 1, 2) AS INT), --DATEPART(WEEK, T1.ExpectedDate),
	   ExpectedYear = YEAR(T1.ExpectedDate),
	   T1.Isolated,
	   T1.MaterialState,
	   T1.MaterialType,
	   PlannedDate = FORMAT(T1.PlannedDate, 'yyyy-MM-dd', 'en-US'),
	   PlannedWeek = CAST (SUBSTRING(P2.PeriodName, CHARINDEX(' ', P2.PeriodName) + 1, 2) AS INT), --DATEPART(WEEK, T1.PlannedDate),	
	   PlannedYear = YEAR(T1.PlannedDate),
	   T1.Remark,
	   T1.RequestID,
	   T1.RequestingSystem,
	   T1.SynchronisationCode,
	   T1.TotalNrOfPlates,
	   T1.TotalNrOfTests
	FROM
	(
	    SELECT 
		    'DPW' AS ContainerType,
		    'NL' AS CountryCode,
		    MAX(V0.CropCode) AS CropCode,
		    ExpectedDate = COALESCE ( MAX(V1.ExpectedReadyDateLab), MAX(V0.ExpectedReadyDate)),
		    'N' AS Isolated,	
		    'FRS' AS MaterialState,
		    MaterialType = MAX(V0.MaterialType),
		    PlannedDate =  MAX(V0.PlannedDate),
		    'PAC' AS Remark, 
		    T.TestID AS RequestID, 
		    'PAC' AS RequestingSystem,
		    'NL' AS SynchronisationCode,
			MAX(TP.NrOfPlates) AS TotalNrOfPlates,
			MAX(TP.NrOfMarkes) AS TotalNrOfTests		    
	    FROM
	    (	
		    SELECT 
			    TestID, 
			    DA.DetAssignmentID, 
			    AC.CropCode,
				MaterialType = CASE WHEN MT.MaterialTypeCode IS NULL THEN 'SDS' ELSE MT.MaterialTypeCode END, --default value SDS
			    DA.PlannedDate,
			    DA.ExpectedReadyDate,
				DA.StatusCode
		    FROM TestDetAssignment TDA
		    JOIN DeterminationAssignment DA ON DA.DetAssignmentID = TDA.DetAssignmentID
		    JOIN Method M ON M.MethodCode = DA.MethodCode
		    JOIN CropMethod CM ON CM.MethodID = M.MethodID AND CM.ABSCropCode = DA.ABSCropCode
			--handle if same method is used for hybrid and parent
			JOIN
			(
				SELECT 
					VarietyNr, 
					UsedFor = CASE WHEN dbo.FN_IsParent(VarietyNr, @HybridAsParentCrop) = 0 THEN 'Hyb' ELSE 'Par' END
				FROM Variety
			) V ON V.VarietyNr = DA.VarietyNr AND V.UsedFor = CM.UsedFor
		    JOIN ABSCrop AC On AC.ABSCropCode = DA.ABSCropCode
			LEFT JOIN CalcCriteriaPerCrop CC ON CC.CropCode = AC.CropCode
			LEFT JOIN MaterialType MT ON MT.MaterialTypeID = CC.MaterialTypeID
	    ) V0 
		LEFT JOIN
		(
			SELECT 
				T.TestID,
				ExpectedReadyDateLab = MAX(DA.ExpectedReadyDate) 
			FROM DeterminationAssignment DA
			JOIN TestDetAssignment TDA ON TDA.DetAssignmentID = DA.DetAssignmentID
			JOIN Test T On T.TestID = TDA.TestID
			WHERE (ISNULL(@PeriodID,0) = 0 OR T.PeriodID = @PeriodID) AND DA.IsLabPriority = 1
			GROUP BY T.TestID
		) V1 ON V1.TestID = V0.TestID
	    JOIN Test T ON T.TestID = V0.TestID		
	    JOIN @TestPlates TP ON TP.TestID = T.TestID
	    WHERE (ISNULL(@PeriodID,0) = 0 OR T.PeriodID = @PeriodID) AND (T.StatusCode < 200 AND V0.StatusCode = 300) --sometimes test status remain on 100 even though all DA got status 300
	    GROUP BY T.TestID
	) T1
	JOIN [Period] P1 ON T1.ExpectedDate BETWEEN P1.StartDate AND P1.EndDate --Expected Week
	JOIN [Period] P2 ON T1.PlannedDate BETWEEN P2.StartDate AND P2.EndDate -- Planned Week

END

GO


