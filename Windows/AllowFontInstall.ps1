# © 2018 BKV LLC
# Scott McCutchen
# Systems Administrator
# scott.mccutchen@bkv.com
#
# This script runs as a computer startup script in order to grant permission for font installs

# this command makes the system fonts folder writeable, and turns it into a non-system folder
attrib -r -s %systemroot%\fonts

# this command takes ownership of the fonts folder so that we can make permission changes to it
takeown /f C:\Windows\Fonts /r /d n

# grant permission to the appropriate user group
cacls C:\Windows\Fonts /e /t /g users:c

# do the same thing for the font cache
# NOTE:  you will receive an access denied message when running this command - THIS IS NORMAL
cacls C:\Windows\System32\FNTCACHE.DAT /e /t /g users:c

# finally, we need to modify the access control list on the font folder's registry key
$acl = Get-Acl "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Fonts"
$rule = New-Object System.Security.AccessControl.RegistryAccessRule ("UA\Allow Font Install","FullControl","Allow")
$acl.SetAccessRule($rule)
$acl | Set-Acl -Path "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Fonts"