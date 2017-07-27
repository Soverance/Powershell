# © 2017 BKV, Inc.
# Scott McCutchen
# www.bkv.com
# scott.mccutchen@bkv.com

# This script runs an automated backup of Tableau server.

$TableauBinDir = "C:\Program Files\Tableau\Tableau Server\10.3\bin"
$TableauBackupDir = "C:\Program Files\Tableau\Tableau Server\Backup"
$TableauBackupWithFileName = $TableauBackupDir + "\TableauBackup"
$ExpirationDate = (Get-Date).AddDays(-15) #backups are deleted after expiration

cd $TableauBinDir

# Runs the Tableau backup command with the following optional params:
# -d, to append the date to the file name
# -v, to verify the backup once complete
# -t, to specify the location of temp files during the backup process
# This is piped together with Out-Null cmdlet to force Powershell to wait until this process completes before starting the upload process
./tabadmin backup $TableauBackupWithFileName -d -v -t $TableauBackupDir | Out-Null

# Upload the backups into an Azure Storage Blob for safe keeping
$StorageAccount = "your-storage-account-name"
$StorageKey = "your-storage-key"
$StorageContainer = 'your-storage-container-name'
# Set the Azure Storage Context
$StorageContext = New-AzureStorageContext –StorageAccountName $StorageAccount -StorageAccountKey $StorageKey

# From the local folder, remove all backups older than 15 days - we don't care about old data!
Get-ChildItem -Path $TableauBackupDir -Recurse -File | Where LastWriteTime -lt $ExpirationDate | Remove-Item -Force

# Get all items in local backup dir
$backups = Get-ChildItem $TableauBackupDir 
# loop through them
foreach($file in $backups)
{
    $FileName = "$TableauBackupDir\$file"
    $BlobName = "$file"
    # upload blob
    Set-AzureStorageBlobContent -File $Filename -Container $StorageContainer -Blob $BlobName -Context $StorageContext -Force
}

# Clean the Azure Storage Container of all stale data
Get-AzureStorageBlob -Context $StorageContext -Container $StorageContainer | Where LastWriteTime -lt $ExpirationDate | Remove-AzureStorageBlob -Force