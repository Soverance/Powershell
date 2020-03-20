# © 2018 Soverance Studios
# Scott McCutchen
# scott.mccutchen@soverance.com

# Server Core Dns Server Configuration Help

# use the following commands to set the external Dns Forwarding configuration

# display the current Dns Server forwarder configuration
Get-DnsServerForwarder

# set the new Dns Server forwarder config
Set-DnsServerForwarder -IPAddress 8.8.8.8, 8.8.4.4