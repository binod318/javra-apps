--data insertion
IF NOT EXISTS (SELECT * FROM TestType WHERE TestTypeID = 9)
BEGIN

	INSERT TestType (TestTypeID, TestTypeCode, TestTypeName, [Status], DeterminationRequired, RemarkRequired)
	VALUES (9, 'LDISK', 'Leaf Disk', 'ACT', 1, 0)

END
GO

IF NOT EXISTS (SELECT * FROM TestType WHERE TestTypeID = 9)
BEGIN
	INSERT TestProtocol(TestTypeID, TestProtocolName, Isolated)
	VALUES (9, 'Elisa tom/pap', 0),
		   (9, 'Elisa cuc', 0),
		   (9, 'PCR tests', 0)	
END
GO
IF NOT EXISTS (SELECT * FROM MaterialType WHERE MaterialTypeCode = 'LEAF')
BEGIN
	INSERT MaterialType (MaterialTypeCode, MaterialTypeDescription)
	VALUES ('LEAF', 'Leaf'),
		   ('SEED', 'Seed')
END
GO
