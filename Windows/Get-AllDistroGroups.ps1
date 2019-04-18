# © 2018 Soverance Studios
# Scott McCutchen
# scott.mccutchen@soverance.com

# This script will find all the distribution groups in Active Directory

###########################################
##
## Computer Configuration
##
###########################################

$groups = Get-ADGroup -Filter {GroupCategory -eq "Distribution"} -searchbase "OU=ExchangeGroups,OU=Atlanta,OU=Locations,DC=soverance,DC=com" -Properties Mail

$Output = foreach ($g in $Groups)
{
    New-Object -TypeName PSObject -Property @{
        GroupName = $g.name
        Mail = $g.mail
    } | Select-Object GroupName,Members,Mail
}

$Output | Export-CSV -Path "C:\Soverance\groups.csv"

