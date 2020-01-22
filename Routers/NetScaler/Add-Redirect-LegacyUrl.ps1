# AutoCluster High Availability Automatic Deployment Tools
# Scott McCutchen
# DevOps Engineer
# scott.mccutchen@soverance.com

# NOTE:  You should execute this script AFTER running the "Add-Redirect-HttpToHttps.ps1" for the URL you're redirecting to
# Executing the secure redirect script for your target URL first will allow you to have already created the appropriate responder action required to execute this script
# Do note that this script is intended only to redirect to an HTTPS protocol.  HTTP protocols should always be redirected to HTTPS.

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
    [string]$ContentSwitchingVirtualServerName = $(throw "-ContentSwitchingVirtualServerName : You must specify the name of the existing Content Switching Virtual Server which manages HTTP traffic."),

    [Parameter(Mandatory=$True)]
    [string]$Hostname = $(throw "-Hostname : You must specify the external hostname you wish to redirect."),

    [Parameter(Mandatory=$True)]
    [string]$RedirectToHostname = $(throw "-RedirectToHostname : You must specify the hostname you wish to redirect to."),

    [Parameter(Mandatory=$False)]
    [switch]$Remove
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
    $PolicyName = "LegacyRedirect_$($RedirectName)"
    $PolicyRule = "HTTP.REQ.HOSTNAME.CONTAINS(`"$($Hostname)`")"
    $RedirectToAction = "`"https://$($RedirectToHostname)`""
    $RedirectToActionName = ""

    $SessionObject = Connect-NSAppliance -NetScalerUrl $NetScalerUrl -NetScalerUser $NetScalerUser -NetScalerPass $NetScalerPass

    
    # validate certificate
    Find-NSCertificate -SessionObject $SessionObject

    if ($Remove)
    {
        # NOTE:  THE ORDER IN WHICH THESE FUNCTIONS ARE EXECUTED MATTERS
        Remove-NSContentSwitchingResponderPolicyBinding -SessionObject $SessionObject -Name $PolicyName -CsvServer $ContentSwitchingVirtualServerName
        Remove-NSResponderPolicy -SessionObject $SessionObject -Name $PolicyName
    }
    else 
    {  
        $actions = Get-NSResponderActions -SessionObject $SessionObject

        foreach ($action in $actions.responderaction)
        {
            if ($action.target -eq $RedirectToAction)
            {
                $RedirectToActionName = $action.name
            }
        }

        if ($RedirectToActionName)
        {
            Add-NSResponderPolicy -SessionObject $SessionObject -Name $PolicyName -Rule $PolicyRule -Action $RedirectToActionName

            [double]$NextAvailablePriority = Get-NextAvailableContentSwitchingResponderPolicyPriority -SessionObject $SessionObject -CsvServer $ContentSwitchingVirtualServerName
            Add-NSContentSwitchingResponderPolicyBinding -SessionObject $SessionObject -PolicyName $PolicyName -Priority $NextAvailablePriority -CsvServer $ContentSwitchingVirtualServerName
        }
        else 
        {
            Write-Error "The responder policy you intended to redirect to was not found."
        }
    }    
}
catch 
{
    Write-Error "ERROR on line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)"
}

#endregion
