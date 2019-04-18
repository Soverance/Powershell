# © 2018 Soverance Studios
# Scott McCutchen
# scott.mccutchen@soverance.com
#
# This script will update the RDP port of a specified computer

# define the port you wish to use for RDP
$RDPPort = 7250

# open that port in the local firewall
New-NetFirewallRule -DisplayName "RDP Custom Port" -Direction Inbound -LocalPort $RDPPort -Protocol TCP -Action Allow

# update the RDP port registry key value with the new port number
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-TCP" -Name PortNumber -Value $RDPPort

# You must restart the machine for this change to take effect
# additionally, if you are changing the port of a virtual machine in Azure,
# you will need to update the network security group for this VM to allow the new port number