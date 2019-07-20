# © 2018 Soverance Studios
# Scott McCutchen
# scott.mccutchen@soverance.com
#
# This script will restore the "Control Panel" link to the context menu when right-clicking the Start menu taskbar icon in Windows 10

$key = "HKCU:\Soverance\"

# force creation of the registry key if it does not exist
If  ( -Not ( Test-Path $Key)){New-Item -Path $Key -ItemType RegistryKey -Force}
Set-ItemProperty -path $Key -Name "Soverance" -Type "String" -Value "Soverance"

#
if ((Get-ItemProperty -Path $key -Name ControlPanelLink).ControlPanelLink)
{
    # if the registry key exists, go ahead and quit because this script has already run successfully.
    exit
}
# if the registry key does not exist, run this script and add it
else
{
    # set the local application data path
    $path = "$env:LOCALAPPDATA\Microsoft\Windows\WinX\Group2"

    # store the base64 encoded shortcut file to the Control Panel
    $x = "UEsDBBQAAAAIAEphSkmJ5YBS0QAAAPcDAAARAAAAQ29udHJvbCBQYW5lbC5sbmvzYWBgYBRhYgCBA2CSwa2BmQEiQAAwovEnAzEnA8MCXSBtGBwQ/Kgrwm2Pj4Xz7j/Ck9Vm5J4ThCkURtIEUxyq4TO/cr6l94oLD6/oPrz6GaRYCKaYEU1xtW7v74sTTPz2J+St4ZykvR+kmAmm+Og13laY6SLMYM0LVMsz81Iyi1RjiiuLS1JzjY1ikvPzSoryc/RSK1KJ8eswAKoM5QyZDHkMKUCyCMiLYShmqATiEoZUhlwGYwYjoEgyQz5QRQlQPp8hh0EPKFPBMFLCZyQBAFBLAQIUABQAAAAIAEphSkmJ5YBS0QAAAPcDAAARAAAAAAAAAAAAAAAAAAAAAABDb250cm9sIFBhbmVsLmxua1BLBQYAAAAAAQABAD8AAAAAAQAAAAA=".replace("`n","")

    # convert the base64 string into something usable and archive it
    [Convert]::FromBase64String($x) | Set-Content $path\temp.zip -Encoding Byte

    # expand the archive into the appdata path
    Expand-Archive $path\temp.zip -DestinationPath $path -Force

    # remove the archive
    Remove-Item $path\temp.zip

    # restart explorer.exe.  
    # using this command via powershell will stop and then restart the explorer service automatically.
    Stop-Process -Name Explorer

    # set a registry key to verify successful installation of the control panel link
    # this is necessary as this script is run as a logon script via GPO
    # and we have no need to run this script again if this registry key exists
    New-Item "HKCU:\Soverance\" -Force | New-ItemProperty -Name ControlPanelLink -Value 1 -Force | Out-Null
}

