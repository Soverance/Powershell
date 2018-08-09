# © 2018 Soverance Studios, LLC
# Scott McCutchen
# DevOps Engineer
# scott.mccutchen@soverance.com

# This script will automatically deploy the Soverance Internal WiFi configuration if it does not yet exist on the local machine
# This script is run as a logon script for all laptop users via the "Soverance Internal WiFi" Group Policy

# collect all the current user profiles
$profiles = netsh wlan show profiles | Select-String 'All User Profile'

# get the sanitized SSID list by stripping the first 27 characters from each returned profile
$SSIDList = $profiles | foreach {[PSCustomObject]@{SSID=$_.line.substring(27)}}

foreach ($SSID in $SSIDList)
{
    # if there are no SSID's named "Soverance-Internal"
    if ($SSID -ne "Soverance-Internal")
    {
        # install the Soverance-Internal wifi profile
        netsh wlan add profile filename="C:\ProgramData\Soverance\Config-Soverance-Internal.xml"
    }
}