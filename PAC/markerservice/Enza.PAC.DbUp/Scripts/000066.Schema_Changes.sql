CREATE TABLE [dbo].[Well](
	[WellID] [INT] IDENTITY(1,1) NOT NULL,
	[Position] [CHAR](3) NOT NULL,
	[PlateID] [INT] NOT NULL,
	[DetAssignmentID] [INT]
 CONSTRAINT [PK_Well] PRIMARY KEY CLUSTERED 
(
	[WellID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[Well]  WITH CHECK ADD  CONSTRAINT [FK_Well_Plate] FOREIGN KEY([PlateID])
REFERENCES [dbo].[Plate] ([PlateID])
GO

ALTER TABLE [dbo].[Well]  WITH CHECK ADD  CONSTRAINT [FK_Well_DetAssignment] FOREIGN KEY([DetAssignmentID])
REFERENCES [dbo].[DeterminationAssignment] ([DetAssignmentID])
GO

ALTER TABLE Plate
DROP COLUMN TestDetAssignmentID
GO

