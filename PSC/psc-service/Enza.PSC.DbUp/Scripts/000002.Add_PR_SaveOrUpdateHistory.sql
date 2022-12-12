DROP PROCEDURE IF EXISTS [dbo].[PR_SaveOrUpdateHistory]
GO


CREATE PROCEDURE [dbo].[PR_SaveOrUpdateHistory]
(
	@PlateIDBarcode		NVARCHAR(50), 
	@SampleNrBarcode	NVARCHAR(50), 
	@User				NVARCHAR(50), 
	@IsMatched			BIT
) AS BEGIN
	SET NOCOUNT ON;
		
	INSERT INTO History(PlateIDBarcode, SampleNrBarcode, [User], CreatedDate, IsMatched) 
    VALUES(@PlateIDBarcode, @SampleNrBarcode, @User, GETUTCDATE(), @IsMatched);


END
GO
