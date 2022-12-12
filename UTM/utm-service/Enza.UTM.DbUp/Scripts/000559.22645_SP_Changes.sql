DROP PROCEDURE IF EXISTS [dbo].[PR_PLAN_GetApprovedSlots]
GO


/*
Author					Date			Remarks
-------------------------------------------------------------------------------
Dibya Suvedi			2020-Apr-02		#11245: Sp Created
Krishna Gautam			2020-Apr-03		#11245: Change request for showing only crops that user have access and date greater than today
Krishna Gautam			2020-Feb-11		#18921: add test type to slot.
Krishna Gautam			2021-June-09	#22628: sp changed.

==================================Example======================================
--EXEC PR_PLAN_GetApprovedSlots 'JAVRA\dsuvedi', '57','TO'

*/


CREATE PROCEDURE [dbo].[PR_PLAN_GetApprovedSlots]
(
    @UserName	 NVARCHAR(100) = NULL,
    @SlotName	 NVARCHAR(200) = NULL,
	@Crops		 NVARCHAR(MAX)
) AS BEGIN
    SET NOCOUNT ON;

    SELECT TOP 200
	   S.SlotID,
	   S.SlotName,
	   S.CropCode,
	   S.PlannedDate,
	   S.ExpectedDate,
	   S.MaterialTypeID,
	   S.MaterialStateID,
	   S.Isolated,
	   S.BreedingStationCode,
	   S.TestTypeID
    FROM Slot S
	JOIN string_split(@Crops,',') T ON T.[value] = S.CropCode
    WHERE S.StatusCode = 200
	AND S.TestTypeID <> 9 -- other than Leafdisk
    AND (ISNULL(@UserName, '') = '' OR S.RequestUser = @UserName)
    AND (ISNULL(@SlotName, '') = '' OR S.SlotName LIKE CONCAT('%', @SlotName, '%'))
	AND S.PlannedDate > GETDATE()
    ORDER BY S.PlannedDate DESC;
END
GO


DROP PROCEDURE IF EXISTS [dbo].[PR_LFDISK_GetApprovedSlots]
GO


/*
Author					Date			Remarks
-------------------------------------------------------------------------------
Dibya Suvedi			2020-Apr-02		#11245: Sp Created
Krishna Gautam			2020-Apr-03		#11245: Change request for showing only crops that user have access and date greater than today
Krishna Gautam			2020-Feb-11		#18921: add test type to slot.
Krishna Gautam			2021-June-09	#22628: sp changed.

==================================Example======================================
--EXEC PR_LFDISK_GetApprovedSlots 'JAVRA\dsuvedi', '57','TO'

*/


CREATE PROCEDURE [dbo].[PR_LFDISK_GetApprovedSlots]
(
    @UserName	 NVARCHAR(100) = NULL,
    @SlotName	 NVARCHAR(200) = NULL,
	@Crops		 NVARCHAR(MAX)
) AS BEGIN
    SET NOCOUNT ON;

    SELECT TOP 200
	   S.SlotID,
	   S.SlotName,
	   S.CropCode,
	   S.PlannedDate,
	   S.ExpectedDate,
	   S.MaterialTypeID,
	   S.MaterialStateID,
	   S.Isolated,
	   S.BreedingStationCode,
	   S.TestTypeID,
	   TestProtocolID = CASE WHEN RC.SlotID IS NULL THEN 0 ELSE RC.TestProtocolID END,
	   SiteID = ISNULL(S.SiteID,0)
    FROM Slot S
	LEFT JOIN 
	(
		SELECT SlotID, TestProtocolID = Max(TestProtocolID) FROM ReservedCapacity 
		GROUP By SlotID
	) RC ON RC.SlotID = S.SlotID
	JOIN string_split(@Crops,',') T ON T.[value] = S.CropCode
    WHERE S.StatusCode = 200
	AND S.TestTypeID = 9 --LeafDisk
    AND (ISNULL(@UserName, '') = '' OR S.RequestUser = @UserName)
    AND (ISNULL(@SlotName, '') = '' OR S.SlotName LIKE CONCAT('%', @SlotName, '%'))
	AND S.PlannedDate > GETDATE()
    ORDER BY S.PlannedDate DESC;
END
GO


