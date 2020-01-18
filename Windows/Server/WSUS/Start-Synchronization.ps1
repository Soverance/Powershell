# Get WSUS Updates
# Scott McCutchen
# DevOps Engineer
# scott.mccutchen@soverance.com

#region
##############################################
###
###  Parameters
###
##############################################

param 
(
    [Parameter(Mandatory=$True)]
    [string]$Server
)
#endregion

#region
##############################################
###
###  Main
###
##############################################

try 
{
    [Reflection.Assembly]::LoadWithPartialName("Microsoft.UpdateServices.Administration") | Out-Null
    $wsus = [Microsoft.UpdateServices.Administration.AdminProxy]::GetUpdateServer($Server, $False,8530);
    $wsus.GetSubscription().StartSynchronization();
}
catch 
{
    Write-Error "ERROR in $($MyInvocation.MyCommand) on line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)"
}

#endregion
