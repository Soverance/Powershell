# AutoCluster Deployment Tools
# Scott McCutchen
# DevOps Engineer
# scott.mccutchen@m3as.com

# This script will create a new certificate signing request for Server Authentication certificates

param 
(
    [Parameter(Mandatory=$True)]
    [string]$CertName,

    [Parameter(Mandatory=$True)]
    [string]$CAServerName,

    [Parameter(Mandatory=$True)]
    [string]$DomainUser, # = $(throw "-DomainUser : domain join service account for the active directory domain."), 

    [Parameter(Mandatory=$True)]
    [string]$DomainPass # = $(throw "-DomainPass : password for the AD domain service account.") 
)

try 
{
    Write-Output "Creating CertificateRequest(CSR) for $($CertName)."

    $pass = ConvertTo-SecureString -String $DomainPass -AsPlainText -Force
    $domainCreds = New-Object -TypeName "System.Management.Automation.PSCredential" -ArgumentList $DomainUser, $pass

    $session = New-PSSession -ComputerName $CAServerName -Credential $domainCreds -UseSSL -SessionOption $so
 
    Invoke-Command -Session $session -ScriptBlock {
    
    $CSRPath = "c:\$($using:CertName).csr"
    $INFPath = "c:\$($using:CertName).inf"
    $Signature = '$Windows NT$' 
 
# see here for a full list of certreq params:  https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/certreq_1 
$INF =
@"
[Version]
Signature= "$($Signature)" 
 
[NewRequest]
Subject = "CN=$($using:CertName), OU=DEVOPS, O=M3 Accounting, L=Lawrenceville, S=Georgia, C=US"
KeySpec = 1
KeyLength = 2048
Exportable = TRUE
MachineKeySet = TRUE
SMIME = False
PrivateKeyArchive = FALSE
UserProtected = FALSE
UseExistingKeySet = FALSE
ProviderName = "Microsoft RSA SChannel Cryptographic Provider"
ProviderType = 12
RequestType = PKCS10
KeyUsage = 0xa0
 
[EnhancedKeyUsageExtension]
 
OID=1.3.6.1.5.5.7.3.1 
"@
 
        Write-Output "Certificate Request is being generated..."
        $INF | out-file -filepath $INFPath -force
        certreq -new $INFPath $CSRPath
    
    }

    Write-Output "Certificate Request has been generated"
}
catch {

}

