# scott.mccutchen@soverance.com
# Server Core IP Configuration Help

# Use this script as a technical document to help configure Server Core installations.  I tend to run these cmdlets in order.

# This script is for requesting certificates from Lets Encrypt.
# This script assumes you have run (or manually processed the cmdlets within) the "LE-VaultConfig.ps1" script located in this repo.
# You must edit the $profilename variable here to match whatever you specified in the LE-VaultConfig

# Additionally, this script assumes that the site exists on the same server and is online, available through IIS.

# Parameters
param (
    # define the custom vault profile name
	[string]$profilename = $(throw "- A valid vault profile name must be specified."),
    # define the site you wish to secure
    [string]$dnsname = $(throw "- A valid DNS hostname must be specified.")
)

# you must import the module into the current session in order to use it's cmdlets
Import-Module ACMESharp

# get date
$time = Get-Date -Format M.d.yyyy 

# create a time-stamped vault site and cert alias
$sitealias = "$($dnsname)" + "-$($time)"
$certalias = "$($dnsname)" + "-cert-$($time)"
$wwwdns = "www." + $dnsname
$wwwalias = "$($wwwdns)" + "-$($time)"

# define the site's root directory.
# this logic would need to be updated to make this work outside of my own environment.  But it's fine here.
$siterootpath = "C:\inetpub\wwwroot\" + $($dnsname) + "\.well-known\acme-challenge\"

# Submit a new DNS domain name identifier for the site you wish to secure with an LE SSL certificate (-Dns and –Alias are required params)
New-ACMEIdentifier –Dns $dnsname –Alias $sitealias -VaultProfile $profilename
New-ACMEIdentifier -Dns $wwwdns -Alias $wwwalias -VaultProfile $profilename

# Handle the challenge to prove domain ownership
# This can be done multiple ways, either manually through an HTTP or DNS challenge, or automatic IIS / Apache challenges.  
# More information on all supported challenge handlers available can be found on the ACMESharp Github documentation:  https://github.com/ebekker/ACMESharp/wiki/Challenge-Types%2C-Challenge-Handlers-and-Providers
# To obtain the necessary information for a HTTP challenge, use the following cmdlet:
$challengeresult1 = Complete-ACMEChallenge $sitealias –ChallengeType http-01 –Handler manual -VaultProfile $profilename
$challengeresult2 = Complete-ACMEChallenge $wwwalias –ChallengeType http-01 –Handler manual -VaultProfile $profilename

# extract the challenge content output
$challengeoutput1 = $challengeresult1.Challenges.challenge.FileContent
$challengeoutput2 = $challengeresult2.Challenges.challenge.FileContent

# create the challenge file name by taking the first section of the challenge output content
# the file has no extension!
$outputfilename1 = $challengeoutput1.split(".")[0]
$outputfilename2 = $challengeoutput2.split(".")[0]

# Create the file in the appropriate web directory
New-Item -Path $siterootpath -Name $outputfilename1 -Value $challengeoutput1 -Force | Out-Null
New-Item -Path $siterootpath -Name $outputfilename2 -Value $challengeoutput2 -Force | Out-Null

# submit the challenge to Lets Encrypt so that they can perform a validation
# this will obviously fail if the challenge was not successful
Submit-ACMEChallenge $sitealias -ChallengeType http-01 -VaultProfile $profilename
Submit-ACMEChallenge $wwwalias -ChallengeType http-01 -VaultProfile $profilename

# just give it a few seconds to complete...
sleep -s 15

# You can check the status of the challenge with the following command:
Update-ACMEIdentifier -IdentifierRef $sitealias -VaultProfile $profilename
Update-ACMEIdentifier -IdentifierRef $wwwalias -VaultProfile $profilename

# Generate the certificates
New-ACMECertificate $sitealias -Generate -Alias $certalias -AlternativeIdentifierRefs @($wwwalias) -VaultProfile $profilename

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

# show the available installers (should produce 'iis' in the soverance environment)
Get-ACMEInstallerProfile -ListInstallers

# install the certificate in IIS
Install-ACMECertificate -CertificateRef $certalias -Installer iis -InstallerParameters @{WebsiteRef = $dnsname ; Force = $true}


