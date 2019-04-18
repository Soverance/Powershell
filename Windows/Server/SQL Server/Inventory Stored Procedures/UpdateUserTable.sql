-- tells the server to use the "DRUM-Inventory Database
-- this USE directive must be removed to run this script via SQL Agent Job
USE "DRUM-Inventory"
GO

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
	displayName nvarchar(100),
	title nvarchar(100),
	mail nvarchar(100),
	department nvarchar(100),
	telephoneNumber nvarchar(15),
	office nvarchar(100)
);
END

-- configures the next query to insert it's results into the employees table
INSERT INTO
	[dbo].[Employees]

-- performs an LDAP query against our Active Directory to return a dataset of users and their attributes
SELECT * FROM OpenQuery
  (
	ADSI,
		'SELECT physicalDeliveryOfficeName, telephoneNumber, department, mail, title, displayName, sAMAccountName
		FROM  ''LDAP://SOV-PDC.soverance.com/OU=Locations,DC=soverance,DC=com''
		WHERE objectClass =  ''User''
  ') AS tblADSI
WHERE mail LIKE '%_@soverance.com'
ORDER BY displayname