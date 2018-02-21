# © 2018 Soverance Studios
# Scott McCutchen
# soverance.com
# scott.mccutchen@soverance.com
#
# Remotely update the group policy of the specified computer

param (
	[string]$computer = $(throw "-computer is required. You must specify a valid hostname on the network.")
)

# Use the Invoke-Command cmdlet, specifying a remote computer name, and then use the -scriptblock param to send a command to the remote computer
# you can do all sorts of stuff this way, but I most commonly use it to remotely update group policy
Invoke-Command -ComputerName $computer -ScriptBlock {gpupdate /force}