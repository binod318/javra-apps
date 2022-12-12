/*
Changed By			DATE				Description

Krishna Gautam		-					Stored procedure created	
Krishna Gautam		2021-05-15			#21378: Change in service to cancel test
Krishna Gautam		2021-05-18			#21381: Change in service to update max plants on test.



*/


ALTER PROCEDURE [dbo].[PR_SaveTestMaterialDeterminationWithTVP_ForRDT]
(	
	@CropCode							NVARCHAR(15),
	@TestID								INT,	
	@TVP_TMD_WithDate TVP_TMD_WithDate	READONLY,
	@TVPProperty TVP_PropertyValue		READONLY
) AS BEGIN
	SET NOCOUNT ON;	
	
	DECLARE @StatusCode INT, @ImportLevel NVARCHAR(MAX)='';

	SELECT @StatusCode = Statuscode, @ImportLevel = ImportLevel FROM Test WHERE TestID = @TestID;

	IF(ISNULL(@StatusCode,0) >=200) BEGIN

		DECLARE @CancelledLimsRefTable TABLE(ID INT);
		DECLARE @UnCancelledLimsRefTable TABLE(ID INT);

		--insert cancelled tests
		INSERT INTO @CancelledLimsRefTable(ID)
		SELECT TMD.InterfaceRefID FROM TestMaterialDetermination TMD
		JOIN @TVP_TMD_WithDate TT ON TT.MaterialID = TMD.MaterialID AND TMD.DeterminationID = TT.DeterminationID AND ISNULL(TT.Selected,1) = 0 AND TMD.TestID = @TestID
		GROUP BY TMD.InterfaceRefID;

		--insert Uncancelled tests
		INSERT INTO @UnCancelledLimsRefTable(ID)
		SELECT TMD.InterfaceRefID FROM TestMaterialDetermination TMD
		JOIN @TVP_TMD_WithDate TT ON TT.MaterialID = TMD.MaterialID AND TMD.DeterminationID = TT.DeterminationID AND ISNULL(TT.Selected,0) = 1 AND TMD.TestID = @TestID
		GROUP BY TMD.InterfaceRefID;

		--change to cancelled test
		UPDATE T SET T.StatusCode = 200 
		FROM TestMaterialDetermination T
		JOIN @CancelledLimsRefTable C ON C.ID = T.InterfaceRefID AND T.TestID = @TestID;

		--change to uncancelled test
		UPDATE T SET T.StatusCode = 100 
		FROM TestMaterialDetermination T
		JOIN @UnCancelledLimsRefTable C ON C.ID = T.InterfaceRefID AND T.TestID = @TestID;
		
		IF(@Importlevel = 'LIST')
		BEGIN
		--changed to updated test
			UPDATE T SET 
				T.StatusCode = 300,
				T.MaxSelect = S.MaxSelect
			FROM TestMaterialDetermination T
			JOIN @TVP_TMD_WithDate S ON T.DeterminationID = S.DeterminationID AND T.TestID = @TestID AND ISNULL(S.Selected,0) = 1 AND ISNULL(S.MaxSelect,0) <> ISNULL(T.MaxSelect,0)
		END


		--update test

		UPDATE TEST SET StatusCode = 450 WHERE TestID = @TestID;


		----here all record must be present
		--MERGE INTO TestMaterialDetermination T
		--USING @TVP_TMD_WithDate S
		--ON T.MaterialID = S.MaterialID  AND T.DeterminationID = S.DeterminationID AND T.TestID = @TestID
		--WHEN MATCHED
		--THEN UPDATE SET 
		--	T.StatusCode = CASE 
		--					WHEN ISNULL(S.Selected,1) = 0 AND ISNULL(T.StatusCode,100) = 100 THEN 200 
		--					WHEN ISNULL(S.Selected,1) = 1 AND ISNULL(S.MaxSelect,0) > 0 AND @Importlevel = 'LIST' THEN 300
		--					ELSE 100 END,
		--	T.MaxSelect = CASE WHEN ISNULL(S.MaxSelect,0) <> ISNULL(T.MaxSelect,0) AND @Importlevel = 'LIST' THEN S.MaxSelect ELSE T.MaxSelect END; --Import level are PLT or LIST

	END

	ElSE
	BEGIN
		--insert or delete statement for merge
		MERGE INTO TestMaterialDetermination T 
		USING @TVP_TMD_WithDate S	
		ON T.MaterialID = S.MaterialID  AND T.DeterminationID = S.DeterminationID AND T.TestID = @TestID
		--This is done because front end may send null for selected value if no change is done on checkbox for determination 
		WHEN MATCHED AND ISNULL(S.Selected,1) = 1 AND ISNULL(T.ExpectedDate,'') != ISNULL(S.ExpectedDate,'')
			THEN UPDATE SET T.ExpectedDate = S.ExpectedDate		
		WHEN MATCHED AND ISNULL(S.Selected,1) = 0 
		THEN DELETE
		WHEN NOT MATCHED AND ISNULL(S.Selected,0) = 1 THEN 
		INSERT(TestID,MaterialID,DeterminationID,ExpectedDate) VALUES (@TestID,S.MaterialID,s.DeterminationID,S.ExpectedDate);


		MERGE INTO TestMaterial T 
		USING @TVPProperty S ON T.MaterialID = S.MaterialID  AND T.TestID = @TestID AND S.[Key] = 'MaterialStatus'
		WHEN MATCHED AND ISNULL(T.MaterialStatus,'') <> ISNULL(S.[Value],'') THEN UPDATE
			SET T.MaterialStatus = S.[Value]
		WHEN NOT MATCHED THEN
			INSERT(TestID, MaterialID, MaterialStatus)
			VALUES(@TestID, S.MaterialID, S.[Value]);
	END

			
END

