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
$PathToMySQLDump = "C:\MySQL\5.7\bin\mysqldump.exe"

# Credentials of the MySQL user account


# Get today's date, to be used for naming purposes
$Date = (get-date).ToString('MM-dd-yyyy')

# Where to store the backup files
$LocalBackupPath = "C:\WEB\studio\"

# Databases to backup
$DB0 = "soverance.com"

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


