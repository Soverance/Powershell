# © 2017 Soverance Studios
# Scott McCutchen
# soverance.com

param (
	[string]$computer = $(throw "-computer is required. Supply a valid computer hostname on your network.")
)


Invoke-Command -ComputerName $computer -ScriptBlock {gpupdate /force}

