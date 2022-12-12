DROP PROCEDURE IF EXISTS [dbo].[PR_GetFolderDetails]
GO


/*
Author					Date			Description
Binod Gurung			2020-jan-23		Transcation isolation level implemented to avoid record lock	
Krishna Gautam			2020/02/19		Calculation of nr of marker is done per plate on group level.
Dibya					2020/02/20		Made #plates as absolute number.
Krishna Gautam			2020/02/27		Added plates information on batches.
Binod Gurung			2020/03/10		#11471 Sorting added on Variety name 

===================================Example================================

    EXEC PR_GetFolderDetails 4792;
	
*/
CREATE PROCEDURE [dbo].[PR_GetFolderDetails]
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
	   TempPlateID INT,
	   PlateNames NVARCHAR(MAX)
    );
	
    INSERT @tbl(DetAssignmentID, TestID, TestName, CropCode, MethodCode, PlatformName, NrOfPlates, NrOfMarkers, VarietyNr, VarietyName, SampleNr, IsLabPriority, IsParent, TraitMarkers,Markers,TempPlateID,PlateNames)
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
	TempPlateID,
	Plates
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
	   Prio = CASE WHEN V.HybOp = 0 AND V.[Type] = 'P' THEN 1 ELSE 0 END,
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
		TempPlateID = CEILING(SUM(ISNULL(NrOfPlates,0)) OVER (Partition by T.Testid Order by C.CropCode ASC, DA.MethodCode ASC, P.PlatformDesc ASC, ISNULL(DA.IsLabPriority, 0) DESC, CASE WHEN V.HybOp = 0 AND V.[Type] = 'P' THEN 1 ELSE 0 END DESC, DA.DetAssignmentID ASC) /1),
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
	WHERE T.PeriodID = @PeriodID
	) T1
	ORDER BY T1.CropCode ASC, T1.MethodCode ASC, T1.PlatformDesc ASC, ISNULL(T1.IsLabPriority, 0) DESC, Prio DESC, T1.Shortname ASC

	

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
	   TraitMarkers,
	   PlateNames
    FROM @tbl T
	ORDER BY ID


    SELECT 
	   MIN(T2.StatusCode) AS StatusCode
    FROM @tbl T1
    JOIN Test T2 ON T2.TestID = T1.TestID;
END
GO


DROP PROCEDURE IF EXISTS [dbo].[PR_ReservePlateplansInLimsCallback]
GO



