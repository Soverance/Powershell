USE [DRUM-Inventory]
GO
/****** Object:  StoredProcedure [dbo].[GetErrorInfo]    Script Date: 4/18/2019 10:44:18 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Scott McCutchen
-- Create date: 03/14/2019
-- Description:	This procedure collects error information from a failed stored procedure
-- =============================================
ALTER PROCEDURE [dbo].[GetErrorInfo]
AS
SELECT
    ERROR_NUMBER() AS ErrorNumber
    ,ERROR_SEVERITY() AS ErrorSeverity
    ,ERROR_STATE() AS ErrorState
    ,ERROR_PROCEDURE() AS ErrorProcedure
    ,ERROR_LINE() AS ErrorLine
    ,ERROR_MESSAGE() AS ErrorMessage;
