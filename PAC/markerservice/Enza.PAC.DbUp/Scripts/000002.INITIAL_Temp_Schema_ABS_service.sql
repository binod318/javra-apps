/****** Object:  Table [dbo].[ABS_Determination_assignments]    Script Date: 8/29/2019 10:48:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ABS_Determination_assignments](
	[Determination_assignment] [int] NOT NULL,
	[Date_booked] [datetime] NULL,
	[Sample_number] [int] NULL,
	[Priority_code] [smallint] NULL,
	[Method_code] [nvarchar](8) NOT NULL,
	[Crop_code] [nvarchar](12) NOT NULL,
	[Primary_number] [int] NULL,
	[Batch_number] [int] NULL,
	[Repeat_indicator] [bit] NOT NULL,
	[Process_code] [nvarchar](10) NULL,
	[Process_number] [int] NULL,
	[Determination_status_code] [smallint] NOT NULL,
	[Utmost_inlay_date] [datetime] NULL,
	[Expected_date_ready] [datetime] NULL,
 CONSTRAINT [PK_Determination_assignme2__17] PRIMARY KEY NONCLUSTERED 
(
	[Determination_assignment] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = ON, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[ABS_Process_lots]    Script Date: 8/29/2019 10:48:30 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ABS_Process_lots](
	[Process_number] [int] NOT NULL,
	[Batch_number] [int] NOT NULL,
	[Batch_output_description] [nvarchar](255) NULL,
 CONSTRAINT [PK_Process_lots_1__12] PRIMARY KEY CLUSTERED 
(
	[Process_number] ASC,
	[Batch_number] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  StoredProcedure [dbo].[EZ_GetDeterminationAssignment]    Script Date: 8/29/2019 10:48:30 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--EXEC [EZ_GetDeterminationAssignment] NULL, '2019-01-08', '2019-01-15' , 'PAC-01,PAC-EL', 'TO,SP,HP,EP', '5', '1,2,3,5,7', 0, 100;
CREATE PROCEDURE [dbo].[EZ_GetDeterminationAssignment] 
     @Determination_assignment INT = 0 --= 1207375                               [OPTIONAL VALUE!!]
       ,@Planned_date_From DateTime --= '2016-03-04 00:00:00.000'  
       ,@Planned_date_To DateTime --= '2018-12-06 00:00:00.000'
       ,@MethodCode Varchar(20) --= 'PAC-01'
       ,@ABScrop Varchar(20) --= 'SP'
       ,@StatusCode Varchar(20) --= '5'
       ,@Priority Varchar(20) --= '1,2,3,4'
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
       And Date_booked >= @Planned_date_From
       And Date_booked <= @Planned_date_To
       AND    Method_code IN (@MethodCode)
       AND Crop_code IN (@ABScrop)
    AND Determination_status_code IN (SELECT * FROM STRING_SPLIT(@StatusCode, ','))
    AND Priority_code IN (SELECT * FROM STRING_SPLIT(@Priority, ','))

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
       And Date_booked >= @Planned_date_From
       And Date_booked <= @Planned_date_To
       AND Method_code IN (@MethodCode)
       AND Crop_code     IN (@ABScrop)
    AND Determination_status_code IN (SELECT * FROM STRING_SPLIT(@StatusCode, ','))
       AND Priority_code IN (SELECT value FROM STRING_SPLIT(@Priority, ','))
  ORDER BY Crop_code 
  OFFSET @PageNumber*@PageSize ROWS
  FETCH NEXT @PageSize ROWS ONLY

END

GO
