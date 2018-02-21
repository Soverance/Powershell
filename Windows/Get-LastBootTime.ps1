# © 2018 Soverance Studios
# Scott McCutchen
# soverance.com
# scott.mccutchen@soverance.com
#
# Remotely obtain the last boot time of the specified computer

#specify a remote computer hostname
param (
	[string]$computer = $(throw "-computer is required. You must specify a valid hostname on the network.")
)

# Get the last boot time of a remote computer, and convert the output to a legible time
Get-WmiObject Win32_OperatingSystem -ComputerName $computer | select csname, @{LABEL='LastBootUpTime' ;EXPRESSION={$_.ConverttoDateTime($_.lastbootuptime)}}