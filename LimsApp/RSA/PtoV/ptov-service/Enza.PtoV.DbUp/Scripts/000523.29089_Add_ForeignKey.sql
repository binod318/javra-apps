
ALTER TABLE [Cell]
DROP CONSTRAINT IF EXISTS FK_CellRow
GO

ALTER TABLE [Cell]
ADD CONSTRAINT FK_CellRow
FOREIGN KEY (RowID) REFERENCES [Row](RowID)
GO

ALTER TABLE [Cell]
DROP CONSTRAINT IF EXISTS FK_CellColumn
GO

ALTER TABLE [Cell]
ADD CONSTRAINT FK_CellColumn
FOREIGN KEY (ColumnID) REFERENCES [Column](ColumnID)
GO
