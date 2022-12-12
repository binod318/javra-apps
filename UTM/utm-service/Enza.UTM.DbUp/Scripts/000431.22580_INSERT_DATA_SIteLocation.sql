DECLARE @TempTable TABLE(SiteName NVARCHAR(100));

INSERT INTO @TempTable(SiteName)
VALUES
('ENZA-BTARDT-NL'),
('ENZA-BTARDT-ES'),
('ENZA-BTARDT-US'),
('ENZA-BTARDT-TR')
;

MERGE INTO SiteLocation T
USING @TempTable S ON S.SiteName = T.SiteName
WHEN NOT MATCHED THEN 
INSERT(SiteName,StatusCode)
VALUES(S.SiteName, 100);

GO