# © 2017 BKV, Inc.
# Scott McCutchen
# www.bkv.com
# scott.mccutchen@bkv.com

# You must have the Azure Powershell Module installed to use this script,
# and have logged into your Azure subscription using the Login-AzureRmAccount command.
#Login-AzureRmAccount
 
# Ensure the correct Azure subscription is current before continuing. View all via Get-AzureRmSubscription -All
#Select-AzureRmSubscription -SubscriptionId "[your-id-goes-here]" -TenantId "[your-azure-ad-tenant-id-goes-here]"
 
$ResourceGroupName = "ADMT"
$ResourceGroupLocation = "East US 2"  # when backing up virtual machines, vaults must be created in the same location as the VMs they back up
$TemplateFile = "azuredeploy.json"
$TemplateParametersFile = "azuredeploy.parameters.json"

# You may run the test command manually to ensure the template is valid before deployment
#Test-AzureRmResourceGroupDeployment -ResourceGroupName $ResourceGroupName -TemplateFile $TemplateFile -TemplateParameterFile $TemplateParametersFile -Verbose
 
# Create or update the resource group using the specified template file and template parameters file
New-AzureRmResourceGroup -Name $ResourceGroupName -Location $ResourceGroupLocation -Verbose -Force -ErrorAction Stop

# Deploy from local Template File
# Templates can be deployed from remote locations (such as GitHub) by supplying the -TemplateUri parameter
New-AzureRmResourceGroupDeployment -Name ((Get-ChildItem $TemplateFile).BaseName + '-' + ((Get-Date).ToUniversalTime()).ToString('MMdd-HHmm')) `
-ResourceGroupName $ResourceGroupName `
-TemplateFile $TemplateFile `
-TemplateParameterFile $TemplateParametersFile `
-Force -Verbose