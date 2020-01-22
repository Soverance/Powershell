-- Customer Node Documentation Database Configuration
-- Scott McCutchen
-- DevOps Engineer
-- scott.mccutchen@soverance.com

-- this script returns all the entries in the database for a specified NodeId
-- it assumes the database already exists and has been initialized using the Create-Database.sql script in this directory

-- use the specified database
USE [$(databaseName)];
GO

DECLARE @NodeId varchar(3) = '$(NodeId)'
DECLARE @DeploymentEnvironment varchar(max) = '$(DeploymentEnvironment)'
DECLARE @SelectStatement NVARCHAR(2000)

SET @SelectStatement = 'SELECT * FROM [dbo].[' + @DeploymentEnvironment + '] WHERE [dbo].[' + @DeploymentEnvironment + '].[NodeId] = ''' + @NodeId + ''''

BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from interfering with SELECT statements.
	SET NOCOUNT ON;

    EXEC sp_executesql @SelectStatement

END;
