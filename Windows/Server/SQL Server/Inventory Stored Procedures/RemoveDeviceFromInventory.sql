USE [DRUM-Inventory]
GO
/****** Object:  StoredProcedure [dbo].[RemoveDeviceFromInventory]    Script Date: 4/18/2019 10:45:18 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Scott McCutchen
-- Create date: 03/14/2019
-- Description:	This procedure will remove the specified device from inventory
-- =============================================
ALTER PROCEDURE [dbo].[RemoveDeviceFromInventory]
	-- Add the parameters for the stored procedure here
	@BarcodeTag nvarchar(255)
AS
BEGIN TRY
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- Remove the device from the Devices table
    DELETE FROM dbo.[Devices]
	WHERE [BarcodeTag] = @BarcodeTag;

	-- @VerifyDeviceRemoval should always be 0 if we successfully inserted one or more rows
	-- if @VerifyDeviceRemoval is 1, then removing the device failed for some reason
	DECLARE @VerifyDeviceRemoval Int = CASE WHEN @@ROWCOUNT = 0 THEN 1 ELSE 0 END

	-- Remove the device from the Mapping table
	DELETE FROM dbo.[Mapping]
	WHERE [BarcodeTag] = @BarcodeTag;

	-- @VerifyMappingRemoval should always be 0 if we successfully inserted one or more rows
	-- if @VerifyMappingRemoval is 1, then removing the mapping failed for some reason
	DECLARE @VerifyMappingRemoval Int = CASE WHEN @@ROWCOUNT = 0 THEN 1 ELSE 0 END

	-- =============================================
	--
	--  BEGIN VERIFICATION RETURN
	--
	--  This block will return an appropriate value based on the success or failure of the previous INSERT statements
	--  @ReturnValue should always be 0 if both statements were successful.
	--  Any returned value other than 0 means that this procedure failed.
	--  In this case, because this procedure is called from Microsoft Flow, we're not using the RETURN keyword,
	--  and instead we use the SELECT keyword to ensure the response is sent back to Flow correctly.
	--  As per the MS Flow documentation, return values and output parameters are unavailable when running stored procedures from Flow
	--  https://docs.microsoft.com/en-us/connectors/sql/
	-- =============================================
	DECLARE @ReturnValue Int = @VerifyDeviceRemoval + @VerifyMappingRemoval
	SELECT @ReturnValue
END TRY
BEGIN CATCH
	EXECUTE GetErrorInfo;
END CATCH
