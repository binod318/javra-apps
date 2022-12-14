DELETE FROM [dbo].[Status]
GO
INSERT [dbo].[Status] ([StatusID], [StatusTable], [StatusCode], [StatusName], [StatusDescription]) VALUES (1, N'DeterminationAssignment', 100, N'Created', N'Pac test created by automatic plan')
GO
INSERT [dbo].[Status] ([StatusID], [StatusTable], [StatusCode], [StatusName], [StatusDescription]) VALUES (2, N'DeterminationAssignment', 200, N'Planned', N'Pac test confirmed')
GO
INSERT [dbo].[Status] ([StatusID], [StatusTable], [StatusCode], [StatusName], [StatusDescription]) VALUES (3, N'DeterminationAssignment', 300, N'Declustered', N'Declustered')
GO
INSERT [dbo].[Status] ([StatusID], [StatusTable], [StatusCode], [StatusName], [StatusDescription]) VALUES (4, N'DeterminationAssignment', 400, N'InLIMS', N'Sent to LIMS')
GO
INSERT [dbo].[Status] ([StatusID], [StatusTable], [StatusCode], [StatusName], [StatusDescription]) VALUES (5, N'DeterminationAssignment', 500, N'Determined', N'Determined')
GO
INSERT [dbo].[Status] ([StatusID], [StatusTable], [StatusCode], [StatusName], [StatusDescription]) VALUES (6, N'DeterminationAssignment', 600, N'Calculated', N'Calculated')
GO
INSERT [dbo].[Status] ([StatusID], [StatusTable], [StatusCode], [StatusName], [StatusDescription]) VALUES (7, N'DeterminationAssignment', 650, N'Repeat', N'Repeat')
GO
INSERT [dbo].[Status] ([StatusID], [StatusTable], [StatusCode], [StatusName], [StatusDescription]) VALUES (8, N'DeterminationAssignment', 700, N'Ready', N'Ready')
GO
INSERT [dbo].[Status] ([StatusID], [StatusTable], [StatusCode], [StatusName], [StatusDescription]) VALUES (9, N'DeterminationAssignment', 999, N'Cancelled', N'Cancelled')
GO
INSERT [dbo].[Status] ([StatusID], [StatusTable], [StatusCode], [StatusName], [StatusDescription]) VALUES (10, N'Marker', 100, N'Active', N'Active')
GO
INSERT [dbo].[Status] ([StatusID], [StatusTable], [StatusCode], [StatusName], [StatusDescription]) VALUES (11, N'Marker', 200, N'Inactive', N'InActive')
GO
INSERT [dbo].[Status] ([StatusID], [StatusTable], [StatusCode], [StatusName], [StatusDescription]) VALUES (12, N'Test', 100, N'Created', N'Created')
GO
INSERT [dbo].[Status] ([StatusID], [StatusTable], [StatusCode], [StatusName], [StatusDescription]) VALUES (13, N'Test', 150, N'Declustered', N'Declustered')
GO
INSERT [dbo].[Status] ([StatusID], [StatusTable], [StatusCode], [StatusName], [StatusDescription]) VALUES (14, N'Test', 200, N'Requested(Plates)', N'Requested(Plates)')
GO
INSERT [dbo].[Status] ([StatusID], [StatusTable], [StatusCode], [StatusName], [StatusDescription]) VALUES (15, N'Test', 300, N'Received(Plates)', N'Received(Plates)')
GO
INSERT [dbo].[Status] ([StatusID], [StatusTable], [StatusCode], [StatusName], [StatusDescription]) VALUES (16, N'Test', 350, N'Plate Filling', N'Plate Filling')
GO
INSERT [dbo].[Status] ([StatusID], [StatusTable], [StatusCode], [StatusName], [StatusDescription]) VALUES (17, N'Test', 400, N'Sent to LIMS', N'Sent to LIMS')
GO
INSERT [dbo].[Status] ([StatusID], [StatusTable], [StatusCode], [StatusName], [StatusDescription]) VALUES (18, N'Test', 500, N'Received(Result)', N'Received(Result)')
GO
INSERT [dbo].[Status] ([StatusID], [StatusTable], [StatusCode], [StatusName], [StatusDescription]) VALUES (19, N'Test', 600, N'Authorized', N'Authorized')
GO
INSERT [dbo].[Status] ([StatusID], [StatusTable], [StatusCode], [StatusName], [StatusDescription]) VALUES (20, N'Test', 700, N'Stopped', N'Stopped')
GO
