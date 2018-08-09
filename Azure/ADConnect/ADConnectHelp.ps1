# � 2018 Soverance Studios, LLC.
# Scott McCutchen
# soverance.com
# scott.mccutchen@soverance.com

# This file is not intended to be run on it's own!
# Instead, it is intended to be a reference library for manual usage of cmdlets during the administration of Azure AD Connect

# If you end up needing to connect to the Azure AD service and make manual changes to the directory,
# you'll want to use the Azure AD 2.0 PS module
# See here for more info:  https://docs.microsoft.com/en-us/powershell/module/Azuread/?view=azureadps-2.0

# Start a sync cycle
# run this command with -PolicyType Initial to force a full sync
Start-ADSyncSyncCycle -PolicyType Delta

# Check the Sync Interval
Get-ADSyncScheduler

# Set the Sync Interval to a custom value
# This example sets the interval to 30 minutes
Set-ADSyncScheduler -CustomizedSyncCycleInterval 00:30:00

# enable the automated sync cycle
Set-ADSyncScheduler -SyncCycleEnabled $True

# Changing the UPN of a user in Azure AD
# You must first connect to the Azure AD service with the "Connect-AzureAD" cmdlet
Set-AzureADUser -ObjectID "scottm@soverance.com" -UserPrincipalName "scott.mccutchen@soverance.com"

# Allow the AD Connect service to auto-update
Set-ADSyncAutoUpgrade -AutoUpgradeState Enabled

# Toubleshooting the password hash synchronization feature
# see here for more info:  https://docs.microsoft.com/en-us/azure/active-directory/connect/active-directory-aadconnectsync-troubleshoot-password-hash-synchronization
Invoke-ADSyncDiagnostics -PasswordSync

# In many environments, we want to use the "mail" AD attribute as the user principal name, instead of the actual UPN as stored in AD.
# this is often cleaner for a better user login experience, as they're more used to using their email address than anything else
# to make the sync work properly, you must modify a series of synchronization rules with the following expression:

# Expression = userPrincipalName = IIF(IsPresent([mail]),[mail], IIF(IsPresent([sAMAccountName]),([sAMAccountName]&"@"&%Domain.FQDN%),Error("AccountName is not present")))

# This change cannot be made via powershell, as far as I know, and must be done via the GUI Synchronization Rules Editor
# Keep in mind that if this change is made to a default rule, it will be overwritten during the next AD Connect upgrade.
# You must copy and disable the default rule, and then edit the copy to preserve the changes during upgrades

# the synchronization rules that must be modifed are:

# In from AD – User AccountEnabled
# In from AD – InetOrgPerson AccountEnabled
# In from AD – User Common
# In from AD – InetOrgPerson Common
