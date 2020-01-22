# Citrix NetScaler Automation Module
# Scott McCutchen
# DevOps Engineer
# scott.mccutchen@soverance.com

# This module contains functions relevant to working with Citrix NetScaler

# NetScaler Nitro REST API Reference Documentation
# https://developer-docs.citrix.com/projects/netscaler-nitro-api/en/11.1/

##############################################
###
###  Module Start
###
##############################################

# It's not required to use the .NET SDK for this... since we can interface directly with the REST API via PowerShell
# If you wanted to use the full .NET SDK, you would need to go grab these DLLs from the download available through the NetScaler appliance
# # Load NetScaler .NET Assemblies
# $parent = (Get-Item $PSScriptRoot).Parent.Parent.FullName
# $newtonPath = $parent + "\Dependencies\nitro-csharp\lib\Newtonsoft.Json.dll"
# Add-Type -Path $newtonPath
# $nitroPath = $parent + "\Dependencies\nitro-csharp\lib\nitro.dll"
# Add-Type -Path $nitroPath

$global:head = @{   
    "Content-Type" = "application/json"
}

##############################################
###
###  Functions
###
##############################################

#region BASIC FUNCTIONS
# this function connects to a NetScaler appliance API endpoint, and returns a session token cookie that can be used in later API requests
function Connect-NSAppliance()
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$True)]
        [string]$NetScalerUrl, # = $(throw "-NetScalerUrl : the domain name URL for the NetScaler appliance."),
        
        [Parameter(Mandatory=$True)]
        [string]$NetScalerUser, # = $(throw "-NetScalerUser : username of the account to access NetScaler."), 
        
        [Parameter(Mandatory=$True)]
        [string]$NetScalerPass # = $(throw "-NetScalerPass : password for the account to access NetScaler."), 
    )
    
    $head = @{        
        "Content-Type" = "application/vnd.com.citrix.netscaler.lbvserver+json"
    }

    $body = @{        
        "login" = @{
            "username" = $NetScalerUser
            "password" = $NetScalerPass
        }
    }

    $connectionUrl = "http://$($NetScalerUrl)/nitro/v1/config/login" 
    
    try 
    {
        # hit the NetScaler API endpoint to obtain a session token
        $result = Invoke-RestMethod -Method Post -Uri $connectionUrl -Headers $head -Body (ConvertTo-Json $body -Depth 4) -ContentType "application/json"
        
        # create a cookie object to hold the session token
        $nsCookie = New-Object System.Net.Cookie
        $nsCookie.Name = "NITRO_AUTH_TOKEN"
        $nsCookie.Value = $result.sessionid
        $nsCookie.Domain = $NetScalerUrl

        # create a new web session object, since the -SessionVariable param of Invoke-RestMethod doesn't seem to work
        $webSession = New-Object Microsoft.PowerShell.Commands.WebRequestSession
        $webSession.Cookies.Add($nsCookie)  # add the cookie to the web request session

        # create a new custom object to hold all our netscaler session crap
        $nsSession = New-Object PSObject
        $nsSession | Add-Member -MemberType NoteProperty -Name Protocol -Value "http" -TypeName String
        $nsSession | Add-Member -MemberType NoteProperty -Name Endpoint -Value $NetScalerUrl -TypeName String
        $nsSession | Add-Member -MemberType NoteProperty -Name Session -Value $webSession -TypeName Microsoft.PowerShell.Commands.WebRequestSession

        return $nsSession
    }
    catch 
    {
        Write-Error "ERROR in $($MyInvocation.MyCommand) on line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)"
    }
}
#endregion

#region IP ADDRESS FUNCTIONS
# this function returns a list of all IP address objects stored in the NetScaler
function Get-NSIPAddresses()
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$True)]
        [PSObject]$SessionObject
    )
    
    $connectionUrl = "$($SessionObject.Protocol)://$($SessionObject.Endpoint)/nitro/v1/config/nsip" 
    
    try 
    {
        return Invoke-RestMethod -Method Get -Uri $connectionUrl -Headers $global:head -ContentType "application/json" -WebSession $SessionObject.Session
    }
    catch 
    {
        Write-Error "ERROR in $($MyInvocation.MyCommand) on line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)"
    }
}

# this function adds a single IPv4 address to the NetScaler
function Add-NSIPAddress()
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$True)]
        [PSObject]$SessionObject,
        [Parameter(Mandatory=$True)]
        [string]$Ipv4Address,
        [Parameter(Mandatory=$True)]
        [string]$Netmask,
        [Parameter(Mandatory=$False)]
        [string]$Type = "VIP"
    )
    
    try 
    {
        $IPs = Get-NSIPAddresses -SessionObject $SessionObject
        $matching = $False

        foreach ($IP in $IPs.nsip)
        {
            if ($IP.ipaddress -eq $Ipv4Address)
            {
                $matching = $True
                Write-Error "That IPv4 address already exists in NetScaler!"
            }            
        }

        if ($matching -eq $False)
        {
            $connectionUrl = "$($SessionObject.Protocol)://$($SessionObject.Endpoint)/nitro/v1/config/nsip" 
    
            $body = @{        
                "nsip" = @{
                    "ipaddress" = $Ipv4Address
                    "netmask" = $Netmask
                    "type" = $Type
                    "arp" = "ENABLED"
                    "icmp" = "ENABLED"
                    #"hostroute" = "DISABLED"
                    #"ospflsatype" = "TYPE5"
                    #"vserverrhilevel" = "ONE_VSERVER"
                    #"vserverrhimode" = "DYNAMIC_ROUTING"
                }
            }

            $IP = Invoke-RestMethod -Method Post -Uri $connectionUrl -Headers $global:head -Body (ConvertTo-Json $body -Depth 3) -ContentType "application/json" -WebSession $SessionObject.Session
            
            Write-Output "Successfully added virtual IP address $($IPv4Address) to NetScaler."
            return
        }
        else 
        {
            Write-Error "Failed to add IP address to NetScaler because it already exists."
        }
    }
    catch 
    {
        Write-Error "ERROR in $($MyInvocation.MyCommand) on line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)"
    }
}

