# © 2018 Soverance Studios
# Scott McCutchen
# scott.mccutchen@soverance.com
#
# This script is used to backup databases in Microsoft SQL Server.
# Run with the following parameters:

param(
    [parameter(Mandatory=$true)]
    [ValidateNotNull()]
    $ServerName,
    [parameter(Mandatory=$true)]
    [ValidateNotNull()]
    $BackupDirectory,
    [parameter(Mandatory=$true)]
    [ValidateNotNull()]
    $DaysToStoreBackups
)

[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO") | Out-Null
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SmoExtended") | Out-Null
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.ConnectionInfo") | Out-Null
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SmoEnum") | Out-Null

$server = New-Object ("Microsoft.SqlServer.Management.Smo.Server") $ServerName
$dbs = $server.Databases
foreach ($database in $dbs | where { $_.IsSystemObject -eq $False })
{
    if($db.Name -ne "tempdb") # We don't want to backup the tempdb database 
     {
    $dbName = $database.Name

    $timestamp = Get-Date -format yyyy-MM-dd-HHmmss
    $targetPath = $BackupDirectory + "\" + $dbName + "_" + $timestamp + ".bak"

    $smoBackup = New-Object ("Microsoft.SqlServer.Management.Smo.Backup")
    $smoBackup.Action = "Database"
    $smoBackup.BackupSetDescription = "Full Backup of " + $dbName
    $smoBackup.BackupSetName = $dbName + " Backup"
    $smoBackup.Database = $dbName
    $smoBackup.MediaDescription = "Disk"
    $smoBackup.Devices.AddDevice($targetPath, "File")
    $smoBackup.SqlBackup($server)
    }

    if($?)
{
Write-Host "backed up $dbName ($ServerName) to $targetPath" -foregroundcolor black -backgroundcolor cyan
}
else
{
Write-Host "Failed to back up $dbName ($ServerName) to $targetPath" -foregroundcolor white -backgroundcolor red
}    
}

Get-ChildItem "$BackupDirectory\*.bak" |? { $_.lastwritetime -le (Get-Date).AddDays(-$DaysToStoreBackups)} |% {Remove-Item $_ -force }

if($?)
{
Write-Host "removed all previous backups older than $DaysToStoreBackups days" -foregroundcolor black -backgroundcolor cyan
}
else
{
Write-Host "Failed to remove old backups. A critical error occured." -foregroundcolor white -backgroundcolor red
} 