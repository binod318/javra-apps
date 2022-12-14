IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ReservedCapacity]') AND type in (N'U'))
ALTER TABLE [dbo].[ReservedCapacity] DROP CONSTRAINT IF EXISTS [FK_PeriodID_ReservedCapacity]
GO
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ReservedCapacity]') AND type in (N'U'))
ALTER TABLE [dbo].[ReservedCapacity] DROP CONSTRAINT IF EXISTS [FK_CropMethodID_ReservedCapacity]
GO
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[CropMethod]') AND type in (N'U'))
ALTER TABLE [dbo].[CropMethod] DROP CONSTRAINT IF EXISTS [FK_PlatformID]
GO
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[CropMethod]') AND type in (N'U'))
ALTER TABLE [dbo].[CropMethod] DROP CONSTRAINT IF EXISTS [FK_MethodID]
GO
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[CropMethod]') AND type in (N'U'))
ALTER TABLE [dbo].[CropMethod] DROP CONSTRAINT IF EXISTS [FK_ABSCropCode]
GO
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Capacity]') AND type in (N'U'))
ALTER TABLE [dbo].[Capacity] DROP CONSTRAINT IF EXISTS [FK_PlatformID_Capacity]
GO
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Capacity]') AND type in (N'U'))
ALTER TABLE [dbo].[Capacity] DROP CONSTRAINT IF EXISTS [FK_PeriodID_Capacity]
GO
/****** Object:  Table [dbo].[ReservedCapacity]    Script Date: 8/30/2019 3:32:27 PM ******/
DROP TABLE IF EXISTS [dbo].[ReservedCapacity]
GO
/****** Object:  Table [dbo].[CropMethod]    Script Date: 8/30/2019 3:32:27 PM ******/
DROP TABLE IF EXISTS [dbo].[CropMethod]
GO
/****** Object:  Table [dbo].[Capacity]    Script Date: 8/30/2019 3:32:27 PM ******/
DROP TABLE IF EXISTS [dbo].[Capacity]
GO
/****** Object:  Table [dbo].[Capacity]    Script Date: 8/30/2019 3:32:27 PM ******/
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
/****** Object:  Table [dbo].[CropMethod]    Script Date: 8/30/2019 3:32:29 PM ******/
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
/****** Object:  Table [dbo].[ReservedCapacity]    Script Date: 8/30/2019 3:32:29 PM ******/
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
SET IDENTITY_INSERT [dbo].[Capacity] ON 
GO
INSERT [dbo].[Capacity] ([CapacityID], [PeriodID], [PlatformID], [NrOfPlates], [Remarks]) VALUES (725, 4778, 8, 200, NULL)
GO
INSERT [dbo].[Capacity] ([CapacityID], [PeriodID], [PlatformID], [NrOfPlates], [Remarks]) VALUES (726, 4744, 8, 150, NULL)
GO
INSERT [dbo].[Capacity] ([CapacityID], [PeriodID], [PlatformID], [NrOfPlates], [Remarks]) VALUES (727, 4774, 8, 300, NULL)
GO
SET IDENTITY_INSERT [dbo].[Capacity] OFF
GO
SET IDENTITY_INSERT [dbo].[CropMethod] ON 
GO
INSERT [dbo].[CropMethod] ([CropMethodID], [MethodID], [ABSCropCode], [PlatformID], [UsedFor], [StatusCode], [DisplayOrder]) VALUES (81, 1, N'SP', 8, N'Hyb', 100, NULL)
GO
INSERT [dbo].[CropMethod] ([CropMethodID], [MethodID], [ABSCropCode], [PlatformID], [UsedFor], [StatusCode], [DisplayOrder]) VALUES (82, 1, N'HP', 8, N'Hyb', 100, NULL)
GO
INSERT [dbo].[CropMethod] ([CropMethodID], [MethodID], [ABSCropCode], [PlatformID], [UsedFor], [StatusCode], [DisplayOrder]) VALUES (83, 1, N'SP', 8, N'Hyb', 100, NULL)
GO
INSERT [dbo].[CropMethod] ([CropMethodID], [MethodID], [ABSCropCode], [PlatformID], [UsedFor], [StatusCode], [DisplayOrder]) VALUES (84, 1, N'RS_P', 8, N'Hyb', 100, NULL)
GO
INSERT [dbo].[CropMethod] ([CropMethodID], [MethodID], [ABSCropCode], [PlatformID], [UsedFor], [StatusCode], [DisplayOrder]) VALUES (85, 2, N'TO', 8, N'Hyb', 100, NULL)
GO
INSERT [dbo].[CropMethod] ([CropMethodID], [MethodID], [ABSCropCode], [PlatformID], [UsedFor], [StatusCode], [DisplayOrder]) VALUES (86, 2, N'RS_T', 8, N'Hyb', 100, NULL)
GO
INSERT [dbo].[CropMethod] ([CropMethodID], [MethodID], [ABSCropCode], [PlatformID], [UsedFor], [StatusCode], [DisplayOrder]) VALUES (87, 3, N'CC', 8, N'Hyb', 100, NULL)
GO
INSERT [dbo].[CropMethod] ([CropMethodID], [MethodID], [ABSCropCode], [PlatformID], [UsedFor], [StatusCode], [DisplayOrder]) VALUES (88, 4, N'EP', 8, N'Hyb', 100, NULL)
GO
INSERT [dbo].[CropMethod] ([CropMethodID], [MethodID], [ABSCropCode], [PlatformID], [UsedFor], [StatusCode], [DisplayOrder]) VALUES (89, 6, N'B_CF', 8, N'Hyb', 100, NULL)
GO
INSERT [dbo].[CropMethod] ([CropMethodID], [MethodID], [ABSCropCode], [PlatformID], [UsedFor], [StatusCode], [DisplayOrder]) VALUES (90, 7, N'ME', 8, N'Hyb', 100, NULL)
GO
INSERT [dbo].[CropMethod] ([CropMethodID], [MethodID], [ABSCropCode], [PlatformID], [UsedFor], [StatusCode], [DisplayOrder]) VALUES (91, 8, N'SP', 8, N'Hyb', 100, NULL)
GO
INSERT [dbo].[CropMethod] ([CropMethodID], [MethodID], [ABSCropCode], [PlatformID], [UsedFor], [StatusCode], [DisplayOrder]) VALUES (92, 10, N'EP', 8, N'Hyb', 100, NULL)
GO
INSERT [dbo].[CropMethod] ([CropMethodID], [MethodID], [ABSCropCode], [PlatformID], [UsedFor], [StatusCode], [DisplayOrder]) VALUES (93, 11, N'ON', 8, N'Par', 100, NULL)
GO
INSERT [dbo].[CropMethod] ([CropMethodID], [MethodID], [ABSCropCode], [PlatformID], [UsedFor], [StatusCode], [DisplayOrder]) VALUES (94, 11, N'SH', 8, N'Par', 100, NULL)
GO
INSERT [dbo].[CropMethod] ([CropMethodID], [MethodID], [ABSCropCode], [PlatformID], [UsedFor], [StatusCode], [DisplayOrder]) VALUES (95, 12, N'LT', 8, N'Hyb', 100, NULL)
GO
INSERT [dbo].[CropMethod] ([CropMethodID], [MethodID], [ABSCropCode], [PlatformID], [UsedFor], [StatusCode], [DisplayOrder]) VALUES (96, 14, N'RS_C', 8, N'Hyb', 100, NULL)
GO
INSERT [dbo].[CropMethod] ([CropMethodID], [MethodID], [ABSCropCode], [PlatformID], [UsedFor], [StatusCode], [DisplayOrder]) VALUES (97, 14, N'PP', 8, N'Hyb', 100, NULL)
GO
INSERT [dbo].[CropMethod] ([CropMethodID], [MethodID], [ABSCropCode], [PlatformID], [UsedFor], [StatusCode], [DisplayOrder]) VALUES (98, 15, N'TO', 8, N'Hyb', 100, NULL)
GO
INSERT [dbo].[CropMethod] ([CropMethodID], [MethodID], [ABSCropCode], [PlatformID], [UsedFor], [StatusCode], [DisplayOrder]) VALUES (99, 16, N'B_KR', 8, N'Hyb', 100, NULL)
GO
INSERT [dbo].[CropMethod] ([CropMethodID], [MethodID], [ABSCropCode], [PlatformID], [UsedFor], [StatusCode], [DisplayOrder]) VALUES (100, 18, N'MW', 8, N'Hyb', 100, NULL)
GO
INSERT [dbo].[CropMethod] ([CropMethodID], [MethodID], [ABSCropCode], [PlatformID], [UsedFor], [StatusCode], [DisplayOrder]) VALUES (101, 19, N'SP', 8, N'Hyb', 100, NULL)
GO
INSERT [dbo].[CropMethod] ([CropMethodID], [MethodID], [ABSCropCode], [PlatformID], [UsedFor], [StatusCode], [DisplayOrder]) VALUES (102, 19, N'HP', 8, N'Hyb', 100, NULL)
GO
INSERT [dbo].[CropMethod] ([CropMethodID], [MethodID], [ABSCropCode], [PlatformID], [UsedFor], [StatusCode], [DisplayOrder]) VALUES (103, 20, N'RD', 8, N'Hyb', 100, NULL)
GO
INSERT [dbo].[CropMethod] ([CropMethodID], [MethodID], [ABSCropCode], [PlatformID], [UsedFor], [StatusCode], [DisplayOrder]) VALUES (104, 21, N'ME', 8, N'Par', 100, NULL)
GO
INSERT [dbo].[CropMethod] ([CropMethodID], [MethodID], [ABSCropCode], [PlatformID], [UsedFor], [StatusCode], [DisplayOrder]) VALUES (105, 22, N'B_CF', 8, N'Par', 100, NULL)
GO
INSERT [dbo].[CropMethod] ([CropMethodID], [MethodID], [ABSCropCode], [PlatformID], [UsedFor], [StatusCode], [DisplayOrder]) VALUES (106, 23, N'CC', 8, N'Par', 100, NULL)
GO
INSERT [dbo].[CropMethod] ([CropMethodID], [MethodID], [ABSCropCode], [PlatformID], [UsedFor], [StatusCode], [DisplayOrder]) VALUES (107, 25, N'ON', 8, N'Par', 100, NULL)
GO
INSERT [dbo].[CropMethod] ([CropMethodID], [MethodID], [ABSCropCode], [PlatformID], [UsedFor], [StatusCode], [DisplayOrder]) VALUES (108, 26, N'HP', 8, N'Par', 100, NULL)
GO
INSERT [dbo].[CropMethod] ([CropMethodID], [MethodID], [ABSCropCode], [PlatformID], [UsedFor], [StatusCode], [DisplayOrder]) VALUES (109, 26, N'SP', 8, N'Par', 100, NULL)
GO
INSERT [dbo].[CropMethod] ([CropMethodID], [MethodID], [ABSCropCode], [PlatformID], [UsedFor], [StatusCode], [DisplayOrder]) VALUES (110, 26, N'RS_P', 8, N'Par', 100, NULL)
GO
INSERT [dbo].[CropMethod] ([CropMethodID], [MethodID], [ABSCropCode], [PlatformID], [UsedFor], [StatusCode], [DisplayOrder]) VALUES (111, 27, N'PP', 8, N'Par', 100, NULL)
GO
INSERT [dbo].[CropMethod] ([CropMethodID], [MethodID], [ABSCropCode], [PlatformID], [UsedFor], [StatusCode], [DisplayOrder]) VALUES (112, 27, N'RS_C', 8, N'Par', 100, NULL)
GO
INSERT [dbo].[CropMethod] ([CropMethodID], [MethodID], [ABSCropCode], [PlatformID], [UsedFor], [StatusCode], [DisplayOrder]) VALUES (113, 29, N'TO', 8, N'Par', 100, NULL)
GO
INSERT [dbo].[CropMethod] ([CropMethodID], [MethodID], [ABSCropCode], [PlatformID], [UsedFor], [StatusCode], [DisplayOrder]) VALUES (114, 30, N'B_KR', 8, N'Par', 100, NULL)
GO
INSERT [dbo].[CropMethod] ([CropMethodID], [MethodID], [ABSCropCode], [PlatformID], [UsedFor], [StatusCode], [DisplayOrder]) VALUES (115, 31, N'RS_T', 8, N'Par', 100, NULL)
GO
INSERT [dbo].[CropMethod] ([CropMethodID], [MethodID], [ABSCropCode], [PlatformID], [UsedFor], [StatusCode], [DisplayOrder]) VALUES (116, 32, N'SQ', 8, N'Par', 100, NULL)
GO
INSERT [dbo].[CropMethod] ([CropMethodID], [MethodID], [ABSCropCode], [PlatformID], [UsedFor], [StatusCode], [DisplayOrder]) VALUES (117, 33, N'MW', 8, N'Par', 100, NULL)
GO
SET IDENTITY_INSERT [dbo].[CropMethod] OFF
GO
SET IDENTITY_INSERT [dbo].[ReservedCapacity] ON 
GO
INSERT [dbo].[ReservedCapacity] ([ReservedCapacityID], [CropMethodID], [PeriodID], [NrOfPlates]) VALUES (136, NULL, 4774, 11)
GO
INSERT [dbo].[ReservedCapacity] ([ReservedCapacityID], [CropMethodID], [PeriodID], [NrOfPlates]) VALUES (137, NULL, 4766, 1)
GO
INSERT [dbo].[ReservedCapacity] ([ReservedCapacityID], [CropMethodID], [PeriodID], [NrOfPlates]) VALUES (140, NULL, 4774, 11)
GO
INSERT [dbo].[ReservedCapacity] ([ReservedCapacityID], [CropMethodID], [PeriodID], [NrOfPlates]) VALUES (141, NULL, 4774, 100000)
GO
INSERT [dbo].[ReservedCapacity] ([ReservedCapacityID], [CropMethodID], [PeriodID], [NrOfPlates]) VALUES (142, NULL, 4774, 198282828)
GO
INSERT [dbo].[ReservedCapacity] ([ReservedCapacityID], [CropMethodID], [PeriodID], [NrOfPlates]) VALUES (143, NULL, 4774, 11)
GO
INSERT [dbo].[ReservedCapacity] ([ReservedCapacityID], [CropMethodID], [PeriodID], [NrOfPlates]) VALUES (144, NULL, 4775, 12)
GO
INSERT [dbo].[ReservedCapacity] ([ReservedCapacityID], [CropMethodID], [PeriodID], [NrOfPlates]) VALUES (145, NULL, 4774, 11)
GO
INSERT [dbo].[ReservedCapacity] ([ReservedCapacityID], [CropMethodID], [PeriodID], [NrOfPlates]) VALUES (146, NULL, 4775, 12)
GO
INSERT [dbo].[ReservedCapacity] ([ReservedCapacityID], [CropMethodID], [PeriodID], [NrOfPlates]) VALUES (149, 95, 4778, 1)
GO
INSERT [dbo].[ReservedCapacity] ([ReservedCapacityID], [CropMethodID], [PeriodID], [NrOfPlates]) VALUES (150, 96, 4778, 5)
GO
SET IDENTITY_INSERT [dbo].[ReservedCapacity] OFF
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
