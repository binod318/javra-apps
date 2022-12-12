DROP PROCEDURE IF EXISTS [dbo].[PR_Update_Test]
GO


/*
Authror					Date				Description 
KRISHNA GAUTAM			2019-Mar-28			Updated previous method to restrict user from changing testtypeid if plate is already created.
=================Example===============
EXEC PR_Update_Test 76,'KATHMANDU\psindurakar',2,0,2,2,'2018-04-27',1
*/

CREATE PROCEDURE [dbo].[PR_Update_Test]
(
	@TestID INT,
	--@UserID NVARCHAR(200),
	@ContainerTypeID INT,
	@Isolated BIT,
	@MaterialTypeID INT,
	@MaterialStateID INT,
	@PlannedDate DateTime,
	@TestTypeID INT,
	@ExpectedDate DATETIME,
	@SlotID INT = NULL, --This value is not required for now 
	@Cumulate BIT,
	@SiteID INT = NULL
)
AS
BEGIN
	DECLARE @ReturnValue INT;
	DECLARE @TestTypeID_Prev INT;
	IF(ISNULL(@TestID,0)=0) BEGIN
		EXEC PR_ThrowError 'Test doesn''t exist.';
		RETURN;
	END

	----check valid test.
	--EXEC @ReturnValue = PR_ValidateTest @TestID, @UserID;
	--IF(@ReturnValue <> 1) BEGIN
	--	RETURN;
	--END
	--check status for validation of changed column
	IF EXISTS(SELECT StatusCode FROM Test WHERE StatusCode >= 400 AND TestID = @TestID) BEGIN
		EXEC PR_ThrowError 'Cannot change for this test.';
		RETURN;
	END

	--check if slot is assigned or not
	IF EXISTS(SELECT SlotID FROM Test T JOIN SlotTest ST ON ST.TestID = @TestID) BEGIN
		EXEC PR_ThrowError 'Cannot change test properties after assigning slot.';
		RETURN;
	END

	--Check if plate is created or not
	SELECT @TestTypeID_Prev = TestTypeID FROM Test WHERE TestID = @TestID;

	IF(ISNULL(@TestTypeID,0) <> ISNULL(@TestTypeID_Prev,0))
	BEGIN
		EXEC PR_ThrowError 'Cannot change ''Test Type''.';
		RETURN;
	END

	SET NOCOUNT ON;
	BEGIN TRY
		BEGIN TRAN
			UPDATE Test 
			SET 
				ContainerTypeID = @ContainerTypeID,
				Isolated = @Isolated,
				TestTypeID = @TestTypeID,
				PlannedDate = @PlannedDate,
				MaterialTypeID = @MaterialTypeID,
				MaterialStateID = @MaterialStateID,
				ExpectedDate = @ExpectedDate,
				Cumulate = @Cumulate,
				SiteID = ISNULL(@SiteID,SiteID)
			WHERE TestID = @TestID;			
		COMMIT TRAN;
		END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
            ROLLBACK;
		THROW;
	END CATCH

END
GO


