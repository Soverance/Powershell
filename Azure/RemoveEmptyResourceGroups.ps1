# © 2018 Soverance Studios
# Scott McCutchen
# scott.mccutchen@soverance.com

# This script will iterate through all available resource groups in your current subscription, and delete any empty ones.

# You must have the Azure Powershell Module installed to use this script,
# and have logged into your Azure subscription using the Login-AzureRmAccount command.
#Login-AzureRmAccount

# Get all Resource Groups
$RGs = Get-AzureRmResourceGroup

# For each group found...
foreach($RG in $RGs)
{
    # Get all the resources in this particular group
    $Resources = Find-AzureRmResource -ResourceGroupNameContains $RG.ResourceGroupName
    # Output total number of resources in group
    $outputstr = $RG.ResourceGroupName + " - " + $Resources.Length
    Write-Output $outputstr
    # If resources is equal to zero...
    if($Resources.Length -eq 0)
    {
        Write-Host "This group contains no resources and would be removed." -foregroundcolor white -backgroundcolor red
        # Remove the group
        #Remove-AzureRmResourceGroup -Name $RG.ResourceGroupName
    }
}