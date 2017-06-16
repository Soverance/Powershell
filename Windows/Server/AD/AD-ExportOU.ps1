# © 2017 Soverance Studios, LLC.
# Scott McCutchen
# www.soverance.com
# info@soverance.com

# Export Active Directory Organizational Unit structure to CSV

$exportpath = $PSScriptRoot

$ExportPathWithFileName = $exportpath + "\OU_Export_" + (Get-Date -format yyyy-MM-dd) + ".csv"

Get-ADOrganizationalUnit -Filter * | export-csv $ExportPathWithFileName