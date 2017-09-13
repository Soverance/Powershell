# © 2017 BKV, Inc.
# Scott McCutchen
# www.bkv.com
# scott.mccutchen@bkv.com

# You must have the Azure Powershell Module installed to use this script,
# and have logged into your Azure subscription using the Login-AzureRmAccount command.
#Login-AzureRmAccount

# Initial Configuration
$location = "East US"
$resourceGroup = "UA-VeeamRepo"
$vmName = "UA-VeeamRepo"

# Create a new resource group for this purpose
New-AzureRmResourceGroup -Name $resourceGroup -Location $location

#$storage = New-AzureRmStorageAccount -ResourceGroupName $resourceGroup -Name "unifiedveeamstorage" -Location $location -SkuName Standard_LRS
$virtualNetwork = Get-AzureRmVirtualNetwork -Name "UA-NET" -ResourceGroupName "UA-Domain"

# create a new Public IP resource
Write-Host "Creating new Public IP..."
$ipName = "UA-PIP-VeeamRepo"
$publicIP = New-AzureRmPublicIpAddress -Name $ipName -ResourceGroupName $resourceGroup -Location $location -AllocationMethod Static

# NETWORK SECURITY GROUP FEATURES HAVE ALREADY BEEN CREATED FOR UA DOMAIN
$nsg = Get-AzureRmNetworkSecurityGroup -Name "UA-NET-SecurityGroup" -ResourceGroupName "UA-Domain"

# create a new Network Interface
Write-Host "Creating new Network Interface..."
$netInterfaceName = "UA-NIC-VeeamRepo"
# The subnet ID must match the appropriate subnet within which you're attempting to provision this resource.  It cannot be the Gateway subnet.
$netInterface = New-AzureRmNetworkInterface -Name $netInterfaceName -ResourceGroupName $resourceGroup -Location $location -SubnetID $virtualNetwork.Subnets[0].Id -PublicIpAddressId $publicIP.Id -NetworkSecurityGroupId $nsg.Id

# Initial VM Configuration
$vmSize = "Standard_A4_V2"
$vm = New-AzureRmVMConfig -VMName $vmName -VMSize $vmSize

# Set Local Admin Credentials
# default local admin for all UA machines is user= AzureAdmin, pass= Andromeda00
# THIS IS NOT A DOMAIN-JOINED ACCOUNT.  IT IS THE LOCAL ADMIN!
$cred = Get-Credential -Message "Type the user name and password of the local administrator account."

# Operating System Config
$vm = Set-AzureRmVMOperatingSystem -VM $vm -Windows -ComputerName $vmName -Credential $cred -ProvisionVMAgent -EnableAutoUpdate

# configure this disk's operating system with a new OS image
$vm = Set-AzureRmVMSourceImage -VM $vm -PublisherName MicrosoftWindowsServer -Offer WindowsServer -Skus 2016-Datacenter -Version latest

# Set Disk Configuration
$osDiskName = "VeeamRepo-OS-Disk"
#$osdiskconfig = New-AzureRmDiskConfig -AccountType StandardLRS -Location $location -CreateOption Empty -DiskSizeGB 128
#$osdisk = New-AzureRmDisk -DiskName $osDiskName -Disk $osdiskconfig -ResourceGroupName $resourceGroup

# Add a managed OS Disk to VM
$vm = Set-AzureRmVMOSDisk -VM $vm -Name $osDiskName -CreateOption FromImage -Windows -Caching 'ReadWrite' -DiskSizeInGB 128 

#  create a managed disk configuration
$datadiskconfig = New-AzureRmDiskConfig -AccountType StandardLRS -Location $location -CreateOption Empty -DiskSizeGB 4095 

# create managed data disks
$datadiskname0 = "VeeamRepo-DataDisk-0"
$datadisk0 = New-AzureRmDisk -DiskName $datadiskname0 -Disk $datadiskconfig -ResourceGroupName $resourceGroup
$datadiskname1 = "VeeamRepo-DataDisk-1"
$datadisk1 = New-AzureRmDisk -DiskName $datadiskname1 -Disk $datadiskconfig -ResourceGroupName $resourceGroup 

$vm = Add-AzureRmVMDataDisk -VM $vm -Name $datadiskname0 -CreateOption Attach -Lun 2 -DiskSizeInGB 4095 -ManagedDiskId $datadisk0.Id
$vm = Add-AzureRmVMDataDisk -VM $vm -Name $datadiskname1 -CreateOption Attach -Lun 3 -DiskSizeInGB 4095 -ManagedDiskId $datadisk1.Id

# Add network interface to VM
$vm = Add-AzureRmVMNetworkInterface -VM $vm -Id $netInterface.Id

$vm = Set-AzureRmVMBootDiagnostics -VM $vm -Enable -ResourceGroupName "UA-Domain" -StorageAccountName "unifiedstorage"

# Create the Virtual Machine
$result = New-AzureRmVM -ResourceGroupName $resourceGroup -Location $location -VM $vm 
# Display Results
$result