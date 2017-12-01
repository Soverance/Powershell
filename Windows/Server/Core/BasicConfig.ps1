# scott.mccutchen@soverance.com
# Server Core Basic Configuration Help

# Use this script as a technical document to help configure Server Core installations.  I tend to run these cmdlets in order.

# If you are using this script as documentation for configuring a new Server Core installation, please perform the steps found in "IPConfig.ps1" before proceeding.

# Set the computer's time zone
# use Get-TimeZone to verify settings
Set-TimeZone -Id "Eastern Standard Time"

# display the computer name
$env:computername

# Assuming you're logged in as a local administrator...
# rename the computer
# the computer will restart automatically with the -Restart param
Rename-Computer -NewName "SOV-SQL" -Restart

# store credentials for the domain you wish to join
$cred = Get-Credential

# join the domain
Add-Computer -ComputerName "SOV-SQL" -DomainName "soverance.net" -Credential $cred -Restart

# if you need to (you should never need to), you can disable the firewall for testing purposes
# be sure to re-enable it when you're done fucking around!
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False

# However, with the firewall up on a new Server Core install by default, file sharing doesn't work.
# You must enable File and Printer Sharing to allow this machine to be found on the network
Get-NetFirewallRule -DisplayGroup 'File and Printer Sharing'|Set-NetFirewallRule -Profile 'Private, Domain' -Enabled true -PassThru|select Name,DisplayName,Enabled,Profile|ft -a

# Sometimes you may need to create a file share on the server, which you can do with the following commands:
# create a new directory
New-Item "C:\SQL" -type directory
# create the SMB share
New-SMBShare -Name "SQL" -Path "C:\SQL" -FullAccess "soverance\developers"

# configure windows automatic updates.  Use "/AU /V" to check the current state of updates
cscript C:\Windows\System32\SCRegEdit.wsf /AU 4