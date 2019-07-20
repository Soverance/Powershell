# © 2018 Soverance Studios
# Scott McCutchen
# scott.mccutchen@soverance.com

# You must have the Azure Powershell Module installed to use this script,
# and have logged into your Azure subscription using the Login-AzureRmAccount command.
#Login-AzureRmAccount

# Initial Configuration
$location = "East US"
$resourceGroup = "SovNet"
$vmName = "SOV-WEB"

# Create a new resource group for this purpose
New-AzureRmResourceGroup -Name $resourceGroup -Location $location
Write-Host "A new resource group was created called: " $resourceGroup

$storage = New-AzureRmStorageAccount -ResourceGroupName $resourceGroup -Name "sovazurestorage" -Location $location -SkuName Standard_LRS
Write-Host "A new storage account was created -" $storage.Name

$subnet0 = New-AzureRmVirtualNetworkSubnetConfig -Name "AzureSubnet" -AddressPrefix 10.0.0.0/24
$virtualNetwork = New-AzureRmVirtualNetwork -Name "SOV-NET" -ResourceGroupName $resourceGroup -AddressPrefix 10.0.0.0/16 -Location $location -Subnet $subnet0
Write-Host "A new subnet was added to the SOV-NET cloud network with ID -" $subnet.Id

# create a new Public IP resource
Write-Host "Creating new Public IP..."
$ipName = "SOV-PIP-WEB"
$publicIP = New-AzureRmPublicIpAddress -Name $ipName -ResourceGroupName $resourceGroup -Location $location -AllocationMethod Static
Write-Host "A new Public IP resource was created in" $resourceGroup

# Create an inbound network security group rule for port 3389
$nsgRuleRDP = New-AzureRmNetworkSecurityRuleConfig -Name SovNet-AllowRDP  -Protocol Tcp `
    -Direction Inbound -Priority 1000 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * `
    -DestinationPortRange 3389 -Access Allow
Write-Host "An RDP Rule to open port 3389 was created for the NIC."

# Create an inbound network security group rule for port 80
$nsgRuleHTTP = New-AzureRmNetworkSecurityRuleConfig -Name SovNet-AllowHTTP  -Protocol Tcp `
    -Direction Inbound -Priority 1001 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * `
    -DestinationPortRange 80 -Access Allow
Write-Host "A HTTP Rule to open port 80 was created for the NIC."

# Create an inbound network security group rule for port 443
$nsgRuleHTTPS = New-AzureRmNetworkSecurityRuleConfig -Name SovNet-AllowHTTPS  -Protocol Tcp `
    -Direction Inbound -Priority 1002 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * `
    -DestinationPortRange 443 -Access Allow
Write-Host "A HTTPS Rule to open port 443 was created for the NIC."

# Create an inbound network security group rule for port 1666
$nsgRulePerforce = New-AzureRmNetworkSecurityRuleConfig -Name SovNet-AllowPerforce  -Protocol Tcp `
    -Direction Inbound -Priority 1003 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * `
    -DestinationPortRange 1666 -Access Allow
Write-Host "A Perforce Rule to open port 1666 was created for the NIC."

# Create a network security group 
Write-Host "Creating new Network Security Group..."
$nsgName = "SOV-NET-SecurityGroup"
$nsg = New-AzureRmNetworkSecurityGroup -ResourceGroupName $resourceGroup -Location $location -Name $nsgName -SecurityRules $nsgRuleRDP,$nsgRuleHTTP,$nsgRuleHTTPS,$nsgRulePerforce
Write-Host "A new Network Security Group resource was created in $($resourceGroup) with the ID: $($nsg.Id)"

# create a new Network Interface
Write-Host "Creating new Network Interface..."
$netInterfaceName = "SOV-NIC-WEB"
# The subnet ID must match the appropriate subnet within which you're attempting to provision this resource.  It cannot be the Gateway subnet.
#$IPconfig = New-AzureRmNetworkInterfaceIpConfig -Name "SOV-WEB-IPconfig" -PrivateIpAddressVersion IPv4 -PrivateIpAddress "172.16.0.4" -SubnetId $subnet.Id -PublicIpAddressId $publicIP.Id
$netInterface = New-AzureRmNetworkInterface -Name $netInterfaceName -ResourceGroupName $resourceGroup -Location $location -SubnetID $virtualNetwork.Subnets[0].Id -PublicIpAddressId $publicIP.Id -NetworkSecurityGroupId $nsg.Id
Write-Host "A new Network Interface resource was created in" $resourceGroup

# Initial VM Configuration
$vmSize = "Standard_B2ms"
$vm = New-AzureRmVMConfig -VMName $vmName -VMSize $vmSize
Write-Host "Virtual Machine provisioned as" $vmSize 

# Set Local Admin Credentials
# THIS IS NOT A DOMAIN-JOINED ACCOUNT.  IT IS THE LOCAL ADMIN!
$cred = Get-Credential -Message "Type the user name and password of the local administrator account."

# Operating System Config
$vm = Set-AzureRmVMOperatingSystem -VM $vm -Windows -ComputerName $vmName -Credential $cred -ProvisionVMAgent -EnableAutoUpdate
Write-Host "Operating System successfully initialized."

# configure this disk's operating system with a new OS image
$vm = Set-AzureRmVMSourceImage -VM $vm -PublisherName MicrosoftWindowsServer -Offer WindowsServer -Skus 2016-Datacenter-Server-Core -Version 2016.127.20170918
#$image = Get-AzureRmVMImage -Location $location -PublisherName MicrosoftWindowsServer -Offer WindowsServer -Skus 2016-Datacenter-Server-Core -Version 2016.127.20170918
Write-Host "OS configured as Windows Server 2016 Datacenter version 2016.127.20170918"

# Set Disk Configuration
$osDiskName = "SOV-WEB-OS-Disk"
# for whatever reason, these B-series VMs dont seem to deploy correctly with 32 or 64 GB OS disks - ErrorMessage: Disks or snapshot cannot be resized down.
# however, it does work with a 128 GB disk.  Maybe this will change when B-series leaves preview?
$osDiskSize = 128
#$osDiskConfig = New-AzureRmDiskConfig -AccountType StandardLRS -Location $location -CreateOption FromImage -DiskSizeGB 32 -OsType Windows
#$osDiskConfig = Set-AzureRmDiskImageReference -Disk $osDiskConfig -Id $image.Id -Lun 0
#$osDisk = New-AzureRmDisk -DiskName $osDiskName -Disk $osDiskConfig -ResourceGroupName $resourceGroup
#Write-Host "OS Disk configured."

# Add OS Disk to VM -CreateOption FromImage -Windows -Caching 'ReadWrite' -DiskSizeInGB 32 
$vm = Set-AzureRmVMOSDisk -VM $vm -Name $osDiskName -CreateOption FromImage -Windows -Caching 'ReadWrite' -DiskSizeInGB $osDiskSize -StorageAccountType PremiumLRS
Write-Host "$($osDiskSize) GB Managed OS Disk added to VM."

# Add network interface to VM
$vm = Add-AzureRmVMNetworkInterface -VM $vm -Id $netInterface.Id

$vm = Set-AzureRmVMBootDiagnostics -VM $vm -Enable -ResourceGroupName $resourceGroup -StorageAccountName "sovazurestorage"

# Create the Virtual Machine
$result = New-AzureRmVM -ResourceGroupName $resourceGroup -Location $location -VM $vm 
# Display Results
$result
