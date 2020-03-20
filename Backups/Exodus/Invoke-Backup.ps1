# Invoke Backup
# Scott McCutchen
# DevOps Engineer
# scott.mccutchen@soverance.com

# This script is intended to be run as a scheduled task, and is the primary entry point for initiating "Exodus" backups of Soverance infrastructure

# Note that this file must be run with Administrator rights

######################################
#region Parameters
######################################

param(

    [Parameter(Mandatory=$False)]
    [string]$hyperHost = "SOV-R230.soverance.net",

    # The Hyper-V export process occurs as the Local System account, which cannot access network resources
    # so you'll get an access denied error if you try to export to an SMB network share
    # SMB Destination:  \\SOV-R230\archive\Hyper-V
    [Parameter(Mandatory=$False)]
    [string]$destinationCluster = "M:\Archive\Hyper-V",

    [Parameter(Mandatory=$False)]
    [int]$backupLimit = 3,

    [Parameter(Mandatory=$False)]
    [string]$fileShare = "\\SCOTT.soverance.net\Repository",

    [Parameter(Mandatory=$False)]
    [string]$destinationFiles = "\\SOV-R230.soverance.net\archive\Files\Repository",

    [Parameter(Mandatory=$False)]
    [string]$logName = "Soverance Automation",

    [Parameter(Mandatory=$False)]
    [string]$source = "Exodus Backup",

    [Parameter(Mandatory=$False)]
    [string]$logFile = "C:\Soverance\RepositoryBackup.log",
    
    [Parameter(Mandatory=$False)]
    [switch]$sendEmail
)

#endregion 

######################################
#region Module Configuration
######################################
$env:PSModulePath = $env:PSModulePath + ";C:\Soverance\Modules"
Import-Module Sov.Mail

#endregion

try
{
    $ErrorActionPreference = "stop"

    # create Event Log if necessary
    $eventLogExists = Get-EventLog -list | Where-Object {$_.logdisplayname -eq $logName} 
    if (!$eventLogExists) 
    {
        New-EventLog -LogName $logName -Source $source
    }

    Write-EventLog -LogName $logName -Source $source -EntryType Information -EventID 1000 -Message "Exodus Backup process initialized."    

    # check to see if the robocopy log file already exists - if not, create it
    if (!(Test-Path $Logfile))
    {
        New-Item -Force -Path $Logfile
    }

    # perform mirror backup of Soverance File Repository
    $FileBackupResults = ./Backup-FileRepository.ps1 -fileShare $fileShare -destination $destinationFiles -logName $logName -source $source -logFile $logFile
      
    # the robocopy output can often be greater than 32766 characters, which is too long to be written to the Windows event log
    # so before writing to the event log, we'll truncate the log 
    # by taking the first 14 lines (which contains some debug info),
    # and the last 10 lines (which contains the summary results of the robocopy process)
    $logFirstContent = Get-Content -Path $logFile -TotalCount 14 | Out-String
    $logTailContent = Get-Content -Path $logFile -Tail 10 | Out-String
    $logTruncatedContent = $logFirstContent + $logTailContent
    
    # log the robocopy procee for Soverance File Repository
    Write-EventLog -LogName $logName -Source $source -EntryType Information -EventID 1001 -Message $logTruncatedContent

    $ClusterBackupResults = ./Backup-HyperV.ps1 -hyperHost $hyperHost -destination $destinationCluster -backupLimit $backupLimit -logName $logName -source $source
    
    # send backup notification email if specified
    if ($sendEmail)
    {
        $mailBody += "File Repository Backup Automation`r`n`r`n"
        $mailBody += $logContent

        $SmtpUser = "someuser@yourdomain.com"
        $SmtpPassword = "YourPassword"
        #$SmtpServer = "smtp.office365.com"
        $SmtpServer = "domain.mail.protection.outlook.com"
        #$SmtpPort = "587"
        $SmtpPort = "25"
        $Recipient = "someuser@otherdomain.com"
        $Subject = "File Repository Automation Logs"
        $pfxFile = "C:\Soverance\soverance.com.pfx"
        $pfxPass = ""

        Send-Mail -SmtpUser $SmtpUser -SmtpServer $SmtpServer -SmtpPort $SmtpPort -Recipient $Recipient -Subject $Subject -Body $mailBody -SmtpPassword $SmtpPassword -UseSSL -pfxFile $pfxFile -pfxPass $pfxPass
    }
}
catch
{
    Write-EventLog -LogName $logName -Source $source -EntryType Error -EventID 1901 -Message "ERROR in $($MyInvocation.MyCommand) on line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)"
    exit 1
}