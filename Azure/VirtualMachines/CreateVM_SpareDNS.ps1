# © 2018 Soverance Studios
# Scott McCutchen
# scott.mccutchen@soverance.com

# You must have the Azure Powershell Module installed to use this script,
# and have logged into your Azure subscription using the Login-AzureRmAccount command.
#Login-AzureRmAccount

# Creates a new Azure Resource Manager VM from a new or pre-existing VHD storage disk

# This script assumes you already have an ARM storage account and virtual network created

# Initial Configuration
$location = "East US"
$resourceGroup = "UA-Domain"
$vmName = "UA-SpareDNS"

$storage =  Get-AzureRmStorageAccount -AccountName "unifiedstorage" -ResourceGroupName "UA-Domain"
$virtualNetwork = Get-AzureRmVirtualNetwork -Name "UA-NET" -ResourceGroupName "UA-Domain"

# create a new Network Interface
$netInterfaceName = "ua-sparedns888"
$netInterface = Get-AzureRmNetworkInterface -Name $netInterfaceName -ResourceGroupName $resourceGroup

# Initial VM Configuration

$vmSize = "Standard_A2_V2"
$vm = New-AzureRmVMConfig -VMName $vmName -VMSize $vmSize
Write-Host "Virtual Machine provisioned as" $vmSize 

# Set Disk Configuration
$osDiskName = "UA-SpareDNS20170809130434"
#$urlVHD = "https://unifiedstorage.blob.core.windows.net/vhds/" + $osDiskName + ".vhd"
#Write-Host "OS Disk configured."

# set URL of old VHD
$urlVHD = "https://unifiedstorage.blob.core.windows.net/vhds/UA-SpareDNS20170809130434.vhd"
Write-Host "Source VHD set to " $urlVHD

# Add OS Disk to VM
# use -CreateOption Attach if you're using an existing VHD
$vm = Set-AzureRmVMOSDisk -VM $vm -Name $osDiskName -VhdUri $urlVHD -CreateOption Attach -Windows -Caching 'ReadWrite'
Write-Host "OS Disk added to VM."

# Add network interface to VM
$vm = Add-AzureRmVMNetworkInterface -VM $vm -Id $netInterface.Id
Write-Host "Network Interface" $netInterfaceName "has been applied to the VM."

$result = New-AzureRmVM -ResourceGroupName $resourceGroup -Location $location -VM $vm 
$result
