SET IDENTITY_INSERT [dbo].[Platform] ON 
GO
INSERT [dbo].[Platform] ([PlatformID], [PlatformCode], [PlatformDesc], [UsedForPac], [DeclusterCrossPlatform], [StatusCode]) VALUES (13, N'SEQ', N'Sequencing', 1, 1, 100)
GO
INSERT [dbo].[Platform] ([PlatformID], [PlatformCode], [PlatformDesc], [UsedForPac], [DeclusterCrossPlatform], [StatusCode]) VALUES (14, N'EXT', N'External', 1, 1, 100)
GO
SET IDENTITY_INSERT [dbo].[Platform] OFF
GO


IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Platform]') AND type in (N'U'))
BEGIN

	 UPDATE [Platform]
	 SET StatusCode = 200 
	 WHERE PlatformCode NOT IN ('LS','SEQ','EXT') 

END

GO