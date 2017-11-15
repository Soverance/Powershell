# scott.mccutchen@soverance.com
# Server Core IP Configuration Help

# Use this script as a technical document to help configure Server Core installations.  I tend to run these cmdlets in order.

# This should be the first process completed when configuring a new Server Core installation.

# Get IP Configuration information
Get-NetIPConfiguration

# Get IP Interface information
Get-NetIPInterface

# Get all network adapters
Get-NetAdapter

# Show all bindings of a specific network adapter
# Usually using the name returned from the "Get-NetAdapter" cmdlet
Get-NetAdapterBinding -Name "Ethernet"

# Disable bindings 
# these component IDs are returned by the "Get-NetAdapterBinding" cmdlet in the ComponentID column
# we generally disable IPv6 until we explicitly require it, which is usually never
Disable-NetAdapterBinding -Name "Ethernet" -ComponentID ms_tcpip6

# Rename the network adapter to a syntax appropriate for our environment
Get-NetAdapter -Name "Ethernet" | Rename-NetAdapter -NewName "SOV-NIC-SQL" -PassThru

# Set a static IP address to the NIC
# this command will automatically disable DHCP on the adapter
New-NetIPAddress -InterfaceAlias "SOV-NIC-SQL" -IPv4Address "192.168.1.65" -PrefixLength 24 -DefaultGateway "192.168.1.254"

# Verify DHCP disabled
Get-NetIPInterface -InterfaceAlias "SOV-NIC-SQL"

# set static DNS information
Set-DnsClientServerAddress -InterfaceAlias "SOV-NIC-SQL" -ServerAddresses "192.168.1.64, 192.168.1.65"