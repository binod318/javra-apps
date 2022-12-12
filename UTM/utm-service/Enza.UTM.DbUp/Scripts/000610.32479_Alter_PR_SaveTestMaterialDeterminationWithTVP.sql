DROP PROCEDURE IF EXISTS [dbo].[PR_SaveTestMaterialDeterminationWithTVP]
GO


/*
Author:			KRISHNA GAUTAM
Created Date:	2017-DEC-06
Description:	Save test material determination. */

/*
=================Example===============

*/


CREATE PROCEDURE [dbo].[PR_SaveTestMaterialDeterminationWithTVP]
(	
	@CropCode		NVARCHAR(15),
	@TestID			INT,	
	@TVPM TVP_TMD	READONLY
) AS BEGIN
	SET NOCOUNT ON;	
	DECLARE @Tbl TABLE (MaterialID INT, MaterialKey NVARCHAR(50));

	INSERT INTO @Tbl (MaterialID, MaterialKey)
	SELECT M.MaterialID, M.MaterialKey
	FROM Material M
	JOIN
	(
		SELECT DISTINCT MaterialID 
		FROM @TVPM 
		--WHERE Selected = 1
	) M2 ON M2.MaterialID = M.MaterialID;

	--insert or delete statement for merge
	MERGE INTO TestMaterialDetermination T 
	USING 
	(
		SELECT T2.MaterialID,T1.DeterminationID,T1.Selected 
			FROM 
			( SELECT MaterialID , DeterminationID, Selected FROM 
				@TVPM 
				GROUP BY MaterialID, DeterminationID, Selected
			) AS T1
		LEFT JOIN @Tbl T2 ON T1.MaterialID = T2.MaterialID			
	) S
	ON T.MaterialID = S.MaterialID  AND T.DeterminationID = S.DeterminationID AND T.TestID = @TestID
	WHEN NOT MATCHED BY TARGET AND S.Selected = 1 THEN 
		INSERT(TestID,MaterialID,DeterminationID) VALUES (@TestID,S.MaterialID,s.DeterminationID)
	WHEN MATCHED AND S.Selected = 0 AND T.MaterialID = S.MaterialID  AND T.DeterminationID = S.DeterminationID AND T.TestID = @TestID THEN 
	DELETE;	
END




GO


