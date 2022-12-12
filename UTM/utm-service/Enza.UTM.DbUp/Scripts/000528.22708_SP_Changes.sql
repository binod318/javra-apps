DROP PROCEDURE IF EXISTS [dbo].[PR_LFDISK_SaveConfiguration]
GO

DROP PROCEDURE IF EXISTS [dbo].[PR_LFDISK_SaveConfigurationName]
GO


/*
Author					Date			Remarks
-------------------------------------------------------------------------------
Binod Gurung			2021-June-25	#22708: Save configuration name
==================================Example======================================
--EXEC PR_LFDISK_SaveConfigurationName 12799,'My custom config1'

*/


CREATE PROCEDURE [dbo].[PR_LFDISK_SaveConfigurationName]
(
	@TestID INT,
	@SamleConfigName NVARCHAR(100)
) AS BEGIN
    SET NOCOUNT ON;

	IF NOT EXISTS(SELECT TestID FROM Test WHERE TestID = @TestID )
	BEGIN
		EXEC PR_ThrowError 'Invalid TestID.';
		RETURN;
	END

	IF NOT EXISTS(SELECT TestID FROM Test WHERE TestID = @TestID AND TestTypeID = 9 )
	BEGIN
		EXEC PR_ThrowError 'Invalid TestType.';
		RETURN;
	END

    UPDATE Test
	SET SampleConfigName = @SamleConfigName
	WHERE TestID = @TestID

END
GO


