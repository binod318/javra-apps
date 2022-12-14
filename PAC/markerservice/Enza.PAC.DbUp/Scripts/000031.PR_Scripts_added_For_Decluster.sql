/****** Object:  StoredProcedure [dbo].[PR_Ignite_Decluster]    Script Date: 10/21/2019 10:14:10 AM ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[PR_Ignite_Decluster]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[PR_Ignite_Decluster]
GO
/****** Object:  StoredProcedure [dbo].[PR_FindMatchingVarieties]    Script Date: 10/21/2019 10:14:10 AM ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[PR_FindMatchingVarieties]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[PR_FindMatchingVarieties]
GO
/****** Object:  StoredProcedure [dbo].[PR_FindInbredMarker]    Script Date: 10/21/2019 10:14:10 AM ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[PR_FindInbredMarker]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[PR_FindInbredMarker]
GO
/****** Object:  StoredProcedure [dbo].[PR_Decluster]    Script Date: 10/21/2019 10:14:10 AM ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[PR_Decluster]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[PR_Decluster]
GO
/****** Object:  UserDefinedFunction [dbo].[FN_IsMatching]    Script Date: 10/21/2019 10:14:10 AM ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[FN_IsMatching]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[FN_IsMatching]
GO
/****** Object:  UserDefinedFunction [dbo].[FN_IsMatching]    Script Date: 10/21/2019 10:14:10 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Binod Gurung
-- Create date: 2019/09/05
-- Description:	Function to determine if proposed value and referenced value is matching
-- =============================================
-- SELECT  dbo.FN_IsMatching ('0000','1111')
CREATE FUNCTION [dbo].[FN_IsMatching]
(
	@ProposedValue NVARCHAR(20),
	@ReferenceValue NVARCHAR(20)
)
RETURNS BIT
AS
BEGIN

	DECLARE @HighNibbleProp NVARCHAR(10), @LowNibbleProp NVARCHAR(10), @HighNibbleRef NVARCHAR(10), @LowNibbleRef NVARCHAR(10);
	
	IF(@ProposedValue < '100')
	BEGIN
		
		IF( (@ProposedValue = '0001' AND @ReferenceValue = '0000') OR (@ReferenceValue = '0001' AND @ProposedValue = '0000'))
			RETURN 0;
		IF(@ProposedValue NOT IN ('0000','0001','0002','0055','0099','9999') OR @ReferenceValue NOT IN ('0000','0001','0055','0099','9999'))
			RETURN 0;
		RETURN 1;

	END
	ELSE
	BEGIN

		IF (@ProposedValue = '' OR @ReferenceValue = '' OR @ProposedValue = @ReferenceValue OR @ProposedValue IN ('9999','5555') OR @ReferenceValue IN ('5555','5599','9999'))
			RETURN 1;

		SELECT	@HighNibbleProp = SUBSTRING(@ProposedValue,0,2),
				@LowNibbleProp	= SUBSTRING(@ProposedValue,2,2),
				@HighNibbleRef	= SUBSTRING(@ProposedValue,0,2),
				@LowNibbleRef	= SUBSTRING(@ProposedValue,2,2);

		IF(@LowNibbleProp IN ('55','99') AND (@HighNibbleProp = @HighNibbleRef OR @HighNibbleProp = @LowNibbleRef))
			RETURN 1;
		IF(@LowNibbleRef IN ('55','99') AND (@HighNibbleRef = @HighNibbleProp OR @HighNibbleRef = @LowNibbleProp))
			RETURN 1;
		IF (@LowNibbleProp = '55' AND @LowNibbleRef = '99')
			RETURN 1;
		RETURN 0;

	END

	RETURN 0;
END
GO
/****** Object:  StoredProcedure [dbo].[PR_FindMatchingVarieties]    Script Date: 10/21/2019 10:14:10 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Binod Gurung
-- Create date: 2019/09/05
-- Description:	Procedure to find matching varieties based on give marker values and db marker values
-- =============================================
/*	DECLARE @Json NVARCHAR(MAX) = N'[
					{"ID":1,"MarkerID":1173292,"MarkerValue":"0202"},
					{"ID":2,"MarkerID":45,"MarkerValue":"0202"},
					{"ID":3,"MarkerID":46,"MarkerValue":"1111"},
					{"ID":4,"MarkerID":47,"MarkerValue":"0011"},
					{"ID":5,"MarkerID":8,"MarkerValue":"0101"}
				]';
	DECLARE @ReturnVarieties nvarchar(max);
	EXEC PR_FindMatchingVarieties @Json, 'TO', 9235, @ReturnVarieties OUTPUT;
	SELECT @ReturnVarieties;
*/
CREATE PROCEDURE [dbo].[PR_FindMatchingVarieties]
(
	@Json	NVARCHAR(MAX),
	@Crop	NVARCHAR(10),
	@VarietyNr	INT,
	@ReturnVarieties NVARCHAR(MAX) OUTPUT
)
AS
BEGIN
	SET NOCOUNT ON;

	-- step 1
	DECLARE @MarkerTbl Table(ID INT,MarkerID INT, MarkerValue NVARCHAR(10));
	DECLARE @Table1 Table(VarietyNr INT); 
	DECLARE @Table2 Table(VarietyNr INT); 
	DECLARE @FirstMarkerID INT;
	DECLARE @FirstMarkerValue NVARCHAR(20);

	--Insert MarkerID and MarkerVlaue to Table from JSON
	INSERT INTO @MarkerTbl (ID, MarkerID, MarkerValue)
	SELECT ID, MarkerID, MarkerValue
	FROM OPENJSON(@Json) WITH
	(
		ID			INT '$.ID',
		MarkerID	INT '$.MarkerID',
		MarkerValue	NVARCHAR(MAX) '$.MarkerValue'
	)
	
	SELECT 
		@FirstMarkerID = MarkerID,
		@FirstMarkerValue = MarkerValue 
	FROM @MarkerTbl WHERE ID = 1;
	
	-- step 2 - Fill temptable from all varieties whihc has no markervaluepervariety or has markervaluepervariety and is matching
	INSERT INTO @Table1 (VarietyNr)
	(
		SELECT 		
			V.VarietyNr
		FROM Variety V
		JOIN MarkerValuePerVariety MVPV ON MVPV.VarietyNr = V.VarietyNr AND MVPV.MarkerID = @FirstMarkerID AND dbo.FN_IsMatching(@FirstMarkerValue, MVPV.AlleleScore) = 1
		WHERE V.CropCode = @Crop AND V.PacComp = 1
		GROUP BY V.VarietyNr
		UNION
		SELECT		
			V.VarietyNr
		FROM Variety V
		LEFT JOIN MarkerValuePerVariety MVPV ON MVPV.VarietyNr = V.VarietyNr AND MVPV.MarkerID = @FirstMarkerID
		WHERE V.CropCode = @Crop AND V.PacComp = 1 AND MVPV.VarietyNr IS NULL
		GROUP BY V.VarietyNr
	) 

	--step 3 - Find varieties from filled temp-table which has mvpv and not matching
	INSERT INTO @Table2 (VarietyNr)
	(
		SELECT		
			MVPV.VarietyNr		
		FROM @Table1 V
		JOIN MarkerValuePerVariety MVPV ON MVPV.VarietyNr = V.VarietyNr 
		JOIN @MarkerTbl MT ON MT.MarkerID = MVPV.MarkerID AND dbo.FN_IsMatching(MT.Markervalue, MVPV.AlleleScore) = 0
		WHERE MT.ID <> 1
		GROUP BY MVPV.VarietyNr
	) 

	--Delete all records from @Table1 found in @table2 because these are varieties that has score but not matching
	DELETE FROM @Table1 
	WHERE VarietyNr NOT IN (SELECT VarietyNr FROm @Table2);

	--step 4 - Place input varieties at first in the list 
	SET @ReturnVarieties = @VarietyNr;
	DELETE FROM @Table1 WHERE VarietyNr = @VarietyNr;

	--step 5 - Return Varities in comma separated list
	SELECT @ReturnVarieties = COALESCE( @ReturnVarieties + ',' + CAST(VarietyNr AS NVARCHAR(20)), '') 
	FROM @Table1
	
