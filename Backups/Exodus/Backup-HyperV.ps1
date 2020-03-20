# Hyper-V Backup Script
# Scott McCutchen
# DevOps Engineer
# scott.mccutchen@soverance.com

# This script makes backups of all virtual machines in the local Hyper-V cluster

######################################
#region Parameters
######################################

param(

    [Parameter(Mandatory=$True)]
    [string]$hyperHost,

    # The Hyper-V export process occurs as the Local System account, which cannot access network resources
    # so you'll get an access denied error if you try to export to an SMB network share
    # SMB Destination:  \\SOV-R230\archive\Hyper-V
    [Parameter(Mandatory=$True)]
    [string]$destination,

    [Parameter(Mandatory=$True)]
    [int]$backupLimit,

    [Parameter(Mandatory=$False)]
    [string]$logName,

    [Parameter(Mandatory=$False)]
    [string]$source,

    [Parameter(Mandatory=$False)]
    [string]$hyperVLogFile
)

#endregion 

###########################################
#region Log Transcript Configuration
###########################################

$time = Get-Date -format yyyy.MM.dd.HH.mm

# check to see if the log file already exists - if not, create it
if (!(Test-Path $hyperVLogFile))
{
    New-Item -Force -Path $hyperVLogFile
}

$ErrorActionPreference = "Continue"
Start-Transcript -path $hyperVLogFile -append  # start transcript to log output

######################################
#region Main
######################################
try
{
    $AllVMs = Get-VM -ComputerName $hyperHost

    Write-EventLog -LogName $logName -Source $source -EntryType Information -EventID 3000 -Message "Hyper-V Export Initialized for the following found virtual machines:   $($AllVMs)"

    $backupDestination = "$($destination)\$($time)" 

    # create backup directory
    if (!(Test-Path $backupDestination))
    {
        New-Item -Force -Path $backupDestination -ItemType Directory
    }

    foreach($vm in $AllVMs)
    {
        # build the event log message body for this vm
        $msgBody += "Starting Hyper-V export procedure for the following virtual machine:`r`n"
        $msgBody += "`r`n"
        $msgBody += $vmName = "Name:  $($vm.Name)`r`n"
        $msgBody += $vmID = "ID:  $($vm.Id)`r`n"
        $msgBody += $vmState = "State:  $($vm.State)`r`n"
        $msgBody += $vmProcessorCount = "Processor Count:  $($vm.ProcessorCount)`r`n"
        $msgBody += $vmCpuUsage = "CPU Usage:  $($vm.CpuUsage)`r`n"
        $msgBody += $vmMemoryAssigned = "Memory Assigned:  $($vm.MemoryAssigned)`r`n"
        $msgBody += $vmMemoryDemand = "Memory Demand:  $($vm.MemoryDemand)`r`n"
        $msgBody += $vmMemoryStatus = "Memory Status:  $($vm.MemoryStatus)`r`n"
        $msgBody += $vmUptime = "Uptime:  $($vm.Uptime)`r`n"
        $msgBody += $vmStatus = "Status:  $($vm.Status)`r`n"
        $msgBody += $vmReplicationState = "Replication State:  $($vm.ReplicationState)`r`n"
        $msgBody += $vmGeneration = "Generation:  $($vm.Generation)`r`n"
        $msgBody += $vmDiskPath = "Disk Path:  $($vm.Path)`r`n"

        Write-EventLog -LogName $logName -Source $source -EntryType Information -EventID 3001 -Message $msgBody
        Write-Output $msgBody

        # clear the message body from memory after writing it to event log
        $msgBody = ""

        #region EXPORT JOB
        $ExportJob = Export-VM -ComputerName $hyperHost -Name $vm.Name -Path $backupDestination -AsJob

        while ($ExportJob.State -eq "Running" -or $ExportJob.State -eq "NotStarted")
        {
	        # log backup progress - REMOVED FROM EVENT LOG TO AVOID CLUTTER - we still write progress to the full log
	        $message = "[JOB] $($vm.Name) export progress: $($ExportJob.Progress.PercentComplete)% complete."
            Write-Output $message
	        #Write-EventLog -LogName "Exodus Event Log" -Source "Exodus Source" -EventID 3002 -EntryType Information -Message $message
	        Start-Sleep(60)
        }

        if ($ExportJob.State -ne "Completed")
        {
	        $message = "[JOB] $($vm.Name) export job did not complete.  STATUS: $($ExportJob.State)"
            Write-Output $message
	        Write-EventLog -LogName $logName -Source $source -EntryType Error -EventID 3902 -Message $message
        }

        if ($ExportJob.State -eq "Completed")
        {
	        $message = "[JOB] $($vm.Name) export job has finished with status:  $($ExportJob.State)"
            Write-Output $message
	        Write-EventLog -LogName $logName -Source $source -EntryType Information -EventID 3003 -Message $message
        }
        #endregion

        # MANUAL OPERATION - this is a fix for an error which can occur when you migrate disks between Hyper-V hosts, where the VM itself no longer has permission to access the disk
        # # the servers need to be rebooted after this is applied, and it's rare anyway because it only occurs when you migrate vm disks between hosts
        # so we're just doing this manually instead whenever we encounter the issue
        # ultimately, you need to use cmd.exe to run a command granting the GUID of the virtual machine full control to the VHD, and then reboot the server
        # icacls "C:\Users\Public\Documents\Hyper-V\Virtual hard disks\SOV-ADConnect.vhdx" /grant "NT VIRTUAL MACHINE\2F235459-9BA9-44E5-917E-233E79354D71":(F)
        # $vmPath = (Get-VMHardDiskDrive -VMName $vm.Name).Path
        # $vmId = $vm.Id
        # $Cmd = "icacls ""$vmPath"" /grant ""NT VIRTUAL MACHINE\$vmId"":F /T"
        # & cmd.exe /c $Cmd
    }

    
    # DEPRECATED - Export all virtual machines
    # you can use this instead of the loop, which works fine but doesn't provide a good way to log results.
    # I think it also tries to do them basically all at once, which doesn't turn out great in terms of performance.  it's pretty taxing.
    # since these machines remain operational during this process, we've deprecated this method in favor of the export jobs above
    # because they provide better logging options and can be run sequentially in order to minimize the load put on the hyper-v host during export
    #$AllVMs | Export-VM -Path $backupDestination
    
    # Clean up old backups
    $backups = Get-ChildItem -Path $destination    
    Write-EventLog -LogName $logName -Source $source -EntryType Information -EventID 3004 -Message "Cluster backup retention limit set to $($backupLimit) days.  All backups older than $($backupLimit) days are considered expired, and will be destroyed."
    $backups | Where-Object { $_.lastwritetime -le (Get-Date).AddDays(-$backupLimit)} | ForEach-Object {Remove-Item $_.FullName -Force -Recurse
            Write-Output "[CLEANUP] Removing Backup:  $($_.FullName)"
            Write-EventLog -LogName $logName -Source $source -EntryType Warning -EventID 3500 -Message "Removing Backup:  $($_.FullName)"
    }

    # Finally, stop the logging transcript
    Stop-Transcript | Out-Null

}
catch
{
    Write-Output "[ERROR] Error in $($MyInvocation.MyCommand) on line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)"
    Write-EventLog -LogName $logName -Source $source -EntryType Error -EventID 3901 -Message "ERROR in $($MyInvocation.MyCommand) on line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)"
    exit 1
}

#endregion


