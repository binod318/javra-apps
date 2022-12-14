DROP PROCEDURE IF EXISTS [dbo].[PR_SaveCriteriaPerCrop]
GO


/*
Author					Date				Remarks
Binod Gurung			2021-10-29			Add,update,Delete criteria per crop record

=================EXAMPLE=============
 EXEC PR_SaveCriteriaPerCrop N'[{"CropCode":"ED","ThresholdA":6,"ThresholdB":12,"CalcExternalAppHybrid":1, "CalcExternalAppParent":0,"Action":"i"}]';
 EXEC PR_SaveCriteriaPerCrop N'[{"CropCode":"ED","Action":"d"}]'
 EXEC PR_SaveCriteriaPerCrop @DataAsJson=N'{"CropCode":"AF","ThresholdA":0.0,"ThresholdB":0.0,"CalcExternalAppHybrid":false,"CalcExternalAppParent":false,"Action":"d"}'

*/


CREATE PROCEDURE [dbo].[PR_SaveCriteriaPerCrop]
(
    @DataAsJson NVARCHAR(MAX)
)AS BEGIN
    SET NOCOUNT ON;
	DECLARE @Tbl TABLE(CropCode NVARCHAR(10), ThresholdA DECIMAL(5,2), ThresholdB DECIMAL(5,2), CalcExternalAppHybrid BIT, CalcExternalAppParent BIT, [Action] CHAR(1));

	--Read JSON into temptable
	INSERT @Tbl (CropCode, ThresholdA, ThresholdB, CalcExternalAppHybrid, CalcExternalAppParent, [Action])
	SELECT T1.CropCode,T1.ThresholdA,T1.ThresholdB,T1.CalcExternalAppHybrid,T1.CalcExternalAppParent,T1.[Action] 
	FROM OPENJSON(@DataAsJson) WITH
	(
		CropCode				NVARCHAR(10),
		ThresholdA				DECIMAL(5,2),
		ThresholdB				DECIMAL(5,2),
		CalcExternalAppHybrid	BIT,
		CalcExternalAppParent	BIT,
		[Action]				CHAR(1)
	) T1

	--Validation not to allow save for 0 Threshold value when Calcualte external is not checked
	IF EXISTS
    (
	   SELECT CropCode FROM @Tbl
	   WHERE (ISNULL(ThresholdA,0) = 0 OR ISNULL(ThresholdB,0) = 0 ) AND ISNULL(CalcExternalAppHybrid,0) = 0 AND ISNULL(CalcExternalAppParent,0) = 0 AND [Action] IN ('i','u')
    ) BEGIN
	   EXEC PR_ThrowError N'Threshold value 0 not allowed to save.';
	   RETURN;
    END

    --duplicate validation while adding new and updating existing
    IF EXISTS
    (
	   SELECT T.CropCode FROM @Tbl T
	   JOIN CalcCriteriaPerCrop CC ON CC.CropCode = T.CropCode AND [Action] = 'i'
    ) BEGIN
	   EXEC PR_ThrowError N'Record already exists for selected crop.';
	   RETURN;
    END
    
	MERGE INTO CalcCriteriaPerCrop T
	USING @Tbl S ON T.CropCode = S.CropCode
	WHEN NOT MATCHED AND S.[Action] = 'i' THEN --Insert data
		INSERT (CropCode, ThresholdA, ThresholdB, CalcExternalAppHybrid, CalcExternalAppParent)
		VALUES (S.CropCode, S.ThresholdA, ThresholdB, S.CalcExternalAppHybrid, S.CalcExternalAppParent)
	WHEN MATCHED AND S.[Action] = 'u' THEN -- update data
		UPDATE SET
			ThresholdA = S.ThresholdA,
			ThresholdB = S.ThresholdB,
			CalcExternalAppHybrid = S.CalcExternalAppHybrid,
			CalcExternalAppParent = S.CalcExternalAppParent
	WHEN MATCHED AND S.[Action] = 'd' THEN --delete data
		DELETE;
END
GO


