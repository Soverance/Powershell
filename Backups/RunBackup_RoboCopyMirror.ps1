# © 2018 Soverance Studios
# Scott McCutchen
# soverance.com
# scott.mccutchen@soverance.com

param (
	[string]$source = $(throw "-source is required. You must specify a valid hostname on the network."),
	[string]$destination = $(throw "-destination is required. You must specify a valid destination path on the network.")
)

Write-Host "RoboCopy Mirror Initiated: '$($source)' to '$($destination)' " -foregroundcolor black -backgroundcolor cyan

robocopy $source $destination /COPYALL /B /SEC /MIR /R:0 /W:0 /NFL /NDL