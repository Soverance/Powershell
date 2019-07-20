# © 2018 Soverance Studios
# Scott McCutchen
# scott.mccutchen@soverance.com

# This script navigates to the SCE PS4 Orbis directory, so that you can use the "orbis-ctrl" command
# SYNTAX:
# orbis-ctrl command [options]
#
# U./Orbisse orbis-ctrl /? or orbis-ctrl /help to display a list of command line options
#
# See full documentation on ps4.scedev.net
# https://ps4.scedev.net/resources/documents/SDK/4.500/Neighborhood_and_Utilities-Users_Guide/0004.html#0Controlling_DevKits_with_orbisctrl
#

# Name of Server
$PS4Root = $env:SCE_ROOT_DIR
$Path = ""+ $PS4Root + "\ORBIS\Tools\Target Manager Server\bin"

Set-Location -Path $Path

if($?)
{
	Write-Host "ORBIS CONTROL INITIATED..." -foregroundcolor black -backgroundcolor cyan
    Write-Host "Use orbis-ctrl /? or orbis-ctrl /help to display a list of command line options" -foregroundcolor black -backgroundcolor cyan
}
else
{
	Write-Host "FAILED TO FIND ORBIS CONTROL." -foregroundcolor white -backgroundcolor red
}