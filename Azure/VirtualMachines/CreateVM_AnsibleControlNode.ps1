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
$resourceGroup = "Ansible"
$vmName = "AnsibleControlNode"

# Create a new resource group for this purpose
#New-AzureRmResourceGroup -Name $resourceGroup -Location $location
#Write-Host "A new resource group was created called: " $resourceGroup

# create an Availability Set for this VM
# If an appropriate availability set already exists, use that one instead.
# Creating an Availability Set requires the AzureRM.Compute module
# See this help doc for more details:  https://docs.microsoft.com/en-us/azure/virtual-machines/windows/create-availability-set
#$availabilityName = "DEV-Linux-AvailabilitySet"
#$availability = New-AzureRmAvailabilitySet -ResourceGroupName $resourceGroup -Name $availabilityName -Location $location
#Write-Host "A new availability set was created called: " $availabilityName

# Define user name and password
$securePassword = ConvertTo-SecureString 'Ridill00' -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ("ansibleadmin", $securePassword)

$storage =  Get-AzureRmStorageAccount -AccountName "soveranceansible" -ResourceGroupName $resourceGroup
$virtualNetwork = Get-AzureRmVirtualNetwork -Name "ansiblenet" -ResourceGroupName $resourceGroup
Write-Host "Initialization complete."

# create a new Public IP resource
Write-Host "Creating new Public IP..."
$ipName = "PIP-AnsibleControlNode"
$publicIP = New-AzureRmPublicIpAddress -Name $ipName -ResourceGroupName $resourceGroup -Location $location -AllocationMethod Static
Write-Host "A new Public IP resource was created in" $resourceGroup

# Create an inbound network security group rule for port 80 http
$nsgRuleHTTP = New-AzureRmNetworkSecurityRuleConfig -Name WebHostRuleHTTP  -Protocol Tcp `
    -Direction Inbound -Priority 1001 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * `
    -DestinationPortRange 80 -Access Allow
Write-Host "A HTTP Rule to open port 80 was created for the NSG"

# Create an inbound network security group rule for port 443 https
$nsgRuleHTTPS = New-AzureRmNetworkSecurityRuleConfig -Name WebHostRuleHTTPS  -Protocol Tcp `
    -Direction Inbound -Priority 1002 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * `
    -DestinationPortRange 443 -Access Allow
Write-Host "A HTTPS Rule to open port 443 was created for the NSG."

# Create an inbound network security group rule for port 21 ftp
$nsgRuleFTP = New-AzureRmNetworkSecurityRuleConfig -Name WebHostRuleFTP  -Protocol Tcp `
    -Direction Inbound -Priority 1003 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * `
    -DestinationPortRange 21 -Access Allow
Write-Host "A FTP Rule to open port 21 was created for the NSG."

# Create an inbound network security group rule for port 22 ssh
$nsgRuleSSH = New-AzureRmNetworkSecurityRuleConfig -Name WebHostRuleSSH  -Protocol Tcp `
    -Direction Inbound -Priority 1004 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * `
    -DestinationPortRange 22 -Access Allow
Write-Host "A FTP Rule to open port 22 was created for the NSG."

# Create a network security group
Write-Host "Creating new Network Security Group..."
$nsg = New-AzureRmNetworkSecurityGroup -ResourceGroupName $resourceGroup -Location $location `
    -Name AnsibleSecurityGroup -SecurityRules $nsgRuleHTTP,$nsgRuleHTTPS,$nsgRuleFTP,$nsgRuleSSH
Write-Host "A new Network Security Group resource was created in" $resourceGroup

# create a new Network Interface
Write-Host "Creating new Network Interface..."
$netInterfaceName = "NIC-AnsibleControlNode"
# The subnet ID must match the appropriate subnet within which you're attempting to provision this resource.  It cannot be the Gateway subnet.
$netInterface = New-AzureRmNetworkInterface -Name $netInterfaceName -ResourceGroupName $resourceGroup -Location $location -SubnetID $virtualNetwork.Subnets[0].Id -PublicIpAddressId $publicIP.Id -NetworkSecurityGroupId $nsg.Id
# Use the line below if you already have a Network Interface
#$netInterface = Get-AzureRmNetworkInterface -Name $netInterfaceName -ResourceGroupName $resourceGroup
Write-Host "A new Network Interface resource was created in" $resourceGroup

# Initial VM Configuration

$vmSize = "Standard_B1ms"
$vm = New-AzureRmVMConfig -VMName $vmName -VMSize $vmSize #-AvailabilitySetId $availability.Id
Write-Host "Virtual Machine provisioned as" $vmSize

# Operating System Config
Set-AzureRmVMOperatingSystem -VM $vm -Linux -ComputerName $vmName -Credential $cred -DisablePasswordAuthentication
Set-AzureRmVmSourceImage -VM $vm -PublisherName "Canonical" -Offer "UbuntuServer" -Skus "18.04-LTS" -Version latest

# Set Disk Configuration
$osDiskName = "AnsibleControlNode-OS-Disk"
$urlVHD = "https://soveranceansible.blob.core.windows.net/vhds/" + $osDiskName + ".vhd"
Write-Host "OS Disk configured."

# Add OS Disk to VM
# use -CreateOption Attach if you're using an existing VHD, or FromImage if you'd like to create a new one
$vm = Set-AzureRmVMOSDisk -VM $vm -Name $osDiskName -VhdUri $urlVHD -CreateOption FromImage -Linux -Caching 'ReadWrite' -DiskSizeInGB 2048
Write-Host "OS Disk added to VM."

# Add network interface to VM
$vm = Add-AzureRmVMNetworkInterface -VM $vm -Id $netInterface.Id
Write-Host "Network Interface" $netInterfaceName "has been applied to the VM."

# Configure SSH Keys
# you can create new keys with the PuTTYGen software
$sshPublicKey = Get-Content "$env:USERPROFILE\.ssh\AnsibleControlNodeKey-Public" -Raw
Add-AzureRmVMSshPublicKey -VM $vm -KeyData $sshPublicKey -Path "/home/ansibleadmin/.ssh/authorized_keys"
Write-Host "Added Public Key: " $sshPublicKey 

# Deploy Virtual Machine
$result = New-AzureRmVM -ResourceGroupName $resourceGroup -Location $location -VM $vm
$result
