DROP PROCEDURE IF EXISTS PR_LFDISK_ManageInfo
GO

/*
    DECLARE @DataAsJson NVARCHAR(MAX) = N'{
	"TestID":123,
	 "SampleInfo": [
	   {
		"SampleTestID": 10,
		"Key": "QRCode",
		"Value": "12",
	   }
	 ]
    }';
    EXEC PR_LFDISK_ManageInfo 4582, @DataAsJson;
*/
CREATE PROCEDURE [dbo].[PR_LFDISK_ManageInfo]
(
    @TestID	 INT,
    @DataAsJson NVARCHAR(MAX)
) AS BEGIN
    SET NOCOUNT ON;

	MERGE INTO [LD_Sample] T
	USING
	(
		SELECT 
			SampleTestID,
			[Value]
		FROM 
		OPENJSON(@DataAsJson) WITH
		(
			SampleTestID INT '$.SampleTestID',
			[Key] NVARCHAR(MAX) '$.Key',
			[Value] NVARCHAR(MAX) '$.Value'
		) T1
		JOIN SampleTest ST ON ST.SampleID = T1.SampleID
		WHERE [Key] = 'QRCode' AND ST.TestID = @TestID
	) S ON S.SampleTestID = T.SampleTestID
	WHEN MATCHED THEN
	UPDATE SET REferenceCode = [Value];

END
GO



DROP PROCEDURE IF EXISTS PR_LFDISK_GetDeterminations
GO
/*
Author					Date				Description
KRIAHNA GAUTAM			2021-06-09			#22641:SP created.

=================Example===============
EXEC PR_LFDISK_GetDeterminations 

*/
CREATE PROCEDURE [dbo].[PR_LFDISK_GetDeterminations]
(	
	@CropCode NVARCHAR(MAX)
)
AS BEGIN
	SET NOCOUNT ON;
	DECLARE @Source NVARCHAR(20);

	SELECT 
		T1.DeterminationID,
		T1.DeterminationName,
		T1.DeterminationAlias,
		ColumnLabel = T1.DeterminationName
	FROM Determination T1	
	JOIN TestTypeDetermination TTD ON TTD.DeterminationID = T1.DeterminationID
	WHERE TTD.TestTypeID = 9
	AND T1.CropCode = @CropCode;
	
END

GO