END
GO
/****** Object:  StoredProcedure [dbo].[PR_FindInbredMarker]    Script Date: 10/21/2019 10:14:10 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Binod Gurung
-- Create date: 2019/10/15
-- Description:	Procedure to find inbred marker based on given marker list
-- =============================================
/*	
	DECLARE @ReturnMarker INT;
	EXEC [PR_FindInbredMarker] '22,33,44', 9235, 234, 345, 0, @ReturnMarker OUTPUT;
	SELECT @ReturnMarker;
*/
CREATE PROCEDURE [dbo].[PR_FindInbredMarker]
(
	@MarkerList		NVARCHAR(MAX),
	@VarietyNr		INT,
	@FemaleParent	INT,
	@MaleParent		INT,
	@Reciprocal		BIT,
	@ReturnMarker	INT OUTPUT
)
AS
BEGIN

	DECLARE @VarietyScore NVARCHAR(10), @FemaleScore NVARCHAR(10), @MaleScore NVARCHAR(10), @MarkerID INT;

	SET NOCOUNT ON;
	
	SET @ReturnMarker = 0;
	
	DECLARE Marker_Cursor CURSOR LOCAL FAST_FORWARD FOR
	SELECT [value] FROM string_split(@MarkerList,',');
	OPEN Marker_Cursor;
	FETCH NEXT FROM Marker_Cursor INTO @MarkerID;
	
	WHILE @@FETCH_STATUS = 0
	BEGIN

		SELECT	@VarietyScore = '',
				@FemaleScore  = '',
				@MaleScore	  = '';
		
		SELECT @VarietyScore = V1.AlleleScore FROM MarkerValuePerVariety V1 WHERE V1.VarietyNr	= @VarietyNr	AND V1.MarkerID = @MarkerID

		SELECT @FemaleScore = V2.AlleleScore FROM MarkerValuePerVariety V2 WHERE V2.VarietyNr	= @FemaleParent AND V2.MarkerID = @MarkerID
	
		SELECT @MaleScore = V3.AlleleScore FROM MarkerValuePerVariety V3 WHERE V3.VarietyNr		= @MaleParent	AND V3.MarkerID = @MarkerID

		IF (ISNULL(@VarietyScore,'') <> '' AND ISNULL(@FemaleScore,'') <> '' AND ISNULL(@MaleScore,'') <> '')
		BEGIN

			-- if score of female is less than 100
			IF(@FemaleScore < '100')
			BEGIN
				
				IF(@Reciprocal = 1 AND @FemaleScore = '0001' AND @MaleScore = '0000')
				BEGIN
					SET @ReturnMarker = @MarkerID;
					BREAK;
				END;

				IF(@Reciprocal = 0 AND @FemaleScore = '0000' AND @MaleScore = '00001')
				BEGIN
					SET @ReturnMarker = @MarkerID;
					BREAK;
				END;

			END;
			-- if score of female is greater than or equal to 100
			ELSE
			BEGIN
				
				IF( @VarietyScore < '999'
				AND REPLACE(@VarietyScore, '55', '') = @VarietyScore
				AND @FemaleScore < '999'
				AND @FemaleScore > '100'
				AND REPLACE(@FemaleScore, '55', '') = @FemaleScore
				AND @MaleScore < '999'
				AND @MaleScore > '100'
				AND REPLACE(@MaleScore, '55', '') = @MaleScore)
				BEGIN

					--if female score and male score is not matching
					IF(dbo.FN_IsMatching(@FemaleScore, @MaleScore) = 0)
					BEGIN
						SET @ReturnMarker = @MarkerID;
						BREAK;
					END;

				END;
			END;
		END;

		FETCH NEXT FROM Marker_Cursor INTO @MarkerID;
	END;
	
	CLOSE Marker_Cursor;
	DEALLOCATE Marker_Cursor;
	
