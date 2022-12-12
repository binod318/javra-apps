/*
    DECLARE @DataAsJson NVARCHAR(MAX) = N'{"TestID":12675,"SampleInfo":[{"SampleTestID":512,"Key":"12132","Value":"1"}],"Action":"update","Determinations":[],"SampleIDs":[],"PageNumber":1,"PageSize":3,"TotalRows":0,"Filter":[]}';
    
	EXEC PR_LFDISK_ManageInfo1 4582, @DataAsJson;
*/

ALTER PROCEDURE [dbo].[PR_LFDISK_ManageInfo]
(
    @TestID	 INT,
    @DataAsJson NVARCHAR(MAX)
) AS BEGIN
    SET NOCOUNT ON;

	MERGE INTO [LD_Sample] T
	USING
	(
		SELECT 
			S.SampleID,
			[Value]
		FROM 
		OPENJSON(@DataAsJson,'$.SampleInfo') WITH
		(
			SampleTestID INT '$.SampleTestID',
			[Key] NVARCHAR(MAX) '$.Key',
			[Value] NVARCHAR(MAX) '$.Value'
		) T1
		JOIN LD_SampleTest ST ON ST.SampleTestID = T1.SampleTestID
		JOIN LD_sample S ON ST.SampleID = S.SampleID
		WHERE [Key] = 'QRCode' AND ST.TestID = @TestID
	) S ON S.SampleID = T.SampleID
	WHEN MATCHED THEN
	UPDATE SET REferenceCode = [Value];

	

	MERGE INTO LD_SampleTestDetermination T
    USING 
    ( 
		SELECT 
			SampleTestID, 
			DeterminationID = CAST([Key] AS INT), 
			Selected =CAST([Value] AS BIT)
		FROM
		(
			SELECT 
				SampleTestID,
				[key],
				[Value]
			FROM 
			OPENJSON(@DataAsJson,'$.SampleInfo') WITH
			(
				SampleTestID INT '$.SampleTestID',
				[Key] NVARCHAR(MAX) '$.Key',
				[Value] NVARCHAR(MAX) '$.Value'
			) T1
	   		WHERE ISNUMERIC(ISNULL(T1.[Key],'')) = 1
		) T2
    ) S
    ON T.SampleTestID = S.SampleTestID AND T.DeterminationID = S.DeterminationID
    WHEN NOT MATCHED THEN 
	   INSERT(SampleTestID, DeterminationID, StatusCode) 
	   VALUES(S.SampleTestID,S.DeterminationID,100)
	WHEN MATCHED AND Selected = 0 THEN
		DELETE;

END
