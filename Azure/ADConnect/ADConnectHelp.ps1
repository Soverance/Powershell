# © 2017 BKV, Inc.
# Scott McCutchen
# www.bkv.com
# scott.mccutchen@bkv.com

# This file is not intended to be run on it's own!
# Instead, it is intended to be a reference library for manual usage of cmdlets during the administration of Azure AD Connect

# Start a sync cycle
# run this command with -PolicyType Initial to force a full sync
Start-ADSyncSyncCycle -PolicyType Delta

# Check the Sync Interval
Get-ADSyncScheduler

# Set the Sync Interval to a custom value
# This example sets the interval to 30 minutes
Set-ADSyncScheduler -CustomizedSyncCycleInterval 00:30:00