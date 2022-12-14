/*
Author					Date			Description
Krishna Gautam			2019-Jul-08		Service created to get capacity planning for SO for Lightscanner
Dibya			    2020-Feb-19		Adjusted week name. made shorter name
Dibya			    2020-Feb-27		Adjusted the sorting columns

===================================Example================================

EXEC PR_GetPlanningCapacitySO_LS 4744
*/

ALTER PROCEDURE [dbo].[PR_GetPlanningCapacitySO_LS]
(
	@PeriodID INT
)
AS 
BEGIN

	DECLARE @Query NVARCHAR(MAX),@Query1 NVARCHAR(MAX),@Columns NVARCHAR(MAX), @MinPeriodID INT,@PlatformID INT;
	DECLARE @Period TABLE(PeriodID INT,PeriodName NVARCHAR(MAX));
	DECLARE @ColumnTable TABLE(ColumnID NVARCHAR(MAX), Label NVARCHAR(MAX),[Order] INT, IsVisible BIT,Editable BIT);

	SELECT @PlatformID = PlatformID 
	FROM [Platform] WHERE PlatformCode = 'LS' --Lightscanner;

	IF(ISNULL(@PlatformID,0)=0)
	BEGIN
		EXEC PR_ThrowError 'Invalid Platform';
		RETURN
	END
	
	IF NOT EXISTS (SELECT PeriodID FROM [Period] WHERE PeriodID = @PeriodID)
	BEGIN
		EXEC PR_ThrowError 'Invalid Period (Week)';
		RETURN
	END

	INSERT INTO @Period(PeriodID, PeriodName)
	SELECT 
		P.PeriodID,
		Concat('Wk' + RIGHT(P.PeriodName, 2),Concat(FORMAT(P.StartDate,'MMMdd','en-US'),'-',FORMAT(P.EndDate,'MMMdd','en-US'))) AS PeriodName
	FROM [Period] P 
	WHERE PeriodID BETWEEN @PeriodID - 4 AND @PeriodID +5

	SELECT 
		@Columns = COALESCE(@Columns +',','') + QUOTENAME(PeriodID)
	FROM @Period ORDER BY PeriodID;

	SELECT TOP 1 @MinPeriodID =  PeriodID FROM @Period ORDER BY PeriodID


	IF(ISNULL(@Columns,'') = '')
	BEGIN
		EXEC PR_ThrowError 'No Period (week) found';
		RETURN
	END

	SET @Query = N'SELECT T1.CropMethodID, C.ABSCropCode, T1.MethodCode, UsedFor, '+ @Columns+'
				FROM 
				(
					SELECT 
					   CropMethodID, 
					   PM.MethodID, 
					   MethodCode,
					   ABSCropCode,
					   UsedFor,
					   DisplayOrder
					FROM CropMethod CM
					JOIN Method PM ON PM.MethodID = CM.MethodID
				) 
				T1 				
				JOIN ABSCrop C ON C.ABSCropCode = T1.ABSCropCode
				LEFT JOIN
				(
					SELECT CropMethodID,'+@Columns+'
					FROM 
					(
						SELECT CropMethodID,PeriodID, NrOfPlates = MAX(NrOfPlates) 
						FROM ReservedCapacity						
						GROUP BY CropMethodID,PeriodID
					) 
					SRC
					PIVOT 
					(
						MAX(NrOfPlates)
						FOR PeriodID IN ('+@Columns+')
					)
					PIV

				) T2 ON T2.CropMethodID = T1.CropMethodID	
				Order BY T1.UsedFor, T1.ABSCropCode, T1.MethodCode';

	

	EXEC SP_ExecuteSQL @Query ,N'@PlatformID INT', @PlatformID;


	INSERT INTO @ColumnTable(ColumnID,Label,[Order],IsVisible,Editable)
	VALUES
	('CropMethodID','CropMethodID',0,0,0),
	('ABSCropCode','ABS Crop',1,1,0),
	('MethodCode','Method',2,1,0),
	('UsedFor','UsedFor',3,0,0);
	

	INSERT INTO @ColumnTable(ColumnID,Label,[Order],IsVisible,Editable)
	SELECT PeriodID, PeriodName, PeriodID - @MinPeriodID + 4, 1,1 FROM @Period ORDER BY PeriodID

	SELECT * FROM @ColumnTable
	

    DECLARE @tbl RCAggrTableType;
    
    INSERT @tbl (Method, PeriodID, NrOfPlates, DisplayOrder)
    SELECT 'Hybrid Plates' AS Method, PeriodID, NrOfPlates = SUM(NrOfPlates), 1
    FROM ReservedCapacity RC
    JOIN CropMethod PC ON PC.CropMethodID = RC.CropMethodID 
    WHERE PC.UsedFor = 'HYB'
    GROUP BY PeriodID;
    IF(@@ROWCOUNT = 0) BEGIN
	   INSERT @tbl(Method) VALUES('Hybrid Plates');
    END

    INSERT @tbl (Method, PeriodID, NrOfPlates, DisplayOrder)
    SELECT 'Parentline Plates' AS Method, PeriodID, NrOfPlates = SUM(NrOfPlates), 2
    FROM ReservedCapacity RC
    JOIN CropMethod PC ON PC.CropMethodID = RC.CropMethodID 
    WHERE PC.UsedFor = 'par'
    GROUP BY PeriodID;
    IF(@@ROWCOUNT = 0) BEGIN
	   INSERT @tbl(Method) VALUES('Parentline Plates');
    END

    INSERT @tbl (Method, PeriodID, NrOfPlates, DisplayOrder)
    SELECT 'Total Plates' AS Method, PeriodID, NrOfPlates = SUM(NrOfPlates), 3
    FROM ReservedCapacity
    GROUP BY PeriodID
    IF(@@ROWCOUNT = 0) BEGIN
	   INSERT @tbl(Method) VALUES('Total Plates');
    END
    
    INSERT @tbl (Method, PeriodID, NrOfPlates, DisplayOrder)
    SELECT 'Plates Budget' AS Method, PeriodID, NrOfPlates, 4
    FROM Capacity
    WHERE PlatformID = @PlatformID
    IF(@@ROWCOUNT = 0) BEGIN
	   INSERT @tbl(Method) VALUES('Plates Budget');
    END

    SET @Query1 = N'SELECT Method, ' + @Columns + N' 
    FROM
    (
	   SELECT Method, DisplayOrder, ' + @Columns + N' 
	   FROM @tbl SRC
	   PIVOT 
	   (
		  MAX(NrOfPlates)
		  FOR PeriodID IN (' + @Columns + N')
	   ) PIV 
    ) V1 
    ORDER BY DisplayOrder';
    EXEC SP_ExecuteSQL @Query1 , N'@tbl RCAggrTableType READONLY, @PlatformID INT', @tbl, @PlatformID
END
GO