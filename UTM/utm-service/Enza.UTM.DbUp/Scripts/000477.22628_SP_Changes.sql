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


ALTER PROCEDURE [dbo].[PR_PLAN_GetApprovedSlots]
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
    AND (ISNULL(@UserName, '') = '' OR S.RequestUser = @UserName)
    AND (ISNULL(@SlotName, '') = '' OR S.SlotName LIKE CONCAT('%', @SlotName, '%'))
	AND S.PlannedDate > GETDATE()
	AND ISNULL(S.TestTypeID,1) BETWEEN 1 AND 7
    ORDER BY S.PlannedDate DESC;
END

GO


DROP PROCEDURE IF EXISTS PR_LFDISK_GetApprovedSlots
GO
/*
Author					Date			Remarks
-------------------------------------------------------------------------------

Krishna Gautam			2021-June-09	#22628: sp created.

==================================Example======================================
--EXEC PR_LFDISK_GetApprovedSlots 'JAVRA\kgautam', '7','ON'

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
	   S.MaterialTypeID,
	   S.BreedingStationCode,
	   S.TestTypeID,
	   RC.TestProtocolID
    FROM Slot S
	JOIN ReservedCapacity RC ON RC.SlotID = S.SlotID
	JOIN string_split(@Crops,',') T ON T.[value] = S.CropCode
    WHERE S.StatusCode = 200
    AND (ISNULL(@UserName, '') = '' OR S.RequestUser = @UserName)
    AND (ISNULL(@SlotName, '') = '' OR S.SlotName LIKE CONCAT('%', @SlotName, '%'))
	AND S.PlannedDate > GETDATE()
	AND ISNULL(S.TestTypeID,0) = 9
    ORDER BY S.PlannedDate DESC;
END

GO



