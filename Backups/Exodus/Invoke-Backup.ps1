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
    [string]$taskName = "Exodus Backup",

    [Parameter(Mandatory=$False)]
    [string]$repositorylogFile = "C:\Soverance\RepositoryBackup.log",

    
    [Parameter(Mandatory=$False)]
    [string]$hyperVLogFile = "C:\Soverance\HyperVBackup.log",
    
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


    #region FILE REPOSITORY
    # perform mirror backup of Soverance File Repository
    $FileBackupResults = ./Backup-FileRepository.ps1 -fileShare $fileShare -destination $destinationFiles -logName $logName -source $source -logFile $repositorylogFile
      
    # the robocopy output can often be greater than 32766 characters, which is too long to be written to the Windows event log
    # so before writing to the event log, we'll truncate the log 
    # by taking the first 14 lines (which contains robocopy job header),
    # and the last 10 lines (which contains the robocopy job summary),
    # which effectively excludes all the individual file copy output
    $repositoryLogFirstContent = Get-Content -Path $repositorylogFile -TotalCount 14 | Out-String
    $repositoryLogTailContent = Get-Content -Path $repositorylogFile -Tail 10 | Out-String
    $repositoryLogTruncatedContent = $repositoryLogFirstContent + $repositoryLogTailContent
    
    # log the robocopy process for Soverance File Repository
    Write-EventLog -LogName $logName -Source $source -EntryType Information -EventID 1001 -Message $repositoryLogTruncatedContent

    #endregion


    #region HYPER-V CLUSTER
    $ClusterBackupResults = ./Backup-HyperV.ps1 -hyperHost $hyperHost -destination $destinationCluster -backupLimit $backupLimit -logName $logName -source $source -hyperVLogFile $hyperVLogFile
    
    $hyperVLogContent = Get-Content -Path $hyperVLogFile | Out-String

    Write-EventLog -LogName $logName -Source $source -EntryType Information -EventID 1002 -Message $hyperVLogContent

    #endregion


    #region EMAIL NOTIFICATION
    # send backup notification email if specified
    if ($sendEmail)
    {
        $Subject = "Exodus Backup Automation Summary"
        $SmtpUser = "someemail@soverance.net"
        $SmtpPassword = "somepassword"
        #$SmtpServer = "smtp.office365.com"
        $SmtpServer = "soverance-com.mail.protection.outlook.com"
        #$SmtpPort = "587"
        $SmtpPort = "25"
        $Recipient = "info@soverance.com"        
        $pfxFile = "C:\Soverance\soverance.com.pfx"
        $pfxPass = ""

        #$mailBody += "<b>$($Subject)</b><br><br>"
        $mailBody += "<b>========================================================</b><br>"
        $mailBody += "<b>===    File Repository Backup Process</b><br>"
        $mailBody += "<b>========================================================</b><br>"
        $mailBody += "See the log file on $($hyperHost) for complete robocopy details @ $($repositoryLogFile)<br>"

        $repositoryLogHtml = @"
        <html>
        <head><title>Exodus RoboCopy of Soverance File Repository</title></head>
        <body>
        <pre>$repositoryLogTruncatedContent</pre>
        </body>
        </html>
"@
        $mailBody += $repositoryLogHtml

        $mailBody += "<b>========================================================</b><br>"
        $mailBody += "<b>===    Hyper-V Cluster Backup Process</b><br>"
        $mailBody += "<b>========================================================</b><br>"
        $mailBody += "See the log file on $($hyperHost) for complete Hyper-V details @ $($hyperVLogFile)<br>"

        $hyperVLogHtml = @"
        <html>
        <head><title>Exodus Backup of Soverance Hyper-V Cluster</title></head>
        <body>
        <pre>$hyperVLogContent</pre>
        </body>
        </html>
"@
        $mailBody += $hyperVLogHtml

        Send-Mail -SmtpUser $SmtpUser -SmtpServer $SmtpServer -SmtpPort $SmtpPort -Recipient $Recipient -Subject $Subject -Body $mailBody -SmtpPassword $SmtpPassword -UseSSL -pfxFile $pfxFile -pfxPass $pfxPass

        if ($?)
        {
            Write-EventLog -LogName $logName -Source $source -EntryType Information -EventID 1003 -Message "Summary email has been sent via $($SmtpServer) to the following recipient:  $($Recipient)"
        }
    }

    #endregion

    Write-EventLog -LogName $logName -Source $source -EntryType Information -EventID 1004 -Message "All Exodus processes have completed.  Check log files for details."  
}
catch
{
    Write-EventLog -LogName $logName -Source $source -EntryType Error -EventID 1901 -Message "ERROR in $($MyInvocation.MyCommand) on line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)"
    exit 1
}