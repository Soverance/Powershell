# © 2017 BKV, Inc.
# Scott McCutchen
# www.bkv.com
# scott.mccutchen@bkv.com

# You must have the Azure Powershell Module installed to use this script,
# and have logged into your Azure subscription using the Login-AzureRmAccount command.
#Login-AzureRmAccount

# Initial Configuration
$location = "East US"
$resourceGroup = "UA-ADConnect"
$vmName = "UA-ADConnect"

# Create a new resource group for this purpose
New-AzureRmResourceGroup -Name $resourceGroup -Location $location
Write-Host "A new resource group was created called: " $resourceGroup

$storage = New-AzureRmStorageAccount -ResourceGroupName $resourceGroup -Name "adconnectstorage" -Location $location -SkuName Standard_LRS
$virtualNetwork = Get-AzureRmVirtualNetwork -Name "UA-NET" -ResourceGroupName "UA-Domain"
Write-Host "A new storage account was created -" $storage.Name

# create a new Public IP resource
Write-Host "Creating new Public IP..."
$ipName = "UA-PIP-ADConnect"
$publicIP = New-AzureRmPublicIpAddress -Name $ipName -ResourceGroupName $resourceGroup -Location $location -AllocationMethod Static
Write-Host "A new Public IP resource was created in" $resourceGroup

# NETWORK SECURITY GROUP FEATURES HAVE ALREADY BEEN CREATED FOR UA DOMAIN
$nsg = Get-AzureRmNetworkSecurityGroup -Name "UA-NET-SecurityGroup" -ResourceGroupName "UA-Domain"

# create a new Network Interface
Write-Host "Creating new Network Interface..."
$netInterfaceName = "UA-NIC-ADConnect"
# The subnet ID must match the appropriate subnet within which you're attempting to provision this resource.  It cannot be the Gateway subnet.
$netInterface = New-AzureRmNetworkInterface -Name $netInterfaceName -ResourceGroupName $resourceGroup -Location $location -SubnetID $virtualNetwork.Subnets[0].Id -PublicIpAddressId $publicIP.Id -NetworkSecurityGroupId $nsg.Id
Write-Host "A new Network Interface resource was created in" $resourceGroup

# Initial VM Configuration
$vmSize = "Standard_A1_V2"
$vm = New-AzureRmVMConfig -VMName $vmName -VMSize $vmSize
Write-Host "Virtual Machine provisioned as" $vmSize 

# Set Local Admin Credentials
# default local admin for all UA machines is user= AzureAdmin, pass= Andromeda00
# THIS IS NOT A DOMAIN-JOINED ACCOUNT.  IT IS THE LOCAL ADMIN!
$cred = Get-Credential -Message "Type the user name and password of the local administrator account."

# Operating System Config
$vm = Set-AzureRmVMOperatingSystem -VM $vm -Windows -ComputerName $vmName -Credential $cred -ProvisionVMAgent -EnableAutoUpdate
Write-Host "Operating System successfully initialized."

# configure this disk's operating system with a new OS image
$vm = Set-AzureRmVMSourceImage -VM $vm -PublisherName MicrosoftWindowsServer -Offer WindowsServer -Skus 2016-Datacenter -Version latest
Write-Host "OS configured as Windows Server 2016 Datacenter"

# Set Disk Configuration
$osDiskName = "ADConnect-OS-Disk"
$urlVHD = "https://adconnectstorage.blob.core.windows.net/vhds/" + $osDiskName + ".vhd"
Write-Host "OS Disk configured."

# Add OS Disk to VM
# use -CreateOption Attach if you're using an existing VHD
$vm = Set-AzureRmVMOSDisk -VM $vm -Name $osDiskName -VhdUri $urlVHD -CreateOption FromImage -Windows -Caching 'ReadWrite'
Write-Host "OS Disk added to VM."

# Add network interface to VM
$vm = Add-AzureRmVMNetworkInterface -VM $vm -Id $netInterface.Id
Write-Host "Network Interface" $netInterfaceName "has been applied to the VM."

# Create the Virtual Machine
$result = New-AzureRmVM -ResourceGroupName $resourceGroup -Location $location -VM $vm 
# Display Results
$result
