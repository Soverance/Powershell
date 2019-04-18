USE [DRUM-Inventory]
GO
/****** Object:  StoredProcedure [dbo].[ModifyExistingDevice]    Script Date: 4/18/2019 10:44:47 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Scott McCutchen
-- Create date: 03/20/2019
-- Description:	This procedure will update the information of an existing device
-- =============================================
ALTER PROCEDURE [dbo].[ModifyExistingDevice]
	@BarcodeTag nvarchar(255),
	@ServiceTag nvarchar(255),
	@Model nvarchar(255),
	@OperatingSystem nvarchar(255),
	@Category float,
	@Status float,
	@Location float,
	@PurchaseDate date,
	@EstimatedEOL float,
	@WarrantyEOL nvarchar(255),
	@Comments nvarchar(255),
	@User nvarchar(255)
AS
BEGIN TRY
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- =============================================
	--
	--  BEGIN DEVICE MODIFY
	--
	--  This block modifies an existing record in the Devices table
	-- =============================================
    UPDATE [dbo].[Devices]

	SET	[ServiceTag] = @ServiceTag,
		[Model] = @Model,
		[OperatingSystem] = @OperatingSystem,
		[Category] = @Category,
		[Status] = @Status,
		[Location] = @Location,
		[PurchaseDate] = @PurchaseDate,
		[EstimatedEOL] = @EstimatedEOL,
		[WarrantyEOL] = @WarrantyEOL,
		[Comments] = @Comments

	WHERE [BarcodeTag] = @BarcodeTag;

	-- @VerifyDeviceModify should always be 0 if we successfully modified one or more rows
	-- if @VerifyDeviceModify is 1, then modifying the record failed for some reason
	DECLARE @VerifyDeviceModify Int = CASE WHEN @@ROWCOUNT = 0 THEN 1 ELSE 0 END

	-- =============================================
	--
	--  BEGIN MAPPING MODIFY
	--
	-- This block modifies the device's user mapping in the Mapping table
	-- =============================================
	UPDATE [dbo].[Mapping]

	SET [User] = @User

	WHERE [BarcodeTag] = @BarcodeTag;

	-- @VerifyMappingModify should always be 0 if we successfully inserted one or more rows
	-- if @VerifyMappingModify is 1, then inserting the mapping into the table failed for some reason
	DECLARE @VerifyMappingModify Int = CASE WHEN @@ROWCOUNT = 0 THEN 1 ELSE 0 END

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
	DECLARE @ReturnValue Int = @VerifyDeviceModify + @VerifyMappingModify
	SELECT @ReturnValue
END TRY
BEGIN CATCH
	EXECUTE GetErrorInfo;
END CATCH
