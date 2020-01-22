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
    [string]$LoadBalancerName = $(throw "-LoadBalancerName : You must specify the name of the virtual load balancer you wish to manage via NetScaler."),

    [Parameter(Mandatory=$True)]
    [string]$LoadBalancerVirtualIP = $(throw "-LoadBalancerVirtualIP : You must specify the IP Address of the virtual load balancer."),

    [Parameter(Mandatory=$True)]
    [string]$CertificateName = $(throw "-CertificateName : You must specify a valid server certificate name that is already installed on the NetScaler."),

    [Parameter(Mandatory=$True)]
    [string]$CAName = $(throw "-CAName : You must specify the name of the CA certificate that was specified for the CertificateName param."),

    [Parameter(Mandatory=$True)]
    [string]$ServerIP1 = $(throw "-ServerIP1 : You must specify the IP Address of the first server in the load-balanced pair."),

    [Parameter(Mandatory=$True)]
    [string]$ServerIP2 = $(throw "-ServerIP2 : You must specify the IP Address of the second server in the load-balanced pair."),

    [Parameter(Mandatory=$False)]
    [string]$ContentSwitchingVirtualServerName = $(throw "-ContentSwitchingVirtualServerName : You must specify the name of the existing Content Switching Virtual Server to which you wish to bind the policies."),

    [Parameter(Mandatory=$True)]
    [string]$AppHostname = $(throw "-AppHostname : You must specify the external hostname that will apply to this content switching policy.."),

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
    $ServerName1 = "srv_$($LoadBalancerName)_01"
    $ServerName2 = "srv_$($LoadBalancerName)_02"
    $LBVServerNameHTTP = "vsrv_$($LoadBalancerName)_HTTP"
    $LBVServerNameHTTPS = "vsrv_$($LoadBalancerName)_HTTPS"
    $ServiceGroupNameHTTP = "sg_$($LoadBalancerName)_HTTP"
    $ServiceGroupNameHTTPS = "sg_$($LoadBalancerName)_HTTPS"
    $SwitchingPolicyNameInsight = "csp_$($LoadBalancerName)"

    $SessionObject = Connect-NSAppliance -NetScalerUrl $NetScalerUrl -NetScalerUser $NetScalerUser -NetScalerPass $NetScalerPass

    # virtual ip address for the content switching virtual server
    # NOTE:  we don't re-create these every time for each node, because otherwise when created they must be NAT'ed to a public external IP address
    # in this case, we're expecting that you've created a content switching virtual server for this purpose prior to executing this script
    if ($CreateVirtualIPv4Address)
    {
        Add-NSIPAddress -SessionObject $SessionObject -IPv4Address $VirtualIPv4Address -Netmask "255.255.255.255"
    }

    # validate certificate
    Find-NSCertificate -SessionObject $SessionObject

    if ($Remove)
    {
        # NOTE:  THE ORDER IN WHICH THESE FUNCTIONS ARE EXECUTED MATTERS
        Remove-NSLBServer -SessionObject $SessionObject -ServerName $ServerName1
        Remove-NSLBServer -SessionObject $SessionObject -ServerName $ServerName2    
        Remove-NSLBServiceGroup -SessionObject $SessionObject -ServiceGroupName $ServiceGroupNameHTTP
        Remove-NSLBServiceGroup -SessionObject $SessionObject -ServiceGroupName $ServiceGroupNameHTTPS
        Remove-NSContentSwitchingPolicyBinding -SessionObject $SessionObject -TargetCSVServerName $ContentSwitchingVirtualServerName -PolicyName $SwitchingPolicyNameInsight
        Remove-NSContentSwitchingPolicy -SessionObject $SessionObject -PolicyName $SwitchingPolicyNameInsight
        Remove-NSLBVServer -SessionObject $SessionObject -vServerName $LBVServerNameHTTP
        Remove-NSLBVServer -SessionObject $SessionObject -vServerName $LBVServerNameHTTPS
    }
    else 
    {
        # add individual servers to be load-balanced
        Add-NSLBServer -SessionObject $SessionObject -ServerName $ServerName1 -IPv4Address $ServerIP1
        Add-NSLBServer -SessionObject $SessionObject -ServerName $ServerName2 -IPv4Address $ServerIP2    
        
        # add load-balancing service group
        Add-NSLBServiceGroup -SessionObject $SessionObject -ServiceGroupName $ServiceGroupNameHTTP -ServiceType "HTTP"
        Add-NSLBServiceGroup -SessionObject $SessionObject -ServiceGroupName $ServiceGroupNameHTTPS -ServiceType "SSL"

        # add certificate bindings for SSL Service Group
        Add-NSLBServiceGroupMemberSSLBinding -SessionObject $SessionObject -ServiceGroupName $ServiceGroupNameHTTPS -CertKeyName $CAName -bIsCA 
        Add-NSLBServiceGroupMemberSSLBinding -SessionObject $SessionObject -ServiceGroupName $ServiceGroupNameHTTPS -CertKeyName $CertificateName

        # bind individual servers to a service group
        Add-NSLBServiceGroupMemberBinding -SessionObject $SessionObject -ServiceGroupName $ServiceGroupNameHTTP -ServerName $ServerName1 -Port 80    
        Add-NSLBServiceGroupMemberBinding -SessionObject $SessionObject -ServiceGroupName $ServiceGroupNameHTTP -ServerName $ServerName2 -Port 80
        Add-NSLBServiceGroupMemberBinding -SessionObject $SessionObject -ServiceGroupName $ServiceGroupNameHTTPS -ServerName $ServerName1 -Port 443   
        Add-NSLBServiceGroupMemberBinding -SessionObject $SessionObject -ServiceGroupName $ServiceGroupNameHTTPS -ServerName $ServerName2 -Port 443

        # add service group monitor binding
        Add-NSLBServiceGroupMonitorBinding -SessionObject $SessionObject -ServiceGroupName $ServiceGroupNameHTTP -MonitorName "ping"
        Add-NSLBServiceGroupMonitorBinding -SessionObject $SessionObject -ServiceGroupName $ServiceGroupNameHTTPS -MonitorName "ping"

        # add load balancing virtual servers
        Add-NSLBVServer -SessionObject $SessionObject -vServerName $LBVServerNameHTTP -ServiceType "HTTP" -IP $LoadBalancerVirtualIP
        Add-NSLBVServer -SessionObject $SessionObject -vServerName $LBVServerNameHTTPS -ServiceType "SSL" -IP $LoadBalancerVirtualIP

        # add certificate bindings to the SSL load balacing virtual server
        Add-NSLBVServerSSLCertificateBinding -SessionObject $SessionObject -vServerName $LBVServerNameHTTPS -CertificateName $CertificateName
        Add-NSLBVServerCACertificateBinding -SessionObject $SessionObject -vServerName $LBVServerNameHTTPS -CAName $CAName

        # bind the service groups to the load balancing virtual servers
        Add-NSLBVServiceGroupBinding -SessionObject $SessionObject -vServerName $LBVServerNameHTTP -ServiceGroupName $ServiceGroupNameHTTP
        Add-NSLBVServiceGroupBinding -SessionObject $SessionObject -vServerName $LBVServerNameHTTPS -ServiceGroupName $ServiceGroupNameHTTPS 

        # create a content switching policy for this load balanced URL
        $AppRule = "HTTP.REQ.HOSTNAME.EQ(`"$($AppHostname)`")"
        Add-NSContentSwitchingPolicy -SessionObject $SessionObject -PolicyName $SwitchingPolicyNameInsight -Rule $AppRule
        
        # bind content switching policy to pre-existing content switching virtual servers
        $NextPriority = Get-NextAvailableContentSwitchingPriority -SessionObject $SessionObject
        Add-NSContentSwitchingPolicyBinding -SessionObject $SessionObject -TargetCSVServerName $ContentSwitchingVirtualServerName -PolicyName $SwitchingPolicyNameInsight -TargetLBVServerName $LBVServerNameHTTPS -Priority $NextPriority
    }
}
catch 
{
    Write-Error "ERROR on line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)"
}

#endregion
