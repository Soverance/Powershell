# Linux Automation Module via WinSCP
# Scott McCutchen
# DevOps Engineer
# scott.mccutchen@soverance.com

# This module contains functions relevant to working with the Linux command line via SSH

# This module is dependent on the WinSCP .NET assembly

##############################################
###
###  Module Start
###
##############################################

# Load WinSCP .NET assembly
# You must also include the WinSCP executable (WinSCP.exe) in the same directory
# https://winscp.net/eng/docs/library_install#deploying
$parent = (Get-Item $PSScriptRoot).Parent.Parent.FullName
$fullAssemblyPath = $parent + "\Dependencies\WinSCP-5.15.3-Automation\WinSCPnet.dll"
Add-Type -Path $fullAssemblyPath

# Add WinSCP DLL to Global Assembly Cache 
# NOTE:  NOT NECESSARY FOR THIS AUTOMATION PROCESS...
# If the DLL is not in the GAC, it searches for the EXE in the same directory
# Once you add the DLL to the GAC, it then searches for the EXE as though it were an installed program... i.e., somewhere in C:\Program Files
#Add-Type -AssemblyName "System.EnterpriseServices"
#$publish = New-Object System.EnterpriseServices.Internal.Publish
#$publish.GacInstall($fullAssemblyPath)

#region
##############################################
###
###  Functions
###
##############################################

# This function copies a single file to a linux server.
function Copy-FileToServer()
{
    [CmdletBinding()]
    param (

        [ValidateNotNullOrEmpty()]
        [string]$hostName = $(throw "- A valid hostname or IP address must be specified for your target Linux server."),

        [ValidateNotNullOrEmpty()]
        [string]$targetDir = $(throw "- A valid UNIX directory path must be specified.  If it does not exist, it will be created."),

        [ValidateNotNullOrEmpty()]
        [string]$user = $(throw "- A valid username for the linux host must be specified."),

        [ValidateNotNullOrEmpty()]
        [string]$pass = $(throw "- A valid password must be specified."),

        [ValidateNotNullOrEmpty()]
        [string]$localFilePath = $(throw "- A valid path must be specified to the local file you wish to copy."),

        #[string]$keyPassphrase = $(throw "- You must specify the passphrase for your user's SSH private key."),
        #[string]$keyFilePath = $(throw "- You must specify the file path of your user's SSH private key."),

        [ValidateNotNullOrEmpty()]
        [string]$sshHostKeyFingerprint = $(throw "- You must specify the host's SSH key fingerprint.")
    )
    process {
        try
        {  
            # Setup SSH session options
            $sessionOptions = New-Object WinSCP.SessionOptions -Property @{
                Protocol = [WinSCP.Protocol]::Sftp
                HostName = $hostName
                UserName = $user
                Password = $pass

                # the passphrase for these SSH private keys
                #PrivateKeyPassphrase = $keyPassphrase
                # the private PuTTY keyfile with .ppk extension
                #SshPrivateKeyPath = $keyFilePath

                # the client's FTP server SSH fingerprint.  You'll find this by default when you first connect to the server via PuTTY
                # otherwise it's in the local PuTTY keychain cache, which you can clear and then reconnect to the server to be once again presented with the fingerprint.
                # the PuTTY host key cache is found in Computer\HKEY_CURRENT_USER\Software\SimonTatham\PuTTY\SshHostKeys
                #SshHostKeyFingerprint = "ssh-ed25519 255 ce:02:a8:6a:da:73:90:21:44:58:6a:a9:33:d5:45:19"  #  this is the key for ansible control node 172.19.0.101
                SshHostKeyFingerprint = $sshHostKeyFingerprint

                TimeoutInMilliseconds = 300000  # 5 minutes
            }

            $session = New-Object WinSCP.SessionOptions
            try
            {
                # Connect to Linux server
                $session.Open($sessionOptions)

                # extract the given file name to create a full path for linux
                $fileNameOnly = Split-Path $localFilePath -leaf
                $linuxFullPath = $targetDir + $fileNameOnly

                # create the target directory on linux if it does not exist
                if (!($session.FileExists($targetDir)))
                {
                    $session.CreateDirectory($targetDir)
                }

                # Upload files
                $transferOptions = New-Object WinSCP.TransferOptions
                $transferOptions.TransferMode = [WinSCP.TransferMode]::Binary
                #$transferOptions.OverwriteMode = [WinSCP.OverwriteMode]::Overwrite  # this is the default setting...
                $uploadTransferResult = $session.PutFiles($localFilePath, $linuxFullPath, $False, $transferOptions)

                # Throw on any error
                $uploadTransferResult.Check()

                # Log results and clean files from directory
                foreach ($transfer in $uploadTransferResult.Uploads)
                {
                    Write-Output "Successful copy of $($transfer.FileName) to $($targetDir) on $($hostName)."
                }
            }
            finally
            {
                # Disconnect, clean up
                $session.Dispose()
            }
        }
        catch
        {
            Write-Output "ERROR :  $($_.Exception.Message)"
            exit 1
        }
    }
}