/*
Author					Date			Remarks
Binod Gurung			2019/12/13		Created service to create plate when callback sevice from lims is called to PAC.
Krishna Gautam			2020/01/10		Changed logic to solve issue of well assigning to multiple determination
Krishna Gautam			2020/01/10		Changed Status of test to 350 instead of 300
Krishna Gautam			2020/02/19		Assignment of determination is done as per priority as displayed on Lab lab lab preparation screen.
Binod Gurung			2020/03/10		#11471 Sorting added on Variety name

=================EXAMPLE=============
DECLARE @T1 TVP_Plates
INSERT INTO @T1(LIMSPlateID,LIMSPlateName)
VALUES(336,'abc'),(337,'bcd')
EXEC PR_ReservePlateplansInLimsCallback 44,'Test',322,@T1
*/
CREATE PROCEDURE [dbo].[PR_ReservePlateplansInLimsCallback]
(
	@LIMSPlateplanID		INT,
	@TestName				NVARCHAR(100),
	@TestID					INT,
	@TVP_Plates TVP_Plates	READONLY
) AS BEGIN

	DECLARE @LabPlateTable TABLE(LabID INT, LabPlateName NVARCHAR(100));
	DECLARE @StartRow CHAR(1) = 'A', @EndRow CHAR(1) = 'H', @StartColumn INT = 1, @EndColumn INT = 12, @RowCounter INT = 0, @ColumnCounter INT, @PlateCount INT, @Offset INT = 0, @NextRows INT, @DACount INT, @DetAssignmentID INT;
	DECLARE @TempTbl TABLE (Position VARCHAR(5));
	DECLARE @TempPlateTable TABLE(PlateID INT);
	DECLARE @CreatedWell TABLE(ID INT IDENTITY(1,1), WellID INT, PlateID INT, Position NVARCHAR(10), DAID INT,Inserted BIT);
	DECLARE @TblDA TABLE(ID INT IDENTITY(1,1), DAID INT,NrOfSeeds INT);

	SET NOCOUNT ON;
	BEGIN TRY
		
		BEGIN TRANSACTION;

			IF NOT EXISTS (SELECT * FROM TEST WHERE TestID = @TestID AND StatusCode = 200) BEGIN
				EXEC PR_ThrowError 'Invalid RequestID.';
				ROLLBACK;
				RETURN;
			END
			
			DELETE W FROM Well W
			JOIN Plate P ON P.PlateID = W.PlateID
			WHERE P.TestID = @TestID;

			DELETE Plate WHERE TestID = @TestID


			SET @RowCounter=Ascii(@StartRow);

			WHILE @RowCounter<=Ascii(@EndRow)	BEGIN
				SET @ColumnCounter = @StartColumn;
				WHILE(@ColumnCounter <= @EndColumn) BEGIN							
					INSERT INTO @TempTbl(Position)
						VALUES(CHAR(@RowCounter) + RIGHT('00'+CAST(@ColumnCounter AS VARCHAR),2))
					SET @ColumnCounter = @ColumnCounter + 1;
				END
				SET @RowCounter=@RowCounter + 1;
			END


			INSERT INTO @TblDA(DAID, NrOfSeeds)
			SELECT 
				TDA.DetAssignmentID, 
				M.NrOfSeeds 
			FROM Method M
			JOIN DeterminationAssignment DA ON DA.MethodCode = M.MethodCode
			JOIN Variety V ON V.VarietyNr = DA.VarietyNr
			JOIN TestDetAssignment TDA ON TDA.DetAssignmentID = DA.DetAssignmentID
			WHERE TDA.TestID = @TestID
			ORDER BY ISNULL(DA.IsLabPriority, 0) DESC, CASE WHEN V.HybOp = 0 AND V.[Type] = 'P' THEN 1 ELSE 0 END DESC,  V.Shortname ASC

			
			INSERT INTO @LabPlateTable (LabID, LabPlateName)
			SELECT LIMSPlateID, LIMSPlateName
			FROM @TVP_Plates;	

			--Insert plate info
			MERGE INTO Plate T
			USING
			(
				SELECT LabID, LabPlateName FROM @LabPlateTable

			) S ON S.LabID = T.LabPlateID
			WHEN NOT MATCHED THEN
			  INSERT(PlateName,LabPlateID,TestID)  
			  VALUES(S.LabPlateName,S.LabID, @TestID)
			  OUTPUT INSERTED.PlateID INTO @TempPlateTable(PlateID);


			 --Create empty well for created plates
			INSERT INTO Well(PlateID, Position)
			OUTPUT INSERTED.WellID, INSERTED.PlateID, INSERTED.Position INTO @CreatedWell(WellID,PlateID,Position)
			SELECT T2.PlateID, T1.Position FROM @TempTbl T1
			CROSS APPLY @TempPlateTable T2
			ORDER BY T2.PlateID;

			DELETE FROM @CreatedWell where Position IN ('B01', 'D01', 'F01', 'H01');

			SET @RowCounter =1;
			SELECT @DACount = COUNT(ID) FROM @TblDA;

			WHILE(@RowCounter <= @DACount)
			BEGIN
				SELECT 
					@NextRows = NrOfSeeds,
					@DetAssignmentID = DAID
				FROM @TblDA WHERE ID = @RowCounter;

				MERGE INTO @CreatedWell T
				USING
				(
					SELECT ID FROM @CreatedWell  ORDER BY ID OFFSET @Offset ROWS FETCH NEXT @NextRows ROWS ONLY
				) S
				ON S.ID = T.ID
				WHEN MATCHED THEN
				UPDATE SET T.DAID = @DetAssignmentID;

				SET @Offset = @Offset + @NextRows;

				SET @RowCounter = @RowCounter + 1;

			END

			MERGE INTO Well T
			USING @CreatedWell S
			ON S.WellID = T.WellID
			WHEN MATCHED
			THEN UPDATE SET T.DetAssignmentID = S.DAID;

			
			--Update Test info
			UPDATE Test 
			SET LabPlatePlanID = @LIMSPlateplanID,
				TestName = @TestName,
				StatusCode = 350
			WHERE TestID = @TestID;

		COMMIT;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK;
		THROW;
	END CATCH
END
GO


