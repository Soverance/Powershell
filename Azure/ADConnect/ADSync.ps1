# © 2018 Soverance Studios, LLC.
# Scott McCutchen
# soverance.com
# scott.mccutchen@soverance.com

# This script will manually trigger the Azure AD Sync on UA-ADConnect from a remote computer
# I'm basically just using this so I don't have to RDP directly to the machine to manually run a sync...

Invoke-Command -ComputerName SOV-ADConnect -ScriptBlock {Start-ADSyncSyncCycle -PolicyType Initial}