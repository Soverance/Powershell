# File Repository Backup Script
# Scott McCutchen
# DevOps Engineer
# scott.mccutchen@soverance.com

# This script performs a robocopy mirror process on the Soverance Studios internal network file share.
# It is intended to be run as a scheduled task on our backup server.

# Note that this file must be run with Administrator rights

######################################
#region Parameters
######################################

param(
    [Parameter(Mandatory=$True)]
    [string]$fileShare,

    [Parameter(Mandatory=$True)]
    [string]$destination,

    [Parameter(Mandatory=$True)]
    [string]$logName,

    [Parameter(Mandatory=$True)]
    [string]$source,

    [Parameter(Mandatory=$True)]
    [string]$logFile
)

#endregion 


######################################
#region Main
######################################
try
{
    $ErrorActionPreference = "stop"

     # check to see if the robocopy log file already exists - if not, create it
    if (!(Test-Path $Logfile))
    {
        New-Item -Force -Path $Logfile
    }
    
    Write-EventLog -LogName $logName -Source $source -EntryType Information -EventID 2000 -Message "RoboCopy Mirror Initiated: $($fileShare) to $($destination)"

    # view all robocopy options here:
    # https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/robocopy
    robocopy $fileShare $destination /COPYALL /B /SEC /MIR /R:0 /W:0 /TS /FP /NP /LOG:$logFile 
}
catch
{
    Write-EventLog -LogName $logName -Source $source -EntryType Error -EventID 2901 -Message "ERROR in $($MyInvocation.MyCommand) on line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)"
    exit 1
}

#endregion