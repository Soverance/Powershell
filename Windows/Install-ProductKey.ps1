# © 2018 Soverance Studios
# Scott McCutchen
# scott.mccutchen@soverance.com

param (
	[string]$key = $(throw "-key is required. You must specify a valid Windows product key.")
)

$computer = $env:computername

$service = get-wmiObject -query "select * from SoftwareLicensingService" -computername $computer

$service.InstallProductKey($key)

$service.RefreshLicenseStatus()