# © 2018 Soverance Studios
# Scott McCutchen
# scott.mccutchen@soverance.com

# This script will collect and export information about subfolders in the specified file shares

###########################################
##
## Log Transcript Configuration
##
###########################################
$Logfile = "C:\Soverance\FileShareSubfolders.log"
$time = Get-Date -Format G # get date
# check to see if the log file already exists - if not, create it
if (!(Test-Path $Logfile))
{
    New-Item -Force -Path $Logfile
}
$ErrorActionPreference = "SilentlyContinue"
Stop-Transcript | Out-Null
$ErrorActionPreference = "Continue"
Start-Transcript -path $Logfile -append  # start transcript to log output of tabadmin

###########################################
##
## Computer Configuration
##
###########################################

$shares = @("\\atl-filesrv\Clients",
                "\\atl-filesrv\Clients\Clients",
                "\\atl-filesrv\Clients\Departments",
                "\\atl-filesrv\Clients\Management",
                "\\atl-filesrv\DPM",
                "\\atl-filesrv\Clients\Clients\Hiccup",
                "\\creative\Creative",
                "\\umsvrfile\Admin1",
                "\\umsvrfile\Client Files",
                "\\umsvrfile\LanyapFiles",
                "\\umsvrfile\MACFILES",
                "\\umsvrfile\MACFILES\Client Files")

###########################################
##
## Script
##
###########################################

$subfolders = ForEach ($share in $shares)
{
    Get-ChildItem -Path $share | Select-Object -Property FullName,Parent,Name,LastAccessTime
}

$subfolders | Export-Csv "C:\Soverance\FileShares.csv"

# Finally, stop the transcript
Stop-Transcript | Out-Null


