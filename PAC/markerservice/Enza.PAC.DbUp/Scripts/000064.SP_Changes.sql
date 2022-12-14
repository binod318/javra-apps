DROP PROCEDURE IF EXISTS [dbo].[PR_Ignite_Decluster]
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

	DECLARE @DetAssignmentID INT, @ReturnVarieties NVARCHAR(MAX), @TestID INT;
	
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

			SELECT @TestID = TestID FROM TestDetAssignment WHERE DetAssignmentID = @DetAssignmentID;

			--if all destermination assignments are declustered then update status of Test
			IF NOT EXISTS
			(
				SELECT TD.TestID FROM TestDetAssignment TD
				JOIN DeterminationAssignment DA ON DA.DetAssignmentID = TD.DetAssignmentID
				where DA.StatusCode < 300 AND TD.TestID = @TestID
			)
			BEGIN

				UPDATE Test
				SET StatusCode = 150 --Declustered
				WHERE TestID = @TestID

			END
			
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


DROP PROCEDURE IF EXISTS [dbo].[PR_GetTestInfoForLIMS]
GO

-- =============================================
-- Author:		Binod Gurung
-- Create date: 2019/10/22
-- Description:	Pull Test Information for input period for LIMS
-- =============================================
/*
EXEC PR_GetTestInfoForLIMS 4791, 5
*/
CREATE PROCEDURE [dbo].[PR_GetTestInfoForLIMS]
(
	@PeriodID INT,
	@WeekDiff INT
)
AS
BEGIN
	
	DECLARE @PlannedDateStart DATETIME, @PlannedDateEnd DATETIME, @ExpectedDateStart DATETIME, @ExpectedDateEnd DATETIME, @PlannedDate DATETIME, @ExpectedDate DATETIME;

	SET NOCOUNT ON;

	SELECT 
		@PlannedDateStart = StartDate, 
		@PlannedDateEnd = EndDate 
	FROM [Period] WHERE PeriodID = @PeriodID;

	SELECT @ExpectedDateStart = DATEADD(WEEK, @WeekDiff, @PlannedDateStart);
	SELECT @ExpectedDateEnd = DATEADD(WEEK, @WeekDiff, @PlannedDateEnd);

	-- Planned date is the monday of planned week
	WITH CTE
	AS
	(
		SELECT TOP 1 0 AS N, StartDate FROM [Period] P
			WHERE P.StartDate BETWEEN @PlannedDateStart AND @PlannedDateEnd ORDER BY P.StartDate
		UNION ALL
		SELECT n+1, DATEADD(Day,1, Startdate) AS D1 FROM CTE
			WHERE n<6
	)
	SELECT @PlannedDate = CTE.StartDate FROM CTE
	WHERE DATENAME(WEEKDAY,CTE.StartDate) = 'Monday';

	-- Expected date is the friday of expected week
	WITH CTE
	AS
	(
		SELECT TOP 1 0 AS N, StartDate FROM [Period] P
			WHERE P.StartDate BETWEEN @ExpectedDateStart AND @ExpectedDateEnd ORDER BY P.StartDate
		UNION ALL
		SELECT n+1, DATEADD(Day,1, Startdate) AS D1 FROM CTE
			WHERE n<6
	)
	SELECT @ExpectedDate = CTE.StartDate FROM CTE
	WHERE DATENAME(WEEKDAY,CTE.StartDate) = 'Friday';

	SELECT 
		'DPW'													AS ContainerType,
		'NL'													AS CountryCode,
		MAX(V0.CropCode)										AS CropCode,
		CONVERT(varchar(50), @ExpectedDate, 127)				AS ExpectedDate,
		ExpectedWeek = DATEPART(WEEK, @ExpectedDate),	
		ExpectedYear = YEAR(@ExpectedDate),
		'N'														AS Isolated,	
		'FRS'													AS MaterialState,
		'SDS'													AS MaterialType,
		CONVERT(varchar(50), @PlannedDate, 127)					AS PlannedDate, 
		PlannedWeek = DATEPART(WEEK, @PlannedDate),	
		PlannedYear = YEAR(@PlannedDate),
		'TestRemarks'											AS Remark, 
		T.TestID												AS RequestID, 
		'PAC'													AS RequestingSystem,
		'NL'													AS SynchronisationCode,
		CAST(ROUND(SUM(ISNULL(V0.PlatesPerRow,0)),0) AS INT)	AS TotalNrOfPlates , 
		CAST(ROUND(SUM(ISNULL(TestsPerRow,0)),0) AS INT)		AS TotalNrOfTests  
	FROM
	(	
		SELECT 
			TestID, DA.DetAssignmentID, 
			(M.NrOfSeeds / 92.0) AS PlatesPerRow,
			V1.MarkersPerDA,
			( (M.NrOfSeeds / 92.0) * V1.MarkersPerDA) AS TestsPerRow,
			AC.CropCode
		FROM TestDetAssignment TDA
		JOIN DeterminationAssignment DA ON DA.DetAssignmentID = TDA.DetAssignmentID
		JOIN Method M ON M.MethodCode = DA.MethodCode
		JOIN CropMethod CM ON CM.MethodID = M.MethodID AND CM.ABSCropCode = DA.ABSCropCode
		JOIN ABSCrop AC On AC.ABSCropCode = DA.ABSCropCode
		LEFT JOIN 
		(
			SELECT DetAssignmentID, COUNT(DetAssignmentID) AS MarkersPerDA FROM MarkerToBeTested MTBT 
			GROUP BY DetAssignmentID
		) V1 ON V1.DetAssignmentID = DA.DetAssignmentID
	) V0 
	JOIN Test T ON T.TestID = V0.TestID
	WHERE T.PeriodID = @PeriodID AND T.StatusCode = 150
	GROUP BY T.TestID

END

GO


