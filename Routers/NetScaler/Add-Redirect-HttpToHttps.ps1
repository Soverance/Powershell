# AutoCluster High Availability Automatic Deployment Tools
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
    [string]$NetScalerUrl,

    [Parameter(Mandatory=$True)]
    [string]$NetScalerUser,

    [Parameter(Mandatory=$True)]
    [string]$NetScalerPass,

    [Parameter(Mandatory=$True)]
    [string]$RedirectName = $(throw "-RedirectName : You must specify the name of the redirect rule."),

    [Parameter(Mandatory=$False)]
    [string]$HttpContentSwitchingVirtualServerName = $(throw "-HttpContentSwitchingVirtualServerName : You must specify the name of the existing Content Switching Virtual Server which manages HTTP traffic."),

    [Parameter(Mandatory=$True)]
    [string]$Hostname = $(throw "-Hostname : You must specify the external hostname that will apply to this redirect policy."),

    [Parameter(Mandatory=$False)]
    [switch]$Remove  # call the script with this switch in order to remove the HTTPS redirect
)
#endregion

#region
##############################################
###
###  Module Configuration
###
##############################################

$currentLocation = ";" + $PSScriptRoot + "\Modules"
$env:PSModulePath = $env:PSModulePath + $currentLocation

# DEV - add local modules to path (only applicable to scott's laptop... remove before production use)
$localModules = ";" + "C:\Git\PSModules"
$env:PSModulePath = $env:PSModulePath + $localModules

Import-Module M3.NetScalerAutomation

#endregion 

#region
##############################################
###
###  Main
###
##############################################

try 
{
    $ActionName = "Redirect_$($RedirectName)"
    $ActionTarget = '"https://' + $Hostname + '"'
    $PolicyName = "SecureRedirect_$($RedirectName)"
    $PolicyRule = "HTTP.REQ.HOSTNAME.CONTAINS(`"$($Hostname)`")"

    $SessionObject = Connect-NSAppliance -NetScalerUrl $NetScalerUrl -NetScalerUser $NetScalerUser -NetScalerPass $NetScalerPass
    
    # validate certificate
    Find-NSCertificate -SessionObject $SessionObject

    if ($Remove)
    {
        # NOTE:  THE ORDER IN WHICH THESE FUNCTIONS ARE EXECUTED MATTERS
        Remove-NSContentSwitchingResponderPolicyBinding -SessionObject $SessionObject -Name $PolicyName -CsvServer $HttpContentSwitchingVirtualServerName
        Remove-NSResponderPolicy -SessionObject $SessionObject -Name $PolicyName
        Remove-NSResponderAction -SessionObject $SessionObject -Name $ActionName
    }
    else 
    {
        Add-NSResponderAction -SessionObject $SessionObject -Name $ActionName -Type "redirect" -Target $ActionTarget -ResponseCode 302    
        Add-NSResponderPolicy -SessionObject $SessionObject -Name $PolicyName -Rule $PolicyRule -Action $ActionName
        
        [double]$NextAvailablePriority = Get-NextAvailableContentSwitchingResponderPolicyPriority -SessionObject $SessionObject -CsvServer $HttpContentSwitchingVirtualServerName
        Add-NSContentSwitchingResponderPolicyBinding -SessionObject $SessionObject -PolicyName $PolicyName -Priority $NextAvailablePriority -CsvServer $HttpContentSwitchingVirtualServerName
    }    
}
catch 
{
    Write-Error "ERROR on line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)"
}

#endregion
