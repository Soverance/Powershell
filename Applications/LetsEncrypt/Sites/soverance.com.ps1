# © 2017-2019 Soverance Studios
# Scott McCutchen
# scott.mccutchen@soverance.com

# Let's Encrypt Certificate Renewal Automation

# When copying this file to use for a new site, you must modify the $argumentlist variable to include the approriate configuration
$argumentlist = " -profilename SoveranceVault -dnsname soverance.com -ftpdir ftp://soverance.com/.well-known/acme-challenge/ -user someuser -pass somepass -IncludeWww -TLS"

########################################
##
## MAKE NO CHANGES BEYOND THIS POINT!
##
########################################
# define cert request ps1 file
$certreqfile = "C:\Scripts\Powershell\LetsEncrypt\LE-CertificateRequest.ps1"
# concatenate command
$command = $certreqfile + $argumentlist
# run cert request
Invoke-Expression $command