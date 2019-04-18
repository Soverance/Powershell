USE [DRUM-Inventory]
GO
/****** Object:  StoredProcedure [dbo].[CheckDeviceExists]    Script Date: 4/18/2019 10:42:13 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Scott McCutchen
-- Create date: 03/11/2019
-- Description:	This procedure simply checks whether or not a device exists in the Devices table.
--				It will return 1 (true) if the BarcodeTag exists, and 0 (false) if not
-- =============================================
ALTER PROCEDURE [dbo].[CheckDeviceExists] @BarcodeTag NVARCHAR(255)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    SELECT CASE WHEN EXISTS (
    SELECT *
    FROM dbo.[Devices]
    WHERE BarcodeTag = @BarcodeTag
	)
	THEN CAST(1 AS BIT)
	ELSE CAST(0 AS BIT) END
END
