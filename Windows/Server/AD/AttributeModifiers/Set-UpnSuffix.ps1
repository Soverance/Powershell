# © 2018 Soverance Studios
# Scott McCutchen
# scott.mccutchen@soverance.com

# This script will set the UPN suffix of every user in AD

Import-Module ActiveDirectory

$oldSuffix = "contoso.com"
$newSuffix = "contoso.net"
$ou = "DC=contoso,DC=com"

$server = "SOV-PDC"
Get-ADUser -SearchBase $ou -filter * | ForEach-Object {
    Write-Host "$($_.UserPrincipalName) changes to $($newsuffix)"
    $newUpn = $_.UserPrincipalName.Replace($oldSuffix,$newSuffix)
    $_ | Set-ADUser -server $server -UserPrincipalName $newUpn
}