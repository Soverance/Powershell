# © 2018 Soverance Studios
# Scott McCutchen
# scott.mccutchen@soverance.com

param (
	[string]$computer = $(throw "-computer is required. Supply a valid computer hostname on your network.")
)


Invoke-Command -ComputerName $computer -ScriptBlock {wuauclt /reportnow}

# Other update help...

#Install-Module PSWindowsUpdate
#Get-Command -module PSWindowsUpdate
#Get-WUInstall -AcceptAll -AutoReboot
#Install-WindowsUpdate

