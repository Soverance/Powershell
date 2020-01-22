# DHCP Automation Module for Automatic Cluster Deployments
# Scott McCutchen
# DevOps Engineer
# scott.mccutchen@soverance.com

# This module contains functions for working with DHCP servers during AutoCluster deployments

#region
##############################################
###
###  Functions
###
##############################################

# this function converts a DHCP lease into a DHCP reservation
# NOTE:  the domain user you specify here must be a member of the "DHCP Administrators" group as well as the "Domain Admins" group (i'm aware that's a big security flaw... working on a better solution)
# as far as I'm aware, there is no way to give granular permissions for DHCP (such as only allowing him to create reservations)
function Convert-DHCPLeaseToReservation()
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$True)]
        [PSObject]$Inventory,  # this param expects an Inventory custom PSObject

        [Parameter(Mandatory=$True)]
        [string]$Domain, # = $(throw "-Domain : the fully-qualified active directory domain you wish this cluster to join."),
        
        [Parameter(Mandatory=$True)]
        [string]$DomainUser, # = $(throw "-DomainUser : domain join service account for the active directory domain."), 
        
        [Parameter(Mandatory=$True)]
        [string]$DomainPass, # = $(throw "-DomainPass : password for the AD domain service account."), 
        
        # this session option object should have been created earlier for joining machines to the domain, so we'll use the same one here
        [Parameter(Mandatory=$True)]
        [System.Management.Automation.Remoting.PSSessionOption]$SessionOption
    )

    try
    {        
        $pass = ConvertTo-SecureString -String $DomainPass -AsPlainText -Force
        $domainCreds = New-Object -TypeName "System.Management.Automation.PSCredential" -ArgumentList $DomainUser, $pass

        try 
        {
            $DC = Get-ADDomainController -Filter * -Server $Domain -Credential $domainCreds # grab the first domain controller in the target domain
            
            # get all the files in the DhcpServer module directory
            # we have to split this up and do the process individually for each subfolder simply because we're forced to use the Get-Content cmdlet on older versions of PS, which doesn't have a -Recursive param
            # this block assumes that you've copied this module into the same modules directory as the DhcpServer module
            $parent = (Get-Item $PSScriptRoot).Parent.FullName
            $DhcpModulePath = "$($parent)\DhcpServer"
            $DhcpLocalePath = "$($parent)\DhcpServer\en-US"
            $moduleFileNames = Get-ChildItem -Path $DhcpModulePath -File
            $localeFileNames = Get-ChildItem -Path $DhcpLocalePath -File

            $ModuleFileObjects = @()
            $LocaleFileObjects = @()

            # create a new custom PSObject that contains the file name and content as members for each file
            foreach ($file in $moduleFileNames)
            {
                $FileInfo = New-Object -TypeName PSObject
                $FileInfo | Add-Member -MemberType NoteProperty -Name Name -Value $file.Name
                $FileInfo | Add-Member -MemberType NoteProperty -Name Content -Value (Get-Content $file.FullName -Raw) # Get-Content has no recurse param, so this returns an error on nested folder structures
                $ModuleFileObjects += $FileInfo
            }

            foreach ($file in $localeFileNames)
            {
                $FileInfo = New-Object -TypeName PSObject
                $FileInfo | Add-Member -MemberType NoteProperty -Name Name -Value $file.Name
                $FileInfo | Add-Member -MemberType NoteProperty -Name Content -Value (Get-Content $file.FullName -Raw) # Get-Content has no recurse param, so this returns an error on nested folder structures
                $LocaleFileObjects += $FileInfo
            }
            
            foreach ($Node in $Inventory)
            {
                # Start a remote session on the cluster node
                # I really wanted to do this by starting a session on the cluster node itself,
                # but this results in an "invalid namespace" error when running DhcpServer cmdlets 
                # (because you don't get the DHCP WMI namespace without installing the DHCP Server role, and so just copying over the PSModule is not enough to make it work)
                # instead, we must create a remote session directly on a DHCP server itself
                $session = New-PSSession -ComputerName $DC[0].IPv4Address -Credential $domainCreds -UseSSL -SessionOption $SessionOption # create a new ps session on the target node

                # this is the easy way to copy that module over to the remote computer... but we can't use the -ToSession param until our build nodes run PS v5.0
                # instead of just a one-liner, we're gonna have to do all this janky Set-Content stuff like you see above/below
                #Copy-Item -Path $DhcpModulePath -Destination "..\WindowsPowerShell\Modules\DhcpServer" -ToSession $session -Force

                # open a new session on the DHCP server, and execute commands via ScriptBlock
                Invoke-Command -Session $session -ScriptBlock { 
                    
                    # Get-Location should return the current user's document directory
                    # using the user's default PS Module directory allows us to use the Import-Module cmdlet without adding the directory to the PSModulePath environment variable.
                    $DhcpModulePath = (Get-Location).Path + "\WindowsPowerShell\Modules\DhcpServer"
                    $DhcpLocalePath = (Get-Location).Path + "\WindowsPowerShell\Modules\DhcpServer\en-US"
                    # make sure the path for the DhcpServer module exists in the user's directory, create it if not (it won't exist, in most cases, when this script is first run on a node)                    
                    if (!(Test-Path -Path $DhcpLocalePath))
                    {
                        # we don't bother to create the module's default dir because we'll get it for free by creating the nested dir 
                        New-Item -Path $DhcpLocalePath -ItemType "directory" -Force
                    } 
                    
                    # copy the DhcpServer PSModule files over to the remote server into the user-specific PS modules directory
                    foreach ($file in $Using:ModuleFileObjects)
                    {
                        $filePath = "$($DhcpModulePath)\$($file.Name)"
                        $file.Content | Set-Content -Path $filePath -Force
                    }
                    foreach ($file in $Using:LocaleFileObjects)
                    {
                        $filePath = "$($DhcpLocalePath)\$($file.Name)"
                        $file.Content | Set-Content -Path $filePath -Force
                    }
    
                    # finally we can import the DhcpServer module into this remote PS session
                    Import-Module DhcpServer 
    
                    # get the current DHCP lease, and turn it into a reservation for that IP address
                    Get-DhcpServerv4Lease -ComputerName $Using:DC[0].IPv4Address -IPAddress $Using:ServerInfo.IPAddress | Add-DhcpServerv4Reservation -ComputerName $Using:DC[0].IPv4Address 
                }

                # finally, close the PS Session we created earlier, since there may be a few of them open on the DHCP server now depending on how many nodes we did this for
                Remove-PSSession -Session $session
            }   
        }
        catch 
        {
            Write-Error "ERROR in $($MyInvocation.MyCommand) on line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)"
            exit 1
        }  
    }
    catch
    {
        Write-Error "ERROR in $($MyInvocation.MyCommand) on line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)"
        exit 1
    }
}

# this function is not yet operational
function Remove-DHCPReservation()
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$True)]
        [PSObject]$Inventory,  # this param expects an Inventory custom PSObject

        [Parameter(Mandatory=$True)]
        [string]$Domain, # = $(throw "-Domain : the fully-qualified active directory domain you wish this cluster to join."),
        
        [Parameter(Mandatory=$True)]
        [string]$DomainUser, # = $(throw "-DomainUser : domain join service account for the active directory domain."), 
        
        [Parameter(Mandatory=$True)]
        [string]$DomainPass, # = $(throw "-DomainPass : password for the AD domain service account."),

        [Parameter(Mandatory=$True)]
        [System.Management.Automation.Remoting.PSSessionOption]$SessionOption
    )

    try
    {        
        $pass = ConvertTo-SecureString -String $DomainPass -AsPlainText -Force
        $domainCreds = New-Object -TypeName "System.Management.Automation.PSCredential" -ArgumentList $DomainUser, $pass

        $AuthType = "Negotiate"

        # create a remote session on the DHCP server
        $session = New-PSSession -Credential $domainCreds -Authentication $AuthType -SessionOption $SessionOption -UseSsl
        
        foreach ($Node in $Inventory)
        {
            Invoke-Command -Session $session -ScriptBlock { Remove-DhcpServerv4Reservation -ComputerName $Domain -IPAddress $Node.IPAddress }

            Write-Output "Successfully removed DHCP reservation for $($Node.Hostname)."
        }  
    }
    catch
    {
        Write-Error "ERROR in $($MyInvocation.MyCommand) on line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)"
        exit 1
    }
}

#endregion
