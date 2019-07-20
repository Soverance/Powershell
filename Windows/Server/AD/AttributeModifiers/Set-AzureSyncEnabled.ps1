# © 2018 Soverance Studios
# Scott McCutchen
# scott.mccutchen@soverance.com

# This script will set the AzureSyncEnabled attribute of every AD user in the specified OU to TRUE
# This allows these users to be synced with Azure Active Directory

Import-Module ActiveDirectory

$ou = "DC=contoso,DC=com"

$server = "SOV-PDC"
Get-ADUser -SearchBase $ou -filter * | ForEach-Object {
    Write-Host "$($_.UserPrincipalName) is now Azure Sync Enabled."
    $_ | Set-ADUser -server $server -UserPrincipalName $_.UserPrincipalName -replace @{AzureSyncEnabled=$true}
}