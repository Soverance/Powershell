# Scott McCutchen
# DevOps Engineer
# scott.mccutchen@soverance.com

# This script creates a local administrator user on a Windows machine.
# It is intended to be run manually within a deploytment template, as a scheduled task, or as part of a GPO

##############################################
###
###  Parameters
###
##############################################
#[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword")]

param 
(
    [Parameter(Mandatory=$True)]
    [string]$username,

    [Parameter(Mandatory=$True)]
    [string]$password,

    [Parameter(Mandatory=$False)]
    [string]$group = "Administrators"
)

$adsi = [ADSI]"WinNT://$env:COMPUTERNAME"
$existing = $adsi.Children | Where-Object {$_.SchemaCLassName -eq 'user' -and $_.Name -eq $Username }  # check whether the user already exists

# if the user does not yet exist, create it
if (!$existing)
{
    & NET USER $username $password /add /y /expires:never  # create user account
    & NET LOCALGROUP $group $username /add  # add user to local admin group
    & WMIC USERACCOUNT WHERE "Name='$username'" SET PasswordExpires=FALSE  # set user's password to never expire
}