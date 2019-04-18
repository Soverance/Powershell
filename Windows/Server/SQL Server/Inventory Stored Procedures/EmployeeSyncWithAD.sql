USE [DRUM-Inventory]
GO
/****** Object:  StoredProcedure [dbo].[EmployeeSyncWithAD]    Script Date: 4/18/2019 10:44:04 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Scott McCutchen
-- Create date: 03/11/2019
-- Description:	This procedure fills the Employees table with a list of current employees, pulled from Active Directory
-- =============================================
ALTER PROCEDURE [dbo].[EmployeeSyncWithAD]
AS
-- check the database for the Employees table, and if it exists, truncate it to clear out all data
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Employees]') AND type in (N'U'))
BEGIN
TRUNCATE TABLE [dbo].[Employees]
END

-- check the database for the Employees table, and if it does not exist, create it
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Employees]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[Employees](
	sAMAccountName nvarchar(100),
	Username nvarchar(100),
	Title nvarchar(100),
	Mail nvarchar(100),
	Department nvarchar(100),
	TelephoneNumber nvarchar(15),
	Office nvarchar(100)
);
END

------------------------------------
---
--- BEGIN EMPLOYEE TABLE CREATION
---
------------------------------------
BEGIN
-- configures the next query to insert it's results into the employees table
INSERT INTO
	[dbo].[Employees]

-- performs an LDAP query against our Active Directory to return a dataset of users and their attributes
-- note that LDAP select queries return backwards, so the attribute you want in the first column should be selected last
SELECT * FROM OpenQuery
  (
	ADSI,
		'SELECT physicalDeliveryOfficeName, telephoneNumber, department, mail, title, displayName, sAMAccountName
		FROM  ''LDAP://SOV-PDC.soverance.com/OU=Locations,DC=soverance,DC=com''
		WHERE objectClass =  ''User''
  ') AS tblADSI
WHERE mail LIKE '%_@soverance.com'
ORDER BY displayname
END

------------------------------------
---
--- BEGIN Unassigned Device USER CREATION
---
------------------------------------
BEGIN
INSERT INTO [dbo].[Employees] (
		[sAMAccountName],
		[Username],
		[Title],
		[Mail],
		[Department],
		[TelephoneNumber],
		[Office]
	)
	VALUES (
		'available',
		'Unassigned',
		'Available Device',
		'support@soverance.net',
		'Available',
		'(x3249)',
		'Atlanta'
	)
END

------------------------------------
---
--- BEGIN Loaner Device USER CREATION
---
------------------------------------
BEGIN
INSERT INTO [dbo].[Employees] (
		[sAMAccountName],
		[Username],
		[Title],
		[Mail],
		[Department],
		[TelephoneNumber],
		[Office]
	)
	VALUES (
		'loaner',
		'Loaner',
		'Loaner Device',
		'support@soverance.net',
		'Loaner',
		'(x3249)',
		'Atlanta'
	)
END

------------------------------------
---
--- BEGIN Retired Device USER CREATION
---
------------------------------------
BEGIN
INSERT INTO [dbo].[Employees] (
		[sAMAccountName],
		[Username],
		[Title],
		[Mail],
		[Department],
		[TelephoneNumber],
		[Office]
	)
	VALUES (
		'retired',
		'Retired',
		'Retired Device',
		'support@soverance.net',
		'Retired',
		'(x3249)',
		'Atlanta'
	)
END

------------------------------------
---
--- BEGIN Printer Device USER CREATION
---
------------------------------------
BEGIN
INSERT INTO [dbo].[Employees] (
		[sAMAccountName],
		[Username],
		[Title],
		[Mail],
		[Department],
		[TelephoneNumber],
		[Office]
	)
	VALUES (
		'printer',
		'Printer',
		'Printing Device',
		'support@soverance.net',
		'Printer',
		'(x3249)',
		'Atlanta'
	)
END