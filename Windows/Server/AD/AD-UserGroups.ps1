# © 2017 BKV LLC
# Scott McCutchen
# Systems Administrator
# scott.mccutchen@bkv.com

# Export Active Directory information from the specified server into an Excel .xlsx file

# This script requires the installation of Windows (KB2693643) Microsoft Remote Server Administration Tools
# Once installed, Turn Windows features on or off, then enable Active Directory Module for Windows PowerShell 

# This script is designed to export directly to Excel .xlsx file format, and requires the ImportExcel module to correctly function.
# With the ImportExcel module installed, you DO NOT require a licensed copy of Excel to be installed.
# The ImportExcel module can be installed through the Powershell Gallery using the following commands (PS v5 only!):
# To install for all users:  Install-Module ImportExcel
# To install only for current user:  Install-Module ImportExcel -scope CurrentUser
# PS v4 and below will need to follow installation instructions found on the module's Github page:  https://github.com/dfinke/ImportExcel
# Further info on the ImportExcel module and various usage scenarios can be found in this blog post:  https://blogs.technet.microsoft.com/heyscriptingguy/2015/11/25/introducing-the-powershell-excel-module-2/
# You can run the Export-Excel command with the -Show flag to automatically open the report in Excel (assuming Excel is installed)

# When using Gmail SMTP servers to send this report, Google will by default block the sign-in attempt from Powershell, preventing email from being sent.
# To enable your Gmail account to send email in this manner, you must do one of the following:

# OPTION #1 - ALLOW LESS SECURE APPS
# Visit this help document for more information and directions on how to enable this setting:  https://support.google.com/accounts/answer/6010255?hl=en
# This feature is unavailable for accounts with two-factor authentication enabled
# This is the least secure method and could compromise the security of your Google account.  It is recommended to use Option #2, below.

# OPTION #2 - ENABLE TWO-FACTOR AUTHENTICATION AND USE AN "APP PASSWORD"
# Enabling two-factor authentication will disable the "Allow Less Secure Apps" feature.
# Configure this setting to be a "Mail" application on a "Windows Computer".
# Visit this help document for more information and directions on how to enable this setting:  https://support.google.com/accounts/answer/185833?hl=en

#################################################################
## EDITABLE VARIABLES BELOW
##
## Only make changes to these values here!
#################################################################

# Enter the domain name you wish to scan
$domain = "bkv.local"

# Enter valid SMTP information in order to email the report
# PLEASE SEE THE ABOVE NOTICE ABOUT GMAIL SMTP AUTHENTICATION.
$user = "emailaddress@gmail.com"
$password = "yourpasswordhere"
$smtpserver = "smtp.gmail.com"
$smtpport = "587"

# Enter the "Send To" email address (who receives the report)
$recipient = "emailaddress@gmail.com"

#################################################################
##
## MAKE NO CHANGES BEYOND THIS POINT!
##
#################################################################

# Define the export path to place the .xlsx report
# We're using the current root directory of this script, for simplicity.
$exportpath = $PSScriptRoot

# Builds the complete path of the exported report, including file name.
$ExportPathWithFileName = $exportpath + "\AD_Report_" + (Get-Date -format yyyy-MM-dd) + ".xlsx"
 
# The AD Module must be imported before AD-specific commands can be run
Import-Module ActiveDirectory

# Export AD Users
function ExportAD-Users ()
{
    # Export AD User data, with all parameters
    # This command could take some time, depending on the size of the AD
    $AllADUsers = Get-ADUser -server $domain -Filter * -Properties *

    # Filter the user report for user-friendly data we care about
    # Find the complete list of properties at: https://social.technet.microsoft.com/wiki/contents/articles/12037.active-directory-get-aduser-default-and-extended-properties.aspx
    $AllADUsers |
    Select-Object @{Label = "First Name";Expression = {$_.GivenName}},
    @{Label = "Last Name";Expression = {$_.Surname}},
    @{Label = "Display Name";Expression = {$_.DisplayName}},
    @{Label = "Logon Name";Expression = {$_.SamAccountName}},
    @{Label = "Full address";Expression = {$_.StreetAddress}},
    @{Label = "City";Expression = {$_.City}},
    @{Label = "State";Expression = {$_.ST}},
    @{Label = "Post Code";Expression = {$_.PostalCode}},
    @{Label = "Country/Region";Expression = {$_.Country}},
    @{Label = "Job Title";Expression = {$_.Title}},
    @{Label = "Company";Expression = {$_.Company}},
    @{Label = "Directorate";Expression = {$_.Description}},
    @{Label = "Department";Expression = {$_.Department}},
    @{Label = "Office";Expression = {$_.OfficeName}},
    @{Label = "Phone";Expression = {$_.TelephoneNumber}},
    @{Label = "Email";Expression = {$_.Mail}},
    # Getting this user's manager requires a bit more effort, but is luckily a simply query
    @{Label = "Manager";Expression = {%{(Get-ADUser $_.Manager -server $domain -Properties DisplayName).DisplayName}}},
    @{Label = "Account Status";Expression = {if (($_.Enabled -eq 'TRUE')  ) {'Enabled'} Else {'Disabled'}}}, # the 'if statement replaces $_.Enabled output with a user-friendly readout
    @{Label = "Last LogOn Date";Expression = {$_.LastLogonDate}},
    @{Label = "Password Last Set";Expression = {$_.pwdLastSet}},
    # Getting user group info requires a bit more effort, and data must be made user-friendly before display
    @{Label = "Member Of Groups";Expression = {%{(Get-ADPrincipalGroupMembership $_.SamAccountName | sort | select -ExpandProperty Name) -join ', '}}} | 

    # Export User Report
    Export-Excel -Path $ExportPathWithFileName -WorkSheetname Users
}

# Export AD Group Information
function ExportAD-Groups ()
{
    # Export all Group data
    $ADGroups = Get-ADGroup -Server $domain -Filter *

    # Filter the Group report for user-friendly data we care about
    $ADGroups |
    Select-Object @{Label = "Name";Expression = {$_.Name}},
    @{Label = "Category";Expression = {$_.GroupCategory}},
    @{Label = "Scope";Expression = {$_.GroupScope}},
    @{Label = "Distinguished Name";Expression = {$_.DistinguishedName}} |

    # Export Group Report
    Export-Excel -Path $ExportPathWithFileName -WorkSheetname Groups
}

# Export AD Computer Information
function ExportAD-Computers ()
{
    # Export all Computer data with all extended properties
    $ADComputers = Get-ADComputer -Server $domain -Filter * -Properties *

    # Filter the Computer report for user-friendly data we care about
    $ADComputers |
    Select-Object @{Label = "Name";Expression = {$_.Name}},
    @{Label = "DNS Host Name";Expression = {$_.DNSHostName}},
    @{Label = "Operating System";Expression = {$_.operatingSystem}},
    @{Label = "OS Version";Expression = {$_.operatingSystemVersion}},
    @{Label = "OS Service Pack";Expression = {$_.operatingSystemServicePack}},
    @{Label = "IPv4 Address";Expression = {$_.IPv4Address}},
    @{Label = "Current Image Install Date";Expression = {$_.whenCreated}},
    # We need a bit of extra effort here as well, to pull the date of when the manufacturer first installed Windows
    # We'll use the [WMI] type accelerator for the 
    @{Label = "Manufacturer Install Date";Expression = {%{(([WMI] "").ConvertToDateTime((Get-WmiObject Win32_OperatingSystem -ComputerName $_.Name).InstallDate))}}},
    @{Label = "Enabled";Expression = {$_.Enabled}},
    @{Label = "Distinguished Name";Expression = {$_.DistinguishedName}} |

    # Export Computer Report
    Export-Excel -Path $ExportPathWithFileName -WorkSheetname Computers
}

# Export AD Domain Controller Information
function ExportAD-DCs ()
{
    # Export all Domain Controller data
    $ADDCs = Get-ADDomainController -Filter *

    # Filter the Domain Controller report for user-friendly data we care about
    $ADDCs |
    Select-Object @{Label = "Name";Expression = {$_.Name}},
    @{Label = "Domain";Expression = {$_.Domain}},
    @{Label = "Operating System";Expression = {$_.OperatingSystem}},
    @{Label = "Enabled";Expression = {$_.Enabled}},
    @{Label = "DNS Host Name";Expression = {$_.HostName}},
    @{Label = "Site";Expression = {$_.Site}},
    @{Label = "IPv4 Address";Expression = {$_.IPv4Address}},
    @{Label = "IPv6 Address";Expression = {$_.IPv6Address}},
    @{Label = "Global Catalog";Expression = {$_.IsGlobalCatalog}},
    @{Label = "Read Only";Expression = {$_.IsReadOnly}},
    @{Label = "Operation Master Roles";Expression = {$_.OperationMasterRoles -join ', '}} |

    # Export Domain Controller Report
    Export-Excel -Path $ExportPathWithFileName -WorkSheetname DomainControllers
}

# Export AD Forest Information
function ExportAD-Forests ()
{
    # Export all Forest data
    $ADForests = Get-ADForest -Server $domain
    
    # Filter the Forest report for user-friendly data we care about
    $ADForests |
    Select-Object @{Label = "Name";Expression = {$_.Name}},
    @{Label = "Forest Mode";Expression = {$_.ForestMode}},
    @{Label = "DomainNamingMaster";Expression = {$_.DomainNamingMaster}},
    @{Label = "Domains";Expression = {$_.Domains}},
    @{Label = "Global Catalogs";Expression = {$_.GlobalCatalogs}},
    @{Label = "Root Domain";Expression = {$_.RootDomain}},
    @{Label = "SchemaMaster";Expression = {$_.SchemaMaster}},
    @{Label = "Sites";Expression = {$_.Sites}} |
    
    # Export Forest Report 
    Export-Excel -Path $ExportPathWithFileName -WorkSheetname Forests
}

# Export AD Organizational Unit Information
function ExportAD-OUs ()
{
    #Export all Organizational Unit Information
    $ADOU = Get-ADOrganizationalUnit -Server $domain -Filter *

    # Filter the Organizational Unit report for user-friendly data we care about
    $ADOU |
    Select-Object @{Label = "Name";Expression = {$_.Name}},
    @{Label = "Distinguished Name";Expression = {$_.DistinguishedName}},
    @{Label = "Linked GPOs";Expression = {$_.LinkedGroupPolicyObjects}} |

    # Export Organizational Unit Report 
    Export-Excel -Path $ExportPathWithFileName -WorkSheetname OrganizationalUnits
}

# Email Report
function EmailReport ()
{
    # This is an ugly hack to convert the password string into secure credentials
    $pass = ConvertTo-SecureString -String $password -AsPlainText -Force

    # Store the full SMTP credentials in a single variable
    $creds = New-Object -TypeName "System.Management.Automation.PSCredential" -ArgumentList $user, $pass

    # Create and send the email message with attachment
    Send-MailMessage `
        -To $recipient `
        -Subject 'Active Directory Domain Report' `
        -Body 'You will find the Active Directory Domain Report attached below.' `
        -UseSsl `
        -Port $smtpport `
        -SmtpServer $smtpserver `
        -From $user `
        -Credential $creds `
        -Attachments $ExportPathWithFileName
}

# Run Functions
ExportAD-Users
ExportAD-Groups
ExportAD-Computers
ExportAD-DCs
ExportAD-Forests
ExportAD-OUs
#EmailReport