# © 2018 Soverance Studios, LLC.
# Scott McCutchen
# soverance.com
# scott.mccutchen@soverance.com

# This file is not intended to be run on it's own!
# Instead, it is intended to be a reference library for manual usage of cmdlets during the administration of Azure AD Connect

# If you end up needing to connect to the Azure AD service and make manual changes to the directory, 
# you'll want to use the Azure AD 2.0 PS module
# See here:  https://docs.microsoft.com/en-us/powershell/module/Azuread/?view=azureadps-2.0

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
