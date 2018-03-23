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
$resourceGroup = "SovCloud"
$vmName = "SovCloud"

$storage =  Get-AzureRmStorageAccount -AccountName "soverancecloud" -ResourceGroupName $resourceGroup
$virtualNetwork = Get-AzureRmVirtualNetwork -Name "SovCloudNet" -ResourceGroupName $resourceGroup
$subnet = Get-AzureRmVirtualNetworkSubnetConfig -Name "SovCloudSubnet" -VirtualNetwork $virtualNetwork
# create a new Public IP resource
Write-Host "Creating new Public IP..."
$ipName = "SOV-PIP-Cloud"
$publicIP = New-AzureRmPublicIpAddress -Name $ipName -ResourceGroupName $resourceGroup -Location $location -AllocationMethod Static
Write-Host "A new Public IP resource was created in" $resourceGroup

# Create an inbound network security group rule for port 3389
$nsgRuleRDP = New-AzureRmNetworkSecurityRuleConfig -Name SovCloudRule-RDP  -Protocol Tcp `
    -Direction Inbound -Priority 1000 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * `
    -DestinationPortRange 3389 -Access Allow
Write-Host "An RDP Rule to open port 3389 was created for the NSG."

# Create an inbound network security group rule for port 80
$nsgRuleHTTP = New-AzureRmNetworkSecurityRuleConfig -Name SovCloudRule-HTTP  -Protocol Tcp `
    -Direction Inbound -Priority 1001 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * `
    -DestinationPortRange 80 -Access Allow
Write-Host "A HTTP Rule to open port 80 was created for the NSG."

# Create an inbound network security group rule for port 443
$nsgRuleHTTPS = New-AzureRmNetworkSecurityRuleConfig -Name SovCloudRule-HTTPS  -Protocol Tcp `
    -Direction Inbound -Priority 1002 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * `
    -DestinationPortRange 443 -Access Allow
Write-Host "A HTTPS Rule to open port 443 was created for the NSG."

# Create an inbound network security group rule for port 1666
$nsgRuleP4 = New-AzureRmNetworkSecurityRuleConfig -Name SovCloudRule-P4  -Protocol Tcp `
    -Direction Inbound -Priority 1003 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * `
    -DestinationPortRange 1666 -Access Allow
Write-Host "A P4 Rule to open port 1666 was created for the NSG."

# Create an inbound network security group rule for port 8172
$nsgRuleIIS = New-AzureRmNetworkSecurityRuleConfig -Name SovCloudRule-IIS  -Protocol Tcp `
    -Direction Inbound -Priority 1004 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * `
    -DestinationPortRange 8172 -Access Allow
Write-Host "A IIS Rule to open port 8172 was created for the NSG."

# Create an inbound network security group rule for port 21
$nsgRuleFTP = New-AzureRmNetworkSecurityRuleConfig -Name SovCloudRule-FTP  -Protocol Tcp `
    -Direction Inbound -Priority 1005 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * `
    -DestinationPortRange 21 -Access Allow
Write-Host "A FTP Rule to open port 21 was created for the NSG."

# Create an inbound network security group rule for Passive FTP ports
$nsgRulePassiveFTP = New-AzureRmNetworkSecurityRuleConfig -Name SovCloudRule-PassiveFTP  -Protocol Tcp `
    -Direction Inbound -Priority 1006 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * `
    -DestinationPortRange 1041-1045 -Access Allow
Write-Host "A Passive FTP Rule to open port 1041-1045 was created for the NSG."

# Create a network security group
Write-Host "Creating new Network Interface..."
$nsg = New-AzureRmNetworkSecurityGroup -ResourceGroupName $resourceGroup -Location $location `
    -Name SovCloudSecurityGroup -SecurityRules $nsgRuleRDP,$nsgRuleHTTP,$nsgRuleHTTPS,$nsgRuleP4,$nsgRuleIIS,$nsgRuleFTP,$nsgRulePassiveFTP
Write-Host "A new Network Security Group resource was created in" $resourceGroup

# create a new Network Interface
Write-Host "Creating new Network Interface..."
$netInterfaceName = "SOV-NIC-Cloud"
$IPconfig = New-AzureRmNetworkInterfaceIpConfig -Name "SovCloudIPConfig" -PrivateIpAddressVersion IPv4 -PrivateIpAddress "172.16.0.4" -Subnet $subnet -PublicIpAddress $publicIP
# The subnet ID must match the appropriate subnet within which you're attempting to provision this resource.  It cannot be the Gateway subnet.
$netInterface = New-AzureRmNetworkInterface -Name $netInterfaceName -ResourceGroupName $resourceGroup -Location $location -NetworkSecurityGroupId $nsg.Id -IpConfiguration $IPconfig
#-SubnetID $virtualNetwork.Subnets[2].Id -PublicIpAddressId $publicIP.Id -NetworkSecurityGroupId $nsg.Id -IpConfiguration $IPconfig
# Use the line below if you already have a Network Interface
Write-Host "A new Network Interface resource was created in" $resourceGroup

# Initial VM Configuration

$vmSize = "Standard_B2s"
$vm = New-AzureRmVMConfig -VMName $vmName -VMSize $vmSize
Write-Host "Virtual Machine provisioned as" $vmSize 


# Set Disk Configuration
$osDiskName = "SOV-Cloud-OS"
#$urlVHD = "https://unifiedstorage.blob.core.windows.net/vhds/" + $osDiskName + ".vhd"
#Write-Host "OS Disk configured."

# set URL of old VHD
$urlVHD = "https://soverancecloud.blob.core.windows.net/vhds/SOV-Cloud-OS.vhd"
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
