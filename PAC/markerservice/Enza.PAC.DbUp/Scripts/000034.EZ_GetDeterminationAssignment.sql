--EXEC [EZ_GetDeterminationAssignment] NULL, '2019-09-02', '2019-09-08' , 'PAC-01,PAC-EL', 'TO,SP,HP,EP', '5', '1,2,3,5,7', 0, 100;
ALTER PROCEDURE [dbo].[EZ_GetDeterminationAssignment] 
     @Determination_assignment INT = 0 --= 1207375                               [OPTIONAL VALUE!!]
       ,@Planned_date_From DateTime --= '2016-03-04 00:00:00.000'  
       ,@Planned_date_To DateTime --= '2018-12-06 00:00:00.000'
       ,@MethodCode Varchar(MAX) --= 'PAC-01'
       ,@ABScrop Varchar(MAX) --= 'SP'
       ,@StatusCode Varchar(MAX) --= '5'
       ,@Priority Varchar(MAX) --= '1,2,3,4'
       ,@PageNumber INT --= 0
       ,@PageSize INT --= 10

AS 
BEGIN

SET @StatusCode = replace(@StatusCode, ' ', '') 
SET @Priority = replace(@Priority, ' ', '') 

DECLARE @TotalCount INT
SELECT @TotalCount = Count(*) 
 FROM ABS_Determination_assignments
WHERE 
       CASE WHEN @Determination_assignment IS NULL OR @Determination_assignment = 0
             THEN 1
             ELSE Determination_assignment
       END = CASE WHEN @Determination_assignment IS NULL OR @Determination_assignment = 0
                           THEN 1
                           ELSE @Determination_assignment
       END
   --    And 
	  --(
	  -- (ISNULL(@Planned_date_From, '') = '' OR Date_booked >= @Planned_date_From)
	  -- And 
	  -- (ISNULL(@Planned_date_To, '') = '' OR Date_booked <= @Planned_date_To)
	  -- )
       AND Method_code IN (SELECT [value] FROM STRING_SPLIT(@MethodCode, ','))
       AND Crop_code   IN (SELECT [value] FROM STRING_SPLIT(@ABScrop, ','))
    AND Determination_status_code IN (SELECT [value] FROM STRING_SPLIT(@StatusCode, ','))
    AND Priority_code IN (SELECT [value] FROM STRING_SPLIT(@Priority, ','))

	
SELECT DA.[Determination_assignment] AS DeterminationAssignment
         ,DA.[Date_booked] AS planned_date 
         ,DA.[Sample_number] AS Sample
         ,DA.[Priority_code] AS Prio
         ,DA.[Method_code] AS MethodCode
         ,DA.[Crop_code] AS ABScrop
         ,DA.[Primary_number] AS VarietyNumber
         ,DA.[Batch_number] AS BatchNumber
         ,DA.[Repeat_indicator] AS RepeatIndicator
         ,DA.[Process_number] AS Process
         ,DA.Determination_status_code AS ProductStatus                          -- Vervangen voor juiste kolom
         ,PL.Batch_output_description AS BatchOutputDescription           -- Zie [ABS_DATA].[dbo].[Process_lots] 
         ,DA.[Utmost_inlay_date] AS UtmostInlayDate
         ,DA.[Expected_date_ready] AS ExpectedReadyDate
         ,@TotalCount AS TotalCount
  FROM ABS_Determination_assignments DA
  LEFT JOIN dbo.ABS_Process_lots PL
  ON PL.Batch_number = DA.Batch_number
  WHERE 
       CASE WHEN @Determination_assignment IS NULL OR @Determination_assignment = 0
             THEN 1
             ELSE Determination_assignment
       END = CASE WHEN @Determination_assignment IS NULL OR @Determination_assignment = 0
                           THEN 1
                           ELSE @Determination_assignment
       END
   --   And 
	  --(
	  -- (ISNULL(@Planned_date_From, '') = '' OR Date_booked >= @Planned_date_From)
	  -- And 
	  -- (ISNULL(@Planned_date_To, '') = '' OR Date_booked <= @Planned_date_To)
	  -- )
       AND Method_code IN (SELECT [value] FROM STRING_SPLIT(@MethodCode, ','))
       AND Crop_code   IN (SELECT [value] FROM STRING_SPLIT(@ABScrop, ','))
    AND Determination_status_code IN (SELECT [value] FROM STRING_SPLIT(@StatusCode, ','))
       AND Priority_code IN (SELECT [value] FROM STRING_SPLIT(@Priority, ','))
  ORDER BY Crop_code 
  OFFSET @PageNumber*@PageSize ROWS
  FETCH NEXT @PageSize ROWS ONLY

END
GO