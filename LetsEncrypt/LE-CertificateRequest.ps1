# © 2017-2019 Soverance Studios
# Scott McCutchen
# scott.mccutchen@soverance.com

# This script is for requesting certificates from Lets Encrypt.
# This script assumes you have run (or manually processed the cmdlets within) the "LE-VaultConfig.ps1" script located in this repo.

###########################################
##
## PARAMETERS
##
###########################################
param (
    # define the custom vault profile name
	[string]$profilename = $(throw "- A valid vault profile name must be specified."),
    # define the site you wish to secure
    [string]$dnsname = $(throw "- A valid DNS hostname must be specified."),
    # define the site you wish to connect to
    [string]$ftpdir = $(throw "- A valid FTP domain path must be specified.  EX:  ftp://contoso.com/.well-known/acmechallenge/"),
     # define the FTP username
    [string]$user = $(throw "- A valid FTP username must be specified."),
    # define the FTP user password
    [string]$pass = $(throw "- A valid FTP user password must be specified."),
    # If the -CopyUNC switch is used, then the FTP upload process will be bypassed, and the HTTP challenge file will be copied to a UNC path within the network
    # Instead of an FTP URL path, you must specify this UNC path in the site-specific script stored in the "$ftpdir" variable.
    [switch]$CopyUNC,
    # If the -CopyToLinux switch is used, it will rename the files to something cleaner (without timestamps) and then upload them to the specified Linux server via WinSCP
    [switch]$CopyToLinux,
    # If the -IISInstall switch is used, it will install the certs into IIS
    [switch]$IISInstall,
    # If the -Email switch is used, then an email will be sent upon completion of this script
    [switch]$Email,
    # If the -TLS switch is used, then the FTP upload will occur via FTP with TLS security.  Otherwise, credentials are sent in plain text.
    [switch]$TLS,
    # If the -IncludeWww switch is used, then the www subdomain of the primary dns name will be included as an alias when creating this certificate
    [switch]$IncludeWww,
    # If the -IncludeAliases switch is used, then the certificate will be created with aliases specified in the list
    [switch]$IncludeAliases,
    # If the -IncludeAliases param is used, you must specify a comma-delimited list of aliases to appear on the certificate
    [string[]]$AliasList
)

###########################################
##
## Module Dependency Configuration
##
###########################################
# add the custom module path in order to access the Drum custom PS modules
$env:PSModulePath = $env:PSModulePath + ";C:\Scripts\PowerShell\Modules"
Import-Module SoveranceMail
Import-Module ACMESharp

###########################################
##
## Alias & Root Path Configuration
##
###########################################

# get date
$time = Get-Date -Format o | foreach {$_ -replace ":", "."}

# create a time-stamped vault site and cert alias
$sitealias = "$($dnsname)" + "-$($time)"
$certalias = "$($dnsname)" + "-cert-$($time)"

if ($IncludeWww)
{
    $wwwdns = "www." + $dnsname
    $wwwalias = "$($wwwdns)" + "-$($time)"
}

# define the site's root directory.
# this isn't the actual site root dir, this is just the custom local export directory
# this logic would need to be updated to make this work outside of this particular environment.  But it's fine here.
$siterootpath = "C:\LetsEncrypt\Exports\" + $($dnsname) + "\.well-known\acme-challenge\"

###########################################
##
## Log Transcript Configuration
##
###########################################

$Logfile = "C:\Scripts\Powershell\LetsEncrypt\AcmeAutomation.log"
$time = Get-Date -Format G # get date

# check to see if the log file already exists - if not, create it
if (!(Test-Path $Logfile))
{
    New-Item -Force -Path $Logfile
}
$ErrorActionPreference = "SilentlyContinue"
Stop-Transcript | Out-Null
$ErrorActionPreference = "Continue"
Start-Transcript -path $Logfile -append  # start transcript to log output

###########################################
##
## BEGIN ACME CERT RENEWAL PROCESS
##
###########################################

try
{
    # Submit a new DNS domain name identifier for the site you wish to secure with an LE SSL certificate (-Dns and -Alias are required params)
    New-ACMEIdentifier -Dns $dnsname -Alias $sitealias -VaultProfile $profilename

    if ($IncludeWww)
    {
        New-ACMEIdentifier -Dns $wwwdns -Alias $wwwalias -VaultProfile $profilename
    }

    # Handle the challenge to prove domain ownership
    # This can be done multiple ways, either manually through an HTTP or DNS challenge, or automatic IIS / Apache challenges.
    # More information on all supported challenge handlers available can be found on the ACMESharp Github documentation:  https://github.com/ebekker/ACMESharp/wiki/Challenge-Types%2C-Challenge-Handlers-and-Providers
    # To obtain the necessary information for a HTTP challenge, use the following cmdlet:
    $challengeresult = Complete-ACMEChallenge $sitealias -ChallengeType http-01 -Handler manual -VaultProfile $profilename

    if ($IncludeWww)
    {
        $challengeresultwww = Complete-ACMEChallenge $wwwalias -ChallengeType http-01 -Handler manual -VaultProfile $profilename
    }

    # extract the challenge content output
    $challengeoutput = $challengeresult.Challenges.challenge.FileContent

    if ($IncludeWww)
    {
        $challengeoutputwww = $challengeresultwww.Challenges.challenge.FileContent
    }

    # create the challenge file name by taking the first section of the challenge output content
    # NOTE: the file has no extension!
    $outputfilename = $challengeoutput.split(".")[0]

    if ($IncludeWww)
    {
        $outputfilenamewww = $challengeoutputwww.split(".")[0]
    }

    # Create the challenge file in the appropriate directory
    $challengefile = New-Item -Path $siterootpath -Name $outputfilename -Value $challengeoutput -Force | Out-Null
    $challengefilepath = $siterootpath + $outputfilename
    $finaldestination = $ftpdir + $outputfilename
    Write-Host "File to Load: " $($challengefilepath) -foregroundcolor black -backgroundcolor white
    Write-Host "Final Destination: " $($finaldestination) -foregroundcolor black -backgroundcolor white

    if ($IncludeWww)
    {
        $challengefilewww = New-Item -Path $siterootpath -Name $outputfilenamewww -Value $challengeoutputwww -Force | Out-Null
        $challengefilepathwww = $siterootpath + $outputfilenamewww
        $finaldestinationwww = $ftpdir + $outputfilenamewww
        Write-Host "File to Load: " $($challengefilepathwww) -foregroundcolor black -backgroundcolor white
        Write-Host "Final Destination: " $($finaldestinationwww) -foregroundcolor black -backgroundcolor white
    }

    # define the FTP Upload argument list
    if ($TLS)
    {
        $argumentlist = " -File $($challengefilepath) -Destination $($finaldestination) -User $($user) -Pass $($pass) -TLS"

        if ($IncludeWww)
        {
            $argumentlistwww = " -File $($challengefilepathwww) -Destination $($finaldestinationwww) -User $($user) -Pass $($pass) -TLS"
        }
    }
    else
    {
        $argumentlist = " -File $($challengefilepath) -Destination $($finaldestination) -User $($user) -Pass $($pass)"

        if ($IncludeWww)
        {
            $argumentlistwww = " -File $($challengefilepathwww) -Destination $($finaldestinationwww) -User $($user) -Pass $($pass)"
        }
    }

    # create a path reference to the FTP upload script
    # NOTE: the FTP-Upload.ps1 script must remain within the same directory as this script so that the $uploadscriptpath variable can be correctly set
    $uploadscriptpath = $PSScriptRoot + "\FTP-Upload.ps1"
    $command = $uploadscriptpath + $argumentlist

    if ($IncludeWww)
    {
        $commandwww = $uploadscriptpath + $argumentlistwww
    }

    # if -CopyUNC was specified, we'll just simply copy the file over into the UNC path on our network
    if ($CopyUNC)
    {
        New-Item -Path $ftpdir -Name $outputfilename -Value $challengeoutput -Force | Out-Null

        if ($IncludeWww)
        {
            New-Item -Path $ftpdir -Name $outputfilenamewww -Value $challengeoutputwww -Force | Out-Null
        }
    }
    # if -CopyUNC was not specified, we'll run the FTP upload
    else
    {
        # run the FTP upload
        Invoke-Expression $command

        if ($IncludeWww)
        {
            Invoke-Expression $commandwww
        }
    }

    # submit the challenge to Lets Encrypt so that they can perform a validation
    # this will obviously fail if the challenge was not successful
    Submit-ACMEChallenge $sitealias -ChallengeType http-01 -VaultProfile $profilename

    if ($IncludeWww)
    {
        Submit-ACMEChallenge $wwwalias -ChallengeType http-01 -VaultProfile $profilename
    }

    # You can check the status of the challenge with the following command:
    Update-ACMEIdentifier -IdentifierRef $sitealias -VaultProfile $profilename

    if ($IncludeWww)
    {
        Update-ACMEIdentifier -IdentifierRef $wwwalias -VaultProfile $profilename
    }

    ###########################################
    ##
    ## BEGIN ACME CERT GENERATION PROCESS
    ##
    ###########################################

    # Generate the certificates
    New-ACMECertificate $sitealias -Generate -Alias $certalias -VaultProfile $profilename

    # Submit the certificate for verification
    Submit-ACMECertificate $certalias -VaultProfile $profilename

    # Check to make sure the cert was successfully validated
    Update-ACMECertificate $certalias -VaultProfile $profilename

    $exportpath = "C:\LetsEncrypt\Exports\" + $($dnsname) + "\" + $($sitealias)

    # if the export path does not exist, create it
    if ( -Not (Test-Path $exportpath.trim() ))
    {
        New-Item -Path $exportpath -ItemType Directory
    }

    # export file path configuration
    $exportcsr = $exportpath + "\" + $certalias + ".csr.pem"
    $exportcrtpem = $exportpath + "\" + $certalias + ".crt.pem"
    $exportcrt = $exportpath + "\" + $certalias + ".crt"
    $exportkey = $exportpath + "\" + $certalias + ".key.pem"
    $exportintpem = $exportpath + "\" + $certalias + ".intermediate.crt.pem"
    $exportint = $exportpath + "\" + $certalias + ".intermediate.crt"
    $exportpfx = $exportpath + "\" + $certalias + ".pfx"

    # Export the certificate signing request
    Get-ACMECertificate $certalias -ExportCsrPEM $exportcsr -VaultProfile $profilename

    # Export the certificate itself as .crt
    Get-ACMECertificate $certalias -ExportCertificateDER $exportcrt -VaultProfile $profilename

    # Export the certificate itself as .pem
    Get-ACMECertificate $certalias -ExportCertificatePEM $exportcrtpem -VaultProfile $profilename

    # Export the certificate's private key
    Get-ACMECertificate $certalias -ExportKeyPEM $exportkey -VaultProfile $profilename

    # Export the intermediate certificate as .crt
    Get-ACMECertificate $certalias -ExportCertificateDER $exportint -VaultProfile $profilename

    # Export the intermediate certificate as .pem
    Get-ACMECertificate $certalias -ExportIssuerPEM $exportintpem -VaultProfile $profilename

    # Export the PKCS#12 (PFX) Archive
    # Since this archive bundles the certificate and private key, you can specify the -CertificatePassword param for greater security of the private key
    Get-ACMECertificate $certalias -ExportPkcs12 $exportpfx -VaultProfile $profilename

    # copy the certificates to the dedicated DRUM Agency certificate store on the specified Linux box
    # NOTE:  the $ssldir must have been previously created prior to executing this script block, otherwise it will fail
    if ($CopyToLinux)
    {
        $ssldir = "/etc/ssl/soverance/"
        $linuxuploadscriptpath = "C:\Scripts\Powershell\Applications\WinSCP\CopyCertsToLinux.ps1"
        $argumentlist = " -dnsname $($dnsname) -ssldir $($ssldir) -user root -pass $($pass) -cert $($exportcrtpem) -chain $($exportintpem) -key $($exportkey)"
        $command = $linuxuploadscriptpath + $argumentlist
        Invoke-Expression $command
    }

    if ($IISInstall)
    {
        # install the certificate in IIS
        Install-ACMECertificate -CertificateRef $certalias -Installer iis -InstallerParameters @{WebsiteRef = $dnsname ; Force = $true}
    }

    # send the notification email if the -Email flag was used when calling this script
    if ($Email)
    {
        $mailBody += "New Lets Encrypt Certificates have been generated for $($dnsname)`r`n`r`n"
        $mailBody += "An administrator must manually install the certificates before they will become active.  To find these certs, logon to SOV-WEB and navigate to " + $($exportpath)
        $mailBody += "`r`n`r`nSoverance Support"
        SendMail -Recipient "support@soverance.net" -Subject "LE Certificate Automation Success" -MailBody $mailBody
    }

    # Finally, stop the logging transcript
    Stop-Transcript | Out-Null
}
catch
{
    Write-Host "$($time) : Error: $($_.Exception.Message)`r`n"
    $mailbody = "Error: $($_.Exception.Message)`r`n`r`n"
    $mailbody += "Please see error log for more details @ $($LogFile)"
    $mailBody += "`r`n`r`nSoverance Support"
    SendMail -Recipient "support@soverance.net" -Subject "LE Certificate Automation Failure" -MailBody $mailbody
    exit 1
}






