# Update BitLocker Keys in Active Directory
# Scott McCutchen
# DevOps Engineer
# scott.mccutchen@soverance.com

# This script is intended to be run in the following situation:

# A domain-joined machine becomes encrypted with BitLocker, storing it's recovery key locally.
# Later, a Group Policy is put in place to store all BitLocker keys in Active Directory.
# The machine that was configured with BitLocker prior to receiving the GPO does not store it's BitLocker keys in Active Directory.

# Execute this script to write the BitLocker recovery key back to Active Directory, after which the GPO should resume as normal for all new encryptions

#region
##############################################
###
###  Parameters
###
##############################################

param 
(
    [Parameter(Mandatory=$True)]
    [string]$DriveLetter  # type this value as "D:"
)
#endregion

#region
##############################################
###
###  Main
###
##############################################

try 
{
    $keyID = Get-BitLockerVolume -MountPoint $DriveLetter | Select-Object -ExpandProperty keyprotector | Where-Object {$_.KeyProtectorType -eq 'RecoveryPassword'}
    Backup-BitLockerKeyProtector -MountPoint $DriveLetter -KeyProtectorId $keyID.KeyProtectorId    
}
catch 
{
    Write-Error "ERROR in $($MyInvocation.MyCommand) on line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)"
}

#endregion
