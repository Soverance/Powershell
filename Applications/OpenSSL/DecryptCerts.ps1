# © 2018 Soverance Studios
# Scott McCutchen
# scott.mccutchen@soverance.com
#
# Commands to extract unencrypted keys from PFX files using OpenSSL

# Parameters
param (
    # define the export destination
	[string]$sourcepfx = $(throw "- A valid source PFX path must be specified."),
    # define the export destination
	[string]$destination = $(throw "- A valid directory path must be specified."),
    # define the site you wish to secure
    [string]$dnsname = $(throw "- A valid DNS hostname must be specified.")
)

$crt = $destination + $dnsname + ".crt.pem"
$key = $destination + $dnsname + ".key.pem"
$intermediate = $destination + $dnsname + ".intermediate.pem"

Write-Host "File to Export: " $($crt) -foregroundcolor black -backgroundcolor white
Write-Host "File to Export: " $($key) -foregroundcolor black -backgroundcolor white
Write-Host "File to Export: " $($intermediate) -foregroundcolor black -backgroundcolor white

# export the crt as unencrypted pem
openssl pkcs12 -in $sourcepfx -out $crt -clcerts -nodes -nokeys

# export the unencrypted private key
openssl pkcs12 -in $sourcepfx -out $key -cacerts -nodes

# export the full certificate chain with intermediate
openssl pkcs12 -in $sourcepfx -out $intermediate -clcerts -chain -nokeys