# this function deletes an IPv4 address from the NetScaler
function Remove-NSIPAddress()
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$True)]
        [PSObject]$SessionObject,
        [Parameter(Mandatory=$True)]
        [string]$Ipv4Address
    )
    
    $connectionUrl = "$($SessionObject.Protocol)://$($SessionObject.Endpoint)/nitro/v1/config/nsip/$($Ipv4Address)" 
    
    try 
    {
        return Invoke-RestMethod -Method Delete -Uri $connectionUrl -Headers $global:head -ContentType "application/json" -WebSession $SessionObject.Session
    }
    catch 
    {
        Write-Error "ERROR in $($MyInvocation.MyCommand) on line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)"
    }
}
#endregion

#region SSL CERTIFICATE FUNCTIONS
function Get-NSSSLCertificates()
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$True)]
        [PSObject]$SessionObject
    )
    
    $connectionUrl = "$($SessionObject.Protocol)://$($SessionObject.Endpoint)/nitro/v1/config/sslcertkey" 
    
    try 
    {
        return Invoke-RestMethod -Method Get -Uri $connectionUrl -Headers $global:head -ContentType "application/json" -WebSession $SessionObject.Session
    }
    catch 
    {
        Write-Error "ERROR in $($MyInvocation.MyCommand) on line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)"
    }
}

# this function searches for a specific certificate 
function Find-NSCertificate()
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$True)]
        [PSObject]$SessionObject,
        [Parameter(Mandatory=$False)]
        [string]$CertName = "soverance"
    )
    
    try 
    {
        $SSLs = Get-NSSSLCertificates -SessionObject $SessionObject
    
        foreach ($cert in $SSLs.sslcertkey)
        {
            if ($cert.certkey -eq $CertName)
            {
                Write-Output "Certificate for $($CertName) already exists in NetScaler!"
                Write-Output "There are $($cert.daystoexpiration) days until certificate expiration."

                if ($cert.daystoexpiration -lt 3)
                {
                    Write-Error "There are only $($cert.daystoexpiration). You must update this certificate before continuing."
                }

                #return $cert
                return
            }
        }
    }
    catch 
    {
        Write-Error "ERROR in $($MyInvocation.MyCommand) on line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)"
    }
}
#endregion

#region LOAD BALANCING SERVER FUNCTIONS
function Get-NSLBServers()
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$True)]
        [PSObject]$SessionObject
    )
    
    $connectionUrl = "$($SessionObject.Protocol)://$($SessionObject.Endpoint)/nitro/v1/config/server" 
    
    try 
    {
        return Invoke-RestMethod -Method Get -Uri $connectionUrl -Headers $global:head -ContentType "application/json" -WebSession $SessionObject.Session
    }
    catch 
    {
        Write-Error "ERROR in $($MyInvocation.MyCommand) on line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)"
    }
}

function Add-NSLBServer()
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$True)]
        [PSObject]$SessionObject,
        [Parameter(Mandatory=$False)]
        [string]$ServerName,
        [Parameter(Mandatory=$True)]
        [string]$Ipv4Address
    )

    try 
    {
        $servers = Get-NSLBServers -SessionObject $SessionObject
        $matching = $False

        foreach ($server in $servers.server)
        {
            if ($server.name -eq $ServerName)
            {
                $matching = $True
                Write-Error "The server name $($ServerName) already exists in NetScaler."
            }
        }

        if ($matching -eq $False)
        {
            $connectionUrl = "$($SessionObject.Protocol)://$($SessionObject.Endpoint)/nitro/v1/config/server" 
            
            $body = @{        
                "server" = @{
                    "name" = $ServerName
                    "ipaddress" = $Ipv4Address
                    "comment" = "Deployed via AutoCluster"
                }
            }

            Invoke-RestMethod -Method Post -Uri $connectionUrl -Headers $global:head -Body (ConvertTo-Json $body -Depth 3) -ContentType "application/json" -WebSession $SessionObject.Session

            Write-Output "Successfully added server $($ServerName) to NetScaler."
            return
        }
    }
    catch 
    {
        Write-Error "ERROR in $($MyInvocation.MyCommand) on line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)"
    }
}

function Update-NSLBServer()
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$True)]
        [PSObject]$SessionObject,
        [Parameter(Mandatory=$False)]
        [string]$ServerName,
        [Parameter(Mandatory=$True)]
        [string]$Ipv4Address
    )

    try 
    {
        $connectionUrl = "$($SessionObject.Protocol)://$($SessionObject.Endpoint)/nitro/v1/config/server" 
            
        $body = @{        
            "server" = @{
                "name" = $ServerName
                "ipaddress" = $Ipv4Address
                "comment" = "Deployed via AutoCluster"
            }
        }

        Invoke-RestMethod -Method Put -Uri $connectionUrl -Headers $global:head -Body (ConvertTo-Json $body -Depth 3) -ContentType "application/json" -WebSession $SessionObject.Session

        Write-Output "Successfully updated server $($ServerName) in NetScaler."
        return
    }
    catch 
    {
        Write-Error "ERROR in $($MyInvocation.MyCommand) on line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)"
    }
}

function Remove-NSLBServer()
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$True)]
        [PSObject]$SessionObject,
        [Parameter(Mandatory=$True)]
        [string]$ServerName
    )
    
    $connectionUrl = "$($SessionObject.Protocol)://$($SessionObject.Endpoint)/nitro/v1/config/server/$($ServerName)" 
    
    try 
    {
        return Invoke-RestMethod -Method Delete -Uri $connectionUrl -Headers $global:head -ContentType "application/json" -WebSession $SessionObject.Session
    }
    catch 
    {
        Write-Error "ERROR in $($MyInvocation.MyCommand) on line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)"
    }
}
#endregion

#region LOAD BALANCING SERVICE FUNCTIONS
function Get-NSLBServices()
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$True)]
        [PSObject]$SessionObject
    )
    
    $connectionUrl = "$($SessionObject.Protocol)://$($SessionObject.Endpoint)/nitro/v1/config/service" 
    
    try 
    {
        return Invoke-RestMethod -Method Get -Uri $connectionUrl -Headers $global:head -ContentType "application/json" -WebSession $SessionObject.Session
    }
    catch 
    {
        Write-Error "ERROR in $($MyInvocation.MyCommand) on line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)"
    }
}

function Add-NSLBService()
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$True)]
        [PSObject]$SessionObject,
        [Parameter(Mandatory=$True)]
        [string]$ServiceName,
        [Parameter(Mandatory=$True)]
        [string]$ServerName,
        [Parameter(Mandatory=$True)]
        [string]$ServiceType,
        [Parameter(Mandatory=$True)]
        [int]$Port
    )

    try 
    {
        $services = Get-NSLBServices -SessionObject $SessionObject 
        $matching = $False

        foreach ($service in $services.service)
        {
            if ($service.name -eq $ServiceName)
            {
                $matching = $True
                Write-Error "The service name $($ServiceName) already exists in NetScaler."
            }
        }

        if ($matching -eq $False)
        {
            $connectionUrl = "$($SessionObject.Protocol)://$($SessionObject.Endpoint)/nitro/v1/config/service" 
            
            $body = @{        
                "service" = @{
                    "name" = $ServiceName
                    "servername" = $ServerName
                    "servicetype" = $ServiceType
                    "port" = $Port
                    "customserverid" = "None"
                    "cacheable" = "NO"
                    "state" = "ENABLED"
                    "healthmonitor" = "YES"
                    "appflowlog" = "ENABLED"
                    "cip" = "ENABLED"
                    "cipheader" = "X-Forwarded"
                    "comment" = "Deployed via AutoCluster"
                }
            }

            Invoke-RestMethod -Method Post -Uri $connectionUrl -Headers $global:head -Body (ConvertTo-Json $body -Depth 3) -ContentType "application/json" -WebSession $SessionObject.Session

            Write-Output "Successfully added service $($ServiceName) to NetScaler."
            return
        }
    }
    catch 
    {
        Write-Error "ERROR in $($MyInvocation.MyCommand) on line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)"
    }
}

# this function would delete a specified load balancing service from the NetScaler
# NOTE:  this function isn't necessary if you delete the linked server - deleting the server linked to this service will automatically delete the service as well
function Remove-NSLBService()
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$True)]
        [PSObject]$SessionObject,
        [Parameter(Mandatory=$True)]
        [string]$ServiceName
    )
    
    $connectionUrl = "$($SessionObject.Protocol)://$($SessionObject.Endpoint)/nitro/v1/config/service/$($ServiceName)" 
    
    try 
    {
        return Invoke-RestMethod -Method Delete -Uri $connectionUrl -Headers $global:head -ContentType "application/json" -WebSession $SessionObject.Session
    }
    catch 
    {
        Write-Error "ERROR in $($MyInvocation.MyCommand) on line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)"
    }
}
#endregion

#region LOAD BALANCING SERVICE GROUP FUNCTIONS
function Get-NSLBServiceGroups()
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$True)]
        [PSObject]$SessionObject
    )
    
    $connectionUrl = "$($SessionObject.Protocol)://$($SessionObject.Endpoint)/nitro/v1/config/servicegroup" 
    
    try 
    {
        return Invoke-RestMethod -Method Get -Uri $connectionUrl -Headers $global:head -ContentType "application/json" -WebSession $SessionObject.Session
    }
    catch 
    {
        Write-Error "ERROR in $($MyInvocation.MyCommand) on line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)"
    }
}

function Add-NSLBServiceGroup()
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$True)]
        [PSObject]$SessionObject,
        [Parameter(Mandatory=$True)]
        [string]$ServiceGroupName,
        [Parameter(Mandatory=$True)]
        [string]$ServiceType #  "SSL" or "HTTP"
    )

    try 
    {
        $groups = Get-NSLBServiceGroups -SessionObject $SessionObject 
        $matching = $False

        foreach ($group in $groups.servicegroup)
        {
            if ($group.servicegroupname -eq $ServiceGroupName)
            {
                $matching = $True
                Write-Error "The service group name $($ServiceGroupName) already exists in NetScaler."
            }
        }

        if ($matching -eq $False)
        {
            $connectionUrl = "$($SessionObject.Protocol)://$($SessionObject.Endpoint)/nitro/v1/config/servicegroup" 
            
            $body = @{        
                "servicegroup" = @{
                    "servicegroupname" = "$($ServiceGroupName)"
                    "servicetype" = "$($ServiceType)"
                    #"cachetype" = "SERVER"
                    "cacheable" = "YES"
                    #"state" = "ENABLED"
                    #"healthmonitor" = "YES"
                    #"appflowlog" = "ENABLED"
                    "comment" = "Deployed via AutoCluster"
                }
            }

            Invoke-RestMethod -Method Post -Uri $connectionUrl -Headers $global:head -Body (ConvertTo-Json $body -Depth 3) -ContentType "application/json" -WebSession $SessionObject.Session

            Write-Output "Successfully added service group $($ServiceGroupName) to NetScaler."
            return
        }
    }
    catch 
    {
        Write-Error "ERROR in $($MyInvocation.MyCommand) on line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)"
    }
}

function Remove-NSLBServiceGroup()
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$True)]
        [PSObject]$SessionObject,
        [Parameter(Mandatory=$True)]
        [string]$ServiceGroupName
    )
    
    $connectionUrl = "$($SessionObject.Protocol)://$($SessionObject.Endpoint)/nitro/v1/config/servicegroup/$($ServiceGroupName)" 
    
    try 
    {
        return Invoke-RestMethod -Method Delete -Uri $connectionUrl -Headers $global:head -ContentType "application/json" -WebSession $SessionObject.Session
    }
    catch 
    {
        Write-Error "ERROR in $($MyInvocation.MyCommand) on line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)"
    }
}

#endregion

#region LOAD BALANCING SERVICE GROUP MEMBER BINDING FUNCTIONS

function Get-NSLBServiceGroupMemberBindings()
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$True)]
        [PSObject]$SessionObject
    )
    
    $connectionUrl = "$($SessionObject.Protocol)://$($SessionObject.Endpoint)/nitro/v1/config/servicegroup_servicegroupmember_binding?bulkbindings=yes" 
    
    try 
    {
        return Invoke-RestMethod -Method Get -Uri $connectionUrl -Headers $global:head -ContentType "application/json" -WebSession $SessionObject.Session
    }
    catch 
    {
        Write-Error "ERROR in $($MyInvocation.MyCommand) on line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)"
    }
}

function Add-NSLBServiceGroupMemberBinding()
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$True)]
        [PSObject]$SessionObject,
        [Parameter(Mandatory=$True)]
        [string]$ServiceGroupName,
        [Parameter(Mandatory=$True)]
        [string]$ServerName,
        [Parameter(Mandatory=$True)]
        [string]$Port
    )

    try 
    {
        $connectionUrl = "$($SessionObject.Protocol)://$($SessionObject.Endpoint)/nitro/v1/config/servicegroup_servicegroupmember_binding" 
            
        $body = @{        
            "servicegroup_servicegroupmember_binding" = @{
                "servicegroupname" = $ServiceGroupName
                "servername" = $ServerName
                "port" = $Port
                #"weight" = 1
            }
        }

        Invoke-RestMethod -Method Put -Uri $connectionUrl -Headers $global:head -Body (ConvertTo-Json $body -Depth 3) -ContentType "application/json" -WebSession $SessionObject.Session

        Write-Output "Successfully added service group member server binding $($ServerName) to $($ServiceGroupName)."
        return
    }
    catch 
    {
        Write-Error "ERROR in $($MyInvocation.MyCommand) on line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)"
    }
}

function Add-NSLBServiceGroupMemberSSLBinding()
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$True)]
        [PSObject]$SessionObject,
        [Parameter(Mandatory=$True)]
        [string]$ServiceGroupName,
        [Parameter(Mandatory=$True)]
        [string]$CertKeyName,
        [Parameter(Mandatory=$False)]
        [switch]$bIsCA
    )

    try 
    {
        $connectionUrl = "$($SessionObject.Protocol)://$($SessionObject.Endpoint)/nitro/v1/config/sslservicegroup_sslcertkey_binding" 
            
        switch ($bIsCA)
        {
            $True { 
                $CA = "true"
            }
            $false { 
                $CA = "false"
            }
        }

        $body = @{        
            "sslservicegroup_sslcertkey_binding" = @{
                "servicegroupname" = $ServiceGroupName
                "certkeyname" = $CertKeyName
                "ca" = $CA
            }
        }

        Invoke-RestMethod -Method Put -Uri $connectionUrl -Headers $global:head -Body (ConvertTo-Json $body -Depth 3) -ContentType "application/json" -WebSession $SessionObject.Session

        Write-Output "Successfully added SSL certificate binding $($CertKeyName) to $($ServiceGroupName)."
        return
    }
    catch 
    {
        Write-Error "ERROR in $($MyInvocation.MyCommand) on line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)"
    }
}

function Add-NSLBServiceGroupMonitorBinding()
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$True)]
        [PSObject]$SessionObject,
        [Parameter(Mandatory=$True)]
        [string]$ServiceGroupName,
        [Parameter(Mandatory=$True)]
        [string]$MonitorName # "https"
    )

    try 
    {
        $connectionUrl = "$($SessionObject.Protocol)://$($SessionObject.Endpoint)/nitro/v1/config/service_lbmonitor_binding" 

        # %7B%22params%22%3A%7B%22warning%22%3A%22YES%22%7D%2C%22servicegroup_lbmonitor_binding%22%3A%7B%2
        # servicegroupname%22%3A%22sg_InsightLab_SSL%22%2C%22monitor_name%22%3A%22https%22%2C%22monstate%22%3A%22ENABLED%22%2C%22weight%22%3A%221%22%7D%7D

        $body = @{        
            "service_lbmonitor_binding" = @{
                "name" = $ServiceGroupName
                "monitor_name" = $MonitorName
                "monstate" = "ENABLED"
            }
        }

        Invoke-RestMethod -Method Put -Uri $connectionUrl -Headers $global:head -Body (ConvertTo-Json $body -Depth 3) -ContentType "application/json" -WebSession $SessionObject.Session

        Write-Output "Successfully added protocol monitor binding $($MonitorName) to $($ServiceGroupName)."
        return
    }
    catch 
    {
        Write-Error "ERROR in $($MyInvocation.MyCommand) on line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)"
    }
}

#endregion

#region LOAD BALANCING VIRTUAL SERVERS
function Get-NSLBVServers()
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$True)]
        [PSObject]$SessionObject
    )
    
    $connectionUrl = "$($SessionObject.Protocol)://$($SessionObject.Endpoint)/nitro/v1/config/lbvserver" 
    
    try 
    {
        return Invoke-RestMethod -Method Get -Uri $connectionUrl -Headers $global:head -ContentType "application/json" -WebSession $SessionObject.Session
    }
    catch 
    {
        Write-Error "ERROR in $($MyInvocation.MyCommand) on line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)"
    }
}

function Add-NSLBVServer()
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$True)]
        [PSObject]$SessionObject,
        [Parameter(Mandatory=$True)]
        [string]$vServerName,
        [Parameter(Mandatory=$True)]
        [string]$ServiceType,
        [Parameter(Mandatory=$False)]
        [string]$IP
    )

    try 
    {
        $servers = Get-NSLBServers -SessionObject $SessionObject 
        $matching = $False

        foreach ($server in $servers.lbvserver)
        {
            if ($server.name -eq $vServerName)
            {
                $matching = $True
                Write-Error "The virtual server name $($vServerName) already exists in NetScaler."
            }
        }

        switch ($ServiceType)
        {
            "SSL" { 
                $Port = 443
            }
            "HTTP" { 
                $Port = 80
            }
        }

        if ($matching -eq $False)
        {
            $connectionUrl = "$($SessionObject.Protocol)://$($SessionObject.Endpoint)/nitro/v1/config/lbvserver" 

            if ($IP)
            {
                $body = @{        
                    "lbvserver" = @{
                        "name" = $vServerName
                        "servicetype" = $ServiceType 
                        "ipv46" = $IP
                        "port" = $Port
                        "persistencetype" = "SOURCEIP"
                        "comment" = "Deployed via AutoCluster"
                    }
                }
            }
            else 
            {
                $body = @{        
                    "lbvserver" = @{
                        "name" = $vServerName
                        "servicetype" = $ServiceType 
                        #"state" = "ENABLED"
                        "persistencetype" = "NONE"
                        #"rhistate" = "PASSIVE"
                        #"lbmethod" = "LEASTCONNECTION"
                        #"healthmonitor" = "YES"
                        #"appflowlog" = "ENABLED"
                        #"bypassaaaa" = "NO"
                        #"icmpvsrresponse" = "PASSIVE"
                        "comment" = "Deployed via AutoCluster"
                    }
                }    
            }
            
            Invoke-RestMethod -Method Post -Uri $connectionUrl -Headers $global:head -Body (ConvertTo-Json $body -Depth 3) -ContentType "application/json" -WebSession $SessionObject.Session

            Write-Output "Successfully added virtual server $($vServerName) to NetScaler."
            return
        }
    }
    catch 
    {
        Write-Error "ERROR in $($MyInvocation.MyCommand) on line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)"
    }
}

function Remove-NSLBVServer()
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$True)]
        [PSObject]$SessionObject,
        [Parameter(Mandatory=$True)]
        [string]$vServerName
    )
    
    $connectionUrl = "$($SessionObject.Protocol)://$($SessionObject.Endpoint)/nitro/v1/config/lbvserver/$($vServerName)" 
    
    try 
    {
        return Invoke-RestMethod -Method Delete -Uri $connectionUrl -Headers $global:head -ContentType "application/json" -WebSession $SessionObject.Session
    }
    catch 
    {
        Write-Error "ERROR in $($MyInvocation.MyCommand) on line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)"
    }
}
#endregion

#region LOAD BALANCING VIRTUAL SERVICE BINDINGS
# this function gets a list of all current bindings on a virtual server
function Get-NSLBVServiceBindings()
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$True)]
        [PSObject]$SessionObject
    )
    
    $connectionUrl = "$($SessionObject.Protocol)://$($SessionObject.Endpoint)/nitro/v1/config/lbvserver_service_binding?bulkbindings=yes" 
    
    try 
    {
        return Invoke-RestMethod -Method Get -Uri $connectionUrl -Headers $global:head -ContentType "application/json" -WebSession $SessionObject.Session
    }
    catch 
    {
        Write-Error "ERROR in $($MyInvocation.MyCommand) on line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)"
    }
}

# this function creates a service binding on a virtual server
# NOTE:  we don't need to delete these manually, as they will be automatically cleaned up when you delete the virtual server they are bound to
function Add-NSLBVServiceBinding()
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$True)]
        [PSObject]$SessionObject,
        [Parameter(Mandatory=$True)]
        [string]$vServerName,
        [Parameter(Mandatory=$True)]
        [string]$ServiceName
    )

    try 
    {
        $connectionUrl = "$($SessionObject.Protocol)://$($SessionObject.Endpoint)/nitro/v1/config/lbvserver_service_binding" 
            
        $body = @{        
            "lbvserver_service_binding" = @{
                "name" = $vServerName
                "servicename" = $ServiceName
                "weight" = 1
            }
        }

        Invoke-RestMethod -Method Put -Uri $connectionUrl -Headers $global:head -Body (ConvertTo-Json $body -Depth 3) -ContentType "application/json" -WebSession $SessionObject.Session

        Write-Output "Successfully added service binding $($BindingName) to $($vServerName)."
        return
    }
    catch 
    {
        Write-Error "ERROR in $($MyInvocation.MyCommand) on line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)"
    }
}

function Add-NSLBVServiceGroupBinding()
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$True)]
        [PSObject]$SessionObject,
        [Parameter(Mandatory=$True)]
        [string]$vServerName,
        [Parameter(Mandatory=$True)]
        [string]$ServiceGroupName
    )

    try 
    {
        $connectionUrl = "$($SessionObject.Protocol)://$($SessionObject.Endpoint)/nitro/v1/config/lbvserver_servicegroup_binding" 

        $body = @{        
            "lbvserver_servicegroup_binding" = @{
                "name" = $vServerName
                "servicegroupname" = $ServiceGroupName
            }
        }

        Invoke-RestMethod -Method Put -Uri $connectionUrl -Headers $global:head -Body (ConvertTo-Json $body -Depth 3) -ContentType "application/json" -WebSession $SessionObject.Session

        Write-Output "Successfully added service binding $($ServiceGroupName) to $($vServerName)."
        return
    }
    catch 
    {
        Write-Error "ERROR in $($MyInvocation.MyCommand) on line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)"
    }
}
#endregion

#region LOAD BALANCING VIRTUAL SERVER CERTIFICATE BINDINGS
function Add-NSLBVServerSSLCertificateBinding()
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$True)]
        [PSObject]$SessionObject,
        [Parameter(Mandatory=$True)]
        [string]$vServerName,
        [Parameter(Mandatory=$True)]
        [string]$CertificateName
    )

    try 
    {
        $connectionUrl = "$($SessionObject.Protocol)://$($SessionObject.Endpoint)/nitro/v1/config/sslvserver_sslcertkey_binding" 
            
        $body = @{        
            "sslvserver_sslcertkey_binding" = @{
                "vservername" = $vServerName
                "certkeyname" = $CertificateName
                "snicert" = "false"
            }
        }

        Invoke-RestMethod -Method Put -Uri $connectionUrl -Headers $global:head -Body (ConvertTo-Json $body -Depth 3) -ContentType "application/json" -WebSession $SessionObject.Session

        Write-Output "Successfully added SSL certificate binding $($CertificateName) to $($vServerName)."
        return
    }
    catch 
    {
        Write-Error "ERROR in $($MyInvocation.MyCommand) on line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)"
    }
}

function Add-NSLBVServerCACertificateBinding()
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$True)]
        [PSObject]$SessionObject,
        [Parameter(Mandatory=$True)]
        [string]$vServerName,
        [Parameter(Mandatory=$True)]
        [string]$CAName
    )

    try 
    {
        $connectionUrl = "$($SessionObject.Protocol)://$($SessionObject.Endpoint)/nitro/v1/config/sslvserver_sslcertkey_binding" 
            
        $body = @{        
            "sslvserver_sslcertkey_binding" = @{
                "vservername" = $vServerName                
                "certkeyname" = $CAName
                "ca" = "true"
                "ocspcheck" = "OPTIONAL"
                "skipcaname" = "false"
            }
        }

        Invoke-RestMethod -Method Put -Uri $connectionUrl -Headers $global:head -Body (ConvertTo-Json $body -Depth 3) -ContentType "application/json" -WebSession $SessionObject.Session

        Write-Output "Successfully added CA certificate binding $($CertificateName) to $($vServerName)."
        return
    }
    catch 
    {
        Write-Error "ERROR in $($MyInvocation.MyCommand) on line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)"
    }
}
#endregion

#region Content Switching Policies
function Add-NSContentSwitchingPolicy()
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$True)]
        [PSObject]$SessionObject,
        [Parameter(Mandatory=$True)]
        [string]$PolicyName,
        [Parameter(Mandatory=$True)]
        [string]$Rule
    )

    try 
    {
        $connectionUrl = "$($SessionObject.Protocol)://$($SessionObject.Endpoint)/nitro/v1/config/cspolicy" 
            
        $body = @{        
            "cspolicy" = @{
                "policyname" = $PolicyName
                #"url" = "https://someurl"
                "rule" = $Rule
                #"domain":<String_value>,
                #"action":<String_value>,
                #"logaction":<String_value>        
            }
        }

        Invoke-RestMethod -Method Post -Uri $connectionUrl -Headers $global:head -Body (ConvertTo-Json $body -Depth 3) -ContentType "application/json" -WebSession $SessionObject.Session

        Write-Output "Successfully added content switching policy $($PolicyName)."
        return
    }
    catch 
    {
        Write-Error "ERROR in $($MyInvocation.MyCommand) on line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)"
    }
}

function Remove-NSContentSwitchingPolicy()
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$True)]
        [PSObject]$SessionObject,
        [Parameter(Mandatory=$True)]
        [string]$PolicyName
    )
    
    $connectionUrl = "$($SessionObject.Protocol)://$($SessionObject.Endpoint)/nitro/v1/config/cspolicy/$($PolicyName)" 
    
    try 
    {
        return Invoke-RestMethod -Method Delete -Uri $connectionUrl -Headers $global:head -ContentType "application/json" -WebSession $SessionObject.Session
    }
    catch 
    {
        Write-Error "ERROR in $($MyInvocation.MyCommand) on line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)"
    }
}

function Get-NSContentSwitchingPolicyBindings()
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$True)]
        [PSObject]$SessionObject
    )
    
    $connectionUrl = "$($SessionObject.Protocol)://$($SessionObject.Endpoint)/nitro/v1/config/csvserver_cspolicy_binding?bulkbindings=yes" 
    
    try 
    {
        $policies = Invoke-RestMethod -Method Get -Uri $connectionUrl -Headers $global:head -ContentType "application/json" -WebSession $SessionObject.Session

        return $policies
    }
    catch 
    {
        Write-Error "ERROR in $($MyInvocation.MyCommand) on line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)"
    }
}

function Get-NextAvailableContentSwitchingPriority()
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$True)]
        [PSObject]$SessionObject
    )
    
    try 
    {
        $policies = Get-NSContentSwitchingPolicyBindings -SessionObject $SessionObject

        $values = @()

        foreach ($policy in $policies.csvserver_cspolicy_binding)
        {
            $values += $policy.priority
        }

        $measure = $values | Measure-Object -Maximum
        $nextAvailablePriority = $measure.Maximum + 1
        
        return $nextAvailablePriority
    }
    catch 
    {
        Write-Error "ERROR in $($MyInvocation.MyCommand) on line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)"
    }
}

function Add-NSContentSwitchingPolicyBinding()
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$True)]
        [PSObject]$SessionObject,
        [Parameter(Mandatory=$True)]
        [string]$TargetCSVServerName, # the content switching virtual server you intend to create the binding on
        [Parameter(Mandatory=$True)]
        [string]$PolicyName, # the content switching policy you intend to bind
        [Parameter(Mandatory=$True)]
        [string]$TargetLBVServerName, # the load balancing virtual server associated with the CS policy
        [Parameter(Mandatory=$True)]
        [int]$Priority
    )
    
    $connectionUrl = "$($SessionObject.Protocol)://$($SessionObject.Endpoint)/nitro/v1/config/csvserver_cspolicy_binding" 
    
    $body = @{        
        "csvserver_cspolicy_binding" = @{
            "name" = $TargetCSVServerName
            "policyname" = $PolicyName
            "targetlbvserver" = $TargetLBVServerName
            "priority" = $Priority
            #"gotopriorityexpression" = "END"
            "bindpoint" = "REQUEST"
        }
    }

    try 
    {
        Invoke-RestMethod -Method Post -Uri $connectionUrl -Headers $global:head -Body (ConvertTo-Json $body -Depth 3) -ContentType "application/json" -WebSession $SessionObject.Session

        Write-Output "Successfully added content switching policy binding $($PolicyName)."
        return
    }
    catch 
    {
        Write-Error "ERROR in $($MyInvocation.MyCommand) on line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)"
    }
}

function Remove-NSContentSwitchingPolicyBinding()
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$True)]
        [PSObject]$SessionObject,
        [Parameter(Mandatory=$True)]
        [string]$TargetCSVServerName, # the content switching virtual server you intend to remove the binding from
        [Parameter(Mandatory=$True)]
        [string]$PolicyName # the content switching policy binding you wish to remove
    )

    # http://192.168.61.101/nitro/v1/config/csvserver_cspolicy_binding?args=name:labwebservers-https,policyname:switch_SUWCUBTWNSIT001_443
    
    $connectionUrl = "$($SessionObject.Protocol)://$($SessionObject.Endpoint)/nitro/v1/config/csvserver_cspolicy_binding?args=name:$($TargetCSVServerName),policyname:$($PolicyName)" 
    
    try 
    {
        return Invoke-RestMethod -Method Delete -Uri $connectionUrl -Headers $global:head -ContentType "application/json" -WebSession $SessionObject.Session
    }
    catch 
    {
        Write-Error "ERROR in $($MyInvocation.MyCommand) on line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)"
    }
}

#endregion

#region RESPONDER ACTIONS
function Add-NSResponderAction()
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$True)]
        [PSObject]$SessionObject,
        [Parameter(Mandatory=$True)]
        [string]$Name, 
        [Parameter(Mandatory=$True)]
        [string]$Type, 
        [Parameter(Mandatory=$True)]
        [string]$Target,
        [Parameter(Mandatory=$True)]
        [string]$ResponseCode
    )
    
    $connectionUrl = "$($SessionObject.Protocol)://$($SessionObject.Endpoint)/nitro/v1/config/responderaction" 

    $body = @{        
        "responderaction" = @{
            "name" = $Name
            "type" = $Type
            "target" = $Target
            "responsestatuscode" = $ResponseCode
            "comment" = "Deployed via AutoCluster"
        }
    }

    try 
    {
        Invoke-RestMethod -Method Post -Uri $connectionUrl -Headers $global:head -Body (ConvertTo-Json $body -Depth 3) -ContentType "application/json" -WebSession $SessionObject.Session

        Write-Output "Successfully added Responder Action $($Name)."
        return
    }
    catch 
    {
        Write-Error "ERROR in $($MyInvocation.MyCommand) on line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)"
    }
}

function Remove-NSResponderAction()
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$True)]
        [PSObject]$SessionObject,
        [Parameter(Mandatory=$True)]
        [string]$Name # the content switching policy binding you wish to remove
    )
    
    $connectionUrl = "$($SessionObject.Protocol)://$($SessionObject.Endpoint)/nitro/v1/config/responderaction/$($Name)" 
    
    try 
    {
        return Invoke-RestMethod -Method Delete -Uri $connectionUrl -Headers $global:head -ContentType "application/json" -WebSession $SessionObject.Session
    }
    catch 
    {
        Write-Error "ERROR in $($MyInvocation.MyCommand) on line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)"
    }
}

function Get-NSResponderActions()
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$True)]
        [PSObject]$SessionObject
    )
    
    $connectionUrl = "$($SessionObject.Protocol)://$($SessionObject.Endpoint)/nitro/v1/config/responderaction" 
    
    try 
    {
        $actions = Invoke-RestMethod -Method Get -Uri $connectionUrl -Headers $global:head -ContentType "application/json" -WebSession $SessionObject.Session

        return $actions
    }
    catch 
    {
        Write-Error "ERROR in $($MyInvocation.MyCommand) on line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)"
    }
}

#endregion

#region RESPONDER POLICIES
function Add-NSResponderPolicy()
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$True)]
        [PSObject]$SessionObject,
        [Parameter(Mandatory=$True)]
        [string]$Name, 
        [Parameter(Mandatory=$True)]
        [string]$Rule, 
        [Parameter(Mandatory=$True)]
        [string]$Action
    )
    
    $connectionUrl = "$($SessionObject.Protocol)://$($SessionObject.Endpoint)/nitro/v1/config/responderpolicy" 

    $body = @{        
        "responderpolicy" = @{
            "name" = $Name
            "rule" = $Rule
            "action" = $Action
            "comment" = "Deployed via AutoCluster"
        }
    }

    try 
    {
        Invoke-RestMethod -Method Post -Uri $connectionUrl -Headers $global:head -Body (ConvertTo-Json $body -Depth 3) -ContentType "application/json" -WebSession $SessionObject.Session

        Write-Output "Successfully added Responder Policy $($Name)."
        return
    }
    catch 
    {
        Write-Error "ERROR in $($MyInvocation.MyCommand) on line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)"
    }
}

function Remove-NSResponderPolicy()
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$True)]
        [PSObject]$SessionObject,
        [Parameter(Mandatory=$True)]
        [string]$Name 
    )
    
    $connectionUrl = "$($SessionObject.Protocol)://$($SessionObject.Endpoint)/nitro/v1/config/responderpolicy/$($Name)" 
    
    try 
    {
        return Invoke-RestMethod -Method Delete -Uri $connectionUrl -Headers $global:head -ContentType "application/json" -WebSession $SessionObject.Session
    }
    catch 
    {
        Write-Error "ERROR in $($MyInvocation.MyCommand) on line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)"
    }
}

function Get-NSResponderPolicies()
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$True)]
        [PSObject]$SessionObject
    )
    
    $connectionUrl = "$($SessionObject.Protocol)://$($SessionObject.Endpoint)/nitro/v1/config/responderpolicy" 
    
    try 
    {
        $policies = Invoke-RestMethod -Method Get -Uri $connectionUrl -Headers $global:head -ContentType "application/json" -WebSession $SessionObject.Session

        return $policies
    }
    catch 
    {
        Write-Error "ERROR in $($MyInvocation.MyCommand) on line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)"
    }
}

function Get-NSContentSwitchingResponderPolicyBinding()
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$True)]
        [PSObject]$SessionObject,
        [Parameter(Mandatory=$True)]
        [string]$Name 
    )
    
    $connectionUrl = "$($SessionObject.Protocol)://$($SessionObject.Endpoint)/nitro/v1/config/responderpolicy_binding/$($Name)" 
    
    try 
    {
        $policy = Invoke-RestMethod -Method Get -Uri $connectionUrl -Headers $global:head -ContentType "application/json" -WebSession $SessionObject.Session

        return $policy
    }
    catch 
    {
        Write-Error "ERROR in $($MyInvocation.MyCommand) on line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)"
    }
}

function Get-NSContentSwitchingResponderPolicyBindings()
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$True)]
        [PSObject]$SessionObject
    )
    
    $connectionUrl = "$($SessionObject.Protocol)://$($SessionObject.Endpoint)/nitro/v1/config/responderpolicy_binding?bulkbindings=yes" 
    
    try 
    {
        $policies = Invoke-RestMethod -Method Get -Uri $connectionUrl -Headers $global:head -ContentType "application/json" -WebSession $SessionObject.Session

        return $policies
    }
    catch 
    {
        Write-Error "ERROR in $($MyInvocation.MyCommand) on line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)"
    }
}

function Get-NextAvailableContentSwitchingResponderPolicyPriority()
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$True)]
        [PSObject]$SessionObject,
        [Parameter(Mandatory=$True)]
        [string]$CsvServer
    )
    
    try 
    {
        $policies = Get-NSContentSwitchingResponderPolicyBindings -SessionObject $SessionObject
        $values = @()
        
        foreach ($policy in $policies.responderpolicy_binding.name)
        {    
            $boundServer = "REQ VSERVER $($CsvServer)"
            $policybinding = Get-NSContentSwitchingResponderPolicyBinding -SessionObject $SessionObject -Name $policy
            $boundPolicies = $policybinding.responderpolicy_binding.responderpolicy_csvserver_binding | Where-Object {$_.boundto -eq $boundServer}

            foreach ($boundPolicy in $boundPolicies)
            {
                $values += $boundPolicy.priority
            }
        }

        $measure = $values | Measure-Object -Maximum
        $nextAvailablePriority = $measure.Maximum + 1
        
        return $nextAvailablePriority
    }
    catch 
    {
        Write-Error "ERROR in $($MyInvocation.MyCommand) on line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)"
    }
}

function Add-NSContentSwitchingResponderPolicyBinding()
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$True)]
        [PSObject]$SessionObject,
        [Parameter(Mandatory=$True)]
        [string]$PolicyName, 
        [Parameter(Mandatory=$True)]
        [double]$Priority, 
        [Parameter(Mandatory=$True)]
        [string]$CsvServer
    )
    
    $connectionUrl = "$($SessionObject.Protocol)://$($SessionObject.Endpoint)/nitro/v1/config/csvserver_responderpolicy_binding" 

    $body = @{        
        "csvserver_responderpolicy_binding" = @{
            "policyname" = $PolicyName
            "priority" = $Priority
            "name" = $CsvServer
            #"bindpoint" = "REQUEST"
            #"targetlbvserver" = $CsvServer
            #"gotopriorityexpression" = "END"
            #"comment" = "Deployed via AutoCluster"
        }
    }

    try 
    {
        Invoke-RestMethod -Method Post -Uri $connectionUrl -Headers $global:head -Body (ConvertTo-Json $body -Depth 3) -ContentType "application/json" -WebSession $SessionObject.Session

        Write-Output "Successfully bound Responder Policy $($PolicyName) to the CSVS $($CsvServer)."
        return
    }
    catch 
    {
        Write-Error "ERROR in $($MyInvocation.MyCommand) on line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)"
    }
}

function Remove-NSContentSwitchingResponderPolicyBinding()
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$True)]
        [PSObject]$SessionObject,
        [Parameter(Mandatory=$True)]
        [string]$Name,
        [Parameter(Mandatory=$True)]
        [string]$CsvServer 
    )
    #http://192.168.61.101/nitro/v1/config/csvserver_responderpolicy_binding?args=name:labwebservers_http,policyname:SecureRedirect_QAOpsTest,bindpoint:REQUEST
    $connectionUrl = "$($SessionObject.Protocol)://$($SessionObject.Endpoint)/nitro/v1/config/csvserver_responderpolicy_binding?args=name:$($CsvServer),policyname:$($Name),bindpoint:REQUEST" 
    
    try 
    {
        return Invoke-RestMethod -Method Delete -Uri $connectionUrl -Headers $global:head -ContentType "application/json" -WebSession $SessionObject.Session
    }
    catch 
    {
        Write-Error "ERROR in $($MyInvocation.MyCommand) on line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)"
    }
}

#endregion