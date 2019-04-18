# © 2018 Soverance Studios
# Scott McCutchen
# scott.mccutchen@soverance.com

# This script will collect all of the file shares on the specified computers

###########################################
##
## Log Transcript Configuration
##
###########################################
$Logfile = "C:\Soverance\FileShares.log"
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

$computers = @("computer1",
                "computer2",
                "computer3",
                "computer4")

###########################################
##
## Script
##
###########################################

$shares = ForEach ($computer in $computers)
{
    Write-Host "$($time) : Scanning $($computer).`r`n"
    Get-WmiObject -class Win32_Share -Computer $computer | Where-Object {(@('Remote Admin','Default share','Remote IPC') -notcontains $_.Description)} | Select-Object -Property PSComputerName,Name,Caption,Description,Path
    #Invoke-Command -Computer $computer -ScriptBlock {Get-SmbShare}
    Write-Host "`r`n"
}

$shares | Export-Csv "C:\Soverance\FileShares.csv"

# Finally, stop the transcript
Stop-Transcript | Out-Null