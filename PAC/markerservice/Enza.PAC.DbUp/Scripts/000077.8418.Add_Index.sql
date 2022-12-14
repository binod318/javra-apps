

DROP INDEX IF EXISTS [idx_MarkerValuePerVariety_VarietyNr] ON [dbo].[MarkerValuePerVariety]
GO

CREATE NONCLUSTERED INDEX [idx_MarkerValuePerVariety_VarietyNr] ON [dbo].[MarkerValuePerVariety]
(
	[VarietyNr] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO


