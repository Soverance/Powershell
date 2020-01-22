# NetBox Automation Module 
# Scott McCutchen
# DevOps Engineer
# scott.mccutchen@soverance.com

# This module contains functions relevant to working with NetBox

# Netbox has a strong API, but there's also an available Ansible module... so I chose to use that instead of writing API code.

##############################################
###
###  Module Start
###
##############################################


# netbox api config
# the commented-out global vars are passed to this module via TFS/ADS variables
#[string]$global:token = 'YourNetBoxApiToken'
#[string]$global:netbox_host = 'http://netbox.soverance.com'
#[string]$global:NetBoxCluster = 'NameOfYourNetBoxCluster'

function Get-NetBoxVirtualMachineID()
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$True)]
        [string]$APIurl,
        [Parameter(Mandatory=$True)]
        [string]$Token,
        [Parameter(Mandatory=$True)]
        [string]$Name
    )

    $netbox_api_headers = @{
        "Content-Type" = "application/json"
        "Authorization" = "Token $($Token)"
    }

    # get machine id
    try{
        $machine_url = "$($APIurl)/api/virtualization/virtual-machines/?name=$($Name)"
        $machine = Invoke-RestMethod -Method Get -Uri $machine_url -Headers $netbox_api_headers -ContentType "application/json"

        if($machine.count -eq 0){
            Write-Host "Failed to get ID. No entry found in NetBox for virtual machine: $($Name)."
        }

        return $machine.results.id
    }
    catch{
        Write-Host "ERROR on line $($_.InvocationInfo.ScriptLineNumber): unable to get id for $($Name), more details -> $($_.Exception.Message)"
    }
}

# this function gets the specified NetBox Cluster ID
function Get-NetBoxClusterId()
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$True)]
        [string]$APIurl,
        [Parameter(Mandatory=$True)]
        [string]$Token,
        [Parameter(Mandatory=$True)]
        [string]$Cluster
    )

    $netbox_api_headers = @{
        "Content-Type" = "application/json"
        "Authorization" = "Token $($Token)"
    }

    # get cluster id
    try
    {
        $cluster_url = "$($APIurl)/api/virtualization/clusters/?name=$($Cluster)"
        $cluster_obj = Invoke-RestMethod -Method Get -Uri $cluster_url -Headers $netbox_api_headers -ContentType "application/json"
        
        if($cluster_obj.count -eq 0)
        {
            Write-Host "NetBox Cluster $($Cluster) not found"
        }
        return $cluster_obj.results.id
    }
    catch
    {
        Write-Error "ERROR on line $($_.InvocationInfo.ScriptLineNumber): unable to get ID for cluster $($Cluster), more details -> $($_.Exception.Message)"
    }
}

# this function returns the ID of a specified device type
function Get-NetBoxDeviceTypeId()
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$True)]
        [string]$APIurl,
        [Parameter(Mandatory=$True)]
        [string]$Token,
        [Parameter(Mandatory=$True)]
        [string]$DeviceType
    )

    $netbox_api_headers = @{
        "Content-Type" = "application/json"
        "Authorization" = "Token $($Token)"
    }
    
    # get all device types
    try
    {
        $device_url = "$($APIurl)/api/dcim/device-types"
        $device_obj = Invoke-RestMethod -Method Get -Uri $device_url -Headers $netbox_api_headers -ContentType "application/json"
        if($device_obj.count -eq 0)
        {
            Write-Host "No device types found."
            exit
        }
        return $device_obj.results.id
    }
    catch
    {
        Write-Error "ERROR on line $($_.InvocationInfo.ScriptLineNumber): unable to get ID for device type $($DeviceType), more details -> $($_.Exception.Message)"
        exit
    }
}

# this function creates a new virtual machine entry in NetBox
# note that this function will return a 400 Bad Request error if the machine already exists in Netbox.
function New-NetBoxEntry()
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$True)]
        [string]$APIurl,
        [Parameter(Mandatory=$True)]
        [string]$Token,
        [Parameter(Mandatory=$True)]
        [string]$Cluster,
        [Parameter(Mandatory=$True)]
        [string]$Name,
        [Parameter(Mandatory=$True)]
        [string]$DnsName,
        [Parameter(Mandatory=$True)]
        [string]$IP,
        [Parameter(Mandatory=$True)]
        [string]$Subnet,
        [Parameter(Mandatory=$True)]
        [array]$Tags
    )

    $netbox_api_headers = @{
        "Content-Type" = "application/json"
        "Authorization" = "Token $($Token)"
    }
    
    $cluster_id = Get-NetBoxClusterId -APIUrl $APIurl -Token $Token -Cluster $Cluster

    [hashtable]$machine_body = @{
        "name" = $Name
        "status" = 1
        "cluster" = $cluster_id
        #"primary_ip4" = $IP
        "tags" = $Tags
        "role" = @{
            "name" = "AutoCluster Node"
            "slug" = "autocluster-node"
        }
    }

    # add machine
    try{
        $machine_url = "$($APIurl)/api/virtualization/virtual-machines/"
        $machine = Invoke-RestMethod -Method Post -Uri $machine_url -Headers $netbox_api_headers -Body (ConvertTo-Json $machine_body) -ContentType "application/json"
    }
    catch{
        Write-Error "ERROR on line $($_.InvocationInfo.ScriptLineNumber): unable to add machine $Name, more details -> $($_.Exception.Message)"
        exit 1
    }   

    [hashtable]$interface_body =  @{
            'name' = "primary"
            'status' = 1
            'virtual_machine' = $machine.id
        }

    # add interface
    try{
        $interface_url = "$($APIurl)/api/virtualization/interfaces/"
        $interface = Invoke-RestMethod -Method Post -Uri $interface_url -Headers $netbox_api_headers -Body (ConvertTo-Json $interface_body) -ContentType "application/json"
    }
    catch{
        Write-Error "ERROR on line $($_.InvocationInfo.ScriptLineNumber): unable to add interface for machine $Name, more details -> $($_.Exception.Message)"
        exit
    }   

    [hashtable]$ip_body =  @{
            'address' = "$($IP)/$($Subnet)"
            'status' = 1
            'dns_name' = "$($DnsName)"
            'description' = ""
            'interface' = $interface.id
            "tags" = $Tags
        }
    
    # add ip address
    try{
        Start-Sleep -Seconds 5  # we're only sleeping for a few seconds here because netbox sucks sometimes and fails to add this IP address
        $ip_url = "$($APIurl)/api/ipam/ip-addresses/"
        $machineip = Invoke-RestMethod -Method Post -Uri $ip_url -Headers $netbox_api_headers -Body (ConvertTo-Json $ip_body) -ContentType "application/json"
    }
    catch{
        Write-Error "ERROR on line $($_.InvocationInfo.ScriptLineNumber): unable to add ip address $IP, more details -> $($_.Exception.Message)"
        exit
    }    
    Write-Output "Machine $Name added to NetBox successfully."
}

function Remove-NetBoxTag()
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$True)]
        [string]$APIurl,
        [Parameter(Mandatory=$True)]
        [string]$Token,
        [Parameter(Mandatory=$True)]
        [string]$Tag
    )

    $netbox_api_headers = @{
        "Content-Type" = "application/json"
        "Authorization" = "Token $($Token)"
    }

    # get tag id
    try
    {
        $tag_ID = Get-NetBoxTagId -APIurl $APIurl -Token $Token -Tag $Tag
        $tag_url = "$($APIurl)/api/extras/tags/$($tag_ID)/"
        Invoke-RestMethod -Method Delete -Uri $tag_url -Headers $netbox_api_headers -ContentType "application/json"
    }
    catch
    {
        Write-Error "ERROR on line $($_.InvocationInfo.ScriptLineNumber): unable to get ID for tag $($Tag), more details -> $($_.Exception.Message)"
    }
}

# this function gets the ID of a specified tag - NetBox tags are case sensitive!
function Get-NetBoxTagId()
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$True)]
        [string]$APIurl,
        [Parameter(Mandatory=$True)]
        [string]$Token,
        [Parameter(Mandatory=$True)]
        [string]$Tag
    )

    $netbox_api_headers = @{
        "Content-Type" = "application/json"
        "Authorization" = "Token $($Token)"
    }

    # get tag id
    try
    {
        $tag_url = "$($APIurl)/api/extras/tags/?name=$($Tag)"
        $tag_obj = Invoke-RestMethod -Method Get -Uri $tag_url -Headers $netbox_api_headers -ContentType "application/json"
        
        if($tag_obj.count -eq 0)
        {
            Write-Host "NetBox Tag $($Tag) not found"
        }
        return $tag_obj.results.id
    }
    catch
    {
        Write-Error "ERROR on line $($_.InvocationInfo.ScriptLineNumber): unable to get ID for tag $($Tag), more details -> $($_.Exception.Message)"
    }
}

# this function is called by the AutoCluster deployment to create a NetBox entry for every node in a cluster
function Add-AllEntries()
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$True)]
        [string]$APIurl,
        [Parameter(Mandatory=$True)]
        [string]$Token,
        [Parameter(Mandatory=$True)]
        [string]$Cluster,
        [Parameter(Mandatory=$True)]
        [PSObject]$Inventory
    )

    try
    {
        foreach ($Node in $Inventory)
        {
            New-NetBoxEntry -APIUrl $APIurl -Token $Token -Cluster $Cluster -Name $Node.Hostname -DnsName $Node.FQDN -IP $Node.IPAddress -Subnet $Node.SubnetPrefix -Tags $Node.Tags
        }
    }
    catch{
        Write-Error "ERROR on line $($_.InvocationInfo.ScriptLineNumber): unable to add netbox entry, more details -> $($_.Exception.Message)"
        exit
    }
}

function Remove-NetBoxEntry()
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$True)]
        [string]$APIurl,
        [Parameter(Mandatory=$True)]
        [string]$Token,
        [Parameter(Mandatory=$True)]
        [string]$Name
    )

    $netbox_api_headers = @{
        "Content-Type" = "application/json"
        "Authorization" = "Token $($Token)"
    }

    try
    {
        $MachineID = Get-NetBoxVirtualMachineID -APIurl $APIurl -Token $Token -Name $Name

        if ($MachineID)
        {
            $delete_url = "$($APIurl)/api/virtualization/virtual-machines/$($MachineID)/"
            Invoke-RestMethod -Method Delete -Uri $delete_url -Headers $netbox_api_headers -ContentType "application/json"            
        }
    }
    catch
    {
        Write-Error "ERROR on line $($_.InvocationInfo.ScriptLineNumber): Unable to delete entry for $Name, more details -> $($_.Exception.Message)"
    }    
}
