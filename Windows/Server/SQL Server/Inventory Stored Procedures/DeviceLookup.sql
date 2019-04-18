USE [DRUM-Inventory]
GO
/****** Object:  StoredProcedure [dbo].[DeviceLookup]    Script Date: 4/18/2019 10:42:51 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Scott McCutchen
-- Create date: 03/11/2019
-- Description:	This procedure returns data from inventory on a specified device
-- =============================================
ALTER PROCEDURE [dbo].[DeviceLookup] @BarcodeTag NVARCHAR(255)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from interfering with SELECT statements.
	SET NOCOUNT ON;

	SELECT
	dbo.[Devices].[BarcodeTag],
	dbo.[Devices].[ServiceTag],
	dbo.[Devices].[Model],
	dbo.[OperatingSystem].[OS],
	dbo.[Category].[Category],
	dbo.[Status].[Status],
	dbo.[Locations].[Location],
	dbo.[Devices].[PurchaseDate],
	dbo.[Devices].[EstimatedEOL],
	dbo.[Devices].[WarrantyEOL],
	dbo.[Devices].[Comments],
	dbo.[Employees].[sAMAccountName],
	dbo.[Employees].[Username],
	dbo.[Employees].[Title],
	dbo.[Employees].[Mail],
	dbo.[Employees].[Department],
	dbo.[Employees].[TelephoneNumber]

	FROM dbo.[Devices]

	INNER JOIN dbo.[Category] ON (dbo.[Category].[ID] = dbo.[Devices].[Category])
	INNER JOIN dbo.[OperatingSystem] ON (dbo.[OperatingSystem].[ID] = dbo.[Devices].[OperatingSystem])
	INNER JOIN dbo.[Status] ON (dbo.[Status].[ID] = dbo.[Devices].[Status])
	INNER JOIN dbo.[Locations] ON (dbo.[Locations].[ID] = dbo.[Devices].[Location])
	INNER JOIN dbo.[Mapping] ON (dbo.[Mapping].[BarcodeTag] = dbo.[Devices].[BarcodeTag])
	INNER JOIN dbo.[Employees] ON (dbo.[Employees].[sAMAccountName] = dbo.[Mapping].[User])

	WHERE dbo.[Devices].[BarcodeTag] = @BarcodeTag
END
