/****** Object:  UserDefinedTableType [dbo].[RCAggrTableType]    Script Date: 8/29/2019 10:44:45 AM ******/
CREATE TYPE [dbo].[RCAggrTableType] AS TABLE(
	[Method] [nvarchar](100) NULL,
	[PeriodID] [int] NULL,
	[NrOfPlates] [int] NULL,
	[DisplayOrder] [int] NULL
)
GO
/****** Object:  Table [dbo].[Period]    Script Date: 8/29/2019 10:44:45 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Period](
	[PeriodID] [int] IDENTITY(1,1) NOT NULL,
	[PeriodName] [nvarchar](50) NOT NULL,
	[StartDate] [date] NOT NULL,
	[EndDate] [date] NOT NULL,
	[Remark] [nvarchar](255) NULL,
 CONSTRAINT [PK_Period] PRIMARY KEY CLUSTERED 
(
	[PeriodID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  View [dbo].[VW_Period]    Script Date: 8/29/2019 10:44:46 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[VW_Period] AS
SELECT 
	P.PeriodID,
	P.PeriodName,
	PeriodName2 = Concat(P.PeriodName, '(',Concat(FORMAT(P.StartDate,'MMM-d','en-US'),'-',FORMAT(P.EndDate,'MMM-d','en-US')),')'),
	P.StartDate,
	P.EndDate,
	P.Remark 
FROM [Period] P
GO
/****** Object:  Table [dbo].[ABSCrop]    Script Date: 8/29/2019 10:44:46 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ABSCrop](
	[ABSCropCode] [nvarchar](10) NOT NULL,
	[ABSCropName] [nvarchar](50) NULL,
	[CropCode] [char](2) NULL,
 CONSTRAINT [PK_ABSCropCode] PRIMARY KEY CLUSTERED 
(
	[ABSCropCode] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Capacity]    Script Date: 8/29/2019 10:44:46 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Capacity](
	[CapacityID] [int] IDENTITY(1,1) NOT NULL,
	[PeriodID] [int] NOT NULL,
	[PlatformID] [int] NOT NULL,
	[NrOfPlates] [int] NULL,
	[Remarks] [nvarchar](max) NULL,
PRIMARY KEY CLUSTERED 
(
	[CapacityID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[CropMethod]    Script Date: 8/29/2019 10:44:46 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CropMethod](
	[CropMethodID] [int] IDENTITY(1,1) NOT NULL,
	[MethodID] [int] NULL,
	[ABSCropCode] [nvarchar](10) NULL,
	[PlatformID] [int] NULL,
	[UsedFor] [nvarchar](10) NULL,
	[StatusCode] [int] NULL,
	[DisplayOrder] [int] NULL,
PRIMARY KEY CLUSTERED 
(
	[CropMethodID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[CropRD]    Script Date: 8/29/2019 10:44:46 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CropRD](
	[CropCode] [char](2) NOT NULL,
	[CropName] [nvarchar](50) NULL,
	[InBreed] [bit] NULL,
PRIMARY KEY CLUSTERED 
(
	[CropCode] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[DeterminationAssignment]    Script Date: 8/29/2019 10:44:47 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DeterminationAssignment](
	[DetAssignmentID] [int] NOT NULL,
	[SampleNr] [int] NULL,
	[PriorityCode] [int] NULL,
	[MethodCode] [nvarchar](25) NULL,
	[ABSCropCode] [nvarchar](10) NULL,
	[VarietyNr] [int] NULL,
	[BatchNr] [int] NULL,
	[RepeatIndicator] [bit] NULL,
	[ProcessNr] [nvarchar](100) NULL,
	[ProductStatus] [nvarchar](100) NULL,
	[BatchOutputDesc] [nvarchar](250) NULL,
	[StatusCode] [int] NULL,
	[PlannedDate] [datetime] NULL,
	[UtmostInlayDate] [datetime] NULL,
	[ExpectedReadyDate] [datetime] NULL,
 CONSTRAINT [PK_DetAssignmentID] PRIMARY KEY CLUSTERED 
(
	[DetAssignmentID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Marker]    Script Date: 8/29/2019 10:44:47 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Marker](
	[MarkerID] [int] NOT NULL,
	[MarkerName] [nvarchar](50) NULL,
	[StatusCode] [int] NULL,
 CONSTRAINT [PK_MarkerID] PRIMARY KEY CLUSTERED 
(
	[MarkerID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[MarkerCropPlatform]    Script Date: 8/29/2019 10:44:47 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[MarkerCropPlatform](
	[MarkerCropPlatformID] [int] IDENTITY(1,1) NOT NULL,
	[MarkerID] [int] NOT NULL,
	[PlatformID] [int] NULL,
	[CropCode] [char](2) NULL,
	[InMMS] [bit] NULL,
 CONSTRAINT [PK_MarkerCropPlatformID] PRIMARY KEY CLUSTERED 
(
	[MarkerCropPlatformID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[MarkerToBeTested]    Script Date: 8/29/2019 10:44:47 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[MarkerToBeTested](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[DetAssignmentID] [int] NOT NULL,
	[MarkerID] [int] NULL,
	[InEDS] [bit] NULL,
	[InMMS] [bit] NULL,
	[Audit] [nvarchar](100) NULL,
 CONSTRAINT [PK_MarkerToBeTestedID] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[MarkerValuePerVariety]    Script Date: 8/29/2019 10:44:47 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[MarkerValuePerVariety](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[VarietyNr] [int] NOT NULL,
	[MarkerID] [int] NOT NULL,
	[AlleleScore] [nvarchar](20) NULL,
 CONSTRAINT [PK_MarkerValuePerVarietyID] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[MarkerVarietyPlatform]    Script Date: 8/29/2019 10:44:47 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[MarkerVarietyPlatform](
	[MarkerVarietyPlatformID] [int] IDENTITY(1,1) NOT NULL,
	[MarkerID] [int] NOT NULL,
	[PlatformID] [int] NULL,
	[VarietyNr] [int] NULL,
 CONSTRAINT [PK_MarkerVarietyPlatformID] PRIMARY KEY CLUSTERED 
(
	[MarkerVarietyPlatformID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Method]    Script Date: 8/29/2019 10:44:47 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Method](
	[MethodID] [int] IDENTITY(1,1) NOT NULL,
	[MethodCode] [nvarchar](max) NOT NULL,
	[StatusCode] [int] NOT NULL,
	[NrOfSeeds] [int] NULL,
PRIMARY KEY CLUSTERED 
(
	[MethodID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Platform]    Script Date: 8/29/2019 10:44:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Platform](
	[PlatformID] [int] IDENTITY(1,1) NOT NULL,
	[PlatformCode] [nvarchar](10) NOT NULL,
	[PlatformDesc] [nvarchar](50) NULL,
	[UsedForPac] [bit] NULL,
	[DeclusterCrossPlatform] [bit] NULL,
	[StatusCode] [int] NULL,
 CONSTRAINT [PK_Platform] PRIMARY KEY CLUSTERED 
(
	[PlatformID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[ReservedCapacity]    Script Date: 8/29/2019 10:44:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ReservedCapacity](
	[ReservedCapacityID] [int] IDENTITY(1,1) NOT NULL,
	[CropMethodID] [int] NULL,
	[PeriodID] [int] NULL,
	[NrOfPlates] [int] NULL,
	[SlotName]  AS ('PAC_'+format([ReservedCapacityID],'00000')),
PRIMARY KEY CLUSTERED 
(
	[ReservedCapacityID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Status]    Script Date: 8/29/2019 10:44:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Status](
	[StatusID] [int] NOT NULL,
	[StatusTable] [nvarchar](50) NOT NULL,
	[StatusCode] [int] NOT NULL,
	[StatusName] [nvarchar](50) NOT NULL,
	[StatusDescription] [nvarchar](255) NULL,
 CONSTRAINT [PK_Status] PRIMARY KEY CLUSTERED 
(
	[StatusID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Variety]    Script Date: 8/29/2019 10:44:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Variety](
	[VarietyNr] [int] NOT NULL,
	[CropCode] [char](2) NULL,
	[Shortname] [nvarchar](50) NULL,
	[HybOp] [bit] NULL,
	[Type] [char](1) NULL,
	[PacComp] [bit] NULL,
	[Male] [int] NULL,
	[Female] [int] NULL,
	[Status] [nvarchar](20) NULL,
 CONSTRAINT [PK_VarietyNr] PRIMARY KEY CLUSTERED 
(
	[VarietyNr] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[ABSCrop]  WITH CHECK ADD  CONSTRAINT [FK_CropCode] FOREIGN KEY([CropCode])
REFERENCES [dbo].[CropRD] ([CropCode])
GO
ALTER TABLE [dbo].[ABSCrop] CHECK CONSTRAINT [FK_CropCode]
GO
ALTER TABLE [dbo].[Capacity]  WITH CHECK ADD  CONSTRAINT [FK_PeriodID_Capacity] FOREIGN KEY([PeriodID])
REFERENCES [dbo].[Period] ([PeriodID])
GO
ALTER TABLE [dbo].[Capacity] CHECK CONSTRAINT [FK_PeriodID_Capacity]
GO
ALTER TABLE [dbo].[Capacity]  WITH CHECK ADD  CONSTRAINT [FK_PlatformID_Capacity] FOREIGN KEY([PlatformID])
REFERENCES [dbo].[Platform] ([PlatformID])
GO
ALTER TABLE [dbo].[Capacity] CHECK CONSTRAINT [FK_PlatformID_Capacity]
GO
ALTER TABLE [dbo].[CropMethod]  WITH CHECK ADD  CONSTRAINT [FK_ABSCropCode] FOREIGN KEY([ABSCropCode])
REFERENCES [dbo].[ABSCrop] ([ABSCropCode])
GO
ALTER TABLE [dbo].[CropMethod] CHECK CONSTRAINT [FK_ABSCropCode]
GO
ALTER TABLE [dbo].[CropMethod]  WITH CHECK ADD  CONSTRAINT [FK_MethodID] FOREIGN KEY([MethodID])
REFERENCES [dbo].[Method] ([MethodID])
GO
ALTER TABLE [dbo].[CropMethod] CHECK CONSTRAINT [FK_MethodID]
GO
ALTER TABLE [dbo].[CropMethod]  WITH CHECK ADD  CONSTRAINT [FK_PlatformID] FOREIGN KEY([PlatformID])
REFERENCES [dbo].[Platform] ([PlatformID])
GO
ALTER TABLE [dbo].[CropMethod] CHECK CONSTRAINT [FK_PlatformID]
GO
ALTER TABLE [dbo].[DeterminationAssignment]  WITH CHECK ADD  CONSTRAINT [FK_ABSCropCode_DA] FOREIGN KEY([ABSCropCode])
REFERENCES [dbo].[ABSCrop] ([ABSCropCode])
GO
ALTER TABLE [dbo].[DeterminationAssignment] CHECK CONSTRAINT [FK_ABSCropCode_DA]
GO
ALTER TABLE [dbo].[MarkerCropPlatform]  WITH CHECK ADD  CONSTRAINT [FK_CropCode_MarkerCropPlatform] FOREIGN KEY([CropCode])
REFERENCES [dbo].[CropRD] ([CropCode])
GO
ALTER TABLE [dbo].[MarkerCropPlatform] CHECK CONSTRAINT [FK_CropCode_MarkerCropPlatform]
GO
ALTER TABLE [dbo].[MarkerCropPlatform]  WITH CHECK ADD  CONSTRAINT [FK_MarkerID_MarkerCropPlatform] FOREIGN KEY([MarkerID])
REFERENCES [dbo].[Marker] ([MarkerID])
GO
ALTER TABLE [dbo].[MarkerCropPlatform] CHECK CONSTRAINT [FK_MarkerID_MarkerCropPlatform]
GO
ALTER TABLE [dbo].[MarkerCropPlatform]  WITH CHECK ADD  CONSTRAINT [FK_PlatformID_MarkerCropPlatform] FOREIGN KEY([PlatformID])
REFERENCES [dbo].[Platform] ([PlatformID])
GO
ALTER TABLE [dbo].[MarkerCropPlatform] CHECK CONSTRAINT [FK_PlatformID_MarkerCropPlatform]
GO
ALTER TABLE [dbo].[MarkerToBeTested]  WITH CHECK ADD  CONSTRAINT [FK_DetAssignmentID_MarkerToBeTested] FOREIGN KEY([DetAssignmentID])
REFERENCES [dbo].[DeterminationAssignment] ([DetAssignmentID])
GO
ALTER TABLE [dbo].[MarkerToBeTested] CHECK CONSTRAINT [FK_DetAssignmentID_MarkerToBeTested]
GO
ALTER TABLE [dbo].[MarkerToBeTested]  WITH CHECK ADD  CONSTRAINT [FK_MarkerID_MarkerToBeTested] FOREIGN KEY([MarkerID])
REFERENCES [dbo].[Marker] ([MarkerID])
GO
ALTER TABLE [dbo].[MarkerToBeTested] CHECK CONSTRAINT [FK_MarkerID_MarkerToBeTested]
GO
ALTER TABLE [dbo].[MarkerValuePerVariety]  WITH CHECK ADD  CONSTRAINT [FK_MarkerID_MarkerValuePerVariety] FOREIGN KEY([MarkerID])
REFERENCES [dbo].[Marker] ([MarkerID])
GO
ALTER TABLE [dbo].[MarkerValuePerVariety] CHECK CONSTRAINT [FK_MarkerID_MarkerValuePerVariety]
GO
ALTER TABLE [dbo].[MarkerValuePerVariety]  WITH CHECK ADD  CONSTRAINT [FK_VarietyNr_MarkerValuePerVariety] FOREIGN KEY([VarietyNr])
REFERENCES [dbo].[Variety] ([VarietyNr])
GO
ALTER TABLE [dbo].[MarkerValuePerVariety] CHECK CONSTRAINT [FK_VarietyNr_MarkerValuePerVariety]
GO
ALTER TABLE [dbo].[MarkerVarietyPlatform]  WITH CHECK ADD  CONSTRAINT [FK_MarkerID_MarkerCVPlatform] FOREIGN KEY([MarkerID])
REFERENCES [dbo].[Marker] ([MarkerID])
GO
ALTER TABLE [dbo].[MarkerVarietyPlatform] CHECK CONSTRAINT [FK_MarkerID_MarkerCVPlatform]
GO
ALTER TABLE [dbo].[MarkerVarietyPlatform]  WITH CHECK ADD  CONSTRAINT [FK_PlatformID_MarkerVarietyPlatform] FOREIGN KEY([PlatformID])
REFERENCES [dbo].[Platform] ([PlatformID])
GO
ALTER TABLE [dbo].[MarkerVarietyPlatform] CHECK CONSTRAINT [FK_PlatformID_MarkerVarietyPlatform]
GO
ALTER TABLE [dbo].[MarkerVarietyPlatform]  WITH CHECK ADD  CONSTRAINT [FK_VarietyNr_MarkerVarietyPlatform] FOREIGN KEY([VarietyNr])
REFERENCES [dbo].[Variety] ([VarietyNr])
GO
ALTER TABLE [dbo].[MarkerVarietyPlatform] CHECK CONSTRAINT [FK_VarietyNr_MarkerVarietyPlatform]
GO
ALTER TABLE [dbo].[ReservedCapacity]  WITH CHECK ADD  CONSTRAINT [FK_CropMethodID_ReservedCapacity] FOREIGN KEY([CropMethodID])
REFERENCES [dbo].[CropMethod] ([CropMethodID])
GO
ALTER TABLE [dbo].[ReservedCapacity] CHECK CONSTRAINT [FK_CropMethodID_ReservedCapacity]
GO
ALTER TABLE [dbo].[ReservedCapacity]  WITH CHECK ADD  CONSTRAINT [FK_PeriodID_ReservedCapacity] FOREIGN KEY([PeriodID])
REFERENCES [dbo].[Period] ([PeriodID])
GO
ALTER TABLE [dbo].[ReservedCapacity] CHECK CONSTRAINT [FK_PeriodID_ReservedCapacity]
GO
ALTER TABLE [dbo].[Variety]  WITH CHECK ADD  CONSTRAINT [FK_CropCodeVariety] FOREIGN KEY([CropCode])
REFERENCES [dbo].[CropRD] ([CropCode])
GO
ALTER TABLE [dbo].[Variety] CHECK CONSTRAINT [FK_CropCodeVariety]
GO
/****** Object:  StoredProcedure [dbo].[PR_GetCapacity]    Script Date: 8/29/2019 10:44:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
	EXEC PR_GetCapacity 2019

*/
CREATE PROCEDURE [dbo].[PR_GetCapacity]
(
	@Year INT = NULL
) AS
BEGIN	
	DECLARE @SQL NVARCHAR(MAX), @PeriodName NVARCHAR(MAX), @Where NVARCHAR(MAX) = '', @ColumnsIDs NVARCHAR(MAX), @ColumnsIDs2 NVARCHAR(MAX);

	DECLARE @ColumnTable TABLE(ColumnID NVARCHAR(MAX), Label NVARCHAR(MAX),[Order] INT, IsVisible BIT,Editable BIT);

	IF(ISNULL(@Year,0)<>0) BEGIN
		SET @Where = 'WHERE Year(P.StartDate) = '+CAST(@Year AS NVARCHAR(MAX))+' OR Year(P.EndDate) = '+CAST(@Year AS NVARCHAR(MAX));
	END

	ELSE
	BEGIN
		SET @Where = '';
	END

	SELECT 
		@ColumnsIDs = COALESCE(@ColumnsIDS+',','') + QUOTENAME(PlatformID),
		@ColumnsIDs2 = COALESCE(@ColumnsIDS2+',','') + 'MAX(' + QUOTENAME(PlatformID) + ') AS ' + QUOTENAME(PlatformID)
	FROM [Platform]
	WHERE StatusCode = 100

	IF(ISNULL(@ColumnsIDs,'') = '') BEGIN
		EXEC PR_ThrowError 'No Platform found.';
		RETURN;
	END


	SET @SQL = N'	
				SELECT P.PeriodID, PeriodName2 AS PeriodName, ' +@ColumnsIDs+ ', T1.Remarks FROM [VW_Period] P
				LEFT JOIN 
				(
					SELECT PeriodID,MAX(Remarks) AS Remarks,'+@ColumnsIDs2+'
					FROM 
					(
						SELECT PacPlatFormID,Remarks,PeriodID,NrOfPlates FROM Capacity
					)
					SRC
					PIVOT
					(
						MAX(NrOfPlates)
						FOR PlatformID IN ('+@ColumnsIDs+')
					)
					PT
					GROUP BY PeriodID
				) T1
				ON T1.PeriodID = P.PeriodID '
				+@Where +
				' ORDER BY P.PeriodID';
		
	--PRINT @SQL;
	EXEC sp_executesql @SQL;

	INSERT INTO @ColumnTable(ColumnID,Label,[Order],IsVisible,Editable)
	SELECT PlatformID,PlatformDesc,PlatformID + 1,1,1
	FROM [Platform]
	WHERE StatusCode = 100;

	DECLARE @maxOrder INT;
	SELECT @maxOrder = MAX([order]) FROM @ColumnTable

	INSERT INTO @ColumnTable(ColumnID,Label,[Order],IsVisible,Editable)
	VALUES('PeriodID','PeriodID',0,0,0)
	,('PeriodName','PeriodName',1,1,0)
	,('Remarks','Remarks',@maxOrder +1,1,1);

	SELECT * FROM @ColumnTable order by [order]
	
