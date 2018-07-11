# © 2018 Soverance Studios
# Scott McCutchen
# scott.mccutchen@soverance.com

# This script will remotely logoff the specified user
# Generally we use this to kick someone off an RDP session that they failed to properly logoff from

param(
    [string]$Computer = $(throw "-Computer is required. You must specify a valid hostname on the network."),
    [string]$User = $(throw "-User is required. You must specify a valid SAM account name.")
)

$sessionId = ((quser /server:$Computer | Where-Object { $_ -match $User }) -split ' +')[2]
Invoke-RDUserLogoff -HostServer $Computer -UnifiedSessionId $sessionId