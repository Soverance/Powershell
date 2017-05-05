# Scott McCutchen
# www.soverance.com

# You'll need to run this script using your MySQL login credentials as parameters
# Ex: ./RunWebBackup.ps1 -username $user -password $pass

param (
	[string]$username = $(throw "-username is required."),
	[string]$password = $(Read-Host "Input password :")
)

# Name of Server
$ServerName = "SOV-WEB"

# The Path to the mysqldump.exe program. This is the program that backs up the MySQL database natively.
$PathToMySQLDump = "C:\Program Files\MySQL\MySQL Server 5.7\bin\mysqldump.exe"

# Credentials of the MySQL user account


# Get today's date, to be used for naming purposes
$Date = (get-date).ToString('MM-dd-yyyy')

# Where to store the backup files
$LocalBackupPath = "C:\Backups\MySQL"

# Databases to backup
$DB0 = "soverance-dev"
$DB1 = "shinybaubles"
$DB2 = "mobiusff"

function RunSQLDumps ()
{
	# Backup all of the Databases
	cmd /c " `"$PathToMySQLDump`" --routines --events --user=$username --password=$password $DB0 > $LocalBackupPath\$ServerName-$DB0-$Date.sql "
	if($?)
	{
		Write-Host "$DB0 Backup Successful." -foregroundcolor black -backgroundcolor cyan
	}
	else
	{
		Write-Host "$DB0 Backup Failed." -foregroundcolor white -backgroundcolor red
	}
	
	cmd /c " `"$PathToMySQLDump`" --routines --events --user=$username --password=$password $DB1 > $LocalBackupPath\$ServerName-$DB1-$Date.sql "
	if($?)
	{
		Write-Host "$DB1 Backup Successful." -foregroundcolor black -backgroundcolor cyan
	}
	else
	{
		Write-Host "$DB1 Backup Failed." -foregroundcolor white -backgroundcolor red
	}

	cmd /c " `"$PathToMySQLDump`" --routines --events --user=$username --password=$password $DB2 > $LocalBackupPath\$ServerName-$DB2-$Date.sql "
	if($?)
	{
		Write-Host "$DB2 Backup Successful." -foregroundcolor black -backgroundcolor cyan
		}
	else
	{
		Write-Host "$DB2 Backup Failed." -foregroundcolor white -backgroundcolor red
	}
}

RunSQLDumps

if($?)
{
	Write-Host "INFO :  All backups completed at $LocalBackupPath." -foregroundcolor black -backgroundcolor cyan
}
else
{
	Write-Host "Backups failed. Check logs for more info." -foregroundcolor white -backgroundcolor red
}

# Scott McCutchen
# www.soverance.com

# #####################################################
#
# Since this script runs as a scheduled task, 
# these parameters are currently removed, with credentials hard-coded below,
# because I could not quickly figure out how to pass parameters through the task scheduler.
# 
# Talk about a script security flaw!
#
# To better secure this script, you can remove the hardcoded user info and replace it with parameters
# you'll then run this script manually, passing your MySQL login credentials as parameters
#
# Ex: ./RunWebBackup.ps1 -username $user -password $pass
#
#
#param (
#	[string]$username = $(throw "-username is required."),
#	[string]$password = $(Read-Host "Input password :")
#)

# #########################################################
# FILE COPY SECTION
# #########################################################

# Variables, only Change here
$Destination="S:\Backups\Files" # Copy the Files to this Location
$Versions="5" # How many of the last Backups you want to keep
$BackupDirs="\\SOV-WEB\WEB", "\\SOV-WEB\FTP" # What Folders you want to backup
$Log="Log.txt" # Log Name
$LoggingLevel="1" # LoggingLevel only for Output in Powershell Window, 1=smart, 3=Heavy

#STOP-no changes from here
#STOP-no changes from here
#Settings - do not change anything from here
$Backupdir=$Destination +"\Backup-"+ (Get-Date -format yyyy-MM-dd)+"\"
$Items=0
$Count=0
$ErrorCount=0
$StartDate=Get-Date #-format dd.MM.yyyy-HH:mm:ss

#FUNCTION
#Logging
Function Logging ($State, $Message) 
{
    $Datum=Get-Date -format dd.MM.yyyy-HH:mm:ss

    if (!(Test-Path -Path $Log)) {
        New-Item -Path $Log -ItemType File | Out-Null
    }
    $Text="$Datum - $State"+":"+" $Message"

    if ($LoggingLevel -eq "1" -and $Message -notmatch "was copied") {Write-Host $Text}
    elseif ($LoggingLevel -eq "3" -and $Message -match "was copied") {Write-Host $Text}
   
    add-Content -Path $Log -Value $Text
}
Logging "INFO" "----------------------"
Logging "INFO" "Start the Script"

#Create Backupdir
Function Create-Backupdir 
{
    Logging "INFO" "Create Backupdir $Backupdir"
    New-Item -Path $Backupdir -ItemType Directory | Out-Null

    Logging "INFO" "Move Log file to $Backupdir"
    Move-Item -Path $Log -Destination $Backupdir

    Set-Location $Backupdir
    Logging "INFO" "Continue with Log File at $Backupdir"
}

#Delete Backupdir
Function Delete-Backupdir 
{
    $Folder=Get-ChildItem $Destination | where {$_.Attributes -eq "Directory"} | Sort-Object -Property $_.LastWriteTime -Descending:$false | Select-Object -First 1

    Logging "INFO" "Remove Dir: $Folder"
    
    $Folder.FullName | Remove-Item -Recurse -Force 
}

#Check if Backupdirs and Destination is available
function Check-Dir 
{
    Logging "INFO" "Check if BackupDir and Destination exists"
    if (!(Test-Path $BackupDirs)) {
        return $false
        Logging "Error" "$BackupDirs does not exist"
    }
    if (!(Test-Path $Destination)) {
        return $false
        Logging "Error" "$Destination does not exist"
    }
}

#Save all the Files
Function Make-Backup 
{
    Logging "INFO" "Started the Backup"
    $Files=@()
    $SumMB=0
    $SumItems=0
    $SumCount=0
    $colItems=0
    Logging "INFO" "Count all files and create the Top Level Directories"

    foreach ($Backup in $BackupDirs) {
        $colItems = (Get-ChildItem $Backup -recurse | Where-Object {$_.mode -notmatch "h"} | Measure-Object -property length -sum) 
        $Items=0
        $FilesCount += Get-ChildItem $Backup -Recurse | Where-Object {$_.mode -notmatch "h"}  
        Copy-Item -Path $Backup -Destination $Backupdir -Force -ErrorAction SilentlyContinue
        $SumMB+=$colItems.Sum.ToString()
        $SumItems+=$colItems.Count
    }

    $TotalMB="{0:N2}" -f ($SumMB / 1MB) + " MB of Files"
    Logging "INFO" "There are $SumItems Files with  $TotalMB to copy"

    foreach ($Backup in $BackupDirs) {
        $Index=$Backup.LastIndexOf("\")
        $SplitBackup=$Backup.substring(0,$Index)
        $Files = Get-ChildItem $Backup -Recurse | Where-Object {$_.mode -notmatch "h"} 
        foreach ($File in $Files) {
            $restpath = $file.fullname.replace($SplitBackup,"")
            try {
                Copy-Item  $file.fullname $($Backupdir+$restpath) -Force -ErrorAction SilentlyContinue |Out-Null
                Logging "INFO" "$file was copied"
            }
            catch {
                $ErrorCount++
                Logging "ERROR" "$file returned an error an was not copied"
            }
            $Items += (Get-item $file.fullname).Length
            $status = "Copy file {0} of {1} and copied {3} MB of {4} MB: {2}" -f $count,$SumItems,$file.Name,("{0:N2}" -f ($Items / 1MB)).ToString(),("{0:N2}" -f ($SumMB / 1MB)).ToString()
            $Index=[array]::IndexOf($BackupDirs,$Backup)+1
            $Text="Copy data Location {0} of {1}" -f $Index ,$BackupDirs.Count
            Write-Progress -Activity $Text $status -PercentComplete ($Items / $SumMB*100)  
            if ($File.Attributes -ne "Directory") {$count++}
        }
    }
    $SumCount+=$Count
    $SumTotalMB="{0:N2}" -f ($Items / 1MB) + " MB of Files"
    Logging "INFO" "----------------------"
    Logging "INFO" "Copied $SumCount files with $SumTotalMB"
    Logging "INFO" "$ErrorCount Files could not be copied"
 }

#Check if Backupdir needs to be cleaned and create Backupdir
$Count=(Get-ChildItem $Destination | where {$_.Attributes -eq "Directory"}).count
Logging "INFO" "Check if there are more than $Versions Directories in the Backupdir"

if ($count -lt $Versions) 
{

    Create-Backupdir

} 
else {
    
    Delete-Backupdir

    Create-Backupdir
}

#Check if all Dir are existing and do the Backup
$CheckDir=Check-Dir

if ($CheckDir -eq $false) 
{
    Logging "ERROR" "One of the Directory are not available, Script has stopped"
} 
else {
    Make-Backup

    $Enddate=Get-Date #-format dd.MM.yyyy-HH:mm:ss
    $span = $EndDate - $StartDate
    $Minutes=$span.Minutes
    $Seconds=$Span.Seconds
    
    Logging "INFO" "Backupduration $Minutes Minutes and $Seconds Seconds"
    Logging "INFO" "----------------------"
    Logging "INFO" "----------------------" 
}

#Write-Host "Press any key to close ..."
#$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

# #########################################################
# DATABASE DUMP SECTION
# #########################################################

# Name of Server
$ServerName = [System.Net.Dns]::GetHostName()

# The Path to the mysqldump.exe program. This is the program that backs up the MySQL database natively.
$PathToMySQLDump = "C:\Program Files\MySQL\MySQL Server 5.7\bin\mysqldump.exe"

# Credentials of the MySQL user account
# Hardcode them here if necessary
#$username = "user"
#$password = "pass"

# Get today's date, to be used for naming purposes
$Date = (get-date).ToString('MM-dd-yyyy')

# Where to store the backup files
$LocalBackupPath = $Backupdir

# Databases to backup
$DB0 = "wp_multi"
$DB1 = "siegeapp"
$DB2 = "volunteer"

function RunSQLDumps ()
{
	# Backup all of the Databases
	cmd /c " `"$PathToMySQLDump`" --routines --events --user=$username --password=$password $DB0 > $LocalBackupPath\$ServerName-$DB0-$Date.sql "
	if($?)
	{
		Write-Host "$DB0 Backup Successful." -foregroundcolor black -backgroundcolor cyan
	}
	else
	{
		Write-Host "$DB0 Backup Failed." -foregroundcolor white -backgroundcolor red
	}
	
	cmd /c " `"$PathToMySQLDump`" --routines --events --user=$username --password=$password $DB1 > $LocalBackupPath\$ServerName-$DB1-$Date.sql "
	if($?)
	{
		Write-Host "$DB1 Backup Successful." -foregroundcolor black -backgroundcolor cyan
	}
	else
	{
		Write-Host "$DB1 Backup Failed." -foregroundcolor white -backgroundcolor red
	}

	cmd /c " `"$PathToMySQLDump`" --routines --events --user=$username --password=$password $DB2 > $LocalBackupPath\$ServerName-$DB2-$Date.sql "
	if($?)
	{
		Write-Host "$DB2 Backup Successful." -foregroundcolor black -backgroundcolor cyan
		}
	else
	{
		Write-Host "$DB2 Backup Failed." -foregroundcolor white -backgroundcolor red
	}
}

RunSQLDumps

# #########################################################
# ARCHIVE SECTION
# #########################################################

# The following sections will compress the backed-up files into a zip archive, and then move them into the GGDA FTP directory so that they can be downloaded at a later time by a Soverance server.
# This is basically a cheap, automated, "off-site" backup solution.

# Set the source directory to compress
$ArchiveSource = $Backupdir
$ArchiveDestination = $Destination +"\Backup-"+ (Get-Date -format yyyy-MM-dd)+".zip"

function RunArchiveCompression ()
{
    # The ZipFile .NET Framework class was introduced with .NET Framework 4.5, but requires the System.IO.Compression.FileSystem assembly, which is not loaded by default.
    # You may need to load the assembly using the Add-Type cmdlet before compressing files on some systems.
    Add-Type -AssemblyName "system.io.compression.filesystem"

    # Compress and Archive the backup directory
    [io.compression.zipfile]::CreateFromDirectory($ArchiveSource, $ArchiveDestination)
}

RunArchiveCompression

# Finally, move the archive into the FTP directory.
# A powershell script on a Soverance server will download this file at a later time for off-site storage.
Move-Item $ArchiveDestination \\GGDA-WEB\data-web\FTP\BackupArchives