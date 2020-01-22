-- Initialize the Customer Node Documentation Table
-- Scott McCutchen
-- DevOps Engineer
-- scott.mccutchen@soverance.com

-- this script will configure the Sisense Pod Documentation Table in an existing database
-- this script assumes the database in question already exists

-- use the specified database
USE [$(databaseName)];
GO

-- check the database for the specified table, and if it does not exist, create it
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[$(DeploymentEnvironment)]') AND type in (N'U'))
BEGIN
    CREATE TABLE [$(DeploymentEnvironment)] (
        [ObjectId] int NOT NULL IDENTITY,
        [NodeId] varchar(3) NOT NULL,
        [CustomerId] varchar(3) NOT NULL,
        [AppUrl] varchar(max),
        [Build01] varchar(30),
        [Build02] varchar(30),
        [Build03] varchar(30),
        [Build04] varchar(30),
        [Build05] varchar(30),
        [Build06] varchar(30),
        [Build07] varchar(30),
        [Build08] varchar(30),
        [Build09] varchar(30),
        [Build10] varchar(30),
        [Build11] varchar(30),
        [Build12] varchar(30),
        CONSTRAINT [PK_Development] PRIMARY KEY ([ObjectId])
    );
END;
GO
