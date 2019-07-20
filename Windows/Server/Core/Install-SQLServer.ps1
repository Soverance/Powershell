# © 2018 Soverance Studios
# Scott McCutchen
# scott.mccutchen@soverance.com

# Server Core IP Configuration Help

# Use this script as a technical document to help configure Server Core installations.  I tend to run these cmdlets in order.

# This is for installing SQL Server 2017 Enterprise Core

# first, navigate to the directory where the installation media resides
#then run the following command:

# Mount the installation media
Mount-DiskImage -ImagePath "C:\SQL\en_sql_server_2017_enterprise_core_x64_dvd_11293037.iso"

# use the Get-Volume command to determine the drive letter of the ISO you just mounted
Get-Volume

# Once you know the drive letter, navigate to that directory
Set-Location E:

# run the setup program with various params
# SQL Server 2017 does not support the installation wizard on Server Core operating systems
# see here for full options:  https://docs.microsoft.com/en-us/sql/database-engine/install-windows/install-sql-server-from-the-command-prompt
./Setup.exe /QS /ACTION=Install /IACCEPTSQLSERVERLICENSETERMS /ENU /UPDATEENABLED=1 /UPDATESOURCE=MU /FEATURES=SQLEngine,FullText /INSTANCENAME=SOVERANCESQL /INSTANCEDIR="C:\SQL\" /SQLSVCACCOUNT="NT AUTHORITY\SYSTEM" /SQLSYSADMINACCOUNTS="SOVERANCE\SQL-Admins" /AGTSVCACCOUNT="NT AUTHORITY\Network Service" /TCPENABLED=1 

# Once complete, install the sqlcmd tool
# This tool is part of the Microsoft� Command Line Utilities for SQL Server
# You need version 13.1 or higher to support Always Encrypted (-g) and Azure Active Directory authentication (-G). 
# see here:  https://www.microsoft.com/en-us/download/details.aspx?id=53591
# Once copied to the server, run the installation wizard
Start-Process MsSqlCmdLnUtils.msi

# with the SQL Server command line utilities installed, manually add the path to sqlcmd.exe to the environment variable path
# show the current path with $env:Path
# This command permanently sets the path, so that it is persistent through reboots
[Environment]::SetEnvironmentVariable("Path", $env:Path + ";C:\Program Files\Microsoft SQL Server\Client SDK\ODBC\130\Tools\Binn\", [EnvironmentVariableTarget]::Machine)

# you must restart the server before the above command will take effect

# Check the services to make sure they started up and are running properly
# be sure the SQL-related services are set to start automatically
Get-Service | select -Property name,starttype,status
# Start any services that failed to start during boot (it's usually the mssql service, because the VM needs more resources)
# get all services that start with "MSSQL"
$sqlservice = Get-Service MSSQL*
# start the first service in that arrary - it's usually the default SQL instance service, but you should check first by printing the results of $sqlservice
Start-Service $sqlservice[0]

#Enabling SQL Server Ports
New-NetFirewallRule -DisplayName �SQL Server� -Direction Inbound �Protocol TCP �LocalPort 1433 -Action allow
New-NetFirewallRule -DisplayName �SQL Admin Connection� -Direction Inbound �Protocol TCP �LocalPort 1434 -Action allow
New-NetFirewallRule -DisplayName �SQL Database Management� -Direction Inbound �Protocol UDP �LocalPort 1434 -Action allow
New-NetFirewallRule -DisplayName �SQL Service Broker� -Direction Inbound �Protocol TCP �LocalPort 4022 -Action allow
New-NetFirewallRule -DisplayName �SQL Debugger/RPC� -Direction Inbound �Protocol TCP �LocalPort 135 -Action allow
#Enabling SQL Analysis Ports
New-NetFirewallRule -DisplayName �SQL Analysis Services� -Direction Inbound �Protocol TCP �LocalPort 2383 -Action allow
New-NetFirewallRule -DisplayName �SQL Browser� -Direction Inbound �Protocol TCP �LocalPort 2382 -Action allow
#Enabling Misc. Applications
New-NetFirewallRule -DisplayName �HTTP� -Direction Inbound �Protocol TCP �LocalPort 80 -Action allow
New-NetFirewallRule -DisplayName �SSL� -Direction Inbound �Protocol TCP �LocalPort 443 -Action allow
New-NetFirewallRule -DisplayName �SQL Server Browse Button Service� -Direction Inbound �Protocol UDP �LocalPort 1433 -Action allow

# with the sqlcmd tool installed, login to the server
# login obviously uses param -S servername\instancename
# login will use current session credentials for auth
sqlcmd -S SOV-SQL\SoveranceSQL

# run the following commands on the SQL instance within sqlcmd to enable remote connections
EXEC sys.sp_configure N'remote access', N'1'
GO
# you'll then get a message stating: "Configuration option 'remote access' changed from 0 to 1.  Run the RECONFIGURE statement to install.
# then type:
RECONFIGURE WITH OVERRIDE
GO
# when you return to the prompt, simply type 'exit' to exit sqlcmd
EXIT

# next, import the sqlps module
# https://docs.microsoft.com/en-us/sql/relational-databases/scripting/import-the-sqlps-module
# Import the SQL Server Module.    
Import-Module Sqlps -DisableNameChecking;

# To check whether the module is installed.
Get-Module -ListAvailable -Name Sqlps;

# You may need to enable TCP/IP on the SQL instance
# with sqlps installed, run the following commands:
$smo = 'Microsoft.SqlServer.Management.Smo.'  
$wmi = new-object ($smo + 'Wmi.ManagedComputer')  
# Enable the TCP protocol on the default instance.  If the instance is named, replace MSSQLSERVER with the instance name in the following line.  
$uri = "ManagedComputer[@Name='" + (get-item env:\computername).Value + "']/ServerInstance[@Name='SoveranceSQL']/ServerProtocol[@Name='Tcp']"  
$Tcp = $wmi.GetSmoObject($uri)  
$Tcp.IsEnabled = $true  
$Tcp.Alter()  
$Tcp  
# Enable the named pipes protocol for the default instance.  
$uri = "ManagedComputer[@Name='<computer_name>']/ ServerInstance[@Name='SoveranceSQL']/ServerProtocol[@Name='Np']"  
$Np = $wmi.GetSmoObject($uri)  
$Np.IsEnabled = $true  
$Np.Alter()  
$Np 

# you will need to restart the SQL service for these changes to take effect
# may as well restart the whole machine, for good measure, and to make sure everything comes back online as expected
Restart-Computer