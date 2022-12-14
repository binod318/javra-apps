DROP FUNCTION IF EXISTS [dbo].[FN_IsParent]
GO

-- =============================================
-- Author:		Binod Gurung
-- Create date: 2022/05/04
-- Description:	Function to check if the hybrid variety is used as parent and only for speciic crops from pipeline
--				Return 1 for parent, 0 for hybrid
-- =============================================
-- SELECT  dbo.FN_IsParent (1011389, 'CF,ON')
CREATE FUNCTION [dbo].[FN_IsParent]
(
	@VarietyNr INT,
	@CropCode NVARCHAR(100)
)
RETURNS BIT
AS
BEGIN

	DECLARE @IsParent BIT, @VarietyCrop NVARCHAR(10);

	SELECT 
		@VarietyCrop = CropCode,
		@IsParent = CASE WHEN HybOp = 1 AND [Type] <> 'P' THEN 0 ELSE 1 END
	FROM Variety WHERE VarietyNr = @VarietyNr;

	--check if hybrid is used as parents and only for the crops mentioned in the release pipeline
	IF ( @IsParent = 0 AND @VarietyCrop IN (SELECT [value] FROM STRING_SPLIT(@CropCode,',')))
	BEGIN

		IF EXISTS (SELECT * FROM Variety WHERE Male = @VarietyNr OR Female = @VarietyNr)
			SET @IsParent = 1;

	END
	
	-- CASE WHEN HybOp = 1 AND [Type] <> 'P' THEN 'Hyb' ELSE 'Par' END
	-- Prio = CASE WHEN V.[Type] = 'P' THEN 1 ELSE 0 END,
	
	Return @IsParent;

END

GO




DROP PROCEDURE IF EXISTS [dbo].[PR_Ignite_Decluster]
GO


-- =============================================
-- Author:		Binod Gurung
-- Create date: 2019/10/18
-- Description:	Procedure to ignite decluster
-- =============================================
/*	
	EXEC [PR_Ignite_Decluster]
*/
CREATE PROCEDURE [dbo].[PR_Ignite_Decluster]
(
	@HybridAsParentCrop	NVARCHAR(10)
) 
AS
BEGIN

	DECLARE @DetAssignmentID INT, @ReturnVarieties NVARCHAR(MAX), @TestID INT, @ID INT = 1, @Count INT;;
	DECLARE @tbl TABLE(ID INT IDENTITY(1, 1), TestID INT);
	
	SET NOCOUNT ON;
	
	BEGIN TRY
		BEGIN TRANSACTION;

		DECLARE Determination_Cursor CURSOR LOCAL FAST_FORWARD FOR
		SELECT DetAssignmentID FROM DeterminationAssignment DA WHERE DA.StatusCode = 200
		OPEN Determination_Cursor;
		FETCH NEXT FROM Determination_Cursor INTO @DetAssignmentID;
	
		WHILE @@FETCH_STATUS = 0
		BEGIN
			
			EXEC [PR_Decluster] @DetAssignmentID, @HybridAsParentCrop, @ReturnVarieties OUTPUT;

			--update status of determination assignment 
			UPDATE DeterminationAssignment
			SET StatusCode = 300
			WHERE DetAssignmentID = @DetAssignmentID;

			--for all test where this determination assignment is used update test status if all DA of that test is declustered
			INSERT @tbl(TestID)
			SELECT TestID FROM TestDetAssignment WHERE DetAssignmentID = @DetAssignmentID;

			SELECT @Count = COUNT(ID) FROM @tbl;
			WHILE(@ID <= @Count) BEGIN
				SELECT 
					@TestID = TestID 
				FROM @tbl
				WHERE ID = @ID;

				--if all determination assignments are declustered then update status of Test
				IF NOT EXISTS
				(
					SELECT TD.TestID FROM TestDetAssignment TD
					JOIN DeterminationAssignment DA ON DA.DetAssignmentID = TD.DetAssignmentID
					where DA.StatusCode < 300 AND TD.TestID = @TestID
				)
				BEGIN

					UPDATE Test
					SET StatusCode = 150 --Declustered
					WHERE TestID = @TestID

				END

				SET @ID = @ID + 1;
			END
						
			FETCH NEXT FROM Determination_Cursor INTO @DetAssignmentID;
		END
	
		CLOSE Determination_Cursor;
		DEALLOCATE Determination_Cursor;

		COMMIT;
	END TRY
	BEGIN CATCH
		IF(@@TRANCOUNT > 0)
			ROLLBACK;
		THROW;
	END CATCH
	
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
	@TVP_Plates TVP_Plates	READONLY,
	@HybridAsParentCrop		NVARCHAR(10)
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

			IF NOT EXISTS (SELECT * FROM TEST WHERE TestID = @TestID) BEGIN
				EXEC PR_ThrowError 'Invalid RequestID.';
				ROLLBACK;
				RETURN;
			END

			IF NOT EXISTS (SELECT * FROM TEST WHERE TestID = @TestID AND StatusCode <= 200) BEGIN
				EXEC PR_ThrowError 'Invalid Test Status.';
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
			ORDER BY ISNULL(DA.IsLabPriority, 0) DESC, dbo.FN_IsParent(V.VarietyNr, @HybridAsParentCrop) DESC,  V.Shortname ASC

			
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


DROP PROCEDURE IF EXISTS [dbo].[PR_Decluster]
GO


-- =============================================
-- Author:		Binod Gurung
-- Create date: 2019/10/16
-- Description:	Procedure to decluster varieties
-- =============================================
/*	
	DECLARE @ReturnVarieties NVARCHAR(MAX);
	EXEC [PR_Decluster] 837824, @ReturnVarieties OUTPUT;
	SELECT @ReturnVarieties;
*/
CREATE PROCEDURE [dbo].[PR_Decluster]
(
	@DetAssignmentID	INT,
	@HybridAsParentCrop		NVARCHAR(10),
	@ReturnVarieties	NVARCHAR(MAX) OUTPUT
)
AS
BEGIN

	DECLARE @VarietyNr INT, @Female INT, @Male INT, @IsParent BIT, @Crop NVARCHAR(10), @MarkerID INT, @PlatformID INT, @InMMS BIT, @Score NVARCHAR(10), @VarietyScore NVARCHAR(10), @ImsMarker NVARCHAR(50), @Reciprocal BIT;
	DECLARE @ClusteredVarieties NVARCHAR(MAX), @CountClusteredVarieties INT, @Json NVARCHAR(MAX), @List NVARCHAR(MAX) = '';
	DECLARE @MarkerTbl TABLE(DetAssignmentID INT, MarkerID INT, InEDS BIT, InIMS BIT);
	DECLARE @MMSMarkerTbl TABLE (MarkerID INT, MarkerValue NVARCHAR(10));
	DECLARE @EdmMarkerTbl TABLE (MarkerID INT, MarkerValue NVARCHAR(10));
	DECLARE @EdmMarkerTblOrig TABLE (MarkerID INT, MarkerValue NVARCHAR(10));	
	DECLARE @JsonTbl TABLE (ID INT IDENTITY(1,1), MarkerID INT, MarkerValue NVARCHAR(10));
	DECLARE @ClusterVarTbl TABLE(VarietyNr INT);
	DECLARE @EffectPerMarkerTbl Table(MarkerID INT, Total INT);
	DECLARE @Count1 INT, @Count2 INT, @HighestScore INT, @HighestMarker INT;	
	DECLARE @DeclusterMarkerTbl Table(MarkerID INT); 
	DECLARE @DeclusterMarkerCount INT;
	
	SET NOCOUNT ON;

	SET @ReturnVarieties = '';
	
	-- step 1 : calculate cluster varieties

	--delete all previous marker test before starting new
	DELETE MarkerToBeTested
	WHERE DetAssignmentID = @DetAssignmentID;

	--find variety linked to determination assignment
	SELECT 
		@VarietyNr = VarietyNr,
		@Reciprocal = ReciprocalProd
	FROM DeterminationAssignment WHERE DetAssignmentID = @DetAssignmentID;

	--find variety information
	SELECT 
		@Crop = CropCode,
		@Female = V.Female,
		@Male = V.Male,
		@IsParent = dbo.FN_IsParent(VarietyNr, @HybridAsParentCrop)
	FROM Variety V WHERE V.VarietyNr = @VarietyNr;

	--find extra setting for decluster marker, only if variety is parent
	IF(@IsParent = 1)
	BEGIN
		INSERT @DeclusterMarkerTbl (MarkerID)
		SELECT MarkerID FROM Marker WHERE CropCode = @Crop AND MarkerName IN
		(
			SELECT LTRIM([value]) FROM STRING_SPLIT((SELECT SettingValue FROM ExtraSettings WHERE CropCode = @Crop AND SettingCode = 'ParDeclusterMarkers'), ',')
		)

		SELECT @DeclusterMarkerCount = COUNT(*) FROM @DeclusterMarkerTbl
	END

	DECLARE Marker_Cursor CURSOR LOCAL FAST_FORWARD FOR
		SELECT MarkerID, P.PlatformID, InMMS FROM MarkerCropPlatform MCP
		JOIN [Platform] P ON P.PlatformID = MCP.PlatformID 
		WHERE CropCode = @Crop AND P.UsedForPac = 1
	OPEN Marker_Cursor;
	FETCH NEXT FROM Marker_Cursor INTO @MarkerID, @PlatformID, @InMMS;
	
	WHILE @@FETCH_STATUS = 0
	BEGIN

		SELECT @Score = MVPV.AlleleScore FROM MarkerValuePerVariety MVPV WHERE MVPV.VarietyNr = @VarietyNr AND MarkerID = @MarkerID;

		-- if no score available and marker is in MMS
		IF(ISNULL(@Score,'') = '' AND @InMMS = 1)
			RETURN; --return 

		IF(ISNULL(@Score,'') <> '')
		BEGIN

			IF((@InMMS = 1 OR @IsParent = 1)) --and platform of test and marker is same
			BEGIN
				
				INSERT INTO @MMSMarkerTbl
				VALUES(@MarkerID, @Score);

				INSERT INTO @MarkerTbl
				VALUES(@DetAssignmentID, @MarkerID, ~@InMMS, 0)

			END;
			ELSE IF (@InMMS = 0)
			BEGIN
				
				INSERT INTO @EdmMarkerTbl
				VALUES(@MarkerID, @Score);

			END
		END

		FETCH NEXT FROM Marker_Cursor INTO @MarkerID, @PlatformID, @InMMS;
	END
	
	CLOSE Marker_Cursor;
	DEALLOCATE Marker_Cursor;

	--variables used on next step
	--@MMSMarkerTbl

	--step 2: call findmatchingvarieties
	
	--prepare json to feed sp
	INSERT INTO @JsonTbl(MarkerID, MarkerValue)
	SELECT MarkerID, MarkerValue from @MMSMarkerTbl

	SET @Json = (SELECT * FROM @JsonTbl FOR JSON AUTO);
	EXEC PR_FindMatchingVarieties @Json, @Crop, @VarietyNr, @ClusteredVarieties OUTPUT;

	--insert comma separated list of varieties to table
	INSERT INTO @ClusterVarTbl
	SELECT [value] FROM STRING_SPLIT(@ClusteredVarieties, ',');

	--variables used on next step
	--@ClusterVarTbl, @EdmMarkerTbl

	--step 3 : Apply extra declustering markers

	--data in @EdmMarkerTbl table gets lesser everytime so we need the original list later for finding inbred marker
	INSERT INTO @EdmMarkerTblOrig
	SELECT * FROM @EdmMarkerTbl;

	SELECT @CountClusteredVarieties = COUNT(VarietyNr) FROM @ClusterVarTbl;
			
	--declusterloop
	WHILE (@CountClusteredVarieties > 1)
	BEGIN

		-- Now we need to find a marker that discriminates most
  		-- First calculate per marker how many varieties would be dropped if this marker is added to the list
		-- Reset first
		DELETE FROM @EffectPerMarkerTbl;

		INSERT INTO @EffectPerMarkerTbl
		SELECT MVPV.MarkerID, COUNT(MVPV.MarkerID) AS Total FROM 
		(
			SELECT VarietyNr, ED.MarkerID, ED.MarkerValue FROM @ClusterVarTbl
			CROSS APPLY @EdmMarkerTbl ED
			WHERE VarietyNr <> @VarietyNr
		) V2
		LEFT JOIN MarkerValuePerVariety MVPV ON MVPV.VarietyNr = V2.VarietyNr AND MVPV.MarkerID = V2.MarkerID
		WHERE dbo.FN_IsMatching(V2.MarkerValue, MVPV.AlleleScore) = 0
		GROUP BY MVPV.MarkerID
		
		-- Choose the marker with the highest effect and remove the non-matching varieties from v-clustervarlist
		SET @HighestScore = 0;
		SET @HighestMarker = 0;

		SELECT TOP 1
			@HighestMarker = EP.MarkerID,
			@HighestScore = EP.Total
		FROM @EffectPerMarkerTbl EP 
		WHERE Total > @HighestScore
		ORDER BY EP.Total DESC, MarkerID
		
		--if no marker found with @EffectPerMarkerTbl then quit this loop
		IF(ISNULL(@HighestScore, 0) = 0)
			BREAK;

		-- if marker found then remove marker from edm markerlist
		DELETE FROM @EdmMarkerTbl
		WHERE MarkerID = @HighestMarker
		
		--first find the score for the highest marker of the variety in test 			
		SELECT TOP 1 @VarietyScore = AlleleScore FROM MarkerValuePerVariety WHERE VarietyNr = @VarietyNr AND MarkerID = @HighestMarker;
		
		--Remove varieties from Clusteredlist that no longer match the variety in test - that has markervaluepervariety record but not matching	
		DELETE CV FROM @ClusterVarTbl CV
		JOIN MarkerValuePerVariety MVPV ON  MVPV.VarietyNr = CV.VarietyNr 
										AND MVPV.MarkerID = @HighestMarker 
										AND CV.VarietyNr <> @VarietyNr -- skip self
										AND dbo.FN_IsMatching(@VarietyScore, MVPV.AlleleScore) = 0
								
		--Keep input variety in list in case removed
		IF NOT EXISTS (SELECT * FROM @ClusterVarTbl WHERE VarietyNr = @VarietyNr)
		BEGIN
			INSERT INTO @ClusterVarTbl
			VALUES(@VarietyNr);
		END;

		--Create marker to be tested in temptable
		INSERT INTO @MarkerTbl
		VALUES(@DetAssignmentID, @HighestMarker, 1, 0)

		SELECT @CountClusteredVarieties = COUNT(VarietyNr) FROM @ClusterVarTbl;
		--SET @CountClusteredVarieties = @CountClusteredVarieties - 1;

	END

	--step 4 : Try to find inbred marker
			
	-- find inbred marker if crop allows inbred
	IF EXISTS (SELECT * FROM CropRD WHERE CropCode = @Crop AND InBreed = 1)
	BEGIN

		--convert table column value to comma separated list
		SET @List = '';
		SELECT @List = @List + CAST(MarkerID AS NVARCHAR(20)) + ',' from @MMSMarkerTbl;
		SET @List = SUBSTRING(@List, 0, LEN(@List));

		EXEC [PR_FindInbredMarker] @List, @VarietyNr, @Female, @Male, @Reciprocal, @ImsMarker OUTPUT;

		-- if no inbred marker found using MMSMarkers or only one marker found
		IF(ISNULL(@ImsMarker,'') = '' OR CHARINDEX(ISNULL(@ImsMarker,''),',') = 0)
		BEGIN			

			--convert table column value to comma separated list
			SET @List = '';
			SELECT @List = @List + CAST(MarkerID AS NVARCHAR(20)) + ',' from @EdmMarkerTblOrig;
			SET @List = SUBSTRING(@List, 0, LEN(@List));

			EXEC [PR_FindInbredMarker] @List, @VarietyNr, @Female, @Male, @Reciprocal, @ImsMarker OUTPUT; 

		END;

		--if marker found
		IF(ISNULL(@ImsMarker,'') <> '')
		BEGIN

			--If record already exists for same test/marker update InIms to true
			MERGE INTO @MarkerTbl T
			USING
			(
				SELECT [value] AS Marker FROM STRING_SPLIT(@ImsMarker, ',')
			) S ON T.MarkerID = S.Marker
			WHEN NOT MATCHED THEN
				INSERT (DetAssignmentID, MarkerID, InEDS, InIMS)
				VALUES (@DetAssignmentID, S.Marker, 0, 1)
			WHEN MATCHED THEN
				UPDATE SET T.InIMS = 1;

		END;

	END;
	
	--if @DeclusterMarkerCount = 0 means no extrasetting record (old logic)
	IF(ISNULL(@DeclusterMarkerCount,0) = 0)
	BEGIN
		--Create MarkerToBeTested record in database from temptable @MarkerTbl
		MERGE INTO MarkerToBeTested T
		USING
		(
			SELECT 
				DetAssignmentID, 
				MarkerID, 
				InEDS = CAST(MAX(CAST(InEDS as INT)) AS BIT), 
				InIMS = CAST(MAX(CAST(InIMS as INT)) AS BIT), 
				[Audit] = 'AutoDecluster, ' + CONVERT(NVARCHAR(50), getdate()) 
			FROM @MarkerTbl 
			GROUP BY DetAssignmentID, MarkerID
		) S ON S.DetAssignmentID = T.DetAssignmentID AND S.MarkerID = T.MarkerID
		WHEN NOT MATCHED THEN
			INSERT (DetAssignmentID, MarkerID, InEDS, InIMS, [Audit])
			VALUES (S.DetAssignmentID, S.MarkerID, S.InEDS, S.InIMS, S.[Audit]);
	END
	ELSE
	BEGIN
		--Create MarkerToBeTested record in database from temptable @MarkerTbl
		MERGE INTO MarkerToBeTested T
		USING
		(
			SELECT 
				DetAssignmentID, 
				M.MarkerID, 
				InEDS = CAST(MAX(CAST(InEDS as INT)) AS BIT), 
				InIMS = CAST(MAX(CAST(InIMS as INT)) AS BIT), 
				[Audit] = 'AutoDecluster, ' + CONVERT(NVARCHAR(50), getdate()) 
			FROM @MarkerTbl M
			JOIN @DeclusterMarkerTbl DM On DM.MarkerID = M.MarkerID
			GROUP BY DetAssignmentID, M.MarkerID
		) S ON S.DetAssignmentID = T.DetAssignmentID AND S.MarkerID = T.MarkerID
		WHEN NOT MATCHED THEN
			INSERT (DetAssignmentID, MarkerID, InEDS, InIMS, [Audit])
			VALUES (S.DetAssignmentID, S.MarkerID, S.InEDS, S.InIMS, S.[Audit]);
	END
	--convert table column value to comma separated list
	SET @List = '';
	SELECT @List = @List + CONVERT(NVARCHAR(20),VarietyNr) + ',' from @ClusterVarTbl;
	SET @List = SUBSTRING(@List, 0, LEN(@List));
	SET @ReturnVarieties = @List;
	
