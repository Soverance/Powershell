# © 2017 BKV, Inc.
# Scott McCutchen
# www.bkv.com
# scott.mccutchen@bkv.com

# You must have the Azure Powershell Module installed to use this script,
# and have logged into your Azure subscription using the Login-AzureRmAccount command.
#Login-AzureRmAccount

# This script creates a new ARM virtual network with a VPN gateway

#########################################
#
# THIS SCRIPT HAS BEEN DEPRECATED, AND IT'S FUNCTIONALITY ROLLED INTO THE WindowsServer_ADForest DEPLOYMENT TEMPLATE
#
#########################################

# Create a new resource group for this purpose
New-AzureRmResourceGroup -Name BKV-RM-VPN-GROUP -Location 'East US'

# Define the virtual network subnets
$subnet1 = New-AzureRmVirtualNetworkSubnetConfig -Name 'GatewaySubnet' -AddressPrefix 10.0.1.0/28
$subnet2 = New-AzureRmVirtualNetworkSubnetConfig -Name 'Subnet' -AddressPrefix 10.0.0.0/24

# Create the Virtual Network with the specified subnets
$virtualnet = New-AzureRmVirtualNetwork -Name BKV-RM-NET -ResourceGroupName BKV-RM-VPN-GROUP -Location 'East US' -AddressPrefix 10.0.0.0/16 -Subnet $subnet1, $subnet2

# Apply the gateway subnet configuration to the Virtual Network
Set-AzureRmVirtualNetwork -VirtualNetwork $virtualnet

# Create a local network gateway with multiple address prefixes
$localGateway = New-AzureRmLocalNetworkGateway -Name BKV-Local-Firewall -ResourceGroupName BKV-RM-VPN-GROUP -Location 'East US' -GatewayIpAddress '174.46.101.2' -AddressPrefix @('192.168.52.0/22','192.168.1.0/24','192.168.8.0/24')

# VPN Gateways must have a public IP address.
# The Public IP will be allocated dynamically during provisioning of this resource
# Request a public IP address
$publicIPrequest = New-AzureRmPublicIpAddress -Name BKV-RM-NET-PublicIP -ResourceGroupName BKV-RM-VPN-GROUP -Location 'East US' -AllocationMethod Dynamic

# Create the gateway IP address configuration
$subnetconfig = Get-AzureRmVirtualNetworkSubnetConfig -Name 'GatewaySubnet' -VirtualNetwork $virtualnet
$ipconfig = New-AzureRmVirtualNetworkGatewayIpConfig -Name BKV-RM-NET-ipconfig -SubnetId $subnetconfig.Id -PublicIpAddressId $publicIPrequest.Id

# Create the VPN Gateway
# The -GatewayType for a Site-to-Site configuration is Vpn. The gateway type is always specific to the configuration that you are implementing. For example, other gateway configurations may require -GatewayType ExpressRoute.
# The -VpnType can be RouteBased (referred to as a Dynamic Gateway in some documentation), or PolicyBased (referred to as a Static Gateway in some documentation).
# The -GatewaySku can be Basic, Standard, or HighPerformance. There are configuration limitations for certain SKUs.
$virtualnetGateway = New-AzureRmVirtualNetworkGateway -Name BKV-RM-NET-Gateway -ResourceGroupName BKV-RM-VPN-GROUP -Location 'East US' -IpConfigurations $ipconfig -GatewayType Vpn -VpnType PolicyBased -GatewaySku Basic

# Get the public IP address that was requested earlier
#$publicIP = Get-AzureRmPublicIpAddress -Name BKV-RM-NET-PublicIP -ResourceGroupName BKV-RM-NET-GROUP

# Create the VPN Connection between Azure and local gateways
# The pre-shared key must have been configured on your local gateway in advance of running this command
$connectVPN = New-AzureRmVirtualNetworkGatewayConnection -Name BKV-RM-NET-Connection -ResourceGroupName BKV-RM-VPN-GROUP -Location 'East US' -VirtualNetworkGateway1 $virtualnetGateway -LocalNetworkGateway2 $localGateway -ConnectionType IPsec -RoutingWeight 10 -SharedKey 'Ridill00'