END
GO
/****** Object:  StoredProcedure [dbo].[PR_GetDeterminationAssignments]    Script Date: 8/29/2019 10:44:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
    DECLARE @UnPlannedDataAsJson NVARCHAR(MAX) = N'[{"DetAssignmentID":1,"MethodCode":"PAC-01","ABSCropCode": "HP","PlannedDate":"2019-07-04"}]';
    EXEC PR_GetDeterminationAssignments 4770, '2019-07-01', '2019-07-07', @UnPlannedDataAsJson
*/
CREATE PROCEDURE [dbo].[PR_GetDeterminationAssignments]
(
    @PeriodID			   INT,
    @StartDate			   DATE,
    @EndDate			   DATE,
    @UnPlannedDataAsJson	   NVARCHAR(MAX) = NULL
) AS BEGIN
    SET NOCOUNT ON;

    DECLARE @SQL NVARCHAR(MAX);
    DECLARE @PlatformID INT = 1; --light scanner   

    DECLARE @Capacity TABLE
    (
	   UsedFor VARCHAR(5), 
	   CropCode NVARCHAR(10), 
	   MethodCode NVARCHAR(50), 
	   NrOfResPlates DECIMAL(5,2)
    );
    --handle unplanned records if exists
    DECLARE @DeterminationAssignment TABLE
    (
	   DetAssignmentID    INT,
	   SampleNr		  INT,
	   PriorityCode	  INT,
	   MethodCode		  NVARCHAR(25),
	   ABSCropCode		  NVARCHAR(10),
	   VarietyNr		  INT,
	   BatchNr		  INT,
	   RepeatIndicator    BIT,
	   ProcessNr		  NVARCHAR(100),
	   ProductStatus	  NVARCHAR(100),
	   BatchOutputDesc    NVARCHAR(250),
	   PlannedDate		  DATETIME,
	   UtmostInlayDate    DATETIME,
	   ExpectedReadyDate  DATETIME
    );

    IF(ISNULL(@UnPlannedDataAsJson, '') <> '') BEGIN
	   INSERT @DeterminationAssignment
	   (
		  DetAssignmentID, 
		  SampleNr, 
		  PriorityCode, 
		  MethodCode, 
		  ABSCropCode, 
		  VarietyNr, 
		  BatchNr, 
		  RepeatIndicator, 
		  ProcessNr, 
		  ProductStatus, 
		  BatchOutputDesc, 
		  PlannedDate, 
		  UtmostInlayDate, 
		  ExpectedReadyDate
	   )
	   SELECT * FROM OPENJSON(@UnPlannedDataAsJson) WITH
	   (
		  DetAssignmentID    INT,
		  SampleNr		  INT,
		  PriorityCode	  INT,
		  MethodCode		  NVARCHAR(25),
		  ABSCropCode		  NVARCHAR(10),
		  VarietyNr		  INT,
		  BatchNr		  INT,
		  RepeatIndicator    BIT,
		  ProcessNr		  NVARCHAR(100),
		  ProductStatus	  NVARCHAR(100),
		  BatchOutputDesc    NVARCHAR(250),
		  PlannedDate		  DATETIME,
		  UtmostInlayDate    DATETIME,
		  ExpectedReadyDate  DATETIME
	   );
    END
   
    INSERT @Capacity(UsedFor, CropCode, MethodCode, NrOfResPlates)
    SELECT
	   T1.UsedFor,
	   T1.CropCode,
	   T1.MethodCode,
	   NrOfPlates = SUM(T1.NrOfPlates)
    FROM
    (
	   SELECT 
		  V1.CropCode,
		  DA.MethodCode,
		  V1.UsedFor,
		  NrOfPlates = CAST((V1.NrOfSeeds / 92.0) AS DECIMAL(5,2))
	   FROM 
	   (
		  SELECT 
			 MethodCode,
			 ABSCropCode,
			 PlannedDate
		  FROM DeterminationAssignment
		  UNION
		  SELECT 
			 MethodCode,
			 ABSCropCode,
			 PlannedDate
		  FROM @DeterminationAssignment
	   ) DA
	   JOIN
	   (
		  SELECT 
			 PM.MethodCode,
			 AC.CropCode,
			 AC.ABSCropCode,
			 PM.NrOfSeeds,
			 PCM.UsedFor
		  FROM Method PM
		  JOIN CropMethod PCM ON PCM.MethodID = PM.MethodID
		  JOIN ABSCrop AC ON AC.ABSCropCode = PCM.ABSCropCode
		  WHERE PCM.PlatformID = @PlatformID
		  AND PM.StatusCode = 100
	   ) V1 ON V1.ABSCropCode = DA.ABSCropCode AND V1.MethodCode = DA.MethodCode
	   WHERE CAST(DA.PlannedDate AS DATE) BETWEEN @StartDate AND @EndDate
    ) T1 
    GROUP BY T1.CropCode, T1.MethodCode, T1.UsedFor;
    
    --Get groups
    SELECT
	   V1.SlotName,
	   V1.CropCode,
	   V1.MethodCode,
	   V1.UsedFor,
	   V1.TotalPlates,
	   V2.NrOfResPlates
    FROM
    (
	   SELECT 
		  PC.SlotName,
		  AC.CropCode, 
		  PM.MethodCode,	
		  CM.UsedFor,
		  TotalPlates = SUM(PC.NrOfPlates)
	   FROM ReservedCapacity PC
	   JOIN CropMethod CM ON CM.CropMethodID = PC.CropMethodID
	   JOIN ABSCrop AC ON AC.ABSCropCode = CM.ABSCropCode
	   JOIN Method PM ON PM.MethodID = CM.MethodID
	   WHERE CM.PlatformID = @PlatformID AND PC.PeriodID = @PeriodID
	   GROUP BY PC.SlotName, AC.CropCode, PM.MethodCode, CM.UsedFor
    ) V1
    LEFT JOIN @Capacity V2 ON V2.CropCode = V1.CropCode AND V2.MethodCode = V1.MethodCode AND V2.UsedFor = V1.UsedFor;
    
    SELECT 
	   V2.DetAssignmentID,
	   V1.CropCode,
	   MethodCode = ISNULL(DA.MethodCode, DA2.MethodCode),
	   V1.UsedFor,
	   ABSCropCode = ISNULL(DA.ABSCropCode, DA2.ABSCropCode),
	   SampleNr = ISNULL(DA.SampleNr, DA2.SampleNr),
	   UtmostInlayDate = ISNULL(DA.UtmostInlayDate, DA2.UtmostInlayDate),
	   ExpectedReadyDate = ISNULL(DA.ExpectedReadyDate, DA2.ExpectedReadyDate), 
	   PriorityCode = ISNULL(DA.PriorityCode, DA2.PriorityCode),	   
	   BatchNr = ISNULL(DA.BatchNr, DA2.BatchNr),
	   RepeatIndicator = ISNULL(DA.RepeatIndicator, DA2.RepeatIndicator),
	   VarietyNr = ISNULL(DA.VarietyNr, DA2.VarietyNr),
	   ProcessNr = ISNULL(DA.ProcessNr, DA2.ProcessNr),
	   ProductStatus = ISNULL(DA.ProductStatus, DA2.ProductStatus),
	   BatchOutputDesc = ISNULL(DA.BatchOutputDesc, DA2.BatchOutputDesc),
	   IsPlanned = CAST(V2.IsPlanned AS BIT)
    FROM
    (
	   SELECT 
		  T1.DetAssignmentID,
		  IsPlanned = MAX(T1.IsPlanned)
	   FROM
	   (
		  SELECT
			 DetAssignmentID,
			 IsPlanned = 1
		  FROM DeterminationAssignment
		  WHERE CAST(PlannedDate AS DATE) BETWEEN @StartDate AND @EndDate
		  UNION ALL
		  SELECT
			 DetAssignmentID,
			 IsPlanned = 0
		  FROM @DeterminationAssignment
		  WHERE CAST(PlannedDate AS DATE) BETWEEN @StartDate AND @EndDate
	   ) T1 
	   GROUP BY DetAssignmentID
    ) V2
    LEFT JOIN @DeterminationAssignment DA2 ON DA2.DetAssignmentID = V2.DetAssignmentID AND CAST(DA2.PlannedDate AS DATE) BETWEEN @StartDate AND @EndDate
    LEFT JOIN DeterminationAssignment DA ON DA.DetAssignmentID = V2.DetAssignmentID AND CAST(DA.PlannedDate AS DATE) BETWEEN @StartDate AND @EndDate
    JOIN
    (
	   SELECT
		  AC.CropCode,
		  AC.ABSCropCode,
		  PM.MethodCode,
		  CM.UsedFor
	   FROM CropMethod CM
	   JOIN ABSCrop AC ON AC.ABSCropCode = CM.ABSCropCode
	   JOIN Method PM ON PM.MethodID = CM.MethodID
	   WHERE CM.PlatformID = @PlatformID
    ) V1 ON V1.ABSCropCode = ISNULL(DA.ABSCropCode, DA2.ABSCropCode) AND V1.MethodCode = ISNULL(DA.MethodCode, DA2.MethodCode);
