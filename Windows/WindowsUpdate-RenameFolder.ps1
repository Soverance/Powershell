# © 2017 Soverance Studios
# Scott McCutchen
# soverance.com

param (
	[string]$computer = $(throw "-computer is required. A computer on the local domain network must be specified.")
)

# This command starts the WinRM service, sets it to start automatically with your system, and creates a firewall rule that allows incoming connections. 
# The -Force part of the command tells PowerShell to perform these actions without prompting you for each step.
# THIS COMMAND HAS BEEN ENABLED VIA GROUP POLICY FOR THE BKV.LOCAL DOMAIN, THEREFORE IT IS UNECESSARY HERE but I kept it commented for posterity
#Enable-PSRemoting -Force

# Path Declarations
$source = "C:\Windows\SoftwareDistribution\" # The original path you want to rename
$rename = "SoftwareDistribution.old" # Whatever you would like to rename that folder to

# Rename Windows Update Folder
function RenameWindowsUpdateFolder ()
{
    # Stop the Windows Update service so that the folder can be renamed
    # Alternatively, you could run this command with the service's actual name. i.e., Stop-Service wuauserv
    Invoke-Command -ComputerName $computer -ScriptBlock {Stop-Service -DisplayName "Windows Update"}

    # Assuming the WinRM service is running on the remote computer...
    Invoke-Command -ComputerName $computer -ScriptBlock {Rename-Item -path $Using:source -NewName $Using:rename}

    # Restart the Windows Update service
    Invoke-Command -ComputerName $computer -ScriptBlock {Start-Service -DisplayName "Windows Update"}
}

RenameWindowsUpdateFolder