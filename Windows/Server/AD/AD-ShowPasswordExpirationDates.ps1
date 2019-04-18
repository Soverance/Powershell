# © 2019 Soverance Studios
# Scott McCutchen
# scott.mccutchen@soverance.com

# this script displays all users in the AD along with their password expiration dates

Get-ADUser -filter {Enabled -eq $True -and PasswordNeverExpires -eq $False} –Properties "DisplayName", "msDS-UserPasswordExpiryTimeComputed" |
Select-Object -Property "Displayname",@{Name="ExpiryDate";Expression={[datetime]::FromFileTime($_."msDS-UserPasswordExpiryTimeComputed")}}