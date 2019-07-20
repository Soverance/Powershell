# © 2018 Soverance Studios
# Scott McCutchen
# scott.mccutchen@soverance.com
#
# Recycle Application Pools in IIS

# Uncomment these lines and run them on a new server to install the IIS Web-Scripting-Tools feature
# which is necessary to find the IIS:\ drive

#Import-Module ServerManager
#Add-WindowsFeature Web-Scripting-Tools


try
{
    Import-Module WebAdministration
    Get-WebApplication
 
    $webapps = Get-WebApplication
    $list = @()
    foreach ($webapp in Get-ChildItem IIS:\AppPools\)
    {    
        $name = "IIS:\AppPools\" + $webapp.name  #define app pool path
        $item = @{}  #create empty item array
 
        $item.WebAppName = $webapp.name 
        $item.Version = (Get-ItemProperty $name managedRuntimeVersion).Value 
        $item.State = (Get-WebAppPoolState -Name $webapp.name).Value
        $item.UserIdentityType = $webapp.processModel.identityType 
        $item.Username = $webapp.processModel.userName
        $item.Password = $webapp.processModel.password

        Restart-WebAppPool $webapp.name
        
        if($?)
        {
            $item.SuccessfulRecycle = "TRUE"
        }
        else
        {
            $item.SuccessfulRecycle = "FALSE"
        }

        $obj = New-Object PSObject -Property $item
        $list += $obj
     }
 
    $list | Format-Table -a -Property "WebAppName", "Version", "SuccessfulRecycle", "State", "UserIdentityType", "Username", "Password"
 
}
catch
{
    $ExceptionMessage = "Error in Line: " + $_.Exception.Line + ". " + $_.Exception.GetType().FullName + ": " + $_.Exception.Message + " Stacktrace: " + $_.Exception.StackTrace
    $ExceptionMessage
}