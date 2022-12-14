DROP FUNCTION IF EXISTS [dbo].[FN_IsMatching]
GO

-- =============================================
-- Author:		Binod Gurung
-- Create date: 2019/09/05
-- Description:	Function to determine if proposed value and referenced value is matching
-- =============================================
-- SELECT  dbo.FN_IsMatching ('0000','1111')
CREATE FUNCTION [dbo].[FN_IsMatching]
(
	@ProposedValue NVARCHAR(20),
	@ReferenceValue NVARCHAR(20)
)
RETURNS BIT
AS
BEGIN

	DECLARE @HighNibbleProp NVARCHAR(10), @LowNibbleProp NVARCHAR(10), @HighNibbleRef NVARCHAR(10), @LowNibbleRef NVARCHAR(10);
	
	IF(CAST(@ProposedValue AS INT) < 100)
	BEGIN
		
		IF( (@ProposedValue = '0001' AND @ReferenceValue = '0000') OR (@ReferenceValue = '0001' AND @ProposedValue = '0000'))
			RETURN 0;
		IF(@ProposedValue NOT IN ('0000','0001','0002','0055','0099','9999') OR @ReferenceValue NOT IN ('0000','0001','0055','0099','9999'))
			RETURN 0;
		RETURN 1;

	END
	ELSE
	BEGIN

		IF (@ProposedValue = '' OR @ReferenceValue = '' OR @ProposedValue = @ReferenceValue OR @ProposedValue IN ('9999','5555') OR @ReferenceValue IN ('5555','5599','9999'))
			RETURN 1;

		SELECT	@HighNibbleProp = SUBSTRING(@ProposedValue,0,2),
				@LowNibbleProp	= SUBSTRING(@ProposedValue,2,2),
				@HighNibbleRef	= SUBSTRING(@ProposedValue,0,2),
				@LowNibbleRef	= SUBSTRING(@ProposedValue,2,2);

		IF(@LowNibbleProp IN ('55','99') AND (@HighNibbleProp = @HighNibbleRef OR @HighNibbleProp = @LowNibbleRef))
			RETURN 1;
		IF(@LowNibbleRef IN ('55','99') AND (@HighNibbleRef = @HighNibbleProp OR @HighNibbleRef = @LowNibbleProp))
			RETURN 1;
		IF (@LowNibbleProp = '55' AND @LowNibbleRef = '99')
			RETURN 1;
		RETURN 0;

	END

	RETURN 0;
END
GO


