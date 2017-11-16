# scott.mccutchen@soverance.com
# Server Core WSUS Help

# Use this script as a technical document to help configure Server Core installations.  I tend to run these cmdlets in order.

# This is for installing Windows Server Update Services on Windows Server Core 2016

# Install Update Services
Install-WindowsFeature -Name UpdateServices -IncludeManagementTools
# you get a message about additional configuration required upon success

# change to the directory where WSUS tools are installed
Set-Location "C:\Program Files\Update Services\Tools\"

# configure the download location where WSUS will install updates
./WsusUtil.exe PostInstall CONTENT_DIR=C:\WSUS

# Install the SQL Server feature additions
Install-WindowsFeature -Name UpdateServices-Services,UpdateServices-DB –IncludeManagementTools
# if you get an error about "Feature SQL Server Connectivity has a conflict with the features WID Connectivity", simply remove the WidDB feature like so, and then run the above command again
Remove-WindowsFeature -Name UpdateServices-WidDB

# point WSUS at the desired SQL Server and the download location
./WsusUtil.exe PostInstall SQL_INSTANCE_NAME="SOV-SQL\SOVERANCESQL" CONTENT_DIR=C:\WSUS

# Open the ports required for remote management
New-NetFirewallRule -DisplayName “WSUS-HTTP” -Direction Inbound –Protocol TCP –LocalPort 8530 -Action allow
New-NetFirewallRule -DisplayName “WSUS-HTTPS” -Direction Inbound –Protocol TCP –LocalPort 8531 -Action allow