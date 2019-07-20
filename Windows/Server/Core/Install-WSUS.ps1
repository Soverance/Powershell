# © 2018 Soverance Studios
# Scott McCutchen
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
Install-WindowsFeature -Name UpdateServices-Services,UpdateServices-DB -IncludeManagementTools
# if you get an error about "Feature SQL Server Connectivity has a conflict with the features WID Connectivity", simply remove the WidDB feature like so, and then run the above command again
Remove-WindowsFeature -Name UpdateServices-WidDB

# point WSUS at the desired SQL Server and the download location
./WsusUtil.exe PostInstall SQL_INSTANCE_NAME="SOV-SQL\SOVERANCESQL" CONTENT_DIR=C:\WSUS

# Open the ports required for remote management
New-NetFirewallRule -DisplayName "WSUS-HTTP" -Direction Inbound -Protocol TCP -LocalPort 8530 -Action allow
New-NetFirewallRule -DisplayName "WSUS-HTTPS" -Direction Inbound -Protocol TCP -LocalPort 8531 -Action allow

# Configuring SSL
# Create a new self-signed cert
New-SelfSignedCertificate -Subject "sov-wsus.soverance.net" -DnsName "sov-wsus.soverance.net" -CertStoreLocation "cert:\LocalMachine\My" -KeyAlgorithm RSA -KeyLength 2048 -KeyExportPolicy Exportable -NotAfter (Get-Date).AddYears(5)

# export the cert so it can be imported to other machines
# NOTE:  The Export-PfxCertificate command always seems to give me an "Access Denied" error, even when running as admin and ensuring the cert was exportable
# so instead we'll use the older certutil 
# IMPORTANT:  Remember to update the WSUS Group Policy Objects with this new certificate, so that clients/servers have the proper connectivity
certutil -exportPFX 75ED65AE643FC3D3BECB9548DEEEB65ED35CF3C0 C:\WSUS\UpdateServicesPackages\sov-wsus.soverance.net.pfx

# Install the cert in the IIS console for the WSUS website
Import-Module WebAdministration

# Get Cert thumbprint
$thumbprints = Get-ChildItem -path cert:\LocalMachine\My
$certThumbprint = $thumbprints[1]  

# show current bindings
Get-WebBinding "WSUS Administration"

# remove the existing SSL binding, if necessary
Get-WebBinding -Name "WSUS Administration" -Port 8531 | Remove-WebBinding

# add a new SSL binding with the updated certificate
New-WebBinding -Name "WSUS Administration" -IPAddress * -Port 8531 -Protocol "https" -HostHeader "sov-wsus.soverance.net" -SslFlags 1

#finally, configure the cert to be used with the new binding
(Get-WebBinding -Name "WSUS Administration" -Port 8531 -Protocol "https" -HostHeader "sov-wsus.soverance.net").AddSslCertificate($certThumbprint, "my")