END
GO


DROP PROCEDURE IF EXISTS [dbo].[PR_ProcessAllTestResultSummary]
GO


/*
Author					Date			Remarks
Binod Gurung			2020-jan-23		Trigger background summary calculation for all determination assignment whose result is determined(500)
Binod Gurung			2021-july-16	ThresholdA and ThresholdB is now considered per crop. Also calculation is only done for crops which is not marked
										to do calculation from external application
Binod Gurung			2022-march-05   Test result quality threshold percentage used from pipeline variable [#31737]
Binod Gurung			2022-may-09		FN_IsParent function used for parent check [#34494]

=================EXAMPLE=============

-- EXEC PR_ProcessAllTestResultSummary 43, 22, 'ON'
-- All input values are in percentage (1 - 100)
*/

CREATE PROCEDURE [dbo].[PR_ProcessAllTestResultSummary]
(
	@MissingResultPercentage	DECIMAL(5,2),
	@QualityThresholdPercentage DECIMAL(5,2),
	@HybridAsParentCrop			NVARCHAR(10)
)
AS 
BEGIN
    SET NOCOUNT ON;

	DECLARE @DetAssignment TABLE(DetAssignmentID INT, CropCode CHAR(2), UsedFor NVARCHAR(10));
	DECLARE @tbl TABLE(ID INT IDENTITY(1, 1), DetAssignmentID INT, ThresholdA DECIMAL(5,2), ThresholdB DECIMAL(5,2));
	DECLARE @ThresholdA DECIMAL(5,2), @ThresholdB DECIMAL(5,2), @Crop NVARCHAR(10);

	DECLARE @Errors TABLE (DetAssignmentID INT, ErrorMessage NVARCHAR(MAX));
	DECLARE @PlatformID INT = (SELECT PlatformID FROM [Platform] WHERE PlatformCode = 'LS'); --light scanner ;
	DECLARE @DetAssignmentID INT, @ID INT = 1, @Count INT;
   
	INSERT @DetAssignment(DetAssignmentID, CropCode, UsedFor)
	SELECT 
		W.DetAssignmentID,
		MAX(AC.CropCode),
		UsedFor = CASE WHEN MAX(V.CropCode) IN (SELECT [value] FROM STRING_SPLIT(@HybridAsParentCrop,',')) THEN 
							CASE WHEN dbo.FN_IsParent(MAX(V.VarietyNr), @HybridAsParentCrop) = 0 THEN 'Hyb' ELSE 'Par' END
					   ELSE  
							CASE WHEN MAX(V.[Type]) = 'P' THEN 'Par' WHEN CAST(MAX(CAST(v.HybOp as INT)) AS BIT) = 1 AND MAX(V.[Type]) <> 'P' THEN 'Hyb' ELSE 'Op' END 
				  END		
	FROM TestResult TR
	JOIN Well W ON W.WellID = TR.WellID
	JOIN TestDetAssignment TDA ON TDA.DetAssignmentID = W.DetAssignmentID
	JOIN DeterminationAssignment DA ON DA.DetAssignmentID = TDA.DetAssignmentID
	JOIN ABSCrop AC ON AC.ABSCropCode = DA.ABSCropCode
	-- Do not use Cropmethod because same abscrop+methodID has both hybrid and parent for methodID 8 : That is confusing
	--JOIN
	--(
	--	SELECT
	--		AC.ABSCropCode,
	--		PM.MethodCode,
	--		CM.UsedFor
	--	FROM CropMethod CM
	--	JOIN ABSCrop AC ON AC.ABSCropCode = CM.ABSCropCode
	--	JOIN Method PM ON PM.MethodID = CM.MethodID
	--	WHERE CM.PlatformID = @PlatformID
	--) V1 ON V1.ABSCropCode = DA.ABSCropCode AND V1.MethodCode = DA.MethodCode
	JOIN Variety V ON V.VarietyNr = DA.VarietyNr
	WHERE ISNULL(W.DetAssignmentID, 0) <> 0
	AND DA.StatusCode = 500
	GROUP BY W.DetAssignmentID;

	INSERT @tbl(DetAssignmentID, ThresholdA, ThresholdB)
	SELECT
		D.DetAssignmentID,
		ISNULL(CC.ThresholdA,0),
		ISNULL(CC.ThresholdB,0)
	FROM @DetAssignment D
	LEFT JOIN CalcCriteriaPerCrop CC ON CC.CropCode = D.CropCode
	WHERE (UsedFor = 'Hyb' AND ISNULL(CC.CalcExternalAppHybrid,0) = 0) OR (UsedFor = 'Par' AND ISNULL(CC.CalcExternalAppParent,0) = 0) 
		OR (UsedFor = 'Op' AND (ISNULL(CC.CalcExternalAppParent,0) = 0 OR ISNULL(CC.CalcExternalAppHybrid,0) = 0))
	--If Hybrid do not trigger calculation if CalcExternalAppHybrid = 1, if Parent do not trigger calculation if CalcExternalAppParent = 1, For OP (LT)

	SELECT @Count = COUNT(ID) FROM @tbl;
	WHILE(@ID <= @Count) BEGIN
			
		SELECT 
			@DetAssignmentID = DetAssignmentID,
			@ThresholdA = ThresholdA,
			@ThresholdB = ThresholdB 
		FROM @tbl
		WHERE ID = @ID;

		SET @ID = @ID + 1;

		--threshold value not saved for crop
		IF (@ThresholdA = 0 AND @ThresholdB = 0)
		BEGIN

			SELECT @Crop = AC.CropCode FROM DeterminationAssignment DA 
			JOIN ABSCrop AC ON AC.ABSCropCode = DA.ABSCropCode
			WHERE DA.DetAssignmentID = @DetAssignmentID

			INSERT @Errors(DetAssignmentID, ErrorMessage)
			SELECT @DetAssignmentID, 'Threshold value not found for crop ' + @Crop; 
			
			CONTINUE;
		END

		BEGIN TRY
		BEGIN TRANSACTION;
			
			--Background task 1
			EXEC PR_ProcessTestResultSummary @DetAssignmentID;

			--Background task 2, 3, 4
			EXEC PR_BG_Task_2_3_4 @DetAssignmentID, @MissingResultPercentage, @ThresholdA, @ThresholdB, @QualityThresholdPercentage;

		COMMIT;
		END TRY
		BEGIN CATCH

			--Store exceptions
			INSERT @Errors(DetAssignmentID, ErrorMessage)
			SELECT @DetAssignmentID, ERROR_MESSAGE(); 

			IF @@TRANCOUNT > 0
				ROLLBACK;

		END CATCH

	END   

	SELECT DetAssignmentID, ErrorMessage FROM @Errors;

END
GO


DROP PROCEDURE IF EXISTS [dbo].[PR_GetDeterminationAssigmentOverview]
GO



/*
Author					Date			Remarks
Binod Gurung			-				-
Krishna Gautam			2020-01-21		Where clause added.
Binod Gurung			2020-jan-23		Transcation isolation level implemented to avoid record lock
Krishna Gautam			2020-feb-28		(#11099) Pagination, sorting, filtering implemented and changed on logic to show all result without specific period (week).
Binod Gurung			2020-aug-20		Cropcode added and filter in status added
=================EXAMPLE=============


EXEC PR_GetDeterminationAssigmentOverview @PageNr = 1,
				@PageSize = 10,
				@SortBy = NULL,
				@HybridAsParentCrop = 'ON',
				@SortOrder	= NULL,
				@CropCode  = NULL,
				@DetAssignmentID = NULL,
				@SampleNr = NULL,
				@BatchNr = '19',
				@Shortname	 = NULL,
				@Status	 = NULL,
				@ExpectedReadyDate= NULL,
				@Folder		 = NULL,
				@QualityClass = NULL
*/
CREATE PROCEDURE [dbo].[PR_GetDeterminationAssigmentOverview]
(
    --@PeriodID INT
	@PageNr				INT,
	@PageSize			INT,
	@HybridAsParentCrop	NVARCHAR(10),
	@SortBy				NVARCHAR(100) = NULL,
	@SortOrder			NVARCHAR(20) = NULL,
	@CropCode			NVARCHAR(10) = NULL,
	@DetAssignmentID	NVARCHAR(100) = NULL,
	@SampleNr			NVARCHAR(100) = NULL,
	@BatchNr			NVARCHAR(100) = NULL,
	@Shortname			NVARCHAR(100) = NULL,
	@Status				NVARCHAR(100) = NULL,
	@ExpectedReadyDate	NVARCHAR(100) = NULL,
	@Folder				NVARCHAR(100) = NULL,
	@QualityClass		NVARCHAR(100) = NULL,
	@Plates				NVARCHAR(MAX) = NULL
) AS BEGIN
    SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

	DECLARE @TblColumn TABLE(ColumnLabel VARCHAR(100), ColumnID VARCHAR(100),[Order] INT,IsVisible BIT)
	DECLARE @PlatformID INT = (SELECT PlatformID FROM [Platform] WHERE PlatformCode = 'LS'); --light scanner ;
	DECLARE @Query NVARCHAR(MAX), @Offset INT,@Parameters NVARCHAR(MAX);;

	SET @OffSet = @PageSize * (@pageNr -1);

	INSERT INTO @TblColumn(ColumnLabel,ColumnID,[Order],IsVisible)
	VALUES
	('Crop','CropCode',1,1),
	('Det. Ass#','DetAssignmentID',2,1),
	('Sample#','SampleNr',3,1),
	('Batch#','BatchNr',4,1),
	('Article','Shortname',5,1),
	('Status','Status',6,1),
	('Exp Ready','ExpectedReadyDate',7,1),
	('Folder#','Folder',8,1),
	('Qlty Cls','QualityClass',9,1),
	('Plates','Plates',10,1);

    IF(ISNULL(@SortBy,'') ='')
	BEGIN
		SET @SortBy = 'ExpectedReadyDate'
		SET @SortOrder = 'DESC'
	END
	IF(ISNULL(@SortOrder,'') = '')
	BEGIN
		SET @SortOrder = 'DESC'
	END
	
	SET @Query = N'
	;WITH CTE AS
	(
		SELECT 
			*
		FROM
		(

			SELECT 
			   V.CropCode,
			   DA.DetAssignmentID,
			   DA.SampleNr,   
			   DA.BatchNr,
			   V.Shortname,
			   [Status] = COALESCE(S.StatusName, CAST(DA.StatusCode AS NVARCHAR(10))),
			   ExpectedReadyDate = FORMAT(DA.ExpectedReadyDate, ''dd/MM/yyyy''), 
			   V2.Folder,
			   DA.QualityClass,
			   Plates = STUFF 
			   (
				   (
					   SELECT DISTINCT '', '' + PlateName 
					   FROM Plate P 
					   JOIN Well W ON W.PlateID = P.PlateID 
					   WHERE P.TestID = T.TestID AND W.DetAssignmentID = DA.DetAssignmentID 
					   FOR  XML PATH('''')
				   ), 1, 2, ''''
			   ),
			   IsLabPriority = CAST(ISNULL(DA.IsLabPriority,0) AS INT)
			FROM DeterminationAssignment DA
			JOIN
			(
			   SELECT
				  AC.ABSCropCode,
				  PM.MethodCode,
				  CM.UsedFor
			   FROM CropMethod CM
			   JOIN ABSCrop AC ON AC.ABSCropCode = CM.ABSCropCode
			   JOIN Method PM ON PM.MethodID = CM.MethodID
			   WHERE CM.PlatformID = @PlatformID
			) V1 ON V1.ABSCropCode = DA.ABSCropCode AND V1.MethodCode = DA.MethodCode
			JOIN
			(
				SELECT 
					VarietyNr, 
					Shortname,
					CropCode,
					UsedFor = CASE WHEN dbo.FN_IsParent(VarietyNr, @HybridAsParentCrop) = 0 THEN ''Hyb'' ELSE ''Par'' END
				FROM Variety
			) V ON V.VarietyNr = DA.VarietyNr AND V.UsedFor = V1.UsedFor
			JOIN
			(
				SELECT W.DetAssignmentID, MAX(T.TestName) AS Folder 
				FROM Test T
				JOIN Plate P ON P.TestID = T.TestID
				JOIN Well W ON W.PlateID = P.PlateID
				--WHERE T.StatusCode >= 500
				GROUP BY W.DetAssignmentID
			) V2 On V2.DetAssignmentID = DA.DetAssignmentID
			JOIN TestDetAssignment TDA ON TDA.DetAssignmentID = DA.DetAssignmentID
			JOIN Test T ON T.TestID = TDA.TestID
			JOIN [Status] S ON S.StatusCode = DA.StatusCode AND S.StatusTable = ''DeterminationAssignment''
			WHERE DA.StatusCode IN (500,600,650)
		) T
		WHERE		
			(ISNULL(@CropCode,'''') = '''' OR CropCode like ''%''+ @CropCode +''%'') AND	
			(ISNULL(@DetAssignmentID,'''') = '''' OR DetAssignmentID like ''%''+ @DetAssignmentID +''%'') AND
			(ISNULL(@SampleNr,'''') = '''' OR SampleNr like ''%''+ @SampleNr +''%'') AND
			(ISNULL(@BatchNr,'''') = '''' OR BatchNr like ''%''+ @BatchNr +''%'') AND
			(ISNULL(@Shortname,'''') = '''' OR Shortname like ''%''+ @Shortname +''%'') AND
			(ISNULL(@Status,'''') = '''' OR Status like ''%''+ @Status +''%'') AND
			(ISNULL(@ExpectedReadyDate,'''') = '''' OR ExpectedReadyDate like ''%''+ @ExpectedReadyDate +''%'') AND
			(ISNULL(@Folder,'''') = '''' OR Folder like ''%''+ @Folder +''%'') AND
			(ISNULL(@QualityClass,'''') = '''' OR QualityClass like ''%''+ @QualityClass +''%'')
	), Count_CTE AS (SELECT COUNT(DetAssignmentID) AS [TotalRows] FROM CTE)
	SELECT 
		CropCode,
		DetAssignmentID,
		SampleNr,
		BatchNr,
		Shortname,
		[Status],
		ExpectedReadyDate,
		Folder,
		QualityClass,
		Plates,
		IsLabPriority,
		TotalRows
	FROM CTE,Count_CTE 
	ORDER BY ' + QUOTENAME(@SortBy) + ' ' + @SortOrder + N'   
	OFFSET @Offset ROWS
    FETCH NEXT @PageSize ROWS ONLY'

	SET @Parameters = N'@PlatformID INT, @PageNr INT, @PageSize INT, @HybridAsParentCrop NVARCHAR(10), @CropCode NVARCHAR(10), @DetAssignmentID NVARCHAR(100), @SampleNr NVARCHAR(100), @BatchNr NVARCHAR(100), 
	@Shortname NVARCHAR(100), @Status NVARCHAR(100), @ExpectedReadyDate NVARCHAR(100), @Folder NVARCHAR(100), @QualityClass NVARCHAR(100), @OffSet INT';

	SELECT * FROM @TblColumn ORDER BY [Order]

	 EXEC sp_executesql @Query, @Parameters,@PlatformID, @PageNr, @PageSize, @HybridAsParentCrop, @CropCode, @DetAssignmentID, @SampleNr, @BatchNr, @Shortname, @Status,
	   @ExpectedReadyDate, @Folder, @QualityClass, @OffSet;

END
GO


DROP PROCEDURE IF EXISTS [dbo].[PR_ReceiveResultsinKscoreCallback]
GO


/*

Author					Date			Remarks
Binod Gurung			-				-
Krishna Gautam			2020/01/20		Change on stored procedure to adjust logic of data is sent to LIMS for retest for specific determination but in response we get all result of that folder back.
Binod Gurung			2020/04/14		Delete existing test result before creating new. Test result also created for status 500 because when no result
										is recieved then status still goes to 500 and when result is sent again from LIMS for that test then result 
										should be stored.
Binod Gurung			2022-may-09		FN_IsParent function used for parent check [#34494]

============ExAMPLE===================
DECLARE  @DataAsJson NVARCHAR(MAX) = N'[{"LIMSPlateID":21,"MarkerNr":67,"AlleleScore":"0101","Position":"A01"}]'
EXEC PR_ReceiveResultsinKscoreCallback 331, @DataAsJson
*/
CREATE PROCEDURE [dbo].[PR_ReceiveResultsinKscoreCallback]
(
    @RequestID	 INT, --TestID
    @DataAsJson NVARCHAR(MAX),
	@HybridAsParentCrop		NVARCHAR(10)
) AS BEGIN
	
    SET NOCOUNT ON;

	DECLARE @StatusCode INT;

    BEGIN TRY
		BEGIN TRANSACTION;

		--Delete existing test result before creating new
		DELETE TR FROM Test T
		JOIN Plate P ON P.TestID = T.TestID
		JOIN Well W ON W.PlateID = P.PlateID
		JOIN TestResult TR ON TR.WellID = W.WellID
		WHERE T.TestID = @RequestID
		
		INSERT TestResult (WellID, MarkerID, Score, CreationDate)
		SELECT WellID, MarkerNr, AlleleScore, CreationDate
		FROM
		(	
			SELECT 
				W.WellID,
				T1.MarkerNr, 
				T1.AlleleScore,
				CONVERT(DATE,T1.CreationDate,105) AS CreationDate, -- CreationDate is in format dd-mm-yyyy from LIMS(22-02-2022) so we convert this with this rule select convert(date, varchar_date, 105)
				W.DetAssignmentID				
			FROM OPENJSON(@DataAsJson) WITH
			(
				LIMSPlateID	INT,
				MarkerNr	INT,
				AlleleScore	NVARCHAR(20),
				Position	NVARCHAR(20),
				CreationDate NVARCHAR(20)
			) T1
			JOIN Well W ON W.Position = T1.Position 
			JOIN Plate P ON P.PlateID = W.PlateID AND P.LabPlateID = T1.LIMSPlateID 
			JOIN DeterminationAssignment DA ON DA.DetAssignmentID = W.DetAssignmentID	
			JOIN 
			(
				SELECT T.DetAssignmentID, MarkerID FROM
				(
					SELECT MTB.MarkerID, DetAssignmentID FROM MarkerToBeTested MTB
					UNION
					SELECT MarkerID, DA.DetAssignmentID FROM MarkerPerVariety MPV
					JOIN DeterminationAssignment DA ON DA.VarietyNr = MPV.VarietyNr
					WHERE MPV.StatusCode = 100
				) T
				JOIN TestDetAssignment TDA On TDA.DetAssignmentID = T.DetAssignmentID
				WHERE TDA.TestID = @RequestID
				GROUP BY T.DetAssignmentID, MarkerID
			) MTB ON MTB.DetAssignmentID = DA.DetAssignmentID AND MTB.MarkerID = T1.MarkerNr	--store result only for the requested marker	
			WHERE P.TestID = @RequestID AND DA.StatusCode IN (400,500,650)						--store result only when status is InLIMS or Received or Re-test
			GROUP BY W.WellID, T1.MarkerNr, T1.AlleleScore, T1.CreationDate, W.DetAssignmentID
		) S;

		--If CalcCriteriaPerCrop exists for the particular crop with hybrid/parent combination then status directly goes to 600 instead of 500 
		IF EXISTS
		(
			SELECT CropCode FROM
			(
				SELECT 
					AC.CropCode,
					UsedFor = CASE WHEN dbo.FN_IsParent(V.VarietyNr, @HybridAsParentCrop) = 0 THEN 'Hyb' ELSE 'Par' END,
					UsedForCriteria =  CASE WHEN ISNULL(CCPC.CalcExternalAppHybrid,0) <> 0 AND ISNULL(CCPC.CalcExternalAppParent,0) = 0 THEN 'Hyb' 
											WHEN ISNULL(CCPC.CalcExternalAppHybrid,0) = 0 AND ISNULL(CCPC.CalcExternalAppParent,0) <> 0 THEN 'Par'
											WHEN ISNULL(CCPC.CalcExternalAppHybrid,0) <> 0 AND ISNULL(CCPC.CalcExternalAppParent,0) <> 0 THEN 'Hyb/Par'
											ELSE ''
										END
				FROM DeterminationAssignment DA
				JOIN ABSCrop AC ON AC.ABSCropCode = DA.ABSCropCode
				JOIN Variety V ON V.VarietyNr = DA.VarietyNr
				JOIN CalcCriteriaPerCrop CCPC ON CCPC.CropCode = AC.CropCode
				WHERE DA.DetAssignmentID IN (SELECT TOP 1 DetAssignmentID FROM TestDetAssignment WHERE TestID = @RequestID)
			) T
			WHERE UsedForCriteria LIKE '%' + UsedFor + '%'
		)
			SET @StatusCode = 600;
		ELSE
			SET @StatusCode = 500;


		--update test status
		UPDATE Test SET StatusCode = @StatusCode WHERE TestID = @RequestID;

		--update determination assignment status
		UPDATE DA
			SET DA.StatusCode = @StatusCode
		FROM DeterminationAssignment DA
		JOIN TestDetAssignment TDA ON TDA.DetAssignmentID = DA.DetAssignmentID
		WHERE TDA.TestID = @RequestID AND DA.StatusCode IN (400,500,650)	 --InLIMS or Received or Re-test  
	   
	   COMMIT;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
            ROLLBACK;
		THROW;
	END CATCH    
END
GO


DROP PROCEDURE IF EXISTS [dbo].[PR_GetInfoForUpdateDA]
GO


/*
Author					Date			Remarks
Binod Gurung			2020-jan-21		Get information for UpdateDA
Binod Gurung			2020-jan-23		Transcation isolation level implemented to avoid record lock
Binod Gurung			2020-aug-14		NrOfWells, NrOfDeviation, NrOfInbreds added in the output statement
Binod Gurung			2022-may-09		FN_IsParent function used for parent check [#34494]

=================EXAMPLE=============
EXEC PR_GetInfoForUpdateDA 837822
*/
CREATE PROCEDURE [dbo].[PR_GetInfoForUpdateDA]
(
	@DetAssignmentID	INT,
	@HybridAsParentCrop	NVARCHAR(10)
)
AS
BEGIN
	
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

	DECLARE @StatusCode INT, @TestID INT, @NrOfWells INT;

	SELECT @StatusCode = StatusCode FROM DeterminationAssignment WHERE DetAssignmentID = @DetAssignmentID;
	IF(ISNULL(@DetAssignmentID,0) = 0)
	BEGIN
		EXEC PR_ThrowError 'Invalid ID.';
		RETURN
	END

	IF(@StatusCode <> 600)
	BEGIN
		EXEC PR_ThrowError 'Invalid determination assignment status.';
		RETURN
	END

	SELECT 
		@NrOfWells = COUNT (DISTINCT W.WellID)
	FROM TestDetAssignment TDA
	JOIN Plate P On P.TestID = TDA.TestID
	JOIN Well W ON W.PlateID = P.PlateID AND W.DetAssignmentID = TDA.DetAssignmentID
	WHERE TDA.DetAssignmentID = @DetAssignmentID

	SELECT
		DetAssignmentID = Max(DA.DetAssignmentID),
		ValidatedOn		= FORMAT(MAX(ValidatedOn), 'yyyy-MM-dd', 'en-US'),
		Result			= CAST ( ((ISNULL(MAX(DA.Inbreed),0) + ISNULL(MAX(DA.Deviation),0)) * CAST(100 AS DECIMAL(5,2)) / @NrOfWells) AS DECIMAL(6,2)), --CAST ((MAX(DA.ActualSamples) * 100 / SUM(P.NrOfSamples)) AS DECIMAL),
		QualityClass	= MAX(QualityClass),
		ValidatedBy		= MAX(ValidatedBy),
		NrOfWells		= @NrOfWells,
		Inbreed			= MAX(DA.Inbreed),
		Deviation		= MAX(DA.Deviation),
		Remarks			= MAX(DA.Remarks),
		SendToABS		= MAX(T1.SendToABS)
	FROM DeterminationAssignment DA
	--Get calculation criteria per crop for hybrid/parent based on varietynr
	JOIN
	(
		SELECT 
			DetAssignmentID,
			SendToABS = CASE WHEN UsedForCriteria LIKE '%' + UsedFor + '%' THEN 0 ELSE 1 END
		FROM
		(
			SELECT 
				AC.CropCode,
				DA.DetAssignmentID,
				UsedFor = CASE WHEN dbo.FN_IsParent(V.VarietyNr, @HybridAsParentCrop) = 0 THEN 'Hyb' ELSE 'Par' END,
				UsedForCriteria =  CASE WHEN ISNULL(CCPC.CalcExternalAppHybrid,0) <> 0 AND ISNULL(CCPC.CalcExternalAppParent,0) = 0 THEN 'Hyb' 
										WHEN ISNULL(CCPC.CalcExternalAppHybrid,0) = 0 AND ISNULL(CCPC.CalcExternalAppParent,0) <> 0 THEN 'Par'
										WHEN ISNULL(CCPC.CalcExternalAppHybrid,0) <> 0 AND ISNULL(CCPC.CalcExternalAppParent,0) <> 0 THEN 'Hyb/Par'
										ELSE ''
									END
			FROM DeterminationAssignment DA
			JOIN ABSCrop AC ON AC.ABSCropCode = DA.ABSCropCode
			JOIN Variety V ON V.VarietyNr = DA.VarietyNr
			LEFT JOIN CalcCriteriaPerCrop CCPC ON CCPC.CropCode = AC.CropCode
			WHERE DA.DetAssignmentID = @DetAssignmentID
		) T
	) T1 ON T1.DetAssignmentID = DA.DetAssignmentID
	LEFT JOIN Pattern P On P.DetAssignmentID = DA.DetAssignmentID 
	WHERE DA.DetAssignmentID = @DetAssignmentID
	GROUP BY DA.DetAssignmentID

END

GO


DROP PROCEDURE IF EXISTS [dbo].[PR_GetDeterminationAssignments]
GO


/*
Author					Date			Description
Binod Gurung			2020-jan-23		Transcation isolation level implemented to avoid record lock
Dibya					2020-Feb-19		Performance improvements on unplanned data
Dibya					2020-Feb-25		Included NrOfPlates on response to calculate Plates on check changed event on client side.
Binod Gurung			2021-dec-22		Display empty slots on planning capacity screen [#30584]
Binod Gurung			2021-dec-27		Find invalid determination assignments which has mismatch information from ABS to PAC database [30904]
Binod Gurung			2022-jan-10		Add Fill rate information [#30910]
Binod Gurung			2022-may-09		FN_IsParent function used for parent check [#34494]

===================================Example================================

    --DECLARE @UnPlannedDataAsJson NVARCHAR(MAX) = N'[{"DetAssignmentID":1,"MethodCode":"PAC-01","ABSCropCode": "HP","VarietyNr":"21046"}]';
	DECLARE @UnPlannedDataAsJson TVP_DeterminationAssignment;
	DECLARE @InvalidIDs NVARCHAR(256) ,	@TotalUsed DECIMAL(10,2) ,@TotalReserved DECIMAL(10,2); 
    EXEC PR_GetDeterminationAssignments 4805, @UnPlannedDataAsJson, 'ON', @InvalidIDs OUTPUT, @TotalUsed OUTPUT, @TotalReserved OUTPUT
	SELECT @TotalUsed, @TotalReserved;
*/

CREATE PROCEDURE [dbo].[PR_GetDeterminationAssignments]
(
    @PeriodID	INT,
    @DeterminationAssignment TVP_DeterminationAssignment READONLY,
	@HybridAsParentCrop		NVARCHAR(10),
	@InvalidIDs NVARCHAR(256) OUTPUT,
	@TotalUsed DECIMAL(10,2) OUTPUT,
	@TotalReserved DECIMAL(10,2) OUTPUT
) 
AS 
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    DECLARE @StartDate DATE, @EndDate DATE;
    DECLARE @SQL NVARCHAR(MAX);
    DECLARE @PlatformID INT = (SELECT PlatformID FROM [Platform] WHERE PlatformCode = 'LS'); --light scanner   
    DECLARE @MaxSeqNr INT = 0
    
    DECLARE @Groups TABLE
    (
	   SlotName	    NVARCHAR(100),
	   ABSCropCode	    NVARCHAR(20), 
	   MethodCode	    NVARCHAR(50), 
	   UsedFor	    NVARCHAR(10),
	   TotalPlates	    INT,
	   NrOfResPlates	    DECIMAL(10,2)
    ); 
	DECLARE @GroupTbl TABLE
    (
	   SlotName			NVARCHAR(100),
	   ABSCropCode	    NVARCHAR(20), 
	   MethodCode	    NVARCHAR(50), 
	   UsedFor			NVARCHAR(10),
	   TotalPlates	    INT,
	   TotalRows		INT,
	   NrOfResPlates	DECIMAL(10,2)
    ); 
    DECLARE @Capacity TABLE
    (
	   ABSCropCode	    NVARCHAR(20), 
	   MethodCode	    NVARCHAR(50), 
	   UsedFor			NVARCHAR(10),
	   ResPlates   DECIMAL(10,2)
    );  
    --Prapare output of details records
    DECLARE @Result TABLE
    (
	   SeqNr			  INT,
	   DetAssignmentID    INT,
	   SampleNr		  INT,
	   PriorityCode	  INT,
	   MethodCode		  NVARCHAR(25),
	   ABSCropCode		  NVARCHAR(10),
	   Article		  NVARCHAR(100),
	   VarietyNr		  INT,
	   BatchNr		  INT,
	   RepeatIndicator    BIT,
	   Process		  NVARCHAR(100),
	   ProductStatus	  NVARCHAR(100),
	   Remarks			  NVARCHAR(MAX),
	   PlannedDate		  DATETIME,
	   UtmostInlayDate    DATETIME,
	   ExpectedReadyDate  DATETIME,
	   IsPlanned		  BIT,
	   UsedFor			NVARCHAR(10),
	   CanEdit			BIT,
	   IsLabPriority	BIT,
	   IsPacComplete	BIT,
	   IsInfoMissing	BIT
    );

    SELECT
	   @StartDate = StartDate,
	   @EndDate = EndDate
    FROM [Period]
    WHERE PeriodID = @PeriodID;
	--select * from @DeterminationAssignment; return;
    --Prepare capacities of planned records
    INSERT @Capacity(ABSCropCode, MethodCode, UsedFor, ResPlates)
    SELECT
	   T1.ABSCropCode,
	   T1.MethodCode,
	   T1.UsedFor,
	   NrOfPlates = SUM(T1.NrOfPlates)
    FROM
    (
		SELECT 
			V1.ABSCropCode,
			DA.MethodCode,
			V1.UsedFor,
			NrOfPlates = CAST((V1.NrOfSeeds / 92.0) AS DECIMAL(5,2))
		FROM DeterminationAssignment DA
		JOIN
		(
			SELECT 
				PM.MethodCode,
				AC.ABSCropCode,
				PM.NrOfSeeds,
				pcm.UsedFor
			FROM Method PM
			JOIN CropMethod PCM ON PCM.MethodID = PM.MethodID
			JOIN ABSCrop AC ON AC.ABSCropCode = PCM.ABSCropCode
			WHERE PCM.PlatformID = @PlatformID
			AND PM.StatusCode = 100
		) V1 ON V1.ABSCropCode = DA.ABSCropCode AND V1.MethodCode = DA.MethodCode
		--handle if same method is used for hybrid and parent
		JOIN
		(
			SELECT 
				VarietyNr, 
				UsedFor = CASE WHEN dbo.FN_IsParent(VarietyNr, @HybridAsParentCrop) = 0 THEN 'Hyb' ELSE 'Par' END
			FROM Variety
		) V ON V.VarietyNr = DA.VarietyNr AND V.UsedFor = V1.UsedFor
	   WHERE CAST(DA.PlannedDate AS DATE) BETWEEN @StartDate AND @EndDate
    ) T1 
    GROUP BY T1.ABSCropCode, T1.MethodCode, T1.UsedFor;

    --Prepare Groups of planned records groups
    INSERT @Groups(SlotName, ABSCropCode, MethodCode, UsedFor, TotalPlates, NrOfResPlates)
    SELECT
	   V1.SlotName,
	   V1.ABSCropCode,
	   V1.MethodCode,
	   V1.UsedFor,
	   V1.TotalPlates,
	   ResPlates = ISNULL(V2.ResPlates, 0)
    FROM
    (
	   SELECT 
		  PC.SlotName,
		  AC.ABSCropCode, 
		  PM.MethodCode,
		  CM.UsedFor,
		  TotalPlates = SUM(PC.NrOfPlates)
	   FROM ReservedCapacity PC
	   JOIN CropMethod CM ON CM.CropMethodID = PC.CropMethodID
	   JOIN ABSCrop AC ON AC.ABSCropCode = CM.ABSCropCode
	   JOIN Method PM ON PM.MethodID = CM.MethodID
	   WHERE CM.PlatformID = @PlatformID AND PC.PeriodID = @PeriodID
	   GROUP BY PC.SlotName, AC.ABSCropCode, PM.MethodCode, CM.UsedFor
    ) V1
    LEFT JOIN @Capacity V2 ON V2.ABSCropCode = V1.ABSCropCode AND V2.MethodCode = V1.MethodCode AND V2.UsedFor = V1.UsedFor;
	    
    --Get details of planned determinations    
    INSERT @Result
    (
	   SeqNr,
	   DetAssignmentID,	 
	   MethodCode,		
	   ABSCropCode,
	   SampleNr,
	   UtmostInlayDate, 
	   ExpectedReadyDate,
	   PriorityCode,	
	   BatchNr,	
	   RepeatIndicator, 
	   Article,
	   VarietyNr,
	   Process,		
	   ProductStatus,	
	   Remarks, 
	   PlannedDate,	   
	   IsPlanned,		
	   UsedFor,
	   CanEdit,
	   IsLabPriority,
	   IsPacComplete
    )
    SELECT 
	   DA.SeqNr,
	   DA.DetAssignmentID,
	   DA.MethodCode,
	   DA.ABSCropCode,
	   DA.SampleNr,
	   DA.UtmostInlayDate,
	   DA.ExpectedReadyDate, 
	   DA.PriorityCode,	   
	   DA.BatchNr,
	   DA.RepeatIndicator,
	   V.Shortname,
	   V.VarietyNr,
	   DA.Process,
	   DA.ProductStatus,
	   DA.Remarks,
	   DA.PlannedDate,
	   IsPlanned = 1,
	   UsedFor = V.UsedFor,
	   --UsedFor = V1.UsedFor,
	   CASE WHEN DA.StatusCode < 200 THEN 1 ELSE 0 END,
	   ISNULL(DA.IsLabPriority, 0),
	   1 --Pac complete profile true for already planned DA
    FROM DeterminationAssignment DA
    JOIN
    (
	   SELECT
		  AC.ABSCropCode,
		  PM.MethodCode,
		  CM.UsedFor
	   FROM CropMethod CM
	   JOIN ABSCrop AC ON AC.ABSCropCode = CM.ABSCropCode
	   JOIN Method PM ON PM.MethodID = CM.MethodID
	   WHERE CM.PlatformID = @PlatformID
    ) V1 ON V1.ABSCropCode = DA.ABSCropCode AND V1.MethodCode = DA.MethodCode
	JOIN
	(
		SELECT 
			VarietyNr, 
			Shortname,
			UsedFor = CASE WHEN dbo.FN_IsParent(VarietyNr, @HybridAsParentCrop) = 0 THEN 'Hyb' ELSE 'Par' END
		FROM Variety
	) V ON V.VarietyNr = DA.VarietyNr AND V.UsedFor = V1.UsedFor
    WHERE CAST(DA.PlannedDate AS DATE) BETWEEN @StartDate AND @EndDate
	
    --Process unplannded records    
    IF EXISTS (SELECT DetAssignmentID FROM @DeterminationAssignment) BEGIN
	   SELECT 
		  @MaxSeqNr = MAX(SeqNr) 
	   FROM @Result;
	   
	   --no need to process @Capacity, res plates is always 0 for unplanned records
	   --Prepare Grops of planned records groups
	   INSERT @Groups(SlotName, ABSCropCode, MethodCode, UsedFor, TotalPlates, NrOfResPlates)
	   SELECT
		  V1.SlotName,
		  V1.ABSCropCode,
		  V1.MethodCode,
		  V1.UsedFor,
		  V1.TotalPlates,
		  ResPlates = 0
	   FROM
	   (
		  SELECT 
			 PC.SlotName,
			 AC.ABSCropCode, 
			 PM.MethodCode,
			 CM.UsedFor,
			 TotalPlates = SUM(PC.NrOfPlates)
		  FROM ReservedCapacity PC
		  JOIN CropMethod CM ON CM.CropMethodID = PC.CropMethodID
		  JOIN ABSCrop AC ON AC.ABSCropCode = CM.ABSCropCode
		  JOIN Method PM ON PM.MethodID = CM.MethodID
		  WHERE CM.PlatformID = @PlatformID AND PC.PeriodID = @PeriodID
		  GROUP BY PC.SlotName, AC.ABSCropCode, PM.MethodCode, CM.UsedFor
	   ) V1
	   WHERE NOT EXISTS
	   (
		  SELECT ABSCropCode, MethodCode
		  FROM @Groups
		  WHERE ABSCropCode = V1.ABSCropCode AND MethodCode = V1.MethodCode
	   );
	   
	   --Get details of unplanned determinations    
	   INSERT @Result
	   (
		  SeqNr,
		  DetAssignmentID,	 
		  MethodCode,		
		  ABSCropCode,
		  SampleNr,
		  UtmostInlayDate, 
		  ExpectedReadyDate,
		  PriorityCode,	
		  BatchNr,	
		  RepeatIndicator, 
		  Article,
		  VarietyNr,
		  Process,		
		  ProductStatus,	
		  Remarks, 
		  PlannedDate,	   
		  IsPlanned,		
		  UsedFor,
		  CanEdit,
		  IsLabPriority,
		  IsPacComplete,
		  IsInfoMissing
	   )
	   SELECT 
		  SeqNr = ROW_NUMBER() OVER(ORDER BY DetAssignmentID) + @MaxSeqNr,
		  DA.DetAssignmentID,
		  DA.MethodCode,
		  DA.ABSCropCode,
		  DA.SampleNr,
		  DA.UtmostInlayDate,
		  DA.ExpectedReadyDate, 
		  DA.PriorityCode,	   
		  DA.BatchNr,
		  DA.RepeatIndicator,
		  V.Shortname,
		  V.VarietyNr,
		  DA.Process,
		  DA.ProductStatus,
		  DA.Remarks,
		  DA.PlannedDate,
		  IsPlanned = 0,
		  UsedFor = V.UsedFor,
		  --UsedFor = V1.UsedFor,
		  CASE WHEN DA.PriorityCode IN(4, 7, 8) THEN 0 ELSE 1 END,
		  0,
		  dbo.FN_IsPacProfileComplete (DA.VarietyNr, @PlatformID, V1.CropCode), --#8068 Check PAC profile complete 
		  IsInfoMissing = CASE WHEN V1.ABSCropCode IS NULL OR V.VarietyNr IS NULL THEN 1 ELSE 0 END
	   FROM @DeterminationAssignment DA
	   JOIN
	   (
		  SELECT
			 AC.ABSCropCode,
			 AC.CropCode,
			 PM.MethodCode,
			 CM.UsedFor
		  FROM CropMethod CM
		  JOIN ABSCrop AC ON AC.ABSCropCode = CM.ABSCropCode
		  JOIN Method PM ON PM.MethodID = CM.MethodID
		  WHERE CM.PlatformID = @PlatformID
	   ) V1 ON V1.ABSCropCode = DA.ABSCropCode AND V1.MethodCode = DA.MethodCode
	   --JOIN ABSCrop AC ON AC.ABSCropCode = DA.ABSCropCode
	   JOIN
	   (
			SELECT 
				VarietyNr, 
				Shortname,
				UsedFor = CASE WHEN dbo.FN_IsParent(VarietyNr, @HybridAsParentCrop) = 0 THEN 'Hyb' ELSE 'Par' END
			FROM Variety
	   ) V ON V.VarietyNr = DA.VarietyNr AND V.UsedFor = V1.UsedFor
	   WHERE NOT EXISTS
	   (
		  SELECT DetAssignmentID 
		  FROM DeterminationAssignment
		  WHERE DetAssignmentID = DA.DetAssignmentID
	   );	
	   
    END  

    --return groups
	INSERT @GroupTbl(ABSCropCode, MethodCode, NrOfResPlates, SlotName, TotalPlates, TotalRows, UsedFor )
    SELECT 
		G.ABSCropCode,
		G.MethodCode,
		G.NrOfResPlates,
		G.SlotName,
		G.TotalPlates,
		V.TotalRows,
		G.UsedFor
    FROM @Groups G
    LEFT JOIN
    (
	   SELECT 
		  R.ABSCropCode,
		  R.MethodCode,
		  R.UsedFor,
		  TotalRows = COUNT( R.DetAssignmentID)
	   FROM @Result R
	   GROUP BY R.ABSCropCode, R.MethodCode, R.UsedFor
    ) V ON V.ABSCropCode = G.ABSCropCode AND V.MethodCode = G.MethodCode AND V.UsedFor = G.UsedFor
    WHERE G.TotalPlates > 0

	SELECT * FROM @GroupTbl;

    --return details
    SELECT 
	   DetAssignmentID,	 
	   T.MethodCode,		
	   ABSCropCode,
	   SampleNr,
	   UtmostInlayDate = FORMAT(UtmostInlayDate, 'dd/MM/yyyy'), 
	   ExpectedReadyDate = FORMAT(ExpectedReadyDate, 'dd/MM/yyyy'),
	   PriorityCode,	
	   BatchNr,	
	   RepeatIndicator, 
	   Article,
	   Process,		
	   ProductStatus,	
	   Remarks, 
	   PlannedDate = FORMAT(PlannedDate, 'dd/MM/yyyy'),
	   IsPlanned,		
	   UsedFor,
	   CanEditPlanning = CanEdit,
	   IsLabPriority,
	   IsPacComplete,
	   IsInfoMissing,
	   VarietyNr,
	   NrOfPlates = CAST((M.NrOfSeeds / 92.0) AS DECIMAL(5,2))
    FROM @Result T
    JOIN Method M ON M.MethodCode = T.MethodCode
    ORDER BY T.ABSCropCode, T.MethodCode, T.PriorityCode, ExpectedReadyDate;

	--Fill Rate (total used by batches / total reserved in capacity planning )
	SELECT 
		@TotalUsed = SUM(ISNULL(NrOfResPlates,0))
	FROM @GroupTbl

	SELECT 
		@TotalReserved = SUM(ISNULL(TotalPlates,0))
	FROM @GroupTbl

	--check if Variety is invalid
	SELECT 
		@InvalidIDs = COALESCE(@InvalidIDs + ',','') + CAST (DA.DetAssignmentID AS NVARCHAR(20))
	FROM @DeterminationAssignment DA
	LEFT JOIN Variety V ON V.VarietyNr = DA.VarietyNr
	WHERE V.VarietyNr IS NULL

	--check if Crop/Method is invalid
	SELECT 
		@InvalidIDs = COALESCE(@InvalidIDs + ',','') + CAST (DA.DetAssignmentID AS NVARCHAR(20))
	FROM @DeterminationAssignment DA
	LEFT JOIN
	(
		SELECT
			AC.ABSCropCode,
			PM.MethodCode,
			CM.UsedFor
		FROM CropMethod CM
		JOIN ABSCrop AC ON AC.ABSCropCode = CM.ABSCropCode
		JOIN Method PM ON PM.MethodID = CM.MethodID
		WHERE CM.PlatformID = @PlatformID
	) V1 ON V1.ABSCropCode = DA.ABSCropCode AND V1.MethodCode = DA.MethodCode
	WHERE V1.ABSCropCode IS NULL

	--Add descriptive message if invalid ID exists
	IF(ISNULL(@InvalidIDs,'') <> '')
		SET @InvalidIDs = 'Information mismatch for the following determination assignments.<br>' + @InvalidIDs;

END
GO



DROP PROCEDURE IF EXISTS [dbo].[PR_GetBatch]
GO


/*
Author					Date			Remarks
Krishna Gautam			2020/01/16		Created Stored procedure to fetch data
Krishna Gautam			2020/01/21		Status description is sent instead of status code.
Krishna Gautam			2020/01/21		Column Label change.
Binod Gurung			2020-jan-23		Transcation isolation level implemented to avoid record lock
Dibya Mani Suvedi		2020-jan-27		Changed VarietyName from VarietyNr to ShortName
Dibya Mani Suvedi		2020-Feb-25		Applied sorting and default sorting for ValidatedOn DESC
Binod Gurung			2020-aug-20		Deviation and Inbred added
Binod Gurung			2022-feb-25		Organic(BioIndicator) column added

=================EXAMPLE=============

exec PR_GetBatch @PageNr=1,@PageSize=50,@HybridAsParentCrop='ON',@CropCode=N'SP',@SortBy=N'',@SortOrder=N''
*/
CREATE PROCEDURE [dbo].[PR_GetBatch]
(
	@PageNr INT,
	@PageSize INT,
	@HybridAsParentCrop	NVARCHAR(10),
	@CropCode NVARCHAR(10) =NULL,
	@PlatformDesc NVARCHAR(100) = NULL,
	@MethodCode NVARCHAR(50) = NULL, 
	@Plates NVARCHAR(100) = NULL, 
	@TestName NVARCHAR(100) = NULL,
	@StatusCode NVARCHAR(100) = NULL, 
	@ExpectedWeek NVARCHAR(100) = NULL,
	@SampleNr NVARCHAR(100) = NULL, 
	@BatchNr NVARCHAR(100) = NULL, 
	@DetAssignmentID  NVARCHAR(100) = NULL,
	@VarietyNr NVARCHAR(100) = NULL,
	@BioIndicator NVARCHAR(10) = NULL,
	@QualityClass NVARCHAR(10) = NULL,
	@Deviation NVARCHAR(100) = NULL,
	@Inbreed NVARCHAR(100) = NULL,
	@ValidatedOn VARCHAR(20) = NULL,
	@SortBy	 NVARCHAR(100) = NULL,
	@SortOrder VARCHAR(20) = NULL
)
AS
BEGIN
	SET NOCOUNT ON;
	SET DATEFORMAT DMY;

	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

	IF(ISNULL(@SortBy, '') = '') BEGIN
	   SET @SortBy = 'ValidatedOn';
	END
	IF(ISNULL(@SortOrder, '') = '') BEGIN
	   SET @SortOrder = 'DESC';
	END

	DECLARE @Offset INT;
	DECLARE @Columns TABLE(ColumnID NVARCHAR(100), ColumnName NVARCHAR(100),IsVisible BIT, [Order] INT);
	DECLARE @SQL NVARCHAR(MAX), @Parameters NVARCHAR(MAX);

	SET @OffSet = @PageSize * (@pageNr -1);
	
	SET @SQL = N'
	DECLARE @Status TABLE(StatusCode INT, StatusName NVARCHAR(100));
	
	INSERT INTO @Status(StatusCode, StatusName)
	SELECT StatusCode,StatusName FROM [Status] WHERE StatusTable = ''DeterminationAssignment'';

	WITH CTE AS 
	(
		SELECT * FROM 
		(
			SELECT T.TestID, 
				C.CropCode,
				PlatformDesc = P.PlatformCode,
				M.MethodCode, 
				Plates = CAST(CAST((M.NrOfSeeds/92.0) as decimal(4,2)) AS NVARCHAR(10)), 
				T.TestName ,
				StatusCode = S.StatusName,
				[ExpectedWeek] = CONCAT(FORMAT(DATEPART(WEEK, DA.ExpectedReadyDate), ''00''), '' ('', FORMAT(DA.ExpectedReadyDate, ''yyyy''), '')''),
				SampleNr = CAST(DA.SampleNr AS NVARCHAR(50)), 
				BatchNr = CAST(DA.BatchNr AS NVARCHAR(50)), 
				DetAssignmentID = CAST(DA.DetAssignmentID AS NVARCHAR(50)) ,
				VarietyNr = V.ShortName,
				BioIndicator = CASE WHEN ISNULL(DA.BioIndicator,0) = 0 THEN ''No'' ELSE ''Yes'' END,
				DA.QualityClass,
				DA.Deviation,
				DA.Inbreed,
				ValidatedOn = FORMAT(ValidatedOn, ''dd/MM/yyyy''),
				IsLabPriority = CAST(ISNULL(DA.IsLabPriority,0) AS INT)
			FROM  Test T 
			JOIN TestDetAssignment TDA ON TDA.TestID = T.TestID
			JOIN DeterminationAssignment DA ON DA.DetAssignmentID = TDA.DetAssignmentID
			JOIN @Status S ON S.StatusCode = DA.StatusCode
			JOIN Method M ON M.MethodCode = DA.MethodCode
			JOIN CropMethod CM ON CM.MethodID = M.MethodID AND CM.ABSCropCode = DA.ABSCropCode
			JOIN
			(
				SELECT 
					VarietyNr, 
					Shortname,
					UsedFor = CASE WHEN dbo.FN_IsParent(VarietyNr, @HybridAsParentCrop) = 0 THEN ''Hyb'' ELSE ''Par'' END
				FROM Variety
			) V ON V.VarietyNr = DA.VarietyNr AND V.UsedFor = CM.UsedFor
			JOIN ABSCrop C ON C.ABSCropCode = CM.ABSCropCode
			JOIN [Platform] P ON P.PlatformID = CM.PlatformID
		) T
		WHERE 
		(ISNULL(@CropCode,'''') = '''' OR CropCode like ''%''+ @CropCode +''%'') AND
		(ISNULL(@PlatformDesc,'''') = '''' OR PlatformDesc like ''%''+ @PlatformDesc +''%'') AND
		(ISNULL(@MethodCode,'''') = '''' OR MethodCode like ''%''+ @MethodCode +''%'') AND
		(ISNULL(@Plates,'''') = '''' OR Plates like ''%''+ @Plates +''%'') AND
		(ISNULL(@TestName,'''') = '''' OR TestName like ''%''+ @TestName +''%'') AND
		(ISNULL(@StatusCode,'''') = '''' OR StatusCode like ''%''+ @StatusCode +''%'') AND
		(ISNULL(@ExpectedWeek,'''') = '''' OR ExpectedWeek like ''%''+ @ExpectedWeek +''%'') AND
		(ISNULL(@SampleNr,'''') = '''' OR SampleNr like ''%''+ @SampleNr +''%'') AND
		(ISNULL(@BatchNr,'''') = '''' OR BatchNr like ''%''+ @BatchNr +''%'') AND
		(ISNULL(@DetAssignmentID,'''') = '''' OR DetAssignmentID like ''%''+ @DetAssignmentID +''%'') AND
		(ISNULL(@VarietyNr,'''') = '''' OR VarietyNr like ''%''+ @VarietyNr +''%'') AND
		(ISNULL(@BioIndicator,'''') = '''' OR BioIndicator like ''%''+ @BioIndicator +''%'') AND
		(ISNULL(@QualityClass,'''') = '''' OR QualityClass like ''%''+ @QualityClass +''%'') AND
		(ISNULL(@ValidatedOn,'''') = '''' OR ValidatedOn like ''%''+ @ValidatedOn +''%'') AND
		(ISNULL(@Deviation,'''') = '''' OR Deviation like ''%''+ @Deviation +''%'') AND
		(ISNULL(@Inbreed,'''') = '''' OR Inbreed like ''%''+ @Inbreed +''%'')
	), Count_CTE AS (SELECT COUNT(TestID) AS [TotalRows] FROM CTE)
	SELECT 	
		CropCode,
		PlatformDesc,
		MethodCode, 
		Plates , 
		TestName,
		StatusCode, 
		ExpectedWeek,
		SampleNr, 
		BatchNr, 
		DetAssignmentID ,
		VarietyNr,
		BioIndicator,
		QualityClass,
		Deviation,
		Inbreed,
		ValidatedOn,
		IsLabPriority,
		TotalRows
    FROM CTE,Count_CTE 
    ORDER BY ' + QUOTENAME(@SortBy) + ' ' + @SortOrder + N'   
    OFFSET @Offset ROWS
    FETCH NEXT @PageSize ROWS ONLY';

    SET @Parameters = N'@PageNr INT, @PageSize INT, @HybridAsParentCrop NVARCHAR(10), @CropCode NVARCHAR(10), @PlatformDesc NVARCHAR(100), @MethodCode NVARCHAR(50), 
	@Plates NVARCHAR(100), @TestName NVARCHAR(100), @StatusCode NVARCHAR(100), @ExpectedWeek NVARCHAR(100), @SampleNr NVARCHAR(100), 
	@BatchNr NVARCHAR(100), @DetAssignmentID NVARCHAR(100), @VarietyNr NVARCHAR(100), @BioIndicator NVARCHAR(10), @QualityClass NVARCHAR(10), @Deviation NVARCHAR(100), @Inbreed NVARCHAR(100), @ValidatedOn NVARCHAR(20), @OffSet INT';

    EXEC sp_executesql @SQL, @Parameters, @PageNr, @PageSize, @HybridAsParentCrop, @CropCode, @PlatformDesc, @MethodCode, @Plates, @TestName,
	   @StatusCode, @ExpectedWeek, @SampleNr, @BatchNr, @DetAssignmentID, @VarietyNr, @BioIndicator, @QualityClass, @Deviation, @Inbreed, @ValidatedOn, @OffSet;

	INSERT INTO @Columns(ColumnID,ColumnName,IsVisible,[Order])
	VALUES
	('CropCode','Crop',1,1),	
	('ExpectedWeek','Exp. Wk',1,2),
	('ValidatedOn','Approved Date',1,3),
	('SampleNr','SampleNr',1,4),
	('BatchNr','BatchNr',1,5),
	('DetAssignmentID','Det. Assignment',1,6),
	('VarietyNr','Var. Name',1,7),
	('BioIndicator','Organic',1,8),
	('QualityClass','Qlty Class',1,9),
	('Deviation','Deviation',1,10),
	('Inbreed','Inbred',1,11),
	('PlatformDesc','Platform',1,12),
	('MethodCode','Method',1,13),
	('Plates','#Plates',1,14),
	('TestName','Folder',1,15),
	('StatusCode','Status',1,16)

	SELECT * FROM @Columns order by [Order];
END
GO


DROP PROCEDURE IF EXISTS [dbo].[PR_PlanAutoDeterminationAssignments]
GO


/*
Author					Date			Description
Binod Gurung			2020-jan-23		Transcation isolation level implemented to avoid record lock
Dibya					2020-Feb-19		Performance improvements on unplanned data	
Dibya					2020-MAR-4		Adjusted ExpectedReadyDate
Binod Gurung			2022-may-09		FN_IsParent function used for parent check
===================================Example================================

    DECLARE @ABSDataAsJson NVARCHAR(MAX) =  N'[{"DetAssignmentID":1736406,"MethodCode":"PAC-01","ABSCropCode": "SP","VarietyNr":"21063","PriorityCode": 1}]';
    EXEC PR_PlanAutoDeterminationAssignments 4779, @ABSDataAsJson
*/
CREATE PROCEDURE [dbo].[PR_PlanAutoDeterminationAssignments]
(
    @PeriodID	 INT,
    @ExpWeekDifference	 INT,
    @ABSData	 TVP_DeterminationAssignment READONLY,
	@HybridAsParentCrop		NVARCHAR(10)
) 
AS 
BEGIN
    SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    DECLARE @TransCount BIT = 0;

    DECLARE @ABSCropCode NVARCHAR(10);
    DECLARE @MethodCode	NVARCHAR(25);
    DECLARE @RequiredPlates INT;
    DECLARE @UsedFor NVARCHAR(10);
    DECLARE @PlatesPerMethod	  DECIMAL(5,2);
    DECLARE @RequiredDeterminations INT;
    DECLARE @StartDate DATE, @EndDate DATE;
    DECLARE @PlannedDate DATETIME, @ExpectedReadyDate DATETIME;
    DECLARE @IDX INT = 1;
    DECLARE @CNT INT = 0;
    
    SELECT
	   @StartDate = StartDate,
	   @EndDate = EndDate
    FROM [Period]
    WHERE PeriodID = @PeriodID;

    --This is the first Monday of the selected week
    SET @PlannedDate = dbo.FN_GetWeekStartDate(@StartDate);
    --Add number of week on start date and get the Friday of that week.
    SET @ExpectedReadyDate = DATEADD(WEEK, @ExpWeekDifference, @StartDate);
    --Get Monday of ExpectedReadyDate
    SET @ExpectedReadyDate = dbo.FN_GetWeekStartDate(@ExpectedReadyDate);
    --get the date of Friday of that expected ready date
    SET @ExpectedReadyDate = DATEADD(DAY, 4, @ExpectedReadyDate);

    DECLARE @PlatformID INT = (SELECT PlatformID FROM [Platform] WHERE PlatformCode = 'LS'); --light scanner   

    DECLARE @Capacity TABLE
    (
	   UsedFor	    VARCHAR(5), 
	   ABSCropCode	    NVARCHAR(10), 
	   MethodCode	    NVARCHAR(50), 
	   ReservePlates   DECIMAL(5,2)
    );

    DECLARE @Groups TABLE
    (
	   ID		    INT IDENTITY(1, 1),    
	   ABSCropCode	    NVARCHAR(10), 
	   MethodCode	    NVARCHAR(50), 
	   UsedFor	    VARCHAR(5), 
	   ReservePlates   DECIMAL(5,2),
	   TotalPlates	DECIMAL(5,2)
    );

    --handle unplanned records if exists
    DECLARE @DeterminationAssignment TABLE
    (
	   DetAssignmentID	    INT,
	   SampleNr		    INT,
	   PriorityCode	    INT,
	   MethodCode		    NVARCHAR(25),
	   CropCode		    NVARCHAR(10),
	   ABSCropCode		   NVARCHAR(20),
	   VarietyNr		    INT,
	   BatchNr		    INT,
	   RepeatIndicator	    BIT,
	   Process		    NVARCHAR(100),
	   ProductStatus	    NVARCHAR(100),
	   Remarks	    NVARCHAR(250),
	   PlannedDate		   DATE,
	   UtmostInlayDate	    DATE,
	   ExpectedReadyDate   DATE,
	   ReceiveDate		  DATETIME,
	   ReciprocalProd	  BIT,
	   BioIndicator		  BIT,
	   LogicalClassificationCode	NVARCHAR(20),
	   LocationCode					NVARCHAR(20),
	   UsedFor		    NVARCHAR(10)
    );

     BEGIN TRY
	   IF @@TRANCOUNT = 0 BEGIN
		  BEGIN TRANSACTION;
		  SET @TransCount = 1;
	   END

	   --clean already planned records before planning again
	   DELETE DA
	   FROM DeterminationAssignment DA
	   WHERE CAST(DA.PlannedDate AS DATE) BETWEEN @StartDate AND @EndDate
	   AND DA.StatusCode = 100;

	   INSERT @Capacity(UsedFor, ABSCropCode, MethodCode, ReservePlates)
	   SELECT
		  T1.UsedFor,
		  T1.ABSCropCode,
		  T1.MethodCode,
		  NrOfPlates = SUM(T1.NrOfPlates)
	   FROM
	   (
			SELECT 
				V1.ABSCropCode,
				DA.MethodCode,
				V1.UsedFor,
				NrOfPlates = CAST((V1.NrOfSeeds / 92.0) AS DECIMAL(5,2))
			FROM DeterminationAssignment DA
			JOIN
			(
				SELECT 
				PM.MethodCode,
				AC.ABSCropCode,
				PM.NrOfSeeds,
				PCM.UsedFor
				FROM Method PM
				JOIN CropMethod PCM ON PCM.MethodID = PM.MethodID
				JOIN ABSCrop AC ON AC.ABSCropCode = PCM.ABSCropCode
				WHERE PCM.PlatformID = @PlatformID
				AND PM.StatusCode = 100
			) V1 ON V1.ABSCropCode = DA.ABSCropCode AND V1.MethodCode = DA.MethodCode
			--handle if same method is used for hybrid and parent
			JOIN
			(
				SELECT 
					VarietyNr, 
					UsedFor = CASE WHEN dbo.FN_IsParent(VarietyNr, @HybridAsParentCrop) = 0 THEN 'Hyb' ELSE 'Par' END
				FROM Variety
			) V ON V.VarietyNr = DA.VarietyNr AND V.UsedFor = V1.UsedFor
			WHERE CAST(DA.PlannedDate AS DATE) BETWEEN @StartDate AND @EndDate
	   ) T1 
	   GROUP BY T1.ABSCropCode, T1.MethodCode, T1.UsedFor;

	   INSERT INTO @Groups(ABSCropCode, MethodCode, UsedFor, TotalPlates, ReservePlates)
	   SELECT
		  V1.ABSCropCode,
		  V1.MethodCode,
		  V1.UsedFor,
		  ISNULL(V1.TotalPlates, 0),
		  ISNULL(V2.ReservePlates, 0)
	   FROM
	   (
		  SELECT 
			 PC.SlotName,
			 AC.ABSCropCode, 
			 PM.MethodCode,	
			 CM.UsedFor,
			 TotalPlates = SUM(PC.NrOfPlates)
		  FROM ReservedCapacity PC
		  JOIN CropMethod CM ON CM.CropMethodID = PC.CropMethodID
		  JOIN ABSCrop AC ON AC.ABSCropCode = CM.ABSCropCode
		  JOIN Method PM ON PM.MethodID = CM.MethodID
		  WHERE CM.PlatformID = @PlatformID AND PC.PeriodID = @PeriodID
		  GROUP BY PC.SlotName, AC.ABSCropCode, PM.MethodCode, CM.UsedFor
	   ) V1
	   LEFT JOIN @Capacity V2 ON V2.ABSCropCode = V1.ABSCropCode AND V2.MethodCode = V1.MethodCode AND V2.UsedFor = V1.UsedFor;

	   INSERT @DeterminationAssignment
	   (
		    DetAssignmentID, 
		    SampleNr, 
		    PriorityCode, 
		    MethodCode, 
		    ABSCropCode, 
		    VarietyNr, 
		    BatchNr, 
		    RepeatIndicator, 
		    Process, 
		    ProductStatus, 
		    Remarks, 
		    PlannedDate, 
		    UtmostInlayDate, 
		    ExpectedReadyDate,
		    ReceiveDate,
		    ReciprocalProd,
		    BioIndicator,
		    LogicalClassificationCode,
		    LocationCode,
		    UsedFor
	   )
	   SELECT 
		  T1.DetAssignmentID, 
		  T1.SampleNr, 
		  T1.PriorityCode, 
		  T1.MethodCode, 
		  T1.ABSCropCode, 
		  T1.VarietyNr, 
		  T1.BatchNr, 
		  T1.RepeatIndicator, 
		  T1.Process, 
		  T1.ProductStatus, 
		  T1.Remarks, 
		  @PlannedDate,
		  T1.UtmostInlayDate, 
		  @ExpectedReadyDate,
		  T1.ReceiveDate,
		  T1.ReciprocalProd,
		  T1.BioIndicator,
		  T1.LogicalClassificationCode,
		  T1.LocationCode,
		  UsedFor = CASE WHEN dbo.FN_IsParent(V.VarietyNr, @HybridAsParentCrop) = 0 THEN 'Hyb' ELSE 'Par' END
	   FROM @ABSData T1
	   JOIN ABSCrop C ON C.ABSCropCode = T1.ABSCropCode
	   JOIN Variety V ON V.VarietyNr = T1.VarietyNr
	   JOIN Method M ON M.MethodCode = T1.MethodCode
	   WHERE T1.PriorityCode NOT IN(4, 7, 8)
	   AND dbo.FN_IsPacProfileComplete (V.VarietyNr, @PlatformID, C.CropCode) = 1 -- #8068 Only plan if PAC profile complete is true
	   ORDER BY T1.PriorityCode;
    	  
	   SELECT @CNT = COUNT(ID) FROM @Groups;
	   WHILE(@IDX <= @CNT) BEGIN
		  SELECT 
			 @ABSCropCode =  G.ABSCropCode,
			 @MethodCode = G.MethodCode,
			 @RequiredPlates = G.TotalPlates - G.ReservePlates,
			 @UsedFor = G.UsedFor
		  FROM @Groups G
		  WHERE ID = @IDX;
    
		  IF(@RequiredPlates > 0) BEGIN	   
			 SELECT 
				@PlatesPerMethod = CAST((NrOfSeeds / 92.0) AS DECIMAL(5,2))
			 FROM Method 
			 WHERE MethodCode = @MethodCode;

			 SET @RequiredDeterminations = @RequiredPlates / @PlatesPerMethod;

			 --insert records into DeterminationAssignments and calculate required plates again
			 INSERT INTO DeterminationAssignment
			 (
				DetAssignmentID, 
				SampleNr, 
				PriorityCode, 
				MethodCode, 
				ABSCropCode, 
				VarietyNr, 
				BatchNr, 
				RepeatIndicator, 
				Process, 
				ProductStatus, 
				Remarks, 
				PlannedDate, 
				UtmostInlayDate, 
				ExpectedReadyDate,
				StatusCode,
				ReceiveDate,
				ReciprocalProd,
				BioIndicator,
				LogicalClassificationCode,
				LocationCode
			 )
			 SELECT TOP(@RequiredDeterminations) 
				DetAssignmentID, 
				SampleNr, 
				PriorityCode, 
				MethodCode, 
				ABSCropCode, 
				VarietyNr, 
				BatchNr, 
				RepeatIndicator, 
				Process, 
				ProductStatus, 
				Remarks, 
				D.PlannedDate,
				UtmostInlayDate, 
				ExpectedReadyDate,
				100,
				ReceiveDate,
				ReciprocalProd,
				BioIndicator,
				LogicalClassificationCode,
				LocationCode
			 FROM @DeterminationAssignment D
			 WHERE D.ABSCropCode = @ABSCropCode 
			 AND D.MethodCode = @MethodCode
			 AND D.UsedFor = @UsedFor
			 AND ISNULL(D.PriorityCode, 0) <> 0 
			 AND NOT EXISTS
			 (
				SELECT 
				    DetAssignmentID 
				FROM DeterminationAssignment
				WHERE DetAssignmentID = D.DetAssignmentID
			 )
			 ORDER BY D.PriorityCode;
			 --now check if plates are fulfilled already with priority	   
			 SET @RequiredPlates = @RequiredPlates - (@@ROWCOUNT * @PlatesPerMethod);
			 --if we still need determinations, get it based on expected ready date here
			 IF(@RequiredPlates > 0 AND @RequiredPlates > @PlatesPerMethod) BEGIN
				--PRINT 'we need more'
				--determine how many determinations required for required plates
				SET @RequiredDeterminations = @RequiredPlates / @PlatesPerMethod;

				INSERT INTO DeterminationAssignment
				(
				    DetAssignmentID, 
				    SampleNr, 
				    PriorityCode, 
				    MethodCode, 
				    ABSCropCode, 
				    VarietyNr, 
				    BatchNr, 
				    RepeatIndicator, 
				    Process, 
				    ProductStatus, 
				    Remarks, 
				    PlannedDate, 
				    UtmostInlayDate, 
				    ExpectedReadyDate,
				    StatusCode,
				    ReceiveDate,
				    ReciprocalProd,
				    BioIndicator,
				    LogicalClassificationCode,
				    LocationCode
				)
				SELECT TOP(@RequiredDeterminations) 
				    DetAssignmentID, 
				    SampleNr, 
				    PriorityCode, 
				    MethodCode, 
				    ABSCropCode, 
				    VarietyNr, 
				    BatchNr, 
				    RepeatIndicator, 
				    Process, 
				    ProductStatus, 
				    Remarks, 
				    @PlannedDate,
				    UtmostInlayDate, 
				    ExpectedReadyDate,
				    100,
				    ReceiveDate,
				    ReciprocalProd,
				    BioIndicator,
				    LogicalClassificationCode,
				    LocationCode
				FROM @DeterminationAssignment D
				WHERE D.ABSCropCode = @ABSCropCode 
				AND D.MethodCode = @MethodCode
				AND D.UsedFor = @UsedFor
				AND ISNULL(PriorityCode, 0) = 0 
				AND NOT EXISTS
				(
				    SELECT 
					   DetAssignmentID 
				    FROM DeterminationAssignment
				    WHERE DetAssignmentID = D.DetAssignmentID
				)
				ORDER BY D.ExpectedReadyDate;
			 END
		  END
		  SET @IDX = @IDX + 1;
	   END

	   IF @TransCount = 1 
		  COMMIT;
    END TRY
    BEGIN CATCH
	   IF @TransCount = 1 
		  ROLLBACK;
	   THROW;
    END CATCH
END
GO


DROP PROCEDURE IF EXISTS [dbo].[PR_GetFolderDetails]
GO


/*
Author					Date			Description
Binod Gurung			2020-jan-23		Transcation isolation level implemented to avoid record lock	
Krishna Gautam			2020/02/19		Calculation of nr of marker is done per plate on group level.
Dibya					2020/02/20		Made #plates as absolute number.
Krishna Gautam			2020/02/27		Added plates information on batches.
Binod Gurung			2020/03/10		#11471 Sorting added on Variety name 
Binod Gurtung			2021/11/25		#29378 : Determination assignment status code added
Binod Gurung			2022-jan-10		Add Fill rate information [#30910]
===================================Example================================

    EXEC PR_GetFolderDetails 4828, 'ON';
	
*/
CREATE PROCEDURE [dbo].[PR_GetFolderDetails]
(
    @PeriodID	 INT,
	@HybridAsParentCrop		NVARCHAR(10)
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

	DECLARE @GroupTbl TABLE
	(
		TestID INT, 
		TestName NVARCHAR(20), 
		CropCode NVARCHAR(10), 
		MethodCode NVARCHAR(20), 
		PlatformName NVARCHAR(20), 
		NrOfPlates INT, 
		NrOfMarkers INT, 
		TraitMarkers BIT, 
		IsLabPriority BIT
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
	   Prio = dbo.FN_IsParent(V.VarietyNr, @HybridAsParentCrop), -- when Parent 1 else 0 (display parent first)
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
	WHERE T.PeriodID = @PeriodID
	) T1
	ORDER BY T1.CropCode ASC, T1.MethodCode ASC, T1.PlatformDesc ASC, ISNULL(T1.IsLabPriority, 0) DESC, Prio DESC, T1.Shortname ASC
		
    --create groups
	INSERT @GroupTbl(TestID,TestName,CropCode,MethodCode,PlatformName,NrOfPlates,NrOfMarkers,TraitMarkers,IsLabPriority)
    SELECT 
	   V2.TestID,
	   TestName = COALESCE(V2.TestName, 'Folder ' + CAST(ROW_NUMBER() OVER(ORDER BY V2.TestName) AS VARCHAR)),
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
	ORDER BY V2.TestName --CropCode, MethodCode --old ordering removed because folder name needs to be in order so testid is used

	SELECT * FROM @GroupTbl ORDER BY TestName; 

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
	   MIN(T2.StatusCode) AS TestStatusCode
    FROM @tbl T1
    JOIN Test T2 ON T2.TestID = T1.TestID;
	
	SELECT 
	   MIN(DA.StatusCode) AS DAStatusCode
    FROM @tbl T1
    JOIN DeterminationAssignment DA ON DA.DetAssignmentID = T1.DetAssignmentID;

	--Fill Rate (total used by batches / total reserved in capacity planning )
	--TotalUsed
	SELECT 
		TotalUsed = ISNULL(SUM(ISNULL(NrOfPlates,0)),0)
	FROM @GroupTbl

	--Total reserved in capacity planning
	SELECT 
		TotalReserved = ISNULL(SUM(ISNULL(NrOfPlates,0)),0)
    FROM ReservedCapacity RC
    JOIN CropMethod PC ON PC.CropMethodID = RC.CropMethodID
    WHERE PeriodID = @PeriodID

END
GO


DROP PROCEDURE IF EXISTS [dbo].[PR_FitPlatesToFolder]
GO


/*
Author					Date			Remarks
Krishna Gautam			2020/01/10		Created folder structcture based on lab priority and excelude already sent test while preparing folder structure
Binod Gurung			2020-jan-23		Transcation isolation level implemented to avoid record lock
										SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
Binod Gurung			2021-dec-07		Make maximum numbers of plate in one fodler configurable #29482
Binod Gurung			2022-feb-23		Number of Folders required calculation corrected for method that has seeds more than 92 #33069
Binod Gurung			2022-may-09		FN_IsParent function used for parent check

============ExAMPLE===================
--EXEC PR_FitPlatesToFolder 4792,16,'ON'
*/
CREATE PROCEDURE [dbo].[PR_FitPlatesToFolder]
(
	@PeriodID INT,
	@MaxPlatesInFolder DECIMAL,
	@HybridAsParentCrop	NVARCHAR(10)
)
AS BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
	
	DECLARE @TransCount BIT = 0;
	 
    BEGIN TRY	  
	   IF @@TRANCOUNT = 0 BEGIN
		  BEGIN TRANSACTION;
		  SET @TransCount = 1;
	   END
		  DECLARE @StartDate DATE, @EndDate DATE, @loopCountGroup INT=1,@TotalTestRequired INT =0, @TotalCreatedTests INT =0,  @CropCode NVARCHAR(MAX), @MethodCode NVARCHAR(MAX), @PlatformName NVARCHAR(MAX), @TotalGroups INT, @TotalFolderRequired INT =0, @TestID INT =0, @groupLoopCount INT =0, @Offset INT=0, @NextRows INT =0;
		  --declare table to insert data of determinatonAssignment
		  DECLARE @tblDA TABLE(ID INT IDENTITY(1,1), CropCode NVARCHAR(10),MethodCode NVARCHAR(100),PlatformName NVARCHAR(100),DetAssignmentID INT,NrOfPlates DECIMAL(6,2),TestID INT);
		  --this is group table which is required to calculate how many folders are required per method per crop per platform
		  DECLARE @tblDAGroups TABLE(ID INT IDENTITY(1,1), CropCode NVARCHAR(10),MethodCode NVARCHAR(100),PlatformName NVARCHAR(100),groupRequired INT,MaxRowToSelect INT);
		  --declare Temp test table
		  DECLARE @tblTempTest TABLE(ID INT IDENTITY(1,1), CropCode NVARCHAR(10),MethodCode NVARCHAR(100),PlatformName NVARCHAR(100), TestID INT);
		  --declare test table to get sequential test ID
		  DECLARE @tblSeqTest TABLE(ID INT IDENTITY(1,1), TestID INT);

		  --get date range of current period
		  SELECT 
			 @StartDate = StartDate,
			 @EndDate = EndDate
		  FROM [Period] 
		  WHERE PeriodID = @PeriodID;

		  --for now do not insert testID this should be updated or inserted later depending upon condition
		  INSERT INTO @tblDA(CropCode,MethodCode,PlatformName,DetAssignmentID,NrOfPlates)
			SELECT 
				C.CropCode,
				DA.MethodCode,
				P.PlatformDesc,
				DA.DetAssignmentID,
				M.NrOfSeeds/92.0
			FROM DeterminationAssignment DA
			JOIN ABSCrop C ON C.ABSCropCode = DA.ABSCropCode
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
			JOIN [Platform] P ON P.PlatformID = CM.PlatformID				
			WHERE CAST(DA.PlannedDate AS DATE) BETWEEN @StartDate AND @EndDate	
			AND NOT EXISTS 
			( 
				SELECT TD.DetAssignmentID FROM  TestDetAssignment TD
				JOIN TEST T ON T.TestID = TD.TestID
				WHERE T.StatusCode >= 200 AND T.PeriodID = @PeriodID AND TD.DetAssignmentID = DA.DetAssignmentID
			)
			ORDER BY C.CropCode ASC, DA.MethodCode ASC, P.PlatformDesc ASC, ISNULL(DA.IsLabPriority, 0) DESC, DA.DetAssignmentID ASC;


		  INSERT INTO @tblDAGroups(CropCode,MethodCode,PlatformName,groupRequired, MaxRowToSelect)
			SELECT 
				C.CropCode,
				DA.MethodCode,
				P.PlatformDesc,
				groupRequired = CASE
									WHEN  MAX(M.NrOfSeeds)/92.0 > (@MaxPlatesInFolder / 2) THEN COUNT(DA.DetAssignmentID)--when only one batch is possible in a folder (7-12 plates used by batch)
									WHEN  MAX(M.NrOfSeeds)/92.0 > (@MaxPlatesInFolder / 3) THEN COUNT(DA.DetAssignmentID) / 2 --when maximum of 2 batches are possible in a folder (5-6 plates used by batch)
									ELSE CEILING((SUM(M.NrOfSeeds)/92.0) / @MaxPlatesInFolder)				
								END,
				MaxRecordPerPlate = CASE 
										WHEN  MAX(M.NrOfSeeds)/92.0 > 0 THEN FLOOR(@MaxPlatesInFolder / (MAX(M.NrOfSeeds)/92.0))
										ELSE @MaxPlatesInFolder * (MAX(M.NrOfSeeds)/92.0)
									END
			FROM DeterminationAssignment DA
			JOIN ABSCrop C ON C.ABSCropCode = DA.ABSCropCode
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
			JOIN [Platform] P ON P.PlatformID = CM.PlatformID							
			WHERE CAST(DA.PlannedDate AS DATE) BETWEEN @StartDate AND @EndDate
			AND NOT EXISTS 
			( 
				SELECT TD.DetAssignmentID FROM  TestDetAssignment TD
				JOIN TEST T ON T.TestID = TD.TestID
				WHERE T.StatusCode >= 200 AND T.PeriodID = @PeriodID AND TD.DetAssignmentID = DA.DetAssignmentID
			)
			GROUP BY C.CropCode, DA.MethodCode, P.PlatformDesc
			ORDER BY C.CropCode, DA.MethodCode, P.PlatformDesc;

		  SELECT @TotalTestRequired = SUM(groupRequired) FROM @tblDAGroups;
		  SELECT @TotalCreatedTests = COUNT(TestID) FROM Test WHERE PeriodID = @PeriodID AND StatusCode < 200;

		  WHILE(@TotalCreatedTests < @TotalTestRequired)
		  BEGIN
			 INSERT INTO Test(PeriodID,StatusCode)
			 VALUES(@PeriodID,100);
			 SET @TotalCreatedTests = @TotalCreatedTests + 1;
		  END

		  INSERT INTO @tblSeqTest(TestID)
		  SELECT TestID FROM Test  WHERE PeriodID = @PeriodID AND StatusCode < 200 order by TestID;

		  SELECT @TotalGroups = COUNT(ID) FROM @tblDAGroups
		  SET @loopCountGroup = 1;
		  SET @groupLoopCount= 1;

		  WHILE(@loopCountGroup <= @TotalGroups)
		  BEGIN
			 SELECT @CropCode = CropCode, @MethodCode = MethodCode, @PlatformName = PlatformName, @TotalFolderRequired = groupRequired, @NextRows = MaxRowToSelect from @tblDAGroups Where ID = @loopCountGroup;
			 SET @Offset = 0;
			 WHILE(@TotalFolderRequired > 0)
			 BEGIN
				    SELECT @TestID = TestID FROM @tblSeqTest WHERE ID = @groupLoopCount;
					
				    --SELECT * FROM @tblDA WHERE CropCode = @CropCode AND MethodCode = @MethodCode AND PlatformName = @PlatformName ORDER BY ID OFFSET @Offset ROWS FETCH NEXT @NextRows ROWS ONLY

				    MERGE INTO @TblDA T
				    USING
				    (
					   SELECT * FROM @tblDA WHERE CropCode = @CropCode AND MethodCode = @MethodCode AND PlatformName = @PlatformName ORDER BY ID OFFSET @Offset ROWS FETCH NEXT @NextRows ROWS ONLY
				    ) S ON S.ID = T.ID
				    WHEN MATCHED THEN 
				    UPDATE SET T.TestID = @TestID;

				    SET @groupLoopCount = @groupLoopCount + 1;
				    SET @Offset = @Offset + @NextRows ;
				    SET @TotalFolderRequired = @TotalFolderRequired -1;
			 END

			 SET @loopCountGroup = @loopCountGroup + 1;				
		  END
			
		  MERGE INTO TestDetAssignment T
		  USING @TblDA S
		  ON S.DetAssignmentID = T.DetAssignmentID
		  WHEN MATCHED AND T.TestID <> S.TestID THEN UPDATE
		  SET T.TestID = S.TestID
		  WHEN NOT MATCHED THEN
		  INSERT(DetAssignmentID, TestID)
		  VALUES(S.DetAssignmentID, S.TestID);

	    IF @TransCount = 1
		  COMMIT;
    END TRY
    BEGIN CATCH 
	   IF @TransCount = 1
		  ROLLBACK;
	   THROW;
    END CATCH

END
GO


DROP PROCEDURE IF EXISTS [dbo].[PR_ValidateCapacityPerFolder]
GO


/*
Author					Date			Description
Binod Gurung			2020-jan-23		Transcation isolation level implemented to avoid record lock
Binod Gurung			2022-may-09		FN_IsParent function used for parent check
										
===================================Example================================
*/
CREATE PROCEDURE [dbo].[PR_ValidateCapacityPerFolder]
(
    @PeriodID	 INT,
    @DataAsJson NVARCHAR(MAX),
	@HybridAsParentCrop		NVARCHAR(10)
) AS BEGIN
    SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    DECLARE @PlatformID INT;
    DECLARE @StartDate DATE, @EndDate DATE;
    DECLARE @DeterminationAssignment TABLE
    (
	   DetAssignmentID	    INT,
	   SampleNr		    INT,
	   PriorityCode	    INT,
	   MethodCode		    NVARCHAR(25),
	   CropCode		    NVARCHAR(10),
	   ABSCropCode		   NVARCHAR(20),
	   VarietyNr		    INT,
	   BatchNr		    INT,
	   RepeatIndicator	    BIT,
	   ProcessNr		    NVARCHAR(100),
	   ProductStatus	    NVARCHAR(100),
	   BatchOutputDesc	    NVARCHAR(250),
	   PlannedDate		   DATE,
	   UtmostInlayDate	    DATE,
	   ExpectedReadyDate   DATE,
	   UsedFor		   NVARCHAR(10)
    );
    DECLARE @Capacity TABLE
    (
	   UsedFor	    VARCHAR(5), 
	   ABSCropCode	    NVARCHAR(10), 
	   MethodCode	    NVARCHAR(50), 
	   ReservePlates   DECIMAL(5,2)
    );
    DECLARE @Groups TABLE
    (
	   ABSCropCode	    NVARCHAR(10), 
	   MethodCode	    NVARCHAR(50), 
	   UsedFor	    VARCHAR(5), 
	   ReservePlates   DECIMAL(5,2),
	   TotalPlates	DECIMAL(5,2)
    );

    SELECT 
	   @StartDate = P.StartDate,
	   @EndDate = P.EndDate
    FROM [Period] P 
    WHERE P.PeriodID = @PeriodID;

    INSERT @DeterminationAssignment
    (
	   DetAssignmentID, 
	   SampleNr, 
	   PriorityCode, 
	   MethodCode, 
	   ABSCropCode, 
	   VarietyNr, 
	   BatchNr, 
	   RepeatIndicator, 
	   ProcessNr, 
	   ProductStatus, 
	   BatchOutputDesc, 
	   PlannedDate, 
	   UtmostInlayDate, 
	   ExpectedReadyDate,
	   UsedFor
    )
    SELECT 
	   S.DetAssignmentID, 
	   S.SampleNr, 
	   S.PriorityCode, 
	   S.MethodCode, 
	   S.ABSCropCode, 
	   S.VarietyNr, 
	   S.BatchNr, 
	   S.RepeatIndicator, 
	   S.ProcessNr, 
	   S.ProductStatus, 
	   S.BatchOutputDesc, 
	   CASE WHEN CAST(S.PlannedDate AS DATE) BETWEEN @StartDate AND @EndDate THEN S.PlannedDate ELSE @EndDate END,
	   S.UtmostInlayDate, 
	   S.ExpectedReadyDate,
	   UsedFor = CASE WHEN dbo.FN_IsParent(V.VarietyNr, @HybridAsParentCrop) = 0 THEN 'Hyb' ELSE 'Par' END
    FROM OPENJSON(@DataAsJson) WITH
    (
	   DetAssignmentID	   INT,
	   SampleNr		   INT,
	   PriorityCode	   INT,
	   MethodCode		   NVARCHAR(25),
	   ABSCropCode		   NVARCHAR(10),
	   VarietyNr		   INT,
	   BatchNr		   INT,
	   RepeatIndicator	   BIT,
	   ProcessNr		   NVARCHAR(100),
	   ProductStatus	   NVARCHAR(100),
	   BatchOutputDesc	   NVARCHAR(250),
	   PlannedDate		   DATETIME,
	   UtmostInlayDate	   DATETIME,
	   ExpectedReadyDate   DATETIME,
	   [Action]	        CHAR(1)
    ) S
    JOIN Variety V ON V.VarietyNr = S.VarietyNr
    LEFT JOIN DeterminationAssignment DA ON DA.DetAssignmentID = S.DetAssignmentID	   
    WHERE S.[Action] = 'I'
    AND S.PriorityCode NOT IN(4, 7, 8)
    AND DA.DetAssignmentID IS NULL;

    IF @@ROWCOUNT > 0 BEGIN
	   --check validation
	   SELECT 
		  @PlatformID = PlatformID 
	   FROM [Platform] WHERE PlatformCode = 'LS'; --light scanner 

	   INSERT @Capacity(UsedFor, ABSCropCode, MethodCode, ReservePlates)
	   SELECT
		  T1.UsedFor,
		  T1.ABSCropCode,
		  T1.MethodCode,
		  NrOfPlates = SUM(T1.NrOfPlates)
	   FROM
	   (
		  SELECT 
			 V1.ABSCropCode,
			 DA.MethodCode,
			 V1.UsedFor,
			 NrOfPlates = CAST((V1.NrOfSeeds / 92.0) AS DECIMAL(5,2))
		  FROM
		  (
			 SELECT 
				ABSCropCode,
				MethodCode,
				PlannedDate
			 FROM DeterminationAssignment
			 UNION ALL
			 SELECT 
				ABSCropCode,
				MethodCode,
				PlannedDate 
			 FROM @DeterminationAssignment
		  ) DA
		  JOIN
		  (
			 SELECT 
				PM.MethodCode,
				AC.ABSCropCode,
				PM.NrOfSeeds,
				PCM.UsedFor
			 FROM Method PM
			 JOIN CropMethod PCM ON PCM.MethodID = PM.MethodID
			 JOIN ABSCrop AC ON AC.ABSCropCode = PCM.ABSCropCode
			 JOIN @DeterminationAssignment DA2 ON DA2.ABSCropCode = PCM.ABSCropCode AND DA2.MethodCode = PM.MethodCode
			 --handle if same method is used for hybrid and parent
			 JOIN
			 (
				 SELECT 
				 	 VarietyNr, 
				 	 UsedFor = CASE WHEN dbo.FN_IsParent(VarietyNr, @HybridAsParentCrop) = 0 THEN 'Hyb' ELSE 'Par' END
				 FROM Variety
			 ) V ON V.VarietyNr = DA2.VarietyNr AND V.UsedFor = PCM.UsedFor
			 WHERE PCM.PlatformID = @PlatformID
			 AND PM.StatusCode = 100
		  ) V1 ON V1.ABSCropCode = DA.ABSCropCode AND V1.MethodCode = DA.MethodCode
		  WHERE CAST(DA.PlannedDate AS DATE) BETWEEN @StartDate AND @EndDate
	   ) T1 
	   GROUP BY T1.ABSCropCode, T1.MethodCode, T1.UsedFor;

	   INSERT INTO @Groups(ABSCropCode, MethodCode, UsedFor, TotalPlates, ReservePlates)
	   SELECT
		  V1.ABSCropCode,
		  V1.MethodCode,
		  V1.UsedFor,
		  ISNULL(V1.TotalPlates, 0),
		  ISNULL(V2.ReservePlates, 0)
	   FROM
	   (
			SELECT 
				PC.SlotName,
				AC.ABSCropCode, 
				PM.MethodCode,	
				CM.UsedFor,
				TotalPlates = SUM(PC.NrOfPlates)
			FROM ReservedCapacity PC
			JOIN CropMethod CM ON CM.CropMethodID = PC.CropMethodID
			JOIN ABSCrop AC ON AC.ABSCropCode = CM.ABSCropCode
			JOIN Method PM ON PM.MethodID = CM.MethodID
			JOIN @DeterminationAssignment DA ON DA.ABSCropCode = CM.ABSCropCode AND DA.MethodCode = PM.MethodCode
			--handle if same method is used for hybrid and parent
			JOIN
			(
				SELECT 
					VarietyNr, 
					UsedFor = CASE WHEN dbo.FN_IsParent(VarietyNr, @HybridAsParentCrop) = 0 THEN 'Hyb' ELSE 'Par' END
				FROM Variety
			) V ON V.VarietyNr = DA.VarietyNr AND V.UsedFor = CM.UsedFor
			WHERE CM.PlatformID = @PlatformID AND PC.PeriodID = @PeriodID
			GROUP BY PC.SlotName, AC.ABSCropCode, PM.MethodCode, CM.UsedFor
	   ) V1
	   LEFT JOIN @Capacity V2 ON V2.ABSCropCode = V1.ABSCropCode AND V2.MethodCode = V1.MethodCode AND V2.UsedFor = V1.UsedFor;
		  
	   SELECT 
		  ABSCropCode, 
		  MethodCode, 
		  UsedFor,
		  ReservePlates,
		  TotalPlates
	   FROM @Groups
	   WHERE ReservePlates > TotalPlates;
    END	
END
GO


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
	WHERE T.PeriodID = @PeriodID
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
			WHERE T.PeriodID = @PeriodID AND DA.IsLabPriority = 1
			GROUP BY T.TestID
		) V1 ON V1.TestID = V0.TestID
	    JOIN Test T ON T.TestID = V0.TestID		
	    JOIN @TestPlates TP ON TP.TestID = T.TestID
	    WHERE T.PeriodID = @PeriodID AND (T.StatusCode < 200 AND V0.StatusCode = 300) --sometimes test status remain on 100 even though all DA got status 300
	    GROUP BY T.TestID
	) T1
	JOIN [Period] P1 ON T1.ExpectedDate BETWEEN P1.StartDate AND P1.EndDate --Expected Week
	JOIN [Period] P2 ON T1.PlannedDate BETWEEN P2.StartDate AND P2.EndDate -- Planned Week

END

GO


