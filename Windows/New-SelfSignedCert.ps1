# AutoCluster Deployment Tools
# Scott McCutchen
# DevOps Engineer
# scott.mccutchen@m3as.com

# This script will create a new self-signed certificate on the local machine, and then export the cert so that it can be installed elsewhere

# NOTE:  this script is not currently in use within AutoCluster deployments (it was required for some DSC config, but not anymore)

param 
(
    [Parameter(Mandatory=$True)]
    [string]$dnsname,
    [Parameter(Mandatory=$True)]
    [int]$duration,
    [Parameter(Mandatory=$True)]
    [string]$certPassword
)

try {
    # create a new self-signed cert for our cluster with key usage suitable for encryption
    $cert = New-SelfSignedCertificate -Subject $dnsname -DnsName $dnsname -CertStoreLocation "cert:\LocalMachine\My" -KeyUsage KeyEncipherment,DataEncipherment,KeyAgreement -Type SSLServerAuthentication -KeyAlgorithm RSA -HashAlgorithm SHA256 -Provider "Microsoft Enhanced Cryptographic Provider v1.0" -KeyLength 2048 -KeyExportPolicy Exportable -NotAfter (Get-Date).AddYears($duration)

    $pass = ConvertTo-SecureString -String $certPassword -AsPlainText -Force
    $exportRoot = $PSScriptRoot
    $exportCer = $exportRoot + "$($dnsname)" + ".cer"
    $exportPfx = $exportRoot + "$($dnsname)" + ".pfx"
    $exportThumbprint = $exportRoot + "$($dnsname)" + ".txt"

    Export-Certificate -Cert $cert -FilePath $exportCer  # export public key
    Export-PfxCertificate -Cert "cert:LocalMachine\My\$($cert.Thumbprint)" -FilePath $exportPfx -ChainOption EndEntityCertOnly -NoProperties -Password $pass  # export bundled private key
    New-Item -Path $exportThumbprint -ItemType File -Value "$($cert.Thumbprint)"  # export thumbprint

    return $cert
}
catch {

}

