# © 2017 BKV, Inc.
# Scott McCutchen
# www.bkv.com
# scott.mccutchen@bkv.com

# You must have the Azure Powershell Module installed to use this script,
# and have logged into your Azure subscription using the Login-AzureRmAccount command.
#Login-AzureRmAccount

# Creates a new Azure Resource Manager VM from a new or pre-existing VHD storage disk

# This script assumes you already have an ARM storage account and virtual network created

#########################################
#
# THIS SCRIPT HAS BEEN DEPRECATED, AND IT'S FUNCTIONALITY ROLLED INTO THE WindowsServer_ADForest DEPLOYMENT TEMPLATE
#
#########################################

# Initial Configuration
$location = "eastus"
$resourceGroup = "BKV-RM-DC-GROUP"
$vmName = "BKV-ARM-DC1"

# Create a new resource group for this purpose
New-AzureRmResourceGroup -Name $resourceGroup -Location $location
Write-Host "A new resource group was created called: " $resourceGroup

# create an Availability Set for this VM
# If an appropriate availability set already exists, use that one instead.
# Creating an Availability Set requires the AzureRM.Compute module
# See this help doc for more details:  https://docs.microsoft.com/en-us/azure/virtual-machines/windows/create-availability-set
$availabilityName = "BKV-DC-AvailabilitySet"
$availability = New-AzureRmAvailabilitySet -ResourceGroupName $resourceGroup -Name $availabilityName -Location $location
Write-Host "A new availability set was created called: " $availabilityName

$storage =  Get-AzureRmStorageAccount -AccountName "bkvrmstorage" -ResourceGroupName "rm-storage"
$virtualNetwork = Get-AzureRmVirtualNetwork -Name "BKV-RM-NET" -ResourceGroupName "BKV-RM-VPN-GROUP"
Write-Host "Initialization complete."

# create a new Public IP resource
Write-Host "Creating new Public IP..."
$ipName = "BKV-IP-" + $vmName
$publicIP = New-AzureRmPublicIpAddress -Name $ipName -ResourceGroupName $resourceGroup -Location $location -AllocationMethod Static
# Use the line below if you have already created a Public IP
#$publicIP = Get-AzureRmPublicIpAddress -Name $ipName -ResourceGroupName $resourceGroup
Write-Host "A new Public IP resource was created in" $resourceGroup 

# Create an inbound network security group rule for port 3389
$nsgRuleRDP = New-AzureRmNetworkSecurityRuleConfig -Name TableauSecurityGroupRuleRDP  -Protocol Tcp `
    -Direction Inbound -Priority 1000 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * `
    -DestinationPortRange 3389 -Access Allow
Write-Host "An RDP Rule to open port 3389 was created for the NIC."

# Create an inbound network security group rule for port 80
$nsgRuleWeb = New-AzureRmNetworkSecurityRuleConfig -Name TableauSecurityGroupRuleWWW  -Protocol Tcp `
    -Direction Inbound -Priority 1001 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * `
    -DestinationPortRange 80 -Access Allow
Write-Host "A WWW Rule to open port 80 was created for the NIC."

# Create a network security group
Write-Host "Creating new Network Interface..."
$nsg = New-AzureRmNetworkSecurityGroup -ResourceGroupName $resourceGroup -Location $location `
    -Name TableauSecurityGroup -SecurityRules $nsgRuleRDP,$nsgRuleWeb
Write-Host "A new Network Security Group resource was created in" $resourceGroup

# create a new Network Interface
Write-Host "Creating new Network Interface..."
$netInterfaceName = "BKV-NIC-" + $vmName
# The subnet ID must match the appropriate subnet within which you're attempting to provision this resource.  It cannot be the Gateway subnet.
$netInterface = New-AzureRmNetworkInterface -Name $netInterfaceName -ResourceGroupName $resourceGroup -Location $location -SubnetID $virtualNetwork.Subnets[1].Id -PublicIpAddressId $publicIP.Id -NetworkSecurityGroupId $nsg.Id
# Use the line below if you already have a Network Interface
#$netInterface = Get-AzureRmNetworkInterface -Name $netInterfaceName -ResourceGroupName $resourceGroup
Write-Host "A new Network Interface resource was created in" $resourceGroup

# Initial VM Configuration

$vmSize = "Standard_A1"
$vm = New-AzureRmVMConfig -VMName $vmName -VMSize $vmSize -AvailabilitySetId $availability.Id 
Write-Host "Virtual Machine provisioned as" $vmSize 

# Set Local Admin Credentials
$cred = Get-Credential -Message "Type the user name and password of the local administrator account."

# Operating System Config
$vm = Set-AzureRmVMOperatingSystem -VM $vm -Windows -ComputerName $vmName -Credential $cred -ProvisionVMAgent -EnableAutoUpdate
Write-Host "Operating System successfully initialized."

# configure this disk's operating system with a new OS image
$vm = Set-AzureRmVMSourceImage -VM $vm -PublisherName MicrosoftWindowsServer -Offer WindowsServer -Skus 2016-Datacenter -Version latest
Write-Host "OS configured as Windows Server 2016 Datacenter"

# Set Disk Configuration
$osDiskName = "BKV-ARM-DC1-OS-Disk"
$urlVHD = "https://bkvrmstorage.blob.core.windows.net/vhds/" + $osDiskName + ".vhd"
Write-Host "OS Disk configured."

# set URL of old VHD
#$urlVHD = "https://storage.blob.core.windows.net/ExistingDisk.vhd"
#Write-Host "Source VHD set to " $urlVHD

# Add OS Disk to VM
# use -CreateOption Attach if you're using an existing VHD
$vm = Set-AzureRmVMOSDisk -VM $vm -Name $osDiskName -VhdUri $urlVHD -CreateOption FromImage -Windows -Caching 'ReadWrite'
Write-Host "OS Disk added to VM."

# Add network interface to VM
$vm = Add-AzureRmVMNetworkInterface -VM $vm -Id $netInterface.Id
Write-Host "Network Interface" $netInterfaceName "has been applied to the VM."

$result = New-AzureRmVM -ResourceGroupName $resourceGroup -Location $location -VM $vm 
$result

# Occasionally you may need to add one of these resources to an already existing VM
# If so, you may need to run the Update-AzureRmVM function