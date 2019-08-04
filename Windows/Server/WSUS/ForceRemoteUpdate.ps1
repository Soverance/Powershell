# © 2018 Soverance Studios
# Scott McCutchen
# scott.mccutchen@soverance.com

param (
	[string]$computer = $(throw "-computer is required. Supply a valid computer hostname on your network.")
)

# the command "wuauclt /reportnow" used to work here, but apparently is useless on modern operating systems (Server 2016 and later)
# we use the Get-WUInstall command now instead, which requires the PSWindowsUpdate module to be installed
Invoke-Command -ComputerName $computer -ScriptBlock {Get-WUInstall -AcceptAll -AutoReboot}

# Other update help...

#Install-Module PSWindowsUpdate
#Get-Command -module PSWindowsUpdate
#Get-WUInstall -AcceptAll -AutoReboot
#Install-WindowsUpdate

