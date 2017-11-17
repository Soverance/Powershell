# scott.mccutchen@soverance.com
# Server Core IP Configuration Help

# Use this script as a technical document to help configure Server Core installations.  I tend to run these cmdlets in order.

# This script is for installing and configuring the ACMESharp module and vault necessary to provision Lets Encrypt certificates.

# you must first install the ACMESharp module
#Install-Module ACMESharp
# we also want to install the IIS provider so we can work with Windows servers
#Install-Module -Name ACMESharp.Providers.IIS

# you must then import the module into the current session in order to use it's cmdlets
Import-Module ACMESharp

# we also need to enable the extension modules for IIS
#Enable-ACMEExtensionModule -ModuleName ACMESharp.Providers.IIS

# Verify the module was enabled
Get-ACMEExtensionModule | Select-Object -ExpandProperty Name

# define the custom vault profile name
$profilename = "SoveranceVault"

# You must first initialize a “vault” which stores Lets Encrypt certificates and related artifacts.
# Note: If you proceed to initialize the vault without specifying the vault profile, 
# then running this command in an elevated (admin) Powershell window will create the vault in a system-wide path – otherwise the vault will be created within the current user directory.  
# However, it will also default to saving certificates as flagged for the Encrypted File System (EFS) feature in Windows.  
# Unfortunately, this feature is only available in Windows Enterprise SKUs, and therefore if you run this script in a lower SKU (such as Home or Pro) 
# then the Submit-ACMECertificate cmdlet will return an “Access Denied” error when trying to save the certificate to the vault.
# To avoid this issue on lower SKUs, you must use the Set-ACMEVaultProfile cmdlet to specify a custom root directory, as well as set the BypassEFS flag to true.  
# You must then specify this vault with each successive command.  Set the vault profile with the following command:
Set-ACMEVaultProfile –ProfileName $profilename –Provider local –VaultParameters @{RootPath = “C:\WEB\LetsEncrypt\Vault”; CreatePath = $true; BypassEFS = $true} -Force

# Initialize the vault using the custom profile
# if you run this cmdlet without specifying the BaseUri, it defaults to the current LE staging CA server.
# The staging server doesn't appear to send expiry notifications, which is useless for production use.
# ACME Production CA "Boulder" :  https://acme-v01.api.letsencrypt.org/directory
# ACME Staging CA :  https://acme-staging.api.letsencrypt.org/directory
Initialize-ACMEVault -VaultProfile $profilename -BaseUri "https://acme-v01.api.letsencrypt.org/directory"

# You can use the "Get-VaultProfile cmdlet to verify the vault's config
Get-ACMEVaultProfile -ListProfiles
Get-ACMEVaultProfile -ProfileName $profilename

# create a new contact registration
# you must provide a valid email address and accept the LetsEncrypt TOS
New-ACMERegistration -Contacts mailto:info@soverance.com -AcceptTos -VaultProfile $profilename