END
GO
/****** Object:  StoredProcedure [dbo].[PR_GetPeriod]    Script Date: 8/29/2019 10:44:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--EXEC PR_GetPeriod 2019
CREATE PROCEDURE [dbo].[PR_GetPeriod]
(
	@Year INT
	
)
AS
BEGIN
	SELECT 
		P.PeriodID, 
		PeriodName = CONCAT(P.PeriodName, FORMAT(P.StartDate, ' (MMM-dd-yy - ', 'en-US' ), FORMAT(P.EndDate, 'MMM-dd-yy)', 'en-US' )),
		[Current] = CAST(CASE WHEN GETDATE() BETWEEN P.StartDate AND P.EndDate THEN 1 ELSE 0 END AS BIT),
		P.StartDate,
		P.EndDate
	FROM [Period] P
	WHERE @Year BETWEEN YEAR(P.StartDate) AND YEAR(P.EndDate)
END
GO
/****** Object:  StoredProcedure [dbo].[PR_GetPlanningCapacitySO_LS]    Script Date: 8/29/2019 10:44:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
Author					Date			Description
Krishna Gautam			2019-Jul-08		Service created to get capacity planning for SO for Lightscanner

===================================Example================================

EXEC PR_GetPlanningCapacitySO_LS 4744
*/

