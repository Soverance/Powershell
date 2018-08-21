# © 2018 Soverance Studios
# Scott McCutchen
# scott.mccutchen@soverance.com

# This script will iterate through the active directory groups, and apply an auditing rule to record all actions made to the groups by Domain Admins.

# While many actions will be recorded in the event viewer, we are specifically looking for modifications made to AD Groups
# Security Event 4728 = User Added to Group
# Security Event 4729 = User Removed from Group

# Import The Required Module
Import-Module ActiveDirectory

#Get The RootDSE Info
$rootDSE = Get-ADRootDSE

# Create a Hash Table With The LDAPDisplayName And schemaIDGUID Of Each Schema Class And Attribute
$mappingTable_LDAPDisplayName_schemaIDGUID = @{}
Get-ADObject -SearchBase $($rootDSE.schemaNamingContext) `
    -LDAPFilter "(schemaIDGUID=*)" `
    -Properties LDAPDisplayName,schemaIDGUID | ForEach-Object{
        $mappingTable_LDAPDisplayName_schemaIDGUID[$_.LDAPDisplayName]=[System.GUID]$_.schemaIDGUID
    }

# Get List Of AD Groups to process
# This just gets all groups.  Modify the filter if necessary...
$ADGroups = Get-ADGroup -Server "SOV-PDC" -Filter *
# for example, to get all -H groupds, you might use this:
#$ADGroups = Get-ADGroup -Server "UA-PDC" -Filter {name -like "*-H*"}
# or for testing you might use a specific group, like the dev group
#$ADGroups = Get-ADGroup -Server "UA-PDC" -Identity "Development"


# Object Class And Attribute To Configure Auditing For
$scopedObject = "user"
$schemaIDGUIDScopedObject = $mappingTable_LDAPDisplayName_schemaIDGUID[$scopedObject]
$scopedAttribute = "mail"
$schemaIDGUIDScopedAttribute = $mappingTable_LDAPDisplayName_schemaIDGUID[$scopedAttribute]
$inheritanceScope = "Descendents"

# Security Principal To Audit For Actions
$securityPrincipalAccount = "SOVERANCE\Domain Admins"
$securityPrincipalObject = New-Object System.Security.Principal.NTAccount($securityPrincipalAccount)

# Define Auditing Entry
$rightsCollection = [System.DirectoryServices.ActiveDirectoryRights]::"ReadProperty","WriteProperty"
$auditType = [System.Security.AccessControl.AuditFlags]::"Success","Failure"
$auditDefinition = $securityPrincipalObject,$rightsCollection,$auditType,$schemaIDGUIDScopedAttribute,$inheritanceScope,$schemaIDGUIDScopedObject
$auditRule = New-Object System.DirectoryServices.ActiveDirectoryAuditRule($auditDefinition)

# Process Each OU
$ADGroups | ForEach-Object{
    $group = $_
    $groupDrivePath = $("AD:\" + $group)
    Write-Host ""
    Write-Host "Processing Group: $group" -Foregroundcolor Cyan
    Write-Host "   ADDING Audit Entry..."
    Write-Host "      Security Principal...: $securityPrincipalAccount"
    Write-Host "      Audit Type...........: $auditType"
    Write-Host "      Access Type..........: $rightsCollection"
    Write-Host "      Scoped Attribute.....: $scopedAttribute"
    Write-Host "      Scoped Object Class..: $scopedObject"
    Write-Host "      Scope................: $inheritanceScope"
    Write-Host ""
    $acl = Get-Acl $groupDrivePath -Audit
    $acl.AddAuditRule($auditRule)
    $acl | Set-Acl $groupDrivePath
}
