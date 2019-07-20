# © 2018 Soverance Studios
# Scott McCutchen
# scott.mccutchen@soverance.com

# Server Core Basic Configuration Help

# Use this script as a technical document to help configure Server Core installations.  I tend to run these cmdlets in order.

# On a blank server that has been recently joined to the domain...

# Install the AD-Domain Services feature
Install-WindowsFeature AD-Domain-Services -IncludeManagementTools

# Install the new domain controller into an existing domain
# you must be logged into the computer as an administrator to run this command - Get-Credential will use the credentials of the currently active session
# the computer will be automatically rebooted upon success
Install-ADDSDomainController -DomainName "soverance.net" -credential ${Get-Credential}
