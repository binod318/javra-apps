/*
EXEC PR_GetSlot_ForTest 80

*/
ALTER PROCEDURE [dbo].[PR_GetSlot_ForTest]
(
	--@User NVARCHAR(200),
	@TestID INT = NULL
	
)
AS BEGIN
	IF(ISNULL(@TestID,0)=0)BEGIN
		EXEC PR_ThrowError 'Invalid Test.';
		RETURN;	
	END
	
	DECLARE @TestTypeID INT;
	SELECT @TestTypeID = TestTypeID FROM Test WHERE TestID = @TestID;

	--FOR leaf disk
	IF(@TestTypeID = 9)
	BEGIN
		SELECT * FROM Slot S
		JOIN ReservedCapacity RC ON RC.SlotID = S.SlotID --only one record is there for reserved capacity.
		JOIN [Period] P ON P.PeriodID = S.PeriodID
		JOIN 
		(
			SELECT F.CropCode, T.* 
			FROM [File] F JOIN Test T ON T.FileID = F.FileID
			WHERE T.TestID = @TestID
		) T ON T.CropCode = S.CropCode AND T.TestTypeID = S.TestTypeID AND T.BreedingStationCode = S.BreedingStationCode AND RC.TestProtocolID = T.TestProtocolID AND T.SiteID = S.SiteID
		WHERE S.StatusCode = 200 AND T.TestID = @TestID AND CAST(T.PlannedDate AS DATE) BETWEEN CAST(P.StartDate AS DATE) AND CAST(P.EndDate AS DATE)
	END

	--for other test type
	ELSE
	BEGIN
		SELECT S.SlotID,S.SlotName FROM Slot S
		JOIN [Period] P ON P.PeriodID = S.PeriodID
		JOIN 
		(
			SELECT F.CropCode, T.* 
			FROM [File] F JOIN Test T ON T.FileID = F.FileID
			WHERE T.TestID = @TestID
		) AS T
		ON T.CropCode = S.CropCode 
		AND T.MaterialTypeID = S.MaterialTypeID 
		AND T.Isolated = S.Isolated
		AND T.BreedingStationCode = S.BreedingStationCode		
		WHERE S.StatusCode = 200 AND T.TestID = @TestID 
		AND CAST(T.PlannedDate AS DATE) BETWEEN CAST(P.StartDate AS DATE) AND CAST(P.EndDate AS DATE)
	END
	
END

GO


ALTER PROCEDURE [dbo].[PR_Save_SlotTest]
(
	@TestID INT,
	--@UserID NVARCHAR(200),
	@SlotID INT
) AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @ReturnValue INT, @TestTypeID INT;
	
	BEGIN TRY
		
		SELECT @TestTypeID = TesttypeID FROM Test where TestID = @TestID;

		IF EXISTS(SELECT TestID FROM Test WHERE TestID = @TestID AND StatusCode >= 200) BEGIN
			EXEC PR_ThrowError 'Cannot change slot after request is sent to LIMS.';
			RETURN;		
		END
		IF(ISNULL(@SlotID,0)= 0) BEGIN
			DELETE FROM SlotTest Where TestID = @TestID
			UPDATE Test SET StatusCode = 100 WHERE TestID = @TestID;			
			--Get test detail
			EXEC PR_GetTestDetail @TestID
			RETURN;
		END
		--this is for leaf disk validation
		IF(ISNULL(@TestTypeID,0) = 9)
		BEGIN
			IF NOT EXISTS( 
				SELECT T.TestID
				 FROM [File] F 
				JOIN Test T ON T.FileID = F.FileID
				JOIN Slot S ON F.CropCode = S.CropCode 
				JOIN ReservedCapacity RC ON RC.SlotID = S.SlotID
				JOIN [Period] P ON P.PeriodID = S.PeriodID
				WHERE 
				F.CropCode = S.CropCode 
				AND T.TestTypeID = S.TestTypeID 
				AND T.BreedingStationCode = S.BreedingStationCode 
				AND RC.TestProtocolID = T.TestProtocolID 
				AND T.SiteID = S.SiteID					
				AND S.StatusCode = 200 
				AND T.TestID = @TestID 
				AND S.SlotID = @SlotID
				AND CAST(T.PlannedDate AS DATE) BETWEEN CAST(P.StartDate AS DATE) AND CAST(P.EndDate AS DATE)
				) 
				BEGIN

					EXEC PR_ThrowError 'Cannot link slot to test. Please check property of test.';
					RETURN;	
				END
		END
		ELSE
		BEGIN
			IF NOT EXISTS( 
				SELECT T.TestID--,s.SlotID, T.MaterialStateID,S.MaterialStateID,T.MaterialTypeID,S.MaterialTypeID,T.Isolated, S.Isolated,T.MaterialStateId, S.MaterialStateID
				 FROM [File] F 
				JOIN Test T ON T.FileID = F.FileID
				JOIN Slot S ON F.CropCode = S.CropCode 
				JOIN [Period] P ON P.PeriodID = S.PeriodID

				WHERE 
				F.CropCode = S.CropCode
				AND T.MaterialTypeID = S.MaterialTypeID
				AND T.Isolated = S.Isolated
				AND T.BreedingStationCode = S.BreedingStationCode			
				AND S.StatusCode = 200 
				AND T.TestID = @TestID 
				AND S.SlotID = @SlotID
				AND CAST(T.PlannedDate AS DATE) BETWEEN CAST(P.StartDate AS DATE) AND CAST(P.EndDate AS DATE)
				) 
				BEGIN

					EXEC PR_ThrowError 'Cannot link slot to test. Please check property of test.';
					RETURN;	
				END

		END

		BEGIN TRAN;			
			
			IF EXISTS(SELECT TestID FROM SlotTest WHERE TestID = @TestID) BEGIN
				UPDATE SlotTest SET SlotID = @SlotID WHERE TestID = @TestID;
			END
			ELSE BEGIN
				INSERT INTO SlotTest(SlotID, TestID)
				VALUES(@SlotID, @TestID)	
			END			
			--UPdate test status to 150 meaning status changed from created to slot consumed.
			EXEC PR_Update_TestStatus @TestID, 150;

		COMMIT TRAN;
		--Get test detail
		--EXEC PR_GetTestDetail @TestID, @UserID;
		EXEC PR_GetTestDetail @TestID
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
            ROLLBACK;
		THROW;
	END CATCH
END

GO