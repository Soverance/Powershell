-- Customer Node Documentation Database Configuration
-- Scott McCutchen
-- DevOps Engineer
-- scott.mccutchen@soverance.com

-- this script adds a customer into the database of a specified node
-- it assumes the database already exists and has been initialized using the Create-Database.sql script in this directory

-- use the specified database
USE [$(databaseName)];
GO

DECLARE @DeploymentEnvironment varchar(30) = '$(DeploymentEnvironment)'
DECLARE @NodeId varchar(3) = '$(NodeId)'
DECLARE @CustomerId varchar(3) = '$(CustomerId)'
DECLARE @AppUrl varchar(max) = '$(AppUrl)'
DECLARE @Build01 varchar(30) = '$(Build01)'
DECLARE @Build02 varchar(30) = '$(Build02)'
DECLARE @Build03 varchar(30) = '$(Build03)'
DECLARE @Build04 varchar(30) = '$(Build04)'
DECLARE @Build05 varchar(30) = '$(Build05)'
DECLARE @Build06 varchar(30) = '$(Build06)'
DECLARE @Build07 varchar(30) = '$(Build07)'
DECLARE @Build08 varchar(30) = '$(Build08)'
DECLARE @Build09 varchar(30) = '$(Build09)'
DECLARE @Build10 varchar(30) = '$(Build10)'
DECLARE @Build11 varchar(30) = '$(Build11)'
DECLARE @Build12 varchar(30) = '$(Build12)'

DECLARE @InsertStatement NVARCHAR(2000)

SET @InsertStatement = 'INSERT INTO [dbo].[' + @DeploymentEnvironment + '] ( 

		[dbo].[' + @DeploymentEnvironment + '].[NodeId],
		[dbo].[' + @DeploymentEnvironment + '].[CustomerId],
		[dbo].[' + @DeploymentEnvironment + '].[AppUrl],
		[dbo].[' + @DeploymentEnvironment + '].[Build01],
		[dbo].[' + @DeploymentEnvironment + '].[Build02],
		[dbo].[' + @DeploymentEnvironment + '].[Build03],
		[dbo].[' + @DeploymentEnvironment + '].[Build04],
		[dbo].[' + @DeploymentEnvironment + '].[Build05],
		[dbo].[' + @DeploymentEnvironment + '].[Build06],
		[dbo].[' + @DeploymentEnvironment + '].[Build07],
		[dbo].[' + @DeploymentEnvironment + '].[Build08],
		[dbo].[' + @DeploymentEnvironment + '].[Build09],
		[dbo].[' + @DeploymentEnvironment + '].[Build10],
		[dbo].[' + @DeploymentEnvironment + '].[Build11],
		[dbo].[' + @DeploymentEnvironment + '].[Build12] ) 

		VALUES ( ''' + @NodeId + ''','''
			+ @CustomerId + ''',''' 
			+ @AppUrl + ''',''' 
			+ @Build01 + ''',''' 
			+ @Build02 + ''',''' 
			+ @Build03 + ''',''' 
			+ @Build04 + ''',''' 
			+ @Build05 + ''',''' 
			+ @Build06 + ''',''' 
			+ @Build07 + ''',''' 
			+ @Build08 + ''',''' 
			+ @Build09 + ''',''' 
			+ @Build10 + ''',''' 
			+ @Build11 + ''',''' 
			+ @Build12 + ''')'

BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from interfering with SELECT statements.
	SET NOCOUNT ON;

	EXEC sp_executesql @InsertStatement
			
END;

