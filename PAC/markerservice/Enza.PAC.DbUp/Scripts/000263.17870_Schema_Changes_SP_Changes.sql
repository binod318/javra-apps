DROP TABLE IF EXISTS [dbo].[ExtraSettings]
GO


CREATE TABLE [dbo].[ExtraSettings](
	[ExtraSettingsID] [int] IDENTITY(1,1) NOT NULL,
	[CropCode] [char](2) NOT NULL,
	[SettingCode] [nvarchar](50) NOT NULL,
	[SettingValue] [nvarchar](max)
)

GO

ALTER TABLE [dbo].[ExtraSettings] WITH CHECK ADD FOREIGN KEY([CropCode])
REFERENCES [dbo].[CropRD] ([CropCode])
GO


INSERT ExtraSettings(CropCode, SettingCode, SettingValue)
VALUES ('ON', 'DeclusterMarkers', 'M0000002,M0000136')

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
		@IsParent = (CASE WHEN V.HybOp = 0 AND V.[Type] = 'P' THEN 1 ELSE 0 END)
	FROM Variety V WHERE V.VarietyNr = @VarietyNr;

	--find extra setting for decluster marker, only if variety is parent
	IF(@IsParent = 1)
	BEGIN
		INSERT @DeclusterMarkerTbl (MarkerID)
		SELECT MarkerID FROM Marker WHERE CropCode = @Crop AND MarkerName IN
		(
			SELECT LTRIM([value]) FROM STRING_SPLIT((SELECT SettingValue FROM ExtraSettings WHERE CropCode = @Crop AND SettingCode = 'DeclusterMarkers'), ',')
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


