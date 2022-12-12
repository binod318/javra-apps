
DROP INDEX IF EXISTS [idx_PatternResult_PatternID_Score] ON [dbo].[PatternResult]
GO

CREATE NONCLUSTERED INDEX [idx_PatternResult_PatternID_Score] ON [dbo].[PatternResult]
(
	[PatternID] ASC
)
INCLUDE ([Score]) 
GO


