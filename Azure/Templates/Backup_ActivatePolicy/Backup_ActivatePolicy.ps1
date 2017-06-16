# © 2017 Soverance Studios, LLC.
# Scott McCutchen
# www.soverance.com
# info@soverance.com

# You must have the Azure Powershell Module installed to use this script,
# and have logged into your Azure subscription using the Login-AzureRmAccount command.
#Login-AzureRmAccount
 
# Ensure the correct Azure subscription is current before continuing. View all via Get-AzureRmSubscription -All
#Select-AzureRmSubscription -SubscriptionId "[your-id-goes-here]" -TenantId "[your-azure-ad-tenant-id-goes-here]"

# When selecting Resource Group to which this template needs to be deployed, you must select the Resource Group which corresponds to the pre-existing vault.
$ResourceGroupName = "Sov-Domain" 
#$ResourceGroupLocation = "East US" 
$TemplateFile = "azuredeploy.json"
$TemplateParametersFile = "azuredeploy.parameters.json"

# You may run the test command manually to ensure the template is valid before deployment
#Test-AzureRmResourceGroupDeployment -ResourceGroupName $ResourceGroupName -TemplateFile $TemplateFile -TemplateParameterFile $TemplateParametersFile -Verbose
 
# We don't need to create a new resource group for this template, since we're only concerned with pre-existing groups
#New-AzureRmResourceGroup -Name $ResourceGroupName -Location $ResourceGroupLocation -Verbose -Force -ErrorAction Stop

# Deploy from local Template File
# Templates can be deployed from remote locations (such as GitHub) by supplying the -TemplateUri parameter
New-AzureRmResourceGroupDeployment -Name ((Get-ChildItem $TemplateFile).BaseName + '-' + ((Get-Date).ToUniversalTime()).ToString('MMdd-HHmm')) `
-ResourceGroupName $ResourceGroupName `
-TemplateFile $TemplateFile `
-TemplateParameterFile $TemplateParametersFile `
-Force -Verbose