# © 2017 BKV LLC
# Scott McCutchen
# Systems Administrator
# scott.mccutchen@bkv.com

# The possible values for Rights are: 
# ListDirectory, ReadData, WriteData 
# CreateFiles, CreateDirectories, AppendData 
# ReadExtendedAttributes, WriteExtendedAttributes, Traverse
# ExecuteFile, DeleteSubdirectoriesAndFiles, ReadAttributes 
# WriteAttributes, Write, Delete 
# ReadPermissions, Read, ReadAndExecute 
# Modify, ChangePermissions, TakeOwnership
# Synchronize, FullControl

# This script requires the AlphaFS module to be installed.
# See the AlphaFS GitHub for more info:  https://github.com/alphaleonis/AlphaFS/wiki/PowerShell

# Import-Module -Name 'C:\AlphaFS 2.1\Lib\Net4.0\AlphaFS.dll'

#################### Worker file ####################
. "$PSScriptRoot\Get-AlphaFSChildItem.ps1"

Write-Host "Get-AlphaFSChildItem has been successfully loaded."
#################### End Worker file ####################

$Right=Read-Host "The possible values for Rights are:  ListDirectory, ReadData, WriteData, CreateFiles, CreateDirectories, AppendData, ReadExtendedAttributes, WriteExtendedAttributes, Traverse, ExecuteFile, DeleteSubdirectoriesAndFiles, ReadAttributes, WriteAttributes, Write, Delete, ReadPermissions, Read, ReadAndExecute, Modify, ChangePermissions, TakeOwnership, Synchronize, FullControl"
$StartingDir=Read-Host "What directory do you want to start at?"
$Principal=Read-Host "What security principal do you want to grant" `
"$Right to? `n Use format domain\username or domain\group"

#define a new access rule.
$rule=New-Object System.Security.AccessControl.FileSystemAccessRule($Principal,$Right,"Allow")

foreach ($file in $(Get-AlphaFSChildItem -path $StartingDir -recurse)) 
{
  $acl=Get-ACL $file.FullName
 
  #Add this access rule to the ACL
  $acl.SetAccessRule($rule)

  Write-Progress -Activity "Modifying Permissions:" -CurrentOperation $file.Name `
            -Status $rule -PercentComplete (100)
  
  #Write the changes to the object
  Set-ACL $File.Fullname $acl
}