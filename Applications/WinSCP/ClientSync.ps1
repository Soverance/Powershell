# Soverance Studios
# Scott McCutchen
# scott.mccutchen@soverance.com
#
# This script will sync the Inbound and Outbound directories located on a client's FTP server
# with the Inbound and Outbound directories here in CompleteFTP
# See "L:\data\SomeClient\data\"

# add the custom module path in order to access the SoverancePgp module
$env:PSModulePath = $env:PSModulePath + ";C:\Scripts\PowerShell\Modules"
Import-Module SoverancePgp

$Logfile = "C:\Scripts\PowerShell\Applications\WinSCP\ClientSync.log"

$time = Get-Date  # get date
$time = $time.ToUniversalTime()  # convert to readable time

# check to see if the log file already exists - if not, create it
if (!(Test-Path $Logfile))
{
    New-Item -Force -Path $Logfile
}

Function LogWrite
{
   Param ([string]$logstring)
   Add-content $Logfile -value $logstring
}

try
{
    # Load WinSCP .NET assembly
    Add-Type -Path "C:\Scripts\PowerShell\Applications\WinSCP\WinSCP-5.13.4-Automation\WinSCPnet.dll"

    # Setup session options
    $sessionOptions = New-Object WinSCP.SessionOptions -Property @{
        Protocol = [WinSCP.Protocol]::Sftp
        HostName = "xxx.xxx.xxx.xxx"  # enter the IP address of the client's FTP server
        UserName = "SoveranceUser"
        # the passphrase for these SSH private keys
        PrivateKeyPassphrase = "xxxxxxxxxxx"
        # the combined putty keyfile
        SshPrivateKeyPath = "C:\Scripts\PowerShell\Applications\WinSCP\ssh-keys\SomeClient\user-keys.ppk"
        # the client's FTP server SSH fingerprint.  You'll find this by default when you first connect to the server
        # otherwise it's in the local putty keychain cache, which you can clear and then reconnect to the server to be once again presented with the fingerprint.
        SshHostKeyFingerprint = "ssh-rsa 2048 XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX"
    }

    $session = New-Object WinSCP.Session

    # define the CompleteFTP inbound/outbound directory paths
    # These are the paths accessible to Soverance employees
    $localInbound = "L:\data\SomeClient\automation\Inbound\"
    $localOutbound = "L:\data\SomeClient\automation\Outbound\"
    # This whole temp directory business is only necessary because, for whatever reason,
    # gpg.exe doesn't appear to accept folder paths with spaces in them
    $tempInbound = "C:\temp\client\Inbound\"
    $tempOutbound = "C:\temp\client\Outbound\"

    try
    {
        # Get the number of inbound files to upload to client's FTP
        $inboundFiles = Get-ChildItem -Path $localInbound
        $inboundFileCount = ($inboundFiles | Measure-Object).Count

        # if there is one or more files in the Inbound directory, encrypt them all
        if ($inboundFileCount -gt 0)
        {
            # Create temp directory if it doesn't already exist

            if (!(Test-Path $tempInbound))
            {
                New-Item -Force -Path $tempInbound -ItemType "directory"
            }

            # move all files from Inbound directory to TempDir
            foreach ($file in $inboundFiles)
            {
                $tempInboundDestination = $tempInbound + $file.Name
                Move-Item -Path $file.FullName -Destination $tempInboundDestination -Force
            }

            # encrypt all files in temp inbound dir for client's engineering team.
            # again, this command cannot use spaces in the -FolderPath parameter...
            Add-ClientEncryption -FolderPath $tempInbound -Recipient "engineering@contoso.com"

            # move all newly encrypted files back into the Inbound directory so they can be uploaded
            $encryptedFilter = $tempInbound + "*.gpg"
            Move-Item -Path $encryptedFilter -Destination $localInbound -Force
        }

        # Connect to client SFTP server
        $session.Open($sessionOptions)

        # Upload files
        $transferOptions = New-Object WinSCP.TransferOptions

        #$uploadTransferResult = $session.PutFiles([WinSCP.TransferMode]::Binary, "L:\data\SomeClient\automation\Inbound\*", "/Inbound/", $False)
        $uploadTransferResult = $session.SynchronizeDirectories([WinSCP.SynchronizationMode]::Remote, $localInbound, "/Inbound/", $False)

        # Throw on any error
        $uploadTransferResult.Check()

        # Log results and clean files from directory
        foreach ($transfer in $uploadTransferResult.Uploads)
        {
            LogWrite "$($time) : Upload of $($transfer.FileName) succeeded"
            Remove-Item -Path $transfer.FileName  # delete the file from local inbound directory after upload
        }

        # create the temp outbound dir, if it doesn't already exist
        if (!(Test-Path $tempOutbound))
        {
            New-Item -Force -Path $tempOutbound -ItemType "directory"
        }

        #$downloadTransferResult = $session.GetFiles([WinSCP.TransferMode]::Binary, "/Outbound/*", "L:\data\SomeClient\automation\Outbound\", $False)
        $downloadTransferResult = $session.SynchronizeDirectories([WinSCP.SynchronizationMode]::Local, $tempOutbound, "/Outbound/", $False)

        # Throw on any error
        $downloadTransferResult.Check()

        # Print results
        foreach ($transfer in $downloadTransferResult.Downloads)
        {
            LogWrite "$($time) : Download of $($transfer.FileName) succeeded"
        }

        # decrypt all files in temp outbound dir for Soverance employees.
        # again, this command cannot use spaces in the -FolderPath parameter...
        Remove-ClientEncryption -FolderPath $tempOutbound

        # Move all the decrypted files back into the Outbound directory to be picked up by Soverance Employees
        Get-ChildItem $tempOutbound -Exclude "*.pgp" | ForEach-Object {Move-Item $_ -Destination $localOutbound -Force}
    }
    finally
    {
        # Disconnect, clean up
        $session.Dispose()
        # Remove Temp files
        Remove-Item -Path "C:\temp\client\" -Recurse -Force
    }

    exit 0
}
catch
{
    Write-Host "Error: $($_.Exception.Message)"
    exit 1
}