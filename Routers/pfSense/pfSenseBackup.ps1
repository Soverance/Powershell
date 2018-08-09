# © 2018 Soverance Studios, LLC
# Scott McCutchen
# DevOps Engineer
# scott.mccutchen@soverance.com

# This script runs an automated backup process on pfSense firewalls within the Soverance domain environment.
# It is designed to be run from the Task Scheduler on a server which can resolve DNS queries on the soverance.net domain

# This script is dependent on the open source pfSenseBackup.exe utility by KoenZomers
# https://github.com/KoenZomers/pfSenseBackup
# pfSenseBackup.exe version 2.4.3 is included in this repo, and must remain in the /Backup/ directory for this script to function.

# This script is dependent on the installation of the Git version control system.
# Git must be installed and accessible from the Environment Variable path for this script to run properly.

##########################
##
## CREDENTIALS
##
##########################

# This is a service account originating from the soverance.net Domain Active Directory.
# However, it could be any user with admin access to the pfSense webconfigurator portal.
$user = "user"
$pass = "password"

# This is a Github user account with access to the BKVdigital/pfSense repository
# In this case, I'm using my own account.  My Github account requires Two Factor Authentication
# and therefore must use a "Personal Access Token" to access the Git API.
# In my account, this token is labeled "Unified Agency pfSense Automated Backups"

$gituser = "GitHubUsername"
$gitaccesstoken = "YourAccessTokenHere"

##########################
##
## LOGGING
##
##########################

$Logfile = "C:\Soverance\pfSenseBackup.log"

# check to see if the log file already exists - if not, create it
if (!(Test-Path $Logfile))
{
    New-Item -Force -Path $Logfile -Type file
}

# log writing function
Function LogWrite
{
   Param ([string]$logstring)

   Add-content $Logfile -value $logstring
}

$date = Get-Date  # get date
$time = $date.ToUniversalTime()  # convert to readable time

# Notify start position in the log for legibility
LogWrite "################### BEGIN BACKUP PROCESS - $($time) #####################"

$ErrorActionPreference = "SilentlyContinue"
Stop-Transcript | Out-Null
$ErrorActionPreference = "Continue"

##########################
##
## BACKUP FUNCTIONS
##
##########################

Function PerformBackup
{
    Set-Location -Path "C:\Scripts\pfSense\Backup"  # change to backup dir
    ./pfSenseBackup.exe -u $user -p $pass -s pfSense.soverance.net:8443 -o "C:\Scripts\pfSense\Atlanta" -usessl  # run backup process
    Set-Location -Path $PSScriptRoot  # return to root dir
}

##########################
##
## GITHUB FUNCTIONS
##
##########################

Function CommitToGithub
{
    Set-Location -Path $PSScriptRoot  # return to root dir
    git add .  # add all files to this commit
    $commitmsg = "AutoBackup - $($date.Month)-$($date.Day)-$($date.Year)" # build commit message
    git commit -m $commitmsg  # stage commit locally
    $commiturl = "https://$($gituser):$($gitaccesstoken)@github.com/BKVdigital/pfSense.git"
    # the "2>$1 | out-null" bit here tells git to redirect all stderr output to stdout, and then nullifies any error output
    # see:  https://serverfault.com/questions/565875/executing-a-git-command-using-remote-powershell-results-in-a-nativecommmanderror
    git push $commiturl --all 2>&1 | out-null # push commit remotely
    Set-Location -Path $PSScriptRoot  # return to root dir
}

##########################
##
## MAIN
##
##########################

Start-Transcript -path $Logfile -append  # start transcript to log output of pfSenseBackup.exe

PerformBackup
CommitToGithub

Stop-Transcript  # stop transcript