function Sync-Directory()
{
    [CmdletBinding()]    
    param (

        [ValidateNotNullOrEmpty()]
        [string]$hostName = $(throw "- A valid hostname or IP address must be specified for your target Linux server."),

        [ValidateNotNullOrEmpty()]
        [string]$targetDir = $(throw "- A valid UNIX directory path must be specified.  If it does not exist, it will be created.  EX:  /etc/ansible/cluster/"),

        [ValidateNotNullOrEmpty()]
        [string]$sourceDir = $(throw "- A valid path for the source directory must be specified."),

        [ValidateNotNullOrEmpty()]
        [string]$user = $(throw "- A valid username for the linux host must be specified."),

        [ValidateNotNullOrEmpty()]
        [string]$pass = $(throw "- A valid password must be specified."),

        #[string]$keyPassphrase = $(throw "- You must specify the passphrase for your user's SSH private key."),
        #[string]$keyFilePath = $(throw "- You must specify the file path of your user's SSH private key."),

        [ValidateNotNullOrEmpty()]
        [string]$sshHostKeyFingerprint = $(throw "- You must specify the host's SSH key fingerprint.")
    )
    process {
        try
        {  
            # Setup SSH session options
            $sessionOptions = New-Object WinSCP.SessionOptions -Property @{
                Protocol = [WinSCP.Protocol]::Sftp
                HostName = $hostName
                UserName = $user
                Password = $pass

                # the passphrase for these SSH private keys
                #PrivateKeyPassphrase = $keyPassphrase
                # the private PuTTY keyfile with .ppk extension
                #SshPrivateKeyPath = $keyFilePath

                # the client's FTP server SSH fingerprint.  You'll find this by default when you first connect to the server via PuTTY
                # otherwise it's in the local PuTTY keychain cache, which you can clear and then reconnect to the server to be once again presented with the fingerprint.
                # the PuTTY host key cache is found in Computer\HKEY_CURRENT_USER\Software\SimonTatham\PuTTY\SshHostKeys
                #SshHostKeyFingerprint = "ssh-ed25519 255 ce:02:a8:6a:da:73:90:21:44:58:6a:a9:33:d5:45:19"  #  this is the key for ansible control node 172.19.0.101
                SshHostKeyFingerprint = $sshHostKeyFingerprint

                TimeoutInMilliseconds = 300000  # 5 minutes
            }

            $session = New-Object WinSCP.Session

            try
            {
                # Connect to Linux server
                $session.Open($sessionOptions)

                # create the target directory on linux if it does not exist
                if (!($session.FileExists($targetDir)))
                {
                    $session.CreateDirectory($targetDir)
                }

                # Sync directories
                # this syncs in "remote" mode, which means only the target directory will be modified
                $uploadTransferResult = $session.SynchronizeDirectories([WinSCP.SynchronizationMode]::Remote, $sourceDir, $targetDir, $False)

                # Throw on any error
                if ($uploadTransferResult.Check())
                {
                    Write-Output "Successful sync of $($sourceDir) to $($targetDir) on $($hostName)."
                }  
            }
            finally
            {
                # Disconnect, clean up
                $session.Dispose()
            }
        }
        catch
        {
            Write-Output "ERROR :  $($_.Exception.Message)"
            exit 1
        }
    }
}

function Remove-Directory()
{
    [CmdletBinding()]    
    param (

        [ValidateNotNullOrEmpty()]
        [string]$hostName = $(throw "- A valid hostname or IP address must be specified for your target Linux server."),

        [ValidateNotNullOrEmpty()]
        [string]$targetDir = $(throw "- A valid UNIX directory path must be specified.  EX:  /etc/ansible/cluster/"),

        [ValidateNotNullOrEmpty()]
        [string]$user = $(throw "- A valid username for the linux host must be specified."),

        [ValidateNotNullOrEmpty()]
        [string]$pass = $(throw "- A valid password must be specified."),

        #[string]$keyPassphrase = $(throw "- You must specify the passphrase for your user's SSH private key."),
        #[string]$keyFilePath = $(throw "- You must specify the file path of your user's SSH private key."),

        [ValidateNotNullOrEmpty()]
        [string]$sshHostKeyFingerprint = $(throw "- You must specify the host's SSH key fingerprint.")
    )
    process {
        try
        {  
            # Setup SSH session options
            $sessionOptions = New-Object WinSCP.SessionOptions -Property @{
                Protocol = [WinSCP.Protocol]::Sftp
                HostName = $hostName
                UserName = $user
                Password = $pass

                # the passphrase for these SSH private keys
                #PrivateKeyPassphrase = $keyPassphrase
                # the private PuTTY keyfile with .ppk extension
                #SshPrivateKeyPath = $keyFilePath

                # the client's FTP server SSH fingerprint.  You'll find this by default when you first connect to the server via PuTTY
                # otherwise it's in the local PuTTY keychain cache, which you can clear and then reconnect to the server to be once again presented with the fingerprint.
                # the PuTTY host key cache is found in Computer\HKEY_CURRENT_USER\Software\SimonTatham\PuTTY\SshHostKeys
                #SshHostKeyFingerprint = "ssh-ed25519 255 ce:02:a8:6a:da:73:90:21:44:58:6a:a9:33:d5:45:19"  #  this is the key for ansible control node 172.19.0.101
                SshHostKeyFingerprint = $sshHostKeyFingerprint

                TimeoutInMilliseconds = 300000  # 5 minutes
            }

            $session = New-Object WinSCP.Session

            try
            {
                # Connect to Linux server
                $session.Open($sessionOptions)

                $removalTransferResult = New-Object -TypeName PSObject

                # create the target directory on linux if it does not exist
                if ($session.FileExists($targetDir))
                {
                    $removalTransferResult = $session.RemoveFiles($targetDir)
                }

                # Throw on any error
                if ($removalTransferResult.Check())
                {
                    Write-Output "Removal of $($targetDir) was successful on $($hostName)."
                }  
            }
            finally
            {
                # Disconnect, clean up
                $session.Dispose()
            }
        }
        catch
        {
            Write-Output "ERROR :  $($_.Exception.Message)"
            exit 1
        }
    }
}

function Invoke-LinuxCommand()
{
    [CmdletBinding()]
    [OutputType([WinSCP.CommandExecutionResult])]
    param (

        [ValidateNotNullOrEmpty()]
        [string]$hostName = $(throw "- A valid hostname or IP address must be specified for your target Linux server."),

        [ValidateNotNullOrEmpty()]
        [string]$command= $(throw "- A valid UNIX directory path must be specified.  If it does not exist, it will be created.  EX:  /etc/ansible/cluster/"),

        [ValidateNotNullOrEmpty()]
        [string]$user = $(throw "- A valid username for the linux host must be specified."),

        [ValidateNotNullOrEmpty()]
        [string]$pass = $(throw "- A valid password must be specified."),

        [ValidateNotNullOrEmpty()]
        [string]$keyPassphrase = $(throw "- You must specify the passphrase for your user's SSH private key."),

        [ValidateNotNullOrEmpty()]
        [string]$keyFilePath = $(throw "- You must specify the file path of your user's SSH private key."),

        [ValidateNotNullOrEmpty()]
        [string]$sshHostKeyFingerprint = $(throw "- You must specify the host's SSH key fingerprint.")
    )
    process {
        try
        {  
            # Setup SSH session options
            $sessionOptions = New-Object WinSCP.SessionOptions -Property @{
                Protocol = [WinSCP.Protocol]::Sftp
                HostName = $hostName

                UserName = $user
                # you must not provide a password if using SSH keys
                #Password = $pass

                # the passphrase for these SSH private keys
                PrivateKeyPassphrase = $keyPassphrase
                # the PuTTY private keyfile with .ppk extension
                SshPrivateKeyPath = $keyFilePath

                # the client's FTP server SSH fingerprint.  You'll find this by default when you first connect to the server via PuTTY
                # otherwise it's in the local PuTTY keychain cache, which you can clear and then reconnect to the server to be once again presented with the fingerprint.
                # the PuTTY host key cache is found in Computer\HKEY_CURRENT_USER\Software\SimonTatham\PuTTY\SshHostKeys
                #SshHostKeyFingerprint = "ssh-ed25519 255 ce:02:a8:6a:da:73:90:21:44:58:6a:a9:33:d5:45:19"  #  this is the key for ansible control node 172.19.0.101
                SshHostKeyFingerprint = $sshHostKeyFingerprint
            }

            $session = New-Object WinSCP.Session

            try
            {
                # Connect to Linux server
                $session.Open($sessionOptions)

                # Sync directories
                # see the README.md (KNOWN BUG 01) for a reason why we're not calling the Check() method after this command
                [WinSCP.CommandExecutionResult] $result = $session.ExecuteCommand($command)
                
                Write-Output -InputObject $result.Output
            }
            finally
            {
                # Disconnect, clean up
                $session.Dispose()
            }
        }
        catch
        {
            Write-Output "WinSCP Execute Command ERROR :  $($_.Exception.Message)"
            #exit 1
        }
    }
}

#endregion