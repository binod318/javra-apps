
DROP PROCEDURE IF EXISTS [dbo].[PR_GetBatch]
GO


/*
Author					Date			Remarks
Krishna Gautam			2020/01/16		Created Stored procedure to fetch data

=================EXAMPLE=============

EXEC PR_GetBatch 
		@PageNr = 1,
		@PageSize = 10,
		@CropCode = NULL,
		@PlatformDesc = NULL,
		@MethodCode = NULL,
		@Plates = '2',
		@TestName = NULL,
		@StatusCode = NULL,
		@ExpectedWeek = '19',
		@SampleNr = NULL,
		@BatchNr = NULL,
		@DetAssignmentID = NULL,
		@VarietyNr = NULL
*/

CREATE PROCEDURE [dbo].[PR_GetBatch]
(
	@pageNr INT,
	@PageSize INT,
	@CropCode NVARCHAR(10) =NULL,
	@PlatformDesc NVARCHAR(100) = NULL,
	@MethodCode NVARCHAR(50) = NULL, 
	@Plates NVARCHAR(100) = NULL, 
	@TestName NVARCHAR(100) = NULL,
	@StatusCode NVARCHAR(100) = NULL, 
	@ExpectedWeek NVARCHAR(100) = NULL,
	@SampleNr NVARCHAR(100) = NULL, 
	@BatchNr NVARCHAR(100) = NULL, 
	@DetAssignmentID  NVARCHAR(100) = NULL,
	@VarietyNr NVARCHAR(100) = NULL
)
AS
BEGIN
	
	DECLARE @Offset INT;

	set @Offset = @PageSize * (@pageNr -1);
	;WITH CTE AS 
	(
		SELECT * FROM 
		(
			SELECT T.TestID, 
				C.CropCode,
				P.PlatformDesc,
				M.MethodCode, 
				Plates = CAST(CAST((M.NrOfSeeds/92.0) as decimal(4,2)) AS NVARCHAR(10)), 
				T.TestName ,
				T.StatusCode, 
				[ExpectedWeek] = CAST(DATEPART(Week, DA.ExpectedReadyDate) AS NVARCHAR(10)),
				SampleNr = CAST(DA.SampleNr AS NVARCHAR(50)), 
				BatchNr = CAST(DA.BatchNr AS NVARCHAR(50)), 
				DetAssignmentID = CAST(DA.DetAssignmentID AS NVARCHAR(50)) ,
				VarietyNr = CAST(V.VarietyNr  AS NVARCHAR(50))
			FROM  Test T 
			JOIN TestDetAssignment TDA ON TDA.TestID = T.TestID
			JOIN DeterminationAssignment DA ON DA.DetAssignmentID = TDA.DetAssignmentID
			JOIN Variety V ON V.VarietyNr = DA.VarietyNr
			JOIN Method M ON M.MethodCode = DA.MethodCode
			JOIN CropMethod CM ON CM.MethodID = M.MethodID AND CM.ABSCropCode = DA.ABSCropCode
			JOIN ABSCrop C ON C.ABSCropCode = CM.ABSCropCode
			JOIN [Platform] P ON P.PlatformID = CM.PlatformID
		) T
		WHERE 
		(ISNULL(@CropCode,'') = '' OR CropCode like '%'+ @CropCode +'%') AND
		(ISNULL(@PlatformDesc,'') = '' OR PlatformDesc like '%'+ @PlatformDesc +'%') AND
		(ISNULL(@MethodCode,'') = '' OR MethodCode like '%'+ @MethodCode +'%') AND
		(ISNULL(@Plates,'') = '' OR Plates like '%'+ @Plates +'%') AND
		(ISNULL(@TestName,'') = '' OR TestName like '%'+ @TestName +'%') AND
		(ISNULL(@StatusCode,'') = '' OR StatusCode like '%'+ @StatusCode +'%') AND
		(ISNULL(@ExpectedWeek,'') = '' OR ExpectedWeek like '%'+ @ExpectedWeek +'%') AND
		(ISNULL(@SampleNr,'') = '' OR SampleNr like '%'+ @SampleNr +'%') AND
		(ISNULL(@BatchNr,'') = '' OR BatchNr like '%'+ @BatchNr +'%') AND
		(ISNULL(@DetAssignmentID,'') = '' OR DetAssignmentID like '%'+ @DetAssignmentID +'%') AND
		(ISNULL(@VarietyNr,'') = '' OR VarietyNr like '%'+ @VarietyNr +'%')
	), Count_CTE AS (SELECT COUNT(TestID) AS [TotalRows] FROM CTE)
	SELECT 
	
		CropCode,
		PlatformDesc,
		MethodCode, 
		Plates , 
		TestName ,
		StatusCode, 
		ExpectedWeek,
		SampleNr, 
		BatchNr, 
		DetAssignmentID ,
		VarietyNr,
		TotalRows
	FROM CTE,Count_CTE 
	ORDER BY TestID DESC, DetAssignmentID ASC
	OFFSET @Offset ROWS
	FETCH NEXT @PageSize ROWS ONLY

END
GO


