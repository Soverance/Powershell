# Scott McCutchen
# soverance.com
#
# This is a Powershell Profile script used to automatically connect to Office 365 services.
# You may need to sign this script from within your environment for proper and clean operation
# More information on connecting to Office 365 with Powershell can be found here:  https://technet.microsoft.com/library/dn975125.aspx
# Software Prerequisites:
# .NET Framework 3.5.1 or higher
# Microsoft Online Services Sign On Assistant  =  https://www.microsoft.com/en-us/download/details.aspx?id=41950
# Windows Azure Active Directory Module  =  http://go.microsoft.com/fwlink/p/?linkid=236297

Import-Module MSOnline
$O365Cred = Get-Credential
$O365Session = New-PSSession –ConfigurationName Microsoft.Exchange -ConnectionUri https://ps.outlook.com/powershell -Credential $O365Cred -Authentication Basic -AllowRedirection
Import-PSSession $O365Session
Connect-MsolService –Credential $O365Cred