CREATE TABLE [dbo].[TestResult](
	[TestResultID] [int] IDENTITY(1,1) NOT NULL,
	[WellID] [int] NOT NULL,
	[MarkerID] [int] NOT NULL,
	[Score] [nvarchar](20) NULL,
PRIMARY KEY CLUSTERED 
(
	[TestResultID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[TestResult]  WITH CHECK ADD  CONSTRAINT [FK_TestResult_Marker] FOREIGN KEY([MarkerID])
REFERENCES [dbo].[Marker] ([MarkerID])
GO

ALTER TABLE [dbo].[TestResult] CHECK CONSTRAINT [FK_TestResult_Marker]
GO

ALTER TABLE [dbo].[TestResult]  WITH CHECK ADD  CONSTRAINT [FK_TestResult_Well] FOREIGN KEY([WellID])
REFERENCES [dbo].[Well] ([WellID])
GO

ALTER TABLE [dbo].[TestResult] CHECK CONSTRAINT [FK_TestResult_Well]
GO