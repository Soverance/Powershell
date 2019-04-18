# © 2019 Soverance Studios
# Scott McCutchen
# scott.mccutchen@soverance.com

# This script will install SSL certificates on a specified Linux host

# Parameters
param (
    # define the domain name you wish to upload to
    [string]$dnsname = $(throw "- A valid DNS hostname must be specified."),
    # define the site you wish to connect to
    [string]$ssldir = $(throw "- A valid UNIX file path must be specified.  EX:  /etc/ssl/drumagency/"),
     # define the FTP username
    [string]$user = $(throw "- A valid username must be specified."),
    # define the FTP user password
    [string]$pass = $(throw "- A valid user password must be specified."),
    # define the certificate's file path
    [string]$cert = $(throw "- A valid path to the certificate must be specified."),
    # define the certificate's intermediate chain
    [string]$chain = $(throw "- A valid path to the intermediate chain must be specified."),
    # define the private key's file path
    [string]$key = $(throw "- A valid path to the private key must be specified.")
)

$Logfile = "C:\Scripts\PowerShell\Applications\WinSCP\LinuxSSL.log"

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
        HostName = $dnsname
        UserName = $user
        Password = $pass

        # UNCOMMENT AND MODIFY THE FOLLOWING BLOCK IF YOU'RE USING SSH KEYS FOR AUTHENTICATION
        # the passphrase for these SSH private keys
        #PrivateKeyPassphrase = "xxxxxxxxxxxxxxx"
        # the combined putty keyfile
        #SshPrivateKeyPath = "C:\Scripts\PowerShell\Applications\WinSCP\ssh-keys\user-keys.ppk"

        # the client's FTP server SSH fingerprint.  You'll find this by default when you first connect to the server
        # otherwise it's in the local putty keychain cache, which you can clear and then reconnect to the server to be once again presented with the fingerprint.
        # the PuTTY host key cache is found in Computer\HKEY_CURRENT_USER\Software\SimonTatham\PuTTY\SshHostKeys
        SshHostKeyFingerprint = "ssh-ed25519 256 5a:9b:b0:0e:7f:e7:01:71:17:19:75:20:a7:e7:d1:b6"
    }

    $session = New-Object WinSCP.Session

    try
    {
        $rootpath = "C:\LetsEncrypt\Exports\" + $($dnsname) + "\Clean\"
        if (!(Test-Path $rootpath))
        {
            New-Item -Force -Path $rootpath -ItemType Directory
        }
        $newcert = $($rootpath) + $($dnsname) + ".crt.pem"
        $newchain = $($rootpath) + $($dnsname) + ".intermediate.crt.pem"
        $newkey = $($rootpath) + $($dnsname) + ".key.pem"
        Copy-Item $cert -destination $newcert
        Copy-Item $chain -destination $newchain
        Copy-Item $key -destination $newkey

        # Connect to United SFTP server
        $session.Open($sessionOptions)

        # Upload files
        #$transferOptions = New-Object WinSCP.TransferOptions

        #$uploadTransferResult = $session.PutFiles([WinSCP.TransferMode]::Binary, "L:\data\United Airlines\automation\Inbound\*", "$ssldir", $False)
        $uploadTransferResult = $session.SynchronizeDirectories([WinSCP.SynchronizationMode]::Remote, $rootpath, $ssldir, $False)

        # Throw on any error
        $uploadTransferResult.Check()

        # Log results and clean files from directory
        foreach ($transfer in $uploadTransferResult.Uploads)
        {
            LogWrite "$($time) : Upload of $($transfer.FileName) succeeded"
            $body = "$($time) : Upload of $($transfer.FileName) succeeded."
            #Remove-Item -Path $transfer.FileName  # delete the file from local inbound directory after upload
        }
    }
    finally
    {
        # Disconnect, clean up
        $session.Dispose()
    }

    exit 0
}
catch
{
    LogWrite "Error: $($_.Exception.Message)"
    $body = "Error: $($_.Exception.Message)"
    SendMail -Recipient "support@soverance.net" -Subject "An error occured with the Linux Certificate Upload Automation process." -MailBody $body
    exit 1
}