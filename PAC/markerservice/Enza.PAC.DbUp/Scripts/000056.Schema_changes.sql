ALTER TABLE DeterminationAssignment
ADD ReceiveDate DATETIME
GO

ALTER TABLE DeterminationAssignment
ADD ReciprocalProd BIT
GO

ALTER TABLE DeterminationAssignment
ADD Remarks NVARCHAR(MAX)
GO

ALTER TABLE DeterminationAssignment
ADD BioIndicator BIT
GO

ALTER TABLE DeterminationAssignment
ADD LogicalClassificationCode NVARCHAR(20)
GO

ALTER TABLE DeterminationAssignment
ADD LocationCode NVARCHAR(20)
GO

EXEC sp_rename 'DeterminationAssignment.ProcessNr', 'Process', 'COLUMN';  
GO

ALTER TABLE DeterminationAssignment
DROP COLUMN BatchOutputDesc
GO
