
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Pattern]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[Pattern](
	[PatternID] [int] IDENTITY(1,1) NOT NULL,
	[DetAssignmentID] [int] NOT NULL,
	[NrOfSamples] [int] NOT NULL,
	[SamplePer] [decimal](5, 2) NOT NULL,
	[Type] [nvarchar](30) NULL,
	[MatchingVar] [nvarchar](max) NULL,
	[Status] [int] NULL,
 CONSTRAINT [PK_Pattern] PRIMARY KEY CLUSTERED 
(
	[PatternID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
END
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[PatternResult]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[PatternResult](
	[PatternResID] [int] IDENTITY(1,1) NOT NULL,
	[PatternID] [int] NOT NULL,
	[MarkerID] [int] NOT NULL,
	[Score] [nvarchar](10) NOT NULL,
 CONSTRAINT [PK_PatternResult] PRIMARY KEY CLUSTERED 
(
	[PatternResID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
END
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_Pattern_DeterminationAssignment]') AND parent_object_id = OBJECT_ID(N'[dbo].[Pattern]'))
ALTER TABLE [dbo].[Pattern]  WITH CHECK ADD  CONSTRAINT [FK_Pattern_DeterminationAssignment] FOREIGN KEY([DetAssignmentID])
REFERENCES [dbo].[DeterminationAssignment] ([DetAssignmentID])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_Pattern_DeterminationAssignment]') AND parent_object_id = OBJECT_ID(N'[dbo].[Pattern]'))
ALTER TABLE [dbo].[Pattern] CHECK CONSTRAINT [FK_Pattern_DeterminationAssignment]
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_PatternResult_Marker]') AND parent_object_id = OBJECT_ID(N'[dbo].[PatternResult]'))
ALTER TABLE [dbo].[PatternResult]  WITH CHECK ADD  CONSTRAINT [FK_PatternResult_Marker] FOREIGN KEY([MarkerID])
REFERENCES [dbo].[Marker] ([MarkerID])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_PatternResult_Marker]') AND parent_object_id = OBJECT_ID(N'[dbo].[PatternResult]'))
ALTER TABLE [dbo].[PatternResult] CHECK CONSTRAINT [FK_PatternResult_Marker]
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_PatternResult_Pattern]') AND parent_object_id = OBJECT_ID(N'[dbo].[PatternResult]'))
ALTER TABLE [dbo].[PatternResult]  WITH CHECK ADD  CONSTRAINT [FK_PatternResult_Pattern] FOREIGN KEY([PatternID])
REFERENCES [dbo].[Pattern] ([PatternID])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_PatternResult_Pattern]') AND parent_object_id = OBJECT_ID(N'[dbo].[PatternResult]'))
ALTER TABLE [dbo].[PatternResult] CHECK CONSTRAINT [FK_PatternResult_Pattern]
GO

ALTER TABLE DeterminationAssignment
ADD Deviation INT
GO

ALTER TABLE DeterminationAssignment
ADD Inbreed INT
GO

ALTER TABLE DeterminationAssignment
ADD ActualSamples INT
GO


