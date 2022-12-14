
IF EXISTS (SELECT * FROM Method WHERE MethodCode = 'PAC-01 (Vitalis)')
	RETURN;

INSERT Method
VALUES ('PAC-01 (Vitalis)',100,184)


UPDATE CropMethod
SET MethodID = (SELECT MethodID FROM Method WHERE MethodCode = 'PAC-01 (Vitalis)')
WHERE CropMethodID = 
(
	SELECT MAX(CropMethodID) FROM 
	CropMethod CM
	JOIN Method M ON M.MethodID = CM.MethodID
	WHERE M.MethodCode = 'PAC-01' AND ABSCropCode = 'SP'
)

GO
