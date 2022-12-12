ALTER TABLE TestMaterialDetermination
ADD MaxSelect INT;
GO

ALTER TABLE TestMaterialDetermination
ADD StatusCode INT;
GO


--INSERT INTO StatusTable 

INSERT INTO [Status] ([StatusID], [StatusTable] ,[StatusCode] ,[StatusName] ,[StatusDescription])
     VALUES
     (43, 'TestMaterialDetermination', 100, 'Assigned', 'Assigned'),
     (44, 'TestMaterialDetermination', 200, 'Cancelled in UTM', 'Cancelled in UTM'),
     (45, 'TestMaterialDetermination', 300, 'Updated', 'Updated'),
     (46, 'TestMaterialDetermination', 400, 'Synced', 'Synced'),
     (47,'Test',450,'Test Updated','Test Updated in UTM')

GO