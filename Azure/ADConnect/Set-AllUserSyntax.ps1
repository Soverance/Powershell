# © 2018 Soverance Studios
# Scott McCutchen
# scott.mccutchen@soverance.com

# Connect to the Azure AD service before making changes to the directory, 
# you must use the Azure AD 2.0 PS module
# See here:  https://docs.microsoft.com/en-us/powershell/module/Azuread/?view=azureadps-2.0

# Enter the domain name you wish to scan
$domain = "contoso.com"

# Install the Azure AD PS Module if it does not already exist
#Install-Module AzureAD
Import-Module AzureAD

# Connect to the Azure AD Service
Connect-AzureAD

# Get every user in the local Active Directory
$AllADUsers = Get-ADUser -server $domain -Filter * -Properties *

foreach ($user in $AllADUsers)
{
    if ($user.AzureSyncEnabled -eq $true)
    {
        if ([string]::IsNullOrEmpty(($user.Mail)))
        {
            Write-Host ($($user.DisplayName)) "is missing an email address!" -ForegroundColor Red
        }
        else
        {
            $old = $user.SamAccountName  # get default username
            $old = $old + "@contoso.com"  # convert to old AAD syntax
            $new = $user.Mail  # get current email address
            $new = $new.Substring(0, $new.IndexOf('@'))  # trim email string to get just the username
            $new = $new.ToLower()  # force the username to all lowercase characters
            $new = $new + "@contoso.com"  # concatenate the new email address
            Write-Host ($($user.DisplayName)) "will change from" ($($old)) "to" ($($new))  # write output to console
            Set-AzureADUser -ObjectID $old -UserPrincipalName $new  # set the new username syntax in Azure AD
        }        
    }    
}
