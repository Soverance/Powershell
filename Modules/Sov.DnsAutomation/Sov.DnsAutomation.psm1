# DNS Automation Module for Automatic Cluster Deployments
# Scott McCutchen
# DevOps Engineer
# scott.mccutchen@soverance.com

# This module contains functions for working with DNS servers during AutoCluster deployments

# this module is dependent on the Microsoft DnsServer PowerShell module, which must be imported into the appropriate PS session before executing cmdlets from this module
# Note that the DnsServer and DnsClient PS Modules require PS 3.0 or later

#region
##############################################
###
###  Functions
###
##############################################

# this function adds a new DNS record for a node
function Add-SisenseDnsRecord()
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
            $DC = Get-ADDomainController -Filter * -Server $Domain -Credential $domainCreds # grab the first domain controller in the target domain, which should be the first available DNS server as well
                        
            if ($DC)
            {
                # this is the easy way to copy that module over to the remote computer... but we can't use the -ToSession param until our build nodes run PS v5.0
                # instead of just a one-liner, we're gonna have to do all this janky Set-Content stuff like you'll see below
                #Copy-Item -Path $DnsModulePath -Destination "..\WindowsPowerShell\Modules\DnsServer" -ToSession $session -Force

                # get all the files in the DnsServer module directory
                # unlike the DhcpServer module, the DnsServer module doesn't have any subfolders
                # this block assumes that you've copied this module into the same modules directory as the DnsServer module
                $parent = (Get-Item $PSScriptRoot).Parent.FullName
                $DnsModulePath = "$($parent)\DnsServer"  # actual production path, when run via TFS/ADS release
                $ClientModulePath = "$($parent)\DnsClient"
                $moduleFileNames = Get-ChildItem -Path $DnsModulePath -File
                $clientModuleFileNames = Get-ChildItem -Path $ClientModulePath -File

                $ModuleFileObjects = @()
                $ClientModuleFileObjects = @()

                # create a new custom PSObject that contains the file name and content as members for each file of the Microsoft DnsServer PSModule
                foreach ($file in $moduleFileNames)
                {
                    $FileInfo = New-Object -TypeName PSObject
                    $FileInfo | Add-Member -MemberType NoteProperty -Name Name -Value $file.Name
                    $FileInfo | Add-Member -MemberType NoteProperty -Name Content -Value (Get-Content $file.FullName -Raw) # Get-Content has no recurse param, so this returns an error on nested folder structures
                    $ModuleFileObjects += $FileInfo
                }

                foreach ($file in $clientModuleFileNames)
                {
                    $ClientFileInfo = New-Object -TypeName PSObject
                    $ClientFileInfo | Add-Member -MemberType NoteProperty -Name Name -Value $file.Name
                    $ClientFileInfo | Add-Member -MemberType NoteProperty -Name Content -Value (Get-Content $file.FullName -Raw) # Get-Content has no recurse param, so this returns an error on nested folder structures
                    $ClientModuleFileObjects += $ClientFileInfo
                }
                
                foreach ($Node in $Inventory)
                {
                    # Start a remote session on the first available domain controller
                    # I really wanted to do this by starting a session on the cluster node itself,
                    # but doing so results in an "invalid namespace" error when running DnsServer cmdlets
                    $session = New-PSSession -ComputerName $DC[0].IPv4Address -Credential $domainCreds -UseSSL -SessionOption $SessionOption # create a new ps session on the target node

                    if ($session)
                    {
                        Invoke-Command -Session $session -ScriptBlock { 

                            # Get-Location should return the current user's document directory
                            # using the user's default PS Module directory allows us to use the Import-Module cmdlet without adding the directory to the PSModulePath environment variable.
                            $DnsModulePath = (Get-Location).Path + "\WindowsPowerShell\Modules\DnsServer"
                            $ClientModulePath = (Get-Location).Path + "\WindowsPowerShell\Modules\DnsClient"
                            $ModuleFileObjects = $Using:ModuleFileObjects
                            $ClientModuleFileObjects = $Using:ClientModuleFileObjects
                            # make sure the path for the DnsServer module exists in the user's directory, create it if not (it won't exist, in most cases, when this script is first run on a node)
                            # we don't bother to create the module's default dir because we'll get it for free by creating the nested dir 
                            if (!(Test-Path -Path $DnsModulePath))
                            {
                                New-Item -Path $DnsModulePath -ItemType "directory" -Force
                            } 

                            if (!(Test-Path -Path $ClientModulePath))
                            {
                                New-Item -Path $ClientModulePath -ItemType "directory" -Force
                            } 
                            
                            # copy the DnsServer PSModule files over to the remote server into the user-specific PS modules directory
                            foreach ($file in $ModuleFileObjects)
                            {
                                $filePath = "$($DnsModulePath)\$($file.Name)"
                                $file.Content | Set-Content -Path $filePath -Force
                            }

                            foreach ($file in $ClientModuleFileObjects)
                            {
                                $filePath = "$($ClientModulePath)\$($file.Name)"
                                $file.Content | Set-Content -Path $filePath -Force
                            }
            
                            # finally we can import the DnsServer module into this remote PS session
                            Import-Module DnsServer 
                            Import-Module DnsClient

                            # separate the dns zone from the full Sisense URL
                            $DnsHost = ($Using:Node.SisenseUrl).Split(".")[0]
                            $DnsZone = ($Using:Node.SisenseUrl).Substring(($Using:Node.SisenseUrl).IndexOf(".") + 1)

                            # check to see if a record for this hostname already exists in this dns zone
                            # if it does, get the current record, create a copy in memory, modify it with new data, and post the updated record to the dns server
                            # NOTE:  the "Resolve-DnsName" cmdlet requires the DnsClient psmodule
                            
                            if (Resolve-DnsName -Name $Using:Node.SisenseUrl)
                            {                                
                                Write-Output "A record for the hostname $($Using:Node.SisenseUrl) already exists.  Updating record with new IP information..."
                                $OldRecord = Get-DnsServerResourceRecord -Name $DnsHost -ZoneName $DnsZone -RRType "A"
                                $NewRecord = $OldRecord.Clone()
                                $NewRecord.RecordData.IPv4Address = $Using:Node.IPAddress
                                Set-DnsServerResourceRecord -NewInputObject $NewRecord -OldInputObject $OldRecord -ZoneName $DnsZone -PassThru

                                if ($?)
                                {
                                    Write-Output "The record for the hostname $($Using:Node.SisenseUrl) was successfully updated with new IP information."
                                }
                            }
                            # if the record didn't previously exist, simply create a new one
                            else 
                            {
                                # this command doesn't work on Server 2008, despite being available to the module.  It'll throw an "invalid namespace" error
                                Add-DnsServerResourceRecordA -Name $DnsHost -ZoneName $DnsZone -AllowUpdateAny -IPv4Address $Using:Node.IPAddress -TimeToLive 01:00:00
                                                                
                                if ($?)
                                {
                                    Write-Output "A record for the hostname $($Using:Node.SisenseUrl) was successfully created."
                                }
                            }
                        }
        
                        # finally, close the PS Session we created earlier, since there may be a few of them open on the DNS server now
                        Remove-PSSession -Session $session
                    }
                    else 
                    {
                        Write-Error "ERROR in $($MyInvocation.MyCommand) on line $($_.InvocationInfo.ScriptLineNumber): SESSION INVALID - $($_.Exception.Message)"
                        exit 1
                    }
                }  
            }  
        }
        catch 
        {
            Write-Error "ERROR in $($MyInvocation.MyCommand) on line $($_.InvocationInfo.ScriptLineNumber): GENERIC FAILURE - $($_.Exception.Message)"
            exit 1
        }  
    }
    catch
    {
        Write-Error "ERROR in $($MyInvocation.MyCommand) on line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)"
        exit 1
    }
}


#endregion
