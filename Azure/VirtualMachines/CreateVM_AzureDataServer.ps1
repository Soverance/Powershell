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
$resourceGroup = "UA-AzureDataServer"
$vmName = "AzureDataServer"

$storage =  Get-AzureRmStorageAccount -AccountName "azuredataserver" -ResourceGroupName "UA-AzureDataServer"
$virtualNetwork = Get-AzureRmVirtualNetwork -Name "UA-NET" -ResourceGroupName "UA-Domain"
$subnet = Get-AzureRmVirtualNetworkSubnetConfig -Name "SQL-Subnet" -VirtualNetwork $virtualNetwork
# create a new Public IP resource
Write-Host "Creating new Public IP..."
$ipName = "UA-PIP-AzureDataServer"
$publicIP = New-AzureRmPublicIpAddress -Name $ipName -ResourceGroupName $resourceGroup -Location $location -AllocationMethod Static
Write-Host "A new Public IP resource was created in" $resourceGroup

# get network security group
$nsg = Get-AzureRmNetworkSecurityGroup -ResourceGroupName UA-Domain -Name UA-NET-SecurityGroup

# create a new Network Interface
Write-Host "Creating new Network Interface..."
$netInterfaceName = "UA-NIC-AzureDataServer"
$IPconfig = New-AzureRmNetworkInterfaceIpConfig -Name "AzureDataServerIPConfig" -PrivateIpAddressVersion IPv4 -PrivateIpAddress "172.16.0.6" -Subnet $subnet -PublicIpAddress $publicIP
# The subnet ID must match the appropriate subnet within which you're attempting to provision this resource.  It cannot be the Gateway subnet.
$netInterface = New-AzureRmNetworkInterface -Name $netInterfaceName -ResourceGroupName $resourceGroup -Location $location -NetworkSecurityGroupId $nsg.Id -IpConfiguration $IPconfig
#-SubnetID $virtualNetwork.Subnets[2].Id -PublicIpAddressId $publicIP.Id -NetworkSecurityGroupId $nsg.Id -IpConfiguration $IPconfig
# Use the line below if you already have a Network Interface
Write-Host "A new Network Interface resource was created in" $resourceGroup

# Initial VM Configuration

$vmSize = "Standard_A4m_V2"
$vm = New-AzureRmVMConfig -VMName $vmName -VMSize $vmSize
Write-Host "Virtual Machine provisioned as" $vmSize 


# Set Disk Configuration
$osDiskName = "AzureDataServer-AzureDataServer-2014-09-05"
#$urlVHD = "https://unifiedstorage.blob.core.windows.net/vhds/" + $osDiskName + ".vhd"
#Write-Host "OS Disk configured."

# set URL of old VHD
$urlVHD = "https://azuredataserver.blob.core.windows.net/vhds/AzureDataServer-AzureDataServer-2014-09-05.vhd"
Write-Host "Source VHD set to " $urlVHD

# Add OS Disk to VM
# use -CreateOption Attach if you're using an existing VHD
$vm = Set-AzureRmVMOSDisk -VM $vm -Name $osDiskName -VhdUri $urlVHD -CreateOption Attach -Windows -Caching 'ReadWrite'
Write-Host "OS Disk added to VM."

# Add network interface to VM
$vm = Add-AzureRmVMNetworkInterface -VM $vm -Id $netInterface.Id
Write-Host "Network Interface" $netInterfaceName "has been applied to the VM."

$vm = Add-AzureRmVMDataDisk -VM $vm -Name "AzureDataServer-StorageDisk1" -VhdUri "https://azuredataserver.blob.core.windows.net/vhds/AzureDataServer-StorageDisk1.vhd" -LUN 1 -Caching 'ReadWrite' -CreateOption Attach -DiskSizeInGB 1023
$vm = Add-AzureRmVMDataDisk -VM $vm -Name "AzureDataServer-StorageDisk2" -VhdUri "https://azuredataserver.blob.core.windows.net/vhds/AzureDataServer-StorageDisk2.vhd" -LUN 2 -Caching 'ReadWrite' -CreateOption Attach -DiskSizeInGB 1023
$vm = Add-AzureRmVMDataDisk -VM $vm -Name "AzureDataServer-AzureDataServer-1013-client01" -VhdUri "https://azuredataserver.blob.core.windows.net/vhds/AzureDataServer-AzureDataServer-1013-client01.vhd" -LUN 3 -Caching 'ReadWrite' -CreateOption Attach -DiskSizeInGB 1023     
$vm = Add-AzureRmVMDataDisk -VM $vm -Name "AzureDataServer-StorageDisk4" -VhdUri "https://azuredataserver.blob.core.windows.net/vhds/AzureDataServer-StorageDisk4.vhd" -LUN 4 -Caching 'ReadWrite' -CreateOption Attach -DiskSizeInGB 1023
$vm = Add-AzureRmVMDataDisk -VM $vm -Name "AzureDataServer-StorageDisk5" -VhdUri "https://azuredataserver.blob.core.windows.net/vhds/AzureDataServer-StorageDisk5.vhd" -LUN 5 -Caching 'ReadWrite' -CreateOption Attach -DiskSizeInGB 1023
$vm = Add-AzureRmVMDataDisk -VM $vm -Name "AzureDataServer-StorageDisk6" -VhdUri "https://azuredataserver.blob.core.windows.net/vhds/AzureDataServer-StorageDisk6.vhd" -LUN 6 -Caching 'ReadWrite' -CreateOption Attach -DiskSizeInGB 1023
$vm = Add-AzureRmVMDataDisk -VM $vm -Name "AzureDataServer-StorageDisk7" -VhdUri "https://azuredataserver.blob.core.windows.net/vhds/AzureDataServer-StorageDisk7.vhd" -LUN 0 -Caching 'ReadWrite' -CreateOption Attach -DiskSizeInGB 1023
$vm = Add-AzureRmVMDataDisk -VM $vm -Name "AzureDataServer-StorageDisk8-TempDB1" -VhdUri "https://azuredataserver.blob.core.windows.net/vhds/AzureDataServer-StorageDisk8-TempDB1.vhd" -LUN 7 -Caching 'ReadWrite' -CreateOption Attach -DiskSizeInGB 1023

$result = New-AzureRmVM -ResourceGroupName $resourceGroup -Location $location -VM $vm 
$result