CREATE PROCEDURE [dbo].[PR_GetPlanningCapacitySO_LS]
(
	@PeriodID INT
)
AS 
BEGIN

	DECLARE @Query NVARCHAR(MAX),@Query1 NVARCHAR(MAX),@Columns NVARCHAR(MAX), @MinPeriodID INT,@PlatformID INT;
	DECLARE @Period TABLE(PeriodID INT,PeriodName NVARCHAR(MAX));
	DECLARE @ColumnTable TABLE(ColumnID NVARCHAR(MAX), Label NVARCHAR(MAX),[Order] INT, IsVisible BIT,Editable BIT);

	SELECT @PlatformID = PlatformID 
	FROM Platform WHERE PlatformDesc = 'Lightscanner';

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
		Concat(P.PeriodName, '(',Concat(FORMAT(P.StartDate,'MMM-d','en-US'),'-',FORMAT(P.EndDate,'MMM-d','en-US')),')') AS PeriodName
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

	SET @Query = N'SELECT T1.CropMethodID, C.ABSCropCode,PM.MethodCode, UsedFor, '+ @Columns+'
				FROM 
				(
					SELECT 
					   CropMethodID, 
					   MethodID, 
					   ABSCropCode,
					   UsedFor,
					   DisplayOrder
					FROM CropMethod 
				) 
				T1 
				JOIN Method PM ON PM.MethodID = T1.MethodID
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
	
				Order BY T1.UsedFor, T1.DisplayOrder';

	

	EXEC SP_ExecuteSQL @Query ,N'@PlatformID INT', @PlatformID;


	INSERT INTO @ColumnTable(ColumnID,Label,[Order],IsVisible,Editable)
	VALUES
	('CropMethodID','CropMethodID',0,0,0),
	('ABSCropCode','ABSCropCode',1,1,0),
	('MethodCode','MethodCode',2,1,0),
	('UsedFor','UsedFor',3,0,0);
	

	INSERT INTO @ColumnTable(ColumnID,Label,[Order],IsVisible,Editable)
	SELECT PeriodID, PeriodName,PeriodID - @MinPeriodID + 4, 1,1 FROM @Period ORDER BY PeriodID

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
    SELECT 'Parent lines Plates' AS Method, PeriodID, NrOfPlates = SUM(NrOfPlates), 2
    FROM ReservedCapacity RC
    JOIN CropMethod PC ON PC.CropMethodID = RC.CropMethodID 
    WHERE PC.UsedFor = 'par'
    GROUP BY PeriodID;
    IF(@@ROWCOUNT = 0) BEGIN
	   INSERT @tbl(Method) VALUES('Parent lines Plates');
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
/****** Object:  StoredProcedure [dbo].[PR_SaveCapacity]    Script Date: 8/29/2019 10:44:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
Author					Date			Description
Krishna Gautam			2019-Jul-05		Service created to save pac capacity

===================================Example================================

DECLARE @DataAsJson NVARCHAR(MAX) = N'
[
	{"PeriodID":4744,"PlatformID":"1","Value":"150"}
]';
EXEC PR_SaveCapacity @DataAsJson;
*/
CREATE PROCEDURE [dbo].[PR_SaveCapacity]
(
	@Json NVARCHAR(MAX)
)
AS 
BEGIN
	 SET NOCOUNT ON;
	 DECLARE @PlatformID INT;
	 DECLARE @FilledCapacity TABLE (PeriodID INT,PlatformID INT, Val INT);	 

	 

	 BEGIN TRY
		BEGIN TRANSACTION;

			SELECT 
				 @PlatformID = PlatformID 
			FROM [Platform] 
			WHERE PlatformDesc = 'Lightscanner';

			--Fill temptable from Input Json
			INSERT INTO @FilledCapacity(PeriodID, PlatformID, Val)
			SELECT PeriodID, PlatformID, Val
			FROM OPENJSON(@Json) WITH
			(
				PeriodID	INT '$.PeriodID',
				PlatformID	NVARCHAR(MAX) '$.PlatformID',
				Val			NVARCHAR(MAX) '$.Value'
			);

			--If planned capacity is greater than lab capacity then return error
			IF EXISTS 
			(
				SELECT * FROM @FilledCapacity C
				JOIN
				(
					SELECT FC.PeriodID, FC.PlatformID, SUM(RC.NrOfPlates) AS TotalPlates FROM @FilledCapacity FC 
					JOIN CropMethod CM ON CM.PlatformID = FC.PlatformID
					JOIN ReservedCapacity RC ON RC.CropMethodID = CM.CropMethodID AND RC.PeriodID = FC.PeriodID
					GROUP BY FC.PeriodID, FC.PlatformID
				) T1 ON T1.PeriodID = C.PeriodID AND T1.PlatformID = C.PlatformID
				WHERE T1.TotalPlates > C.Val
			)
			BEGIN
				EXEC PR_ThrowError 'Unable to update lab capacity. More capacity planned already.';
				RETURN
			END	

		
			--update capacity 
			MERGE INTO Capacity T
			USING
			(
				SELECT DISTINCT * FROM OPENJSON(@Json) WITH
				(
					PeriodID INT '$.PeriodID',
					PlatformID NVARCHAR(MAX) '$.PlatformID',
					Val NVARCHAR(MAX) '$.Value'
				) T1
				WHERE ISNUMERIC(PlatformID) = 1

			) S ON S.PeriodID = T.PeriodID AND S.PlatformID = CAST(T.PlatformID AS NVARCHAR(10))
			WHEN NOT MATCHED THEN
			  INSERT(PeriodID,PlatformID,NrOfPlates)  VALUES(S.PeriodID,CAST(S.PlatformID AS INT),CAST(S.val AS INT))
			WHEN MATCHED THEN
			  UPDATE SET T.NrOfPlates = S.val;

			-- Update remarks here
			MERGE INTO Capacity T
			USING
			(
				SELECT * FROM OPENJSON(@Json) WITH
				(
					PeriodID INT '$.PeriodID',
					PlatformID NVARCHAR(MAX) '$.PlatformID',
					Remarks NVARCHAR(MAX) '$.Value'
				) T1
				WHERE PlatformID = 'Remarks'

			) S ON S.PeriodID = T.PeriodID AND T.PlatformID = @PlatformID
			WHEN NOT MATCHED THEN			
				INSERT(PeriodID,PlatformID,NrOfPlates,Remarks)  VALUES(S.PeriodID, @PlatformID, 0, S.Remarks)
			WHEN MATCHED THEN
				UPDATE SET T.Remarks = S.Remarks;

		COMMIT;
	END TRY
	BEGIN CATCH
		ROLLBACK;
		THROW;
	END CATCH
END
GO
/****** Object:  StoredProcedure [dbo].[PR_SavePlanningCapacitySO_LS]    Script Date: 8/29/2019 10:44:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
Author					Date			Description
Krishna Gautam			2019-Jul-09		Service created to save capacity planning for SO for Lightscanner

===================================Example================================

DECLARE @DataAsJson NVARCHAR(MAX) = N'
[
	{
    "CropMethodID": 5,
    "PeriodID": 4656,
    "ForHybrid": 1,
    "Value": 0
  },
	{
    "CropMethodID": 5,
    "PeriodID": 4656,
    "ForHybrid": 0,
    "Value": 0
  }
]';
EXEC PR_SavePlanningCapacitySO_LS @DataAsJson;
*/

CREATE PROCEDURE [dbo].[PR_SavePlanningCapacitySO_LS]
(
	@Json NVARCHAR(MAX)
)
AS
BEGIN
	DECLARE @PlatformID INT;
	DECLARE @UpdateCapacity TABLE (CropMethodID INT,PeriodID INT, NrOfPlates INT);
	DECLARE @ExceededCapacityWeek TABLE (PeriodID INT,PeriodName NVARCHAR(MAX));
	DECLARE @RowCount INT;

	SET NOCOUNT ON;
	 BEGIN TRY
		BEGIN TRANSACTION;

		  INSERT INTO @UpdateCapacity(CropMethodID, PeriodID, NrOfPlates)
		  SELECT CropMethodID, PeriodID, NrOfPlates
		  FROM OPENJSON(@Json) WITH
		  (
			 CropMethodID	 INT '$.CropMethodID',
			 PeriodID			 INT '$.PeriodID',
			 NrOfPlates		 INT	'$.Value'
		  ) T1;
		  
		  SELECT 
			 @PlatformID = PlatformID 
		  FROM [Platform] 
		  WHERE PlatformDesc = 'Lightscanner';
		  IF(ISNULL(@platformID, 0) = 0)
		  BEGIN
			 ROLLBACK;
			 EXEC PR_ThrowError 'Lightscanner platform does not exist.';
			 RETURN
		  END	

		  MERGE INTO ReservedCapacity T
		  USING  @UpdateCapacity S ON S.CropMethodID = T.CropMethodID AND S.PeriodID = T.PeriodID
		  WHEN NOT MATCHED THEN 
			 INSERT (CropMethodID,PeriodID,NrOfPlates)				
			 VALUES (S.CropMethodID, PeriodID,S.NrOfPlates)
		  WHEN MATCHED THEN 
			 UPDATE SET NrOFPlates = S.NrOfPlates;

		  INSERT INTO @ExceededCapacityWeek(PeriodID)
		  SELECT PeriodID 
		  FROM 
		  (
			 SELECT RC.PeriodID, SUM(RC.NrOfPlates) AS ReservedCapacity, ISNULL(MAX(PC.NrOfPlates), 0) AS AvailableCapacity  
			 FROM 
			 (
				SELECT PeriodID FROM @UpdateCapacity
				GROUP BY PeriodID
			 ) UC
			 JOIN ReservedCapacity RC ON RC.PeriodID = UC.PeriodID
			 RIGHT JOIN Capacity PC ON PC.PeriodID = UC.PeriodID 
			 WHERE PC.PlatformID = @PlatformID
			 GROUP BY RC.PeriodID
		  ) T
		  WHERE T.ReservedCapacity > T.AvailableCapacity
		  
		  SELECT @RowCount = COUNT(PeriodID) FROM @ExceededCapacityWeek;

		  IF(ISNULL(@RowCount,0) > 0)
		  BEGIN
			
			 MERGE INTO @ExceededCapacityWeek S
			 USING [Period] T ON T.PeriodID = S.PeriodID
			 WHEN MATCHED THEN
				UPDATE SET S.PeriodName = T.PeriodName;

			 SELECT PeriodID,PeriodName FROM @ExceededCapacityWeek;

			 ROLLBACK;
			 RETURN;
		  END
		
		  SELECT PeriodID,PeriodName FROM @ExceededCapacityWeek;		
	COMMIT;
	END TRY
	BEGIN CATCH
		ROLLBACK;
		THROW;
	END CATCH
END

GO
/****** Object:  StoredProcedure [dbo].[PR_ThrowError]    Script Date: 8/29/2019 10:44:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[PR_ThrowError]
(
	@msg NVARCHAR(MAX)
) AS BEGIN
	RAISERROR (60000, 16, 1, @msg);
END
GO
