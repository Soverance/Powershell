# © 2017 Soverance Studios, LLC.
# Scott McCutchen
# www.soverance.com
# info@soverance.com

# Import Active Directory Organizational Unit structure from CSV

$pathofcsvfile = 'somepath.csv'

# Provide the path of the csv file
$oufile = Import-Csv $pathofcsvfile

# loop over CSV
foreach ($entry in $oufile)
{
    $ouname = $entry.ouname
    $oupath = $entry.oupath

    # Validation check if the OU already exists
    $ouidentity = "OU=" + $ouname + "," + $oupath
    $oucheck = [adsi]::Exists("LDAP://$ouidentity")

    # Creation Condition Check
    If($oucheck -eq "True")
    {
        Write-host -ForegroundColor Red "OU $ouname is already exist in the location $oupath"
    }
    Else 
    {
        # OU not found, so create the OU with Prevent Accidental Deletion enabled
        Write-Output "Creating the OU $ouname ....."
        New-ADOrganizationalUnit -Name $ouname -Path $oupath
        Write-Host -ForegroundColor Green "OU $ouname is created in the location $oupath"
    }
}