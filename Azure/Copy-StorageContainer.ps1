# © 2017 BKV, Inc.
# Scott McCutchen
# www.bkv.com
# scott.mccutchen@bkv.com

# You must have the Azure Powershell Module installed to use this script,
# and have logged into your Azure subscription using the Login-AzureRmAccount command.
#Login-AzureRmAccount

# This script copys an Azure storage container from one to another.
# If the container you wish to copy contains VHDs for currently active virtual machines, they must be stopped before this script will execute successfully (you cannot copy VHDs while in use)
# Using the Start-CopyAzureStorageBlob cmdlet is great, because it utilizes Azure's asynchronous server-side copy capability.

$SourceStorageAccount = "unifiedstorage"
$SourceStorageKey = "46hZL55fSU2EQbEPB6se59T5p4TZJQ03N1jAcS34XhFDXI2x24X1ZExCGzS4Wzc1fWoBaHCmAMnWq/nD8071Og=="
$DestStorageAccount = "bkvlampteststorage"
$DestStorageKey = "7m/hxVvd4E8bv2icRF8xWO8u9QLjKclKj1LgXdXMj/zhM/RfMVeQVzEUz4iFHjuhPJMZ4qcXIi7/6/SJ3iCdbg=="
$SourceStorageContainer = 'vhds'
$DestStorageContainer = 'vhds'

# configure source and destination storage contexts
$SourceStorageContext = New-AzureStorageContext –StorageAccountName $SourceStorageAccount -StorageAccountKey $SourceStorageKey
$DestStorageContext = New-AzureStorageContext –StorageAccountName $DestStorageAccount -StorageAccountKey $DestStorageKey

# Reference the blobs in the source storage container
$Blobs = Get-AzureStorageBlob -Context $SourceStorageContext -Container $SourceStorageContainer
# Create empty array of objects
$BlobCpyAry = @() 

# Start copy process
foreach ($Blob in $Blobs)
{
   Write-Output "Moving $Blob.Name"
   # Copy blob from source container to destination container
   $BlobCopy = Start-CopyAzureStorageBlob -Context $SourceStorageContext -SrcContainer $SourceStorageContainer -SrcBlob $Blob.Name -DestContext $DestStorageContext -DestContainer $DestStorageContainer -DestBlob $Blob.Name -Force
   # add the process to the status array
   $BlobCpyAry += $BlobCopy
}

# Check Status
foreach ($BlobCopy in $BlobCpyAry)
{
   # Get the current process state
   $status = $BlobCopy | Get-AzureStorageBlobCopyState
   # output human readable process

   ### Loop until complete ###                                    
   While($status.Status -eq "Pending"){
     $status = $BlobCopy | Get-AzureStorageBlobCopyState 
     Start-Sleep 10
     $Message = $status.Source.AbsolutePath + " " + $status.Status + " {0:N2}%" -f (($status.BytesCopied/$status.TotalBytes)*100) 
     Write-Output $Message
   }   
}