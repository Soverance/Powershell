# © 2018 Soverance Studios
# Scott McCutchen
# scott.mccutchen@soverance.com
#
# Removes the specified user from the local administrators group of the specified remote computer

param(
    [string]$Computer = $(throw "-Computer is required. You must specify a valid hostname on the network."),
    [string]$User = $(throw "-User is required. You must specify a valid SAM account name.")
)

function Resolve-SamAccount
{
    param(
        [string]$SamAccount
    )

    process
    {
        try
        {
            $ADResolve = ([adsisearcher]"(samaccountname=$User)").findone().properties['samaccountname']
        }
        catch
        {
            $ADResolve = $null
        }

        if (!$ADResolve)
        {
            Write-Warning "User `'$SamAccount`' not found in AD, please input correct SAM Account"
        }

        $ADResolve
    }
}

if ($User -notmatch '\\')
{
    $ADResolved = (Resolve-SamAccount -SamAccount $User)
    $User = 'WinNT://',"$env:userdomain",'/',$ADResolved -join ''
}
else
{
    $ADResolved = ($User -split '\\')[1]
    $DomainResolved = ($User -split '\\')[0]
    $User = 'WinNT://',$DomainResolved,'/',$ADResolved -join ''
}

$Computer | ForEach-Object {
    Write-Verbose "Removing '$ADResolved' from Administrators group on '$_'"
    try {
        ([adsi]"WinNT://$_/Administrators,group").PSBase.Invoke("Remove",$User)
        Write-Verbose "Successfully completed command for '$ADResolved' on '$_'"
    } catch {
        Write-Warning $_
    }
}