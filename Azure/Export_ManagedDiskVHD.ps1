# © 2018 Soverance Studios
# Scott McCutchen
# scott.mccutchen@soverance.com

# get the list of your managed disks
Get-AzureRmDisk | ft ResourceGroupName, Name, DiskSizeGB

# Grant access to the disk
$sas = Grant-AzureRmDiskAccess -ResourceGroupName LINUXVM -DiskName test -DurationInSecond 3600 -Access Read

# Get storage account context
$destContext = New-AzureStorageContext –StorageAccountName accountName -StorageAccountKey 'Key'

# Start copy
$copyBlob = start-AzureStorageBlobCopy -AbsoluteUri $sas.AccessSAS -DestContainer target -DestContext $destContext -DestBlob my.vhd

# Check copy status
$copyBlob | Get-AzureStorageBlobCopyState