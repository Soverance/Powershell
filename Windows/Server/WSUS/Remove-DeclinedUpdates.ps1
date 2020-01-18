# Remove Declined Updates
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
    $file = "c:\temp\WSUS_CleanUp_{0:MMddyyyy_HHmm}.log" -f (Get-Date)
    Start-Transcript -Path $file
    [Reflection.Assembly]::LoadWithPartialName("Microsoft.UpdateServices.Administration") | Out-Null
    $wsus = [Microsoft.UpdateServices.Administration.AdminProxy]::GetUpdateServer($Server, $False,8530);
    $cleanupScope = new-object Microsoft.UpdateServices.Administration.CleanupScope;
    $cleanupScope.DeclineSupersededUpdates    = $true
    $cleanupScope.DeclineExpiredUpdates       = $true
    $cleanupScope.CleanupObsoleteUpdates      = $true
    $cleanupScope.CompressUpdates             = $false
    $cleanupScope.CleanupObsoleteComputers    = $true
    $cleanupScope.CleanupUnneededContentFiles = $true
    $cleanupManager = $wsus.GetCleanupManager();
    $cleanupManager.PerformCleanup($cleanupScope);
    Stop-Transcript
}
catch 
{
    Write-Error "ERROR in $($MyInvocation.MyCommand) on line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)"
}

#endregion
