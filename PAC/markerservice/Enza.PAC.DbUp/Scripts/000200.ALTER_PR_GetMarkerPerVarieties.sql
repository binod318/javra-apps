/*
Author					Date				Remarks
Binod Gurung			-					-
Krishna Gautam			2020-March-04		Columns is returned from stored procedure

=================EXAMPLE=============
PR_GetMarkerPerVarieties

*/
ALTER PROCEDURE [dbo].[PR_GetMarkerPerVarieties]
AS BEGIN
    SET NOCOUNT ON;

	DECLARE @TblColumn TABLE(ColumnLabel VARCHAR(100), ColumnID VARCHAR(100),[Order] INT,IsVisible BIT)

	INSERT INTO @TblColumn(ColumnLabel,ColumnID,[Order],IsVisible)
	VALUES
	('Crop','CropCode',1,1),
	('MarkerPerVarID','MarkerPerVarID',2,0),
	('MarkerID','MarkerID',3,0),
	('Variety name','Shortname',4,1),
	('Variety number','VarietyNr',5,1),
	('Trait marker','MarkerFullName',6,1),
	('Expected result','ExpectedResult',7,1),
	('Remarks','Remarks',8,1),
	('Status','StatusName',9,1);

    SELECT 
	   V.CropCode,
	   MPV.MarkerPerVarID,
	   MPV.MarkerID,
	   V.Shortname,
	   MPV.VarietyNr,
	   M.MarkerFullName,
	   MPV.ExpectedResult, 
	   MPV.Remarks,
	   S.StatusName
    FROM MarkerPerVariety MPV
    JOIN Marker M ON M.MarkerID = MPV.MarkerID
    JOIN Variety V ON V.VarietyNr = MPV.VarietyNr
    JOIN [Status] S ON S.StatusCode = MPV.StatusCode AND S.StatusTable = 'Marker'
    ORDER BY S.StatusCode, M.MarkerName;

	SELECT * FROM @TblColumn order by [Order];
END
