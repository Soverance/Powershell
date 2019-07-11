# Scott McCutchen
# scott.mccutchen@soverance.com
#
# This script runs at user logon for members of the AutoVPN group.
# It will manually add the required routes for this VPN connection to our internal subnets
# This is only necessary to allow the VPN client to use split-tunneling...
# allowing them to use their local gateway, and maintain internet access, while securely accessing internal resources.

$Logfile = "C:\ContosoVPN\$(gc env:computername)_Contoso_VPN.log"

# check to see if the log file already exists - if not, create it
if (!(Test-Path $Logfile))
{
    New-Item -Force -Path $Logfile -Type file
}

# transcript defaults
$ErrorActionPreference = "SilentlyContinue"
Stop-Transcript | Out-Null
$ErrorActionPreference = "Continue"
Start-Transcript -path $Logfile -append  # start transcript to log output of pfSenseBackup.exe

# define the URL of the vpn gateway
# this is set in the DNS zone file: an A record pointing at the public IP address of the VPN gateway
$vpnurl = "vpn.contoso.com"

$time = Get-Date  # get date
$time = $time.ToUniversalTime()  # convert to readable time

$version = $PSVersionTable.PSVersion.Major  # Get the current powershell version

# Check the Powershell version, if the version is less than 5, we know we're working with a non-Windows 10 machine..
if ($version -lt 5)
{
    Write-Host "$($time) :  This operating system does not support Powershell v5. Using classic routing commands instead...`r`n"
    # Add static routes the old-fashioned way on older operating systems
    #route -p add 10.0.0.0 mask 255.255.0.0 192.168.160.1
    netsh interface ip4 add route 10.0.0.0/16 $vpnurl -ErrorVariable RouteError
    #route -p add 172.16.0.0 mask 255.255.255.0 192.168.160.1
    netsh interface ip4 add route 172.16.0.0/24 $vpnurl -ErrorVariable RouteError
    #route -p add 192.168.1.0 mask 255.255.252.0 192.168.160.1
    netsh interface ip4 add route 192.168.1.0/22 $vpnurl -ErrorVariable RouteError
    Write-Host "$($time) :  Stored Error:`r`n"
    Write-Host "$($time) :  $($RouteError[0]).`r`n"
}
else
{
    Write-Host "$($time) :  This operating system supports Powershell v5. Using Add-VpnConnectionRoute cmdlet...`r`n"
    # add static routes the fancy way on Windows 10 (powershell v5 only)
    Add-VpnConnectionRoute -ConnectionName $vpnurl -DestinationPrefix 10.0.0.0/16 -PassThru -ErrorVariable RouteError
    Add-VpnConnectionRoute -ConnectionName $vpnurl -DestinationPrefix 172.16.0.0/24 -PassThru -ErrorVariable RouteError
    Add-VpnConnectionRoute -ConnectionName $vpnurl -DestinationPrefix 192.168.1.0/22 -PassThru -ErrorVariable RouteError
    Write-Host "$($time) :  Stored Error:`r`n"
    Write-Host "$($time) :  $($RouteError[0]).`r`n"
}

$iparray = [System.Net.Dns]::GetHostAddresses($(gc env:computername))  # get IP address array
Write-Host "$($time) :  $(gc env:computername) is connected with the following addresses:`r`n"

foreach ($ip in $iparray)
{
    Write-Host "$($time) :  $($ip)`r`n"  # print each IP on a new line
}