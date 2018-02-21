# © 2018 Soverance Studios
# Scott McCutchen
# soverance.com
# scott.mccutchen@soverance.com

# This script will set the physical street address attribute of every user in the specified AD OU

Import-Module ActiveDirectory

$AtlantaStreet = "3390 Peachtree Road, 10th Floor"
$AtlantaCity = "Atlanta"
$AtlantaState = "GA"
$AtlantaZip = "30326"

$AtlantaOU = "OU=Atlanta,DC=contoso,DC=com"

$server = "SOV-PDC"
Get-ADUser -SearchBase $AtlantaOU -filter * | ForEach-Object {
    Write-Host "$($_.UserPrincipalName) now has a configured physical address."
    $_ | Set-ADUser -server $server -UserPrincipalName $_.UserPrincipalName -replace @{streetAddress=$AtlantaStreet;l=$AtlantaCity;st=$AtlantaState;postalCode=$AtlantaZip}
}