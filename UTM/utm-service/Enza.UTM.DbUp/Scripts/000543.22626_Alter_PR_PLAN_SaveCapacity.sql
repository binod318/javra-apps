DROP PROCEDURE IF EXISTS [dbo].[PR_PLAN_SaveCapacity]
GO


-- =============================================
-- Author:		Binod Gurung
-- Create date: 2018/03/12
-- Description:	Save Capacity
-- =============================================
CREATE PROCEDURE [dbo].[PR_PLAN_SaveCapacity]
(
	@TVP_Capacity TVP_PLAN_Capacity READONLY
)
AS
BEGIN
	
	SET NOCOUNT ON;

	DECLARE @MarkerTypeTestProtocolID INT = 0;

	BEGIN TRY
		BEGIN TRANSACTION;
		
		--Find TestProtocolID for Marker Test
		SELECT 
			@MarkerTypeTestProtocolID = TP.TestProtocolID 
		FROM TestProtocol TP
		JOIN TestType TT ON TT.TestTypeID = TP.TestTypeID
		WHERE TT.DeterminationRequired = 1
		AND TP.TestTypeID IN (1,2); --2GB Marker test and DNA Isolation
						
		-- Insert / Update NrOfTests (For Marker Test)
		MERGE INTO AvailCapacity T
		USING 
		(
			SELECT * FROM @TVP_Capacity 
			WHERE ISNUMERIC(PivotedColumn) = 1 AND PivotedColumn = @MarkerTypeTestProtocolID
		) S
		ON T.PeriodID = S.PeriodID AND T.TestProtocolID = @MarkerTypeTestProtocolID
		WHEN NOT MATCHED THEN
			INSERT 
			(
				PeriodID, 
				TestProtocolID,
				NrOfTests
			)
			VALUES 
			(
				S.PeriodID, 
				CAST(PivotedColumn AS INT),
				CAST([Value] AS INT )
			)

		WHEN MATCHED THEN
			UPDATE
			SET T.NrOfTests  = CAST([Value] AS INT ) ;

		--Insert / Update NrOfPlates (For DNA Isolation)
		MERGE INTO AvailCapacity T
		USING 
		(
			SELECT * FROM @TVP_Capacity 
			WHERE ISNUMERIC(PivotedColumn) = 1 AND PivotedColumn <> @MarkerTypeTestProtocolID
		) S
		ON T.PeriodID = S.PeriodID AND T.TestProtocolID = CAST(S.PivotedColumn AS INT)
		WHEN NOT MATCHED THEN
			INSERT 
			(
				PeriodID, 
				TestProtocolID, 
				NrOfPlates
			)
			VALUES 
			(
				S.PeriodID, 
				CAST(PivotedColumn AS INT),
				CAST([Value] AS INT )
			)

		WHEN MATCHED THEN
			UPDATE
			SET T.NrOfPlates = CAST([Value] AS INT ) ;

		--Update Remark
		MERGE INTO PeriodRemark T
		USING 
		(
			SELECT PeriodID, [Value] FROM @TVP_Capacity 
			WHERE PivotedColumn = 'remark'
		) S
		ON T.PeriodID = S.PeriodID AND ISNULL(T.TestTypeID,0) = 0 AND ISNULL(T.SiteID,0) = 0
		WHEN MATCHED THEN
			UPDATE
			SET T.Remark = S.[Value] 
		WHEN NOT MATCHED THEN
			INSERT(PeriodID,Remark)
			VALUES(S.PeriodID,S.[Value]);

		COMMIT;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK;
		THROW;
	END CATCH
    
END
GO