END
GO
/****** Object:  StoredProcedure [dbo].[PR_Decluster]    Script Date: 10/21/2019 10:14:10 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Binod Gurung
-- Create date: 2019/10/16
-- Description:	Procedure to decluster varieties
-- =============================================
/*	
	DECLARE @ReturnVarieties NVARCHAR(MAX);
	EXEC [PR_Decluster] 1297740, @ReturnVarieties OUTPUT;
	SELECT @ReturnVarieties;
*/
CREATE PROCEDURE [dbo].[PR_Decluster]
(
	@DetAssignmentID	INT,
	@ReturnVarieties	NVARCHAR(MAX) OUTPUT
)
AS
BEGIN

	DECLARE @VarietyNr INT, @Female INT, @Male INT, @IsParent BIT, @Crop NVARCHAR(10), @MarkerID INT, @PlatformID INT, @InMMS BIT, @Score NVARCHAR(10), @VarietyScore NVARCHAR(10), @ImsMarker INT;
	DECLARE @ClusteredVarieties NVARCHAR(MAX), @CountClusteredVarieties INT, @Json NVARCHAR(MAX), @List NVARCHAR(MAX) = '';
	DECLARE @MarkerTbl TABLE(DetAssignmentID INT, MarkerID INT, InEDS BIT, InIMS BIT);
	DECLARE @MMSMarkerTbl TABLE (MarkerID INT, MarkerValue NVARCHAR(10));
	DECLARE @EdmMarkerTbl TABLE (MarkerID INT, MarkerValue NVARCHAR(10));
	DECLARE @EdmMarkerTblOrig TABLE (MarkerID INT, MarkerValue NVARCHAR(10));	
	DECLARE @JsonTbl TABLE (ID INT IDENTITY(1,1), MarkerID INT, MarkerValue NVARCHAR(10));
	DECLARE @ClusterVarTbl TABLE(VarietyNr INT);
	DECLARE @EffectPerMarkerTbl Table(MarkerID INT, Total INT);
	DECLARE @Count1 INT, @Count2 INT, @HighestScore INT, @HighestMarker INT;	
	
	SET NOCOUNT ON;

	SET @ReturnVarieties = '';
	
	-- step 1 : calculate cluster varieties

	--delete all previous marker test before starting new
	DELETE MarkerToBeTested
	WHERE DetAssignmentID = @DetAssignmentID;

	--find variety linked to determination assignment
	SELECT 
		@VarietyNr = VarietyNr
	FROM DeterminationAssignment WHERE DetAssignmentID = @DetAssignmentID;

	--find variety information
	SELECT 
		@Crop = CropCode,
		@Female = V.Female,
		@Male = V.Male,
		@IsParent = (CASE WHEN V.HybOp = 0 AND V.Type = 'C' THEN 1 ELSE 0 END)
	FROM Variety V WHERE V.VarietyNr = @VarietyNr;

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

		INSERT INTO @EffectPerMarkerTbl
		SELECT MVPV.MarkerID, COUNT(MVPV.MarkerID) FROM 
		(
			SELECT VarietyNr, ED.MarkerID, ED.MarkerValue FROM @ClusterVarTbl
			CROSS APPLY @EdmMarkerTbl ED
		) V2
		LEFT JOIN MarkerValuePerVariety MVPV ON MVPV.VarietyNr = V2.VarietyNr AND MVPV.MarkerID = V2.MarkerID
		WHERE dbo.FN_IsMatching(V2.MarkerValue, MVPV.AlleleScore) = 0
		GROUP BY MVPV.MarkerID
		
		-- Get score and marker with highest score count
		SET @HighestScore = 0;
		SET @HighestMarker = 0;

		SELECT TOP 1
			@HighestMarker = EP.MarkerID,
			@HighestScore = EP.Total
		FROM @EffectPerMarkerTbl EP 
		ORDER BY EP.Total DESC
		--WHERE EP.Total = (SELECT MAX(Total) FROM @EffectPerMarkerTbl)
				
		--if no marker found with @EffectPerMarkerTbl then quit this loop
		IF(ISNULL(@HighestScore, 0) = 0)
			BREAK;

		-- if marker found then remove marker from edm markerlist
		DELETE FROM @EdmMarkerTbl
		WHERE MarkerID = @HighestMarker

		--Remove varieties from Clusteredlist that no longer match the variety in test - that has markervaluepervariety record but not matcing
		
		SELECT TOP 1 @VarietyScore = AlleleScore FROM MarkerValuePerVariety WHERE VarietyNr = @VarietyNr AND MarkerID = @MarkerID;

		DELETE CV FROM @ClusterVarTbl CV
		JOIN MarkerValuePerVariety MVPV ON MVPV.VarietyNr = CV.VarietyNr AND MVPV.MarkerID = @HighestMarker AND dbo.FN_IsMatching(@VarietyScore, MVPV.AlleleScore) = 0
								
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
	END

	--step 4 : Try to find inbred marker
			
	-- find inbred marker if crop allows inbred
	IF EXISTS (SELECT * FROM CropRD WHERE CropCode = @Crop AND InBreed = 1)
	BEGIN

		--convert table column value to comma separated list
		SET @List = '';
		SELECT @List = @List + MarkerValue + ',' from @MMSMarkerTbl;
		SET @List = SUBSTRING(@List, 0, LEN(@List));

		EXEC [PR_FindInbredMarker] @List, @VarietyNr, @Female, @Male, 0, @ImsMarker OUTPUT; --Reciprocal indicator not available in db so 0 used for now

		-- if no inbred marker found using MMSMarkers
		IF(@ImsMarker = 0)
		BEGIN			

			--convert table column value to comma separated list
			SET @List = '';
			SELECT @List = @List + MarkerValue + ',' from @EdmMarkerTblOrig;
			SET @List = SUBSTRING(@List, 0, LEN(@List));

			EXEC [PR_FindInbredMarker] @List, @VarietyNr, @Female, @Male, 0, @ImsMarker OUTPUT; --Reciprocal indicator not available in db so 0 used for now

		END;

		--if marker found
		IF(@ImsMarker > 0)
		BEGIN

			--If record already exists for same test/marker update InIms to true
			MERGE INTO @MarkerTbl T
			USING
			(
				SELECT @ImsMarker AS Marker
			) S ON T.MarkerID = S.Marker
			WHEN NOT MATCHED THEN
				INSERT (DetAssignmentID, MarkerID, InEDS, InIMS)
				VALUES (@DetAssignmentID, @ImsMarker, 0, 1)
			WHEN MATCHED THEN
				UPDATE SET T.InIMS = 1;

		END;

	END;
			
	--Create MarkerToBeTested record in database from temptable @MarkerTbl
	INSERT INTO MarkerToBeTested (DetAssignmentID, MarkerID, InEDS, InMMS, [Audit])
	SELECT DetAssignmentID, MarkerID, InEDS, InIMS, 'AutoDecluster, ' + CONVERT(NVARCHAR(50), getdate()) FROM @MarkerTbl

	--convert table column value to comma separated list
	SET @List = '';
	SELECT @List = @List + CONVERT(NVARCHAR(20),VarietyNr) + ',' from @ClusterVarTbl;
	SET @List = SUBSTRING(@List, 0, LEN(@List));
	SET @ReturnVarieties = @List;
	
END
GO
/****** Object:  StoredProcedure [dbo].[PR_Ignite_Decluster]    Script Date: 10/21/2019 10:14:10 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
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
AS
BEGIN

	DECLARE @DetAssignmentID INT, @ReturnVarieties NVARCHAR(MAX);
	
	SET NOCOUNT ON;
	
	BEGIN TRY
		BEGIN TRANSACTION;

		DECLARE Determination_Cursor CURSOR LOCAL FAST_FORWARD FOR
		SELECT DetAssignmentID FROM DeterminationAssignment DA WHERE DA.StatusCode = 200
		OPEN Determination_Cursor;
		FETCH NEXT FROM Determination_Cursor INTO @DetAssignmentID;
	
		WHILE @@FETCH_STATUS = 0
		BEGIN
			
			EXEC [PR_Decluster] @DetAssignmentID, @ReturnVarieties OUTPUT;

			--update status of determination assignment 
			UPDATE DeterminationAssignment
			SET StatusCode = 300
			WHERE DetAssignmentID = @DetAssignmentID;
			
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
