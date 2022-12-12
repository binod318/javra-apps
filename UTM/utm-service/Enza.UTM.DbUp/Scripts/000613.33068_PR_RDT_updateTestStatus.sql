/*

Author					Date					Description

Krishna Gautam			2021-05-27				#21381: Stored procedure created to update status of test and to change status of test material determination
=================Example===============
EXEC PR_RDT_UpdateTestStatus 1045, 200
EXEC PR_RDT_UpdateTestStatus 1045, 500

*/

ALTER PROCEDURE [dbo].[PR_RDT_UpdateTestStatus]
(
	@TestID INT,
	@StatusCode INT,
	@InterfaceRefID NVARCHAR(MAX) = NULL
)
AS 
BEGIN

	UPDATE Test SET StatusCode = @StatusCode WHERE TestID = @TestID;

	IF(ISNULL(@StatusCode,0) = 200)
	BEGIN
		UPDATE TestMaterialDetermination SET StatusCode = 400 WHERE TestID = @TestID;
	END

	--if interface reference id is sent then update to those otherwise update data to all.
	IF(ISNULL(@StatusCode,0) = 500 AND ISNULL(@InterfaceRefID,'') <>'')
	BEGIN
		UPDATE T SET 
			T.StatusCode = CASE WHEN StatusCode = 200 THEN 500 ELSE 400 END
		FROM TestMaterialDetermination  T 
		JOIN String_Split(@InterfaceRefID,',') T1 ON T1.[Value] = T.InterfaceRefID 
		WHERE TestID = @TestID
	END
	ELSE
	BEGIN		
		UPDATE TestMaterialDetermination SET StatusCode = CASE WHEN StatusCode = 200 THEN 500 ELSE 400 END WHERE TestID = @TestID AND StatusCode NOT IN (400, 500);

	END
	
	


END