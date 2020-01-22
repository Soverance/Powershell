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
    [string]$VirtualIPv4Address = $(throw "-VirtualIPv4Address : You must specify the primary virtual IP address."),

    [Parameter(Mandatory=$False)]
    [switch]$CreateVirtualIPv4Address,  # specify this switch if you wish to create a new virtual IP address for the value specified in $VirtualIPv4Address

    [Parameter(Mandatory=$True)]
    [string]$ServerName = $(throw "-ServerName : You must specify the actual server name of the virtual machine you wish to manage via NetScaler."),

    [Parameter(Mandatory=$True)]
    [string]$ServerIPv4Address = $(throw "-ServerIPv4Address : You must specify the actual server IPv4 address of the virtual machine you wish to manage via NetScaler."),

    [Parameter(Mandatory=$True)]
    [string]$CertificateName = $(throw "-CertificateName : You must specify a valid server certificate name that is already installed on the NetScaler."),

    [Parameter(Mandatory=$True)]
    [string]$CAName = $(throw "-ServerName : You must specify the name of the CA certificate that was specified for the CertificateName param."),

    [Parameter(Mandatory=$False)]
    [string]$ContentSwitchingVirtualServerName = $(throw "-ContentSwitchingVirtualServerName : You must specify the name of the existing Content Switching Virtual Server to which you wish to bind the policies."),

    [Parameter(Mandatory=$True)]
    [string]$Hostname = $(throw "-Hostname : You must specify the internal hostname that will apply to this content switching policy.."),

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
    $ServiceName = "svc_$($ServerName)_443"
    $vServerName = "vsrv_$($ServerName)"
    $SwitchingPolicyName = "csp_$($ServerName)_Node"
    $NodeRule = "HTTP.REQ.HOSTNAME.EQ(`"$($Hostname)`")"

    $SessionObject = Connect-NSAppliance -NetScalerUrl $NetScalerUrl -NetScalerUser $NetScalerUser -NetScalerPass $NetScalerPass

    # virtual ip address
    # NOTE:  we don't need to re-create these every time for each node, otherwise when created they must be NAT'ed to a public external IP address
    if ($CreateVirtualIPv4Address)
    {
        Add-NSIPAddress -SessionObject $SessionObject -IPv4Address $VirtualIPv4Address -Netmask "255.255.255.255"
    }
    
    # validate certificate
    Find-NSCertificate -SessionObject $SessionObject

    if ($Remove)
    {
        # NOTE:  THE ORDER IN WHICH THESE FUNCTIONS ARE EXECUTED MATTERS
        Remove-NSContentSwitchingPolicyBinding -SessionObject $SessionObject -TargetCSVServerName $ContentSwitchingVirtualServerName -PolicyName $SwitchingPolicyName
        Remove-NSLBServer -SessionObject $SessionObject -ServerName $ServerName
        Remove-NSLBVServer -SessionObject $SessionObject -vServerName $vServerName
        Remove-NSContentSwitchingPolicy -SessionObject $SessionObject -PolicyName $SwitchingPolicyName
    }
    else 
    {
        # add server
        Add-NSLBServer -SessionObject $SessionObject -ServerName $ServerName -IPv4Address $ServerIPv4Address
        # add services
        Add-NSLBService -SessionObject $SessionObject -ServiceName $ServiceName -ServerName $ServerName -ServiceType "SSL" -Port 443
        # add load balancing virtual servers
        Add-NSLBVServer -SessionObject $SessionObject -vServerName $vServerName -ServiceType "SSL"
        # bind services to load balancing servers
        Add-NSLBVServiceBinding -SessionObject $SessionObject -vServerName $vServerName -ServiceName $ServiceName
        # bind certificates to load balancing virtual servers
        Add-NSLBVServerSSLCertificateBinding -SessionObject $SessionObject -vServerName $vServerName -CertificateName $CertificateName
        Add-NSLBVServerCACertificateBinding -SessionObject $SessionObject -vServerName $vServerName -CAName $CAName
        # add content switching policies        
        Add-NSContentSwitchingPolicy -SessionObject $SessionObject -PolicyName $SwitchingPolicyName -Rule $NodeRule
        # add content switching policy bindings
        $NextPriority = Get-NextAvailableContentSwitchingPriority -SessionObject $SessionObject
        Add-NSContentSwitchingPolicyBinding -SessionObject $SessionObject -TargetCSVServerName $ContentSwitchingVirtualServerName -PolicyName $SwitchingPolicyName -TargetLBVServerName $vServerName -Priority $NextPriority    
    }    
}
catch 
{
    Write-Error "ERROR on line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)"
}

#endregion
