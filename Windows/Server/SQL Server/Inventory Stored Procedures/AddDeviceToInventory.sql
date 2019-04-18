USE [DRUM-Inventory]
GO
/****** Object:  StoredProcedure [dbo].[AddDeviceToInventory]    Script Date: 4/18/2019 10:41:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Scott McCutchen
-- Create date: 03/13/2019
-- Description:	This procedure simply adds the specified device into inventory
-- =============================================
ALTER PROCEDURE [dbo].[AddDeviceToInventory]
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
	-- SET NOCOUNT ON added to prevent extra result sets from interfering with SELECT statements.
	SET NOCOUNT ON;

	-- =============================================
	--
	--  BEGIN DEVICE INSERT
	--
	--  This block inserts the new device into the Devices table
	-- =============================================
    INSERT INTO [dbo].[Devices] (
		[BarcodeTag],
		[ServiceTag],
		[Model],
		[OperatingSystem],
		[Category],
		[Status],
		[Location],
		[PurchaseDate],
		[EstimatedEOL],
		[WarrantyEOL],
		[Comments]
	)
	VALUES (
		@BarcodeTag,
		@ServiceTag,
		@Model,
		@OperatingSystem,
		@Category,
		@Status,
		@Location,
		@PurchaseDate,
		@EstimatedEOL,
		@WarrantyEOL,
		@Comments
	)

	-- @VerifyDeviceInsert should always be 0 if we successfully inserted one or more rows
	-- if @VerifyDeviceInsert is 1, then inserting the device into the table failed for some reason
	DECLARE @VerifyDeviceInsert Int = CASE WHEN @@ROWCOUNT = 0 THEN 1 ELSE 0 END

	-- =============================================
	--
	--  BEGIN MAPPING INSERT
	--
	-- This block inserts the new device's user mapping into the Mapping table
	-- =============================================
	INSERT INTO [dbo].[Mapping] (
		[User],
		[BarcodeTag]
	)
	VALUES (
		@User,
		@BarcodeTag
	)

	-- @VerifyMappingInsert should always be 0 if we successfully inserted one or more rows
	-- if @VerifyMappingInsert is 1, then inserting the mapping into the table failed for some reason
	DECLARE @VerifyMappingInsert Int = CASE WHEN @@ROWCOUNT = 0 THEN 1 ELSE 0 END

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
	DECLARE @ReturnValue Int = @VerifyDeviceInsert + @VerifyMappingInsert
	SELECT @ReturnValue
END TRY
BEGIN CATCH
	EXECUTE GetErrorInfo;
END CATCH