# © 2019 Soverance Studios
# Scott McCutchen
# DevOps Engineer
# scott.mccutchen@soverance.com

# Export Active Directory information from the specified server into an Excel .xlsx file

#region
#################################################################
### 
###  Pre-requisite Documentation
###
#################################################################

# This script requires the installation of Microsoft Remote Server Administration Tools
# Once installed, Turn Windows features on or off, then enable Active Directory Module for Windows PowerShell 

# This script is designed to export directly to Excel .xlsx file format, and requires the ImportExcel module to correctly function.
# With the ImportExcel module installed, you DO NOT require a licensed copy of Excel or Office to be installed.
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

##############################
##
##  Change History & Credits
##
##############################

# This script originally created for internal reporting by Soverance Studios - May, 2016 

#   Scott McCutchen  |  https://soverance.com  |  info@soverance.com  |  Twitter @soverance	

# Updated June 2016 for use with Unique Sports Products AD migration project.
# Updated September 2016 for use with Georgia Game Developers Association AD migration project.
# Updated June 2017 for use with DRUM Agency AD migration project.
# Updated September 2019 for use with M3 Accounting AD migration project.

#endregion

#region
#################################################################
### 
###  Parameters
###
#################################################################

[CmdletBinding(DefaultParametersetName='None')]
param(
    # Enter the domain name you wish to scan
    [Parameter(Mandatory=$True)]
    [string]$domain,
    [Parameter(Mandatory=$True)]
    [string]$domainAdminUser,
    [Parameter(Mandatory=$True)]
    [string]$domainAdminPass,

    [Parameter(ParameterSetName='Email',Mandatory=$false)]
    [switch]$sendEmail,  # specifying this switch will sent the Excel report via email
    # if -sendEmail is specified, you must enter valid SMTP information in order to email the report
    # PLEASE SEE THE DOCUMENTED NOTICE ABOUT GMAIL SMTP AUTHENTICATION.
    [Parameter(ParameterSetName='Email',Mandatory=$true)]
    [string]$email,
    [Parameter(ParameterSetName='Email',Mandatory=$true)]
    [string]$password,
    [Parameter(ParameterSetName='Email',Mandatory=$true)]
    [string]$smtpserver = "smtp.gmail.com",
    [Parameter(ParameterSetName='Email',Mandatory=$true)]
    [string]$smtpport = "587",
    [Parameter(ParameterSetName='Email',Mandatory=$true)]
    [string]$recipient = "info@soverance.com"  # Enter the "Send To" email address (who receives the report)
)

#endregion

#region
#################################################################
###
###  Functions
###
#################################################################

function Get-PasswordExpiryInfo()
{
    param (
        [Parameter(Mandatory=$True)]
        [string]$sAMAccountName
    )
    
    $PSO= Get-ADUserResultantPasswordPolicy -Server $domain -Identity $sAMAccountName -Credential $creds  # store ad user's current password policy
    $defaultDomainPolicy = Get-ADDefaultDomainPasswordPolicy -Server $domain -Credential $creds   # get and store the domain's current default password policy        
    $passwordexpirydefaultdomainpolicy = $defaultDomainPolicy.MaxPasswordAge.Days -ne 0  # make sure the default policy is anything but zero        
                
    # Collect and store the default domain policy, in case no PSO was applied to the user
    if($passwordexpirydefaultdomainpolicy)            
    {            
        $defaultdomainpolicyMaxPasswordAge = $defaultDomainPolicy.MaxPasswordAge.Days  # set max password age      
    }  
    
    # if resulting password policy is anything but null
    if ($PSO)
    {   
        $PSOMaxPasswordAge = $PSO.MaxPasswordAge.days  # store password age
        $pwdlastset = [datetime]::FromFileTime((Get-ADUser -LDAPFilter "(&(samaccountname=$sAMAccountName))" -Server $domain -Credential $creds -properties pwdLastSet).pwdLastSet) # get password last set time
        $expirydate = ($pwdlastset).AddDays($PSOMaxPasswordAge) # get expiry date     
        $delta = ($expirydate - (Get-Date)).Days  # store the delta between today and the expiry date to find how many days are remaining
        
        $ResultingPasswordObject = New-object -TypeName PSObject
        $ResultingPasswordObject | Add-Member -MemberType NoteProperty -Name MaxPasswordAge -Value $PSOMaxPasswordAge
        $ResultingPasswordObject | Add-Member -MemberType NoteProperty -Name pwdLastSet -Value $pwdlastset
        $ResultingPasswordObject | Add-Member -MemberType NoteProperty -Name ExpiryDate -Value $expirydate
        $ResultingPasswordObject | Add-Member -MemberType NoteProperty -Name DaysRemaining -Value $delta

        # $comparionresults = (($expirydate - (Get-Date)).Days -le $notificationstartday) -AND ($delta -ge 1)  # store comparison results
        
        # if ($comparionresults)  # if the results are valid            
        # {            
        #     # CREATE PASSWORD EXPIRATION EMAIL NOTIFICATION TO USER
        #     $mailBody = "Dear " + $user.GivenName + ",`r`n`r`n" # LINE ONE
        #     $mailBody += "Your password will expire after " + $delta + " days. You will need to change your password to continue using your account.`r`n`r`n"  # LINE TWO
        #     $mailBody += "Please ensure that your new password meets our complexity requirements.  You must use at least 8 characters, and you must include at least one capital letter, one lowercase letter, and one special character.`r`n`r`n"            
        #     $mailBody += "To change your password, Windows users can hit 'Ctrl + Alt + Del' and select the 'Change a password' option.`r`n`r`n" 
        #     $mailBody += "Mac OS X users can change their password by going to 'System Preferences -> Users & Groups', then selecting their account and hitting the 'Change Password' button.`r`n`r`n" 
        #     $mailBody += "`r`n`r`nSoverance Studios IT Department"            
        #     $usermailaddress = $user.mail            
        #     SendMail $SMTPserver $sendermailaddress $usermailaddress $mailBody         
        # }      
        
        return $ResultingPasswordObject
    }        
    # if the password policy was not defined, use the default policy    
    else            
    {
        if($passwordexpirydefaultdomainpolicy)            
        {            
            $pwdlastset = [datetime]::FromFileTime((Get-ADUser -LDAPFilter "(&(samaccountname=$samaccountname))" -Server $domain -Credential $creds -properties pwdLastSet).pwdLastSet)            
            $expirydate = ($pwdlastset).AddDays($defaultdomainpolicyMaxPasswordAge)            
            $delta = ($expirydate - (Get-Date)).Days      
            
            $ResultingPasswordObject = New-object -TypeName PSObject
            $ResultingPasswordObject | Add-Member -MemberType NoteProperty -Name MaxPasswordAge -Value $defaultdomainpolicyMaxPasswordAge
            $ResultingPasswordObject | Add-Member -MemberType NoteProperty -Name pwdLastSet -Value $pwdlastset
            $ResultingPasswordObject | Add-Member -MemberType NoteProperty -Name ExpiryDate -Value $expirydate
            $ResultingPasswordObject | Add-Member -MemberType NoteProperty -Name DaysRemaining -Value $delta

            # $comparionresults = (($expirydate - (Get-Date)).Days -le $notificationstartday) -AND ($delta -ge 1) 

            # if ($comparionresults)            
            # {            
            #     $mailBody = "Dear " + $user.GivenName + ",`r`n`r`n"            
            #     $delta = ($expirydate - (Get-Date)).Days            
            #     $mailBody += "Your password will expire after " + $delta + " days. You will need to change your password to continue using your account.`r`n`r`n"  
            #     $mailBody += "Please ensure that your new password meets our complexity requirements.  You must use at least 8 characters, and you must include at least one capital letter, one lowercase letter, and one special character.`r`n`r`n"            
            #     $mailBody += "To change your password, Windows users can hit 'Ctrl + Alt + Del' and select the 'Change a password' option.`r`n`r`n" 
            #     $mailBody += "Mac OS X users can change their password by going to 'System Preferences -> Users & Groups', then selecting their account and hitting the 'Change Password' button.`r`n`r`n" 
            #     $mailBody += "`r`n`r`nSoverance Studios IT Department"            
            #     $usermailaddress = $user.mail            
            #     SendMail $SMTPserver $sendermailaddress $usermailaddress $mailBody           
            # }      
            
            return $ResultingPasswordObject
        }            
    }  
}

# Export AD Users
function Export-ADUsers ()
{
    # Export AD User data, with all parameters
    # This command could take some time, depending on the size of the AD
    $AllADUsers = Get-ADUser -Credential $creds -server $domain -Filter * -Properties *

    # Find the complete list of user properties at: 
    # https://social.technet.microsoft.com/wiki/contents/articles/12037.active-directory-get-aduser-default-and-extended-properties.aspx
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
    @{Label = "Description";Expression = {$_.Description}},
    @{Label = "Department";Expression = {$_.Department}},
    @{Label = "Office";Expression = {$_.OfficeName}},
    @{Label = "Phone";Expression = {$_.TelephoneNumber}},
    @{Label = "Email";Expression = {$_.Mail}},
    @{Label = "Manager";Expression = {ForEach-Object{(Get-ADUser $_.Manager -Server $domain -Credential $creds -Properties DisplayName).DisplayName}}},
    @{Label = "Account Status";Expression = {if (($_.Enabled -eq 'TRUE')  ) {'Enabled'} Else {'Disabled'}}}, # the 'if statement replaces $_.Enabled output with a user-friendly readout
    @{Label = "Locked Out";Expression = {$_.LockedOut}},
    @{Label = "Account Expires";Expression = {(Get-ADUser $_ -Server $domain -Credential $creds -Properties AccountExpirationDate).AccountExpirationDate}},
    @{Label = "Last LogOn Date";Expression = {$_.LastLogonDate}},
    @{Label = "Does Not Require Kerberos Pre-Auth";Expression = {(Get-ADUser $_ -Server $domain -Credential $creds -Properties DoesNotRequirePreAuth).DoesNotRequirePreAuth}},        
    @{Label = "Password Not Required";Expression = {$_.PasswordNotRequired}},
    @{Label = "Password Never Expires";Expression = {$_.PasswordNeverExpires}},
    @{Label = "Password Last Set";Expression = {$_.PasswordLastSet}},
    @{Label = "Password Change At Next LogOn";Expression = {if (($_.pwdLastSet -eq 0)  ) {'TRUE'} Else {'FALSE'}}},
    # there is almost certainly a more efficient way to create this password object for each user, but this is quick and dirty for now
    #@{Label = "Password Last Set";Expression = {(Get-PasswordExpiryInfo($_.SamAccountName)).pwdLastSet}},    
    @{Label = "Max Password Age";Expression = {(Get-PasswordExpiryInfo($_.SamAccountName)).MaxPasswordAge}},
    @{Label = "Password Expiry Date";Expression = {(Get-PasswordExpiryInfo($_.SamAccountName)).ExpiryDate}},
    @{Label = "Password Expiry Days Remaining";Expression = {(Get-PasswordExpiryInfo($_.SamAccountName)).DaysRemaining}},
    # Getting user group info requires a bit more effort, and data must be made user-friendly before display
    @{Label = "Member Of Groups";Expression = {ForEach-Object{(Get-ADPrincipalGroupMembership $_.SamAccountName -Credential $creds | Sort-Object | Select-Object -ExpandProperty Name) -join ', '}}} | 

    # Export User Report
    Export-Excel -Path $ExportPathWithFileName -WorkSheetname Users -AutoSize -AutoFilter -BoldTopRow -FreezeTopRow -ConditionalText $(
        New-ConditionalText -Text "Disabled" -Range "R:R" -ConditionalTextColor Black -BackgroundColor Goldenrod  # highlight accounts that are disabled  
        New-ConditionalText -Text "TRUE" -Range "V:V" -ConditionalTextColor White -BackgroundColor DarkRed  # highlight accounts that do not require kerberos pre-auth  
        New-ConditionalText -Text "TRUE" -Range "W:W" -ConditionalTextColor White -BackgroundColor DarkRed  # highlight accounts that do not require a password
        New-ConditionalText -Text "TRUE" -Range "Z:Z" -ConditionalTextColor Black -BackgroundColor Goldenrod  # highlight accounts that require a password change at next logon
    )
}

function Test-PrivilegedGroup()
{
    param(
        [Parameter(Mandatory=$True)]
        [string]$domain,
        [Parameter(Mandatory=$True)]
        [string]$groupSID
    )
        $DomainObject = Get-ADDomain $domain -Credential $creds
        $DomainSID = $DomainObject.DomainSID

		# Carefully chosen from a more complete list at:
		# https://support.microsoft.com/en-us/kb/243330
		# Administrator (not a group, just FYI)    - $DomainSid-500
		# Domain Admins                            - $DomainSid-512
		# Schema Admins                            - $DomainSid-518
		# Enterprise Admins                        - $DomainSid-519
		# Group Policy Creator Owners              - $DomainSid-520
		# BUILTIN\Administrators                   - S-1-5-32-544
		# BUILTIN\Account Operators                - S-1-5-32-548
		# BUILTIN\Server Operators                 - S-1-5-32-549
		# BUILTIN\Print Operators                  - S-1-5-32-550
		# BUILTIN\Backup Operators                 - S-1-5-32-551
		# BUILTIN\Replicators                      - S-1-5-32-552
		# BUILTIN\Network Configuration Operations - S-1-5-32-556
		# BUILTIN\Incoming Forest Trust Builders   - S-1-5-32-557
		# BUILTIN\Event Log Readers                - S-1-5-32-573
		# BUILTIN\Hyper-V Administrators           - S-1-5-32-578
		# BUILTIN\Remote Management Users          - S-1-5-32-580
		
		$PrivilegedGroups = "$($DomainSid)-512", "$($DomainSid)-518",
		                    "$($DomainSid)-519", "$($DomainSid)-520",
							"S-1-5-32-544", "S-1-5-32-548", "S-1-5-32-549",
							"S-1-5-32-550", "S-1-5-32-551", "S-1-5-32-552",
							"S-1-5-32-556", "S-1-5-32-557", "S-1-5-32-573",
                            "S-1-5-32-578", "S-1-5-32-580"
        
        $IsPrivileged = "Standard"   

        ForEach($PrivilegedGroup in $PrivilegedGroups) 
		{
            if ($PrivilegedGroup -eq $groupSID)
            {
                $IsPrivileged = "Privileged"
            }
        }

        return $IsPrivileged
}

# Export AD Group Information
function Export-ADGroups ()
{
    # Export all Group data
    $ADGroups = Get-ADGroup -Server $domain -Credential $creds -Filter *

    # Filter the Group report for user-friendly data we care about
    $ADGroups |
    Select-Object @{Label = "Name";Expression = {$_.Name}},
    @{Label = "Category";Expression = {$_.GroupCategory}},
    @{Label = "User Count";Expression = {(Get-ADGroupMember -Identity $_.Name -Credential $creds).Count}},
    @{Label = "Scope";Expression = {$_.GroupScope}},
    @{Label = "Restricted Access";Expression = {(Test-PrivilegedGroup($domain)($_.SID))}},
    @{Label = "Distinguished Name";Expression = {$_.DistinguishedName}} |

    # Export Group Report
    Export-Excel -Path $ExportPathWithFileName -WorkSheetname Groups -AutoSize -AutoFilter -BoldTopRow -FreezeTopRow -ConditionalText $(
        New-ConditionalText -Text "0" -Range "C:C" -ConditionalTextColor White -BackgroundColor DarkRed    
        New-ConditionalText -Text "Privileged" -Range "E:E" -ConditionalTextColor White -BackgroundColor DarkRed
    )
}

# Export AD Computer Information
function Export-ADComputers ()
{
    # Export all Computer data with all extended properties
    $ADComputers = Get-ADComputer -Server $domain -Filter * -Credential $creds -Properties *

    $ADComputers |
    Select-Object @{Label = "Name";Expression = {$_.Name}},
    @{Label = "DNS Host Name";Expression = {$_.DNSHostName}},
    @{Label = "Operating System";Expression = {$_.operatingSystem}},
    @{Label = "OS Version";Expression = {$_.operatingSystemVersion}},
    @{Label = "OS Service Pack";Expression = {$_.operatingSystemServicePack}},
    @{Label = "IPv4 Address";Expression = {$_.IPv4Address}},
    @{Label = "Current Image Install Date";Expression = {$_.whenCreated}},
    # We need a bit of extra effort here to pull the date of when the manufacturer first installed Windows, so we'll use the [WMI] type accelerator for the query.
    # I think this WMI query does not work on remote domains... i.e., when the user running the script is outside the context of the domain being queried
    # If you want this value, easiest way to get it is to run this report as a user who lives in the domain being reported
    @{Label = "Manufacturer Install Date";Expression = {ForEach-Object{(([WMI] "").ConvertToDateTime((Get-WmiObject Win32_OperatingSystem -ComputerName $_.Name -Credential $creds).InstallDate))}}},
    @{Label = "Enabled";Expression = {$_.Enabled}},
    @{Label = "Distinguished Name";Expression = {$_.DistinguishedName}} |

    # Export Computer Report
    Export-Excel -Path $ExportPathWithFileName -WorkSheetname Computers -AutoSize -AutoFilter -BoldTopRow -FreezeTopRow 
}

# Export AD Domain Controller Information
function Export-ADDomainControllers ()
{
    # Export all Domain Controller data
    $ADDCs = Get-ADDomainController -Server $domain -Filter * -Credential $creds

    $ADDCs |
    Select-Object @{Label = "Name";Expression = {$_.Name}},
    @{Label = "Domain";Expression = {$_.Domain}},
    @{Label = "Operating System";Expression = {$_.OperatingSystem}},
    @{Label = "Enabled";Expression = {$_.Enabled}},
    @{Label = "LastChange";Expression = {(Get-ADComputer -Identity $_.Name -Server $domain -Credential $creds -Properties whenChanged).whenChanged}},
    @{Label = "DNS Host Name";Expression = {$_.HostName}},
    @{Label = "Site";Expression = {$_.Site}},
    @{Label = "IPv4 Address";Expression = {$_.IPv4Address}},
    @{Label = "IPv6 Address";Expression = {$_.IPv6Address}},
    @{Label = "Global Catalog";Expression = {$_.IsGlobalCatalog}},
    @{Label = "Read Only";Expression = {$_.IsReadOnly}},
    @{Label = "Operation Master Roles";Expression = {$_.OperationMasterRoles -join ', '}} |

    # Export Domain Controller Report
    Export-Excel -Path $ExportPathWithFileName -WorkSheetname DomainControllers -AutoSize -AutoFilter -BoldTopRow -FreezeTopRow 
}

# Export AD Forest Information
function Export-ADForests ()
{
    # Export all Forest data
    $ADForests = Get-ADForest -Server $domain -Credential $creds
    
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
    Export-Excel -Path $ExportPathWithFileName -WorkSheetname Forests -AutoSize -AutoFilter -BoldTopRow -FreezeTopRow 
}

# Export AD Organizational Unit Information
function Export-ADOUs ()
{
    #Export all Organizational Unit Information
    $ADOU = Get-ADOrganizationalUnit -Server $domain -Filter * -Credential $creds
    
    $ADOU |
    Select-Object @{Label = "Name";Expression = {$_.Name}},
    @{Label = "Distinguished Name";Expression = {$_.DistinguishedName}},
    @{Label = "Inheritance Blocked";Expression = {(Get-GPInheritance -Target $_ -Domain $domain -Server $domain -Credential $creds).GpoInheritanceBlocked}},
    # this linked GPO output doesn't seem to work correctly when run against a remote domain (i.e., the powershell user running the script is in a different domain than what was specified for the -Domain parameter)
    # I'm relatively certain it's just running the query within the current PS user's context, which of course returns no GPOs since the ID's don't exist in this context
    # I think it needs to be "LDAP://$domain/$gpo"
    @{Label = "Linked GPOs";Expression = {$(foreach($gpo in $_.LinkedGroupPolicyObjects){ ForEach-Object { -join ([adsi]"LDAP://$gpo").displayName}}) -join', '}} |

    # Export Organizational Unit Report 
    Export-Excel -Path $ExportPathWithFileName -WorkSheetname OrganizationalUnits -AutoSize -AutoFilter -BoldTopRow -FreezeTopRow -ConditionalText $(
        New-ConditionalText -Text "TRUE" -Range "C:C" -ConditionalTextColor Black -BackgroundColor Goldenrod
    )
}

# Email Report
function Send-Report ()
{
    # This is an ugly hack to convert the password string into secure credentials
    $pass = ConvertTo-SecureString -String $password -AsPlainText -Force

    # Store the full SMTP credentials in a single variable
    $creds = New-Object -TypeName "System.Management.Automation.PSCredential" -ArgumentList $email, $pass

    # Create and send the email message with attachment
    Send-MailMessage `
        -To $recipient `
        -Subject 'Active Directory Report' `
        -Body 'Please review the attached Active Directory Report.' `
        -UseSsl `
        -Port $smtpport `
        -SmtpServer $smtpserver `
        -From $email `
        -Credential $creds `
        -Attachments $ExportPathWithFileName
}

#endregion

#region
#################################################################
###
###  Main
###
#################################################################

# Define the export path to place the .xlsx report
# We're using the current root directory of this script, for simplicity.
$exportpath = $PSScriptRoot

# Builds the complete path of the exported report, including file name.
$ExportPathWithFileName = $exportpath + "\AD_Report_" + $domain + "-" + (Get-Date -format yyyy-MM-dd-HH-mm) + ".xlsx"
 
# The AD Module must be imported before AD-specific commands can be run
Import-Module ActiveDirectory
Import-Module ImportExcel

$pass = ConvertTo-SecureString -String $domainAdminPass -AsPlainText -Force
$creds = New-Object -TypeName "System.Management.Automation.PSCredential" -ArgumentList $domainAdminUser, $pass

# Run Functions
Export-ADUsers
Export-ADGroups
Export-ADComputers
Export-ADDomainControllers
Export-ADForests
Export-ADOUs

if ($sendEmail)
{
    Send-Report
}

#endregion