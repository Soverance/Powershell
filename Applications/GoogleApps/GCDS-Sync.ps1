# © 2020 Soverance Studios, LLC
# Scott McCutchen
# DevOps Engineer
# scott.mccutchen@soverance.com

# This script will manually trigger the Google Cloud Directory Sync
# GCDS usually executes this sync automatically, but sometimes you may need a change to update immediately rather than waiting for your standard sync schedule to occur

$cred = Get-Credential

$s = New-PSSession -ComputerName SOV-GCDS -Credential $cred

Invoke-Command -ComputerName SOV-GCDS -Session $s -ScriptBlock {(Set-Location -Path "C:\Program Files\Google Apps Directory Sync\"), (./sync-cmd.exe -a -o -c "C:\Users\Administrator\Desktop\GCDS\GCDS.xml")}
