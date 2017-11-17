# © 2017 BKV LLC
# Scott McCutchen
# Systems Administrator
# scott.mccutchen@soverance.com

# Scan Active Directory for User accounts which have passwords that are about to expire and notify those users via email.

##########################
# PASSWORD POLICY DETAILS
##########################
# More information on customizing password policies can be found here:

# Create a new PSO:  https://technet.microsoft.com/en-us/library/cc754461(v=ws.10).aspx
# Apply a new PSO:  https://technet.microsoft.com/en-us/library/cc731589(v=ws.10).aspx
# PSO Appendix A:  https://technet.microsoft.com/en-us/library/cc754544(v=ws.10).aspx

# A Password Settings Container object must be applied to the user in order for the $verbose option in this script to work.
# if the attribute msDS-ResultantPSO is null for a user, their $verbose output will be empty.
# to view the msDS-ResultantPSO object for a user, you can use the command "Get-ADUserResultantPasswordPolicy -Identity $username"
# alternatively, open the advanced attribute editor in AD Users and Computers, and filter the results for "Constructed" attributes.

##########################
# SMTP DETAILS
##########################
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

# $verbose: Set it to $true if you would like to send the Password Policy settings to the end users. 
# If you not want to use this optional feature, you can set the value to $false.
$verbose = $false  
# $notificationstartday: Set the value of the default interval to start notifying the users about the expiry 
# (This is the delta between the current date and the expiry date)         
$notificationstartday = 14 

# Enter the domain name you wish to scan
$DN = "DC=soverance,DC=net"

# Enter valid SMTP information in order to email the report
# PLEASE SEE THE ABOVE NOTICE ABOUT GMAIL SMTP AUTHENTICATION.
# If you're unsure of the settings you should use here, DO NOT CHANGE THEM!
$sendermailaddress = "dataservice@soverance.com"
$password = "somepassword"
$SMTPserver = "smtp.gmail.com"
$smtpport = "587"

#################################################################
##
## MAKE NO CHANGES BEYOND THIS POINT!
##
#################################################################

$Logfile = "C:\Scripts\AD-PasswordExpiryNotification.log"

# check to see if the log file already exists - if not, create it
if (!(Test-Path $Logfile))
{
    New-Item -Force -Path $Logfile
}

# log writing function
Function LogWrite
{
   Param ([string]$logstring)

   Add-content $Logfile -value $logstring
}

# break a new line in the log for legibility
LogWrite ""

$time = Get-Date  # get date
$time = $time.ToUniversalTime()  # convert to readable time

# Prepare password policy for legibility in the notification mail
Function PreparePasswordPolicyMail ($ComplexityEnabled,$MaxPasswordAge,$MinPasswordAge,$MinPasswordLength,$PasswordHistoryCount)            
{            
    $verbosemailBody = "Below is a summary of the applied Password Policy settings:`r`n`r`n"            
    $verbosemailBody += "Complexity Enabled = " + $ComplexityEnabled + "`r`n`r`n"            
    $verbosemailBody += "Maximum Password Age = " + $MaxPasswordAge + " Days`r`n`r`n"            
    $verbosemailBody += "Minimum Password Age = " + $MinPasswordAge + " Day`r`n`r`n"            
    $verbosemailBody += "Minimum Password Length = " + $MinPasswordLength + " Characters`r`n`r`n"            
    $verbosemailBody += "Remembered Password History = " + $PasswordHistoryCount + "`r`n`r`n"            
    return $verbosemailBody             
}        


# Email Expiry Notification
function SendMail ($SMTPserver,$sendermailaddress,$usermailaddress,$mailBody)
{
    if ($usermailaddress)  # do not send mail if user is invalid or null
    {
        # This is an ugly hack to convert the password string into secure credentials
        $pass = ConvertTo-SecureString -String $password -AsPlainText -Force

        # Store the full SMTP credentials in a single variable
        $creds = New-Object -TypeName "System.Management.Automation.PSCredential" -ArgumentList $sendermailaddress, $pass

        # Create and send the email message with attachment
        Send-MailMessage `
            -To $usermailaddress `
            -Subject 'Soverance Studios - Password Expiry Notification' `
            -Body $mailBody   `
            -UseSsl `
            -Port $smtpport `
            -SmtpServer $SMTPserver `
            -From $sendermailaddress `
            -Credential $creds `

        LogWrite "$($time) : Sending email to :  $($usermailaddress)."
    }
}

#################################################################
##
## MAIN 
##
#################################################################

$domainPolicy = Get-ADDefaultDomainPasswordPolicy    # get and store the current password policy        
$passwordexpirydefaultdomainpolicy = $domainPolicy.MaxPasswordAge.Days -ne 0            
            
# Collect and store the default domain policy, in case no PSO was applied to the user
if($passwordexpirydefaultdomainpolicy)            
{            
    $defaultdomainpolicyMaxPasswordAge = $domainPolicy.MaxPasswordAge.Days  # set max password age        
    if($verbose)            
    {   # if verbose is true, prepare the password policy for readability
        $defaultdomainpolicyverbosemailBody = PreparePasswordPolicyMail $PSOpolicy.ComplexityEnabled $PSOpolicy.MaxPasswordAge.Days $PSOpolicy.MinPasswordAge.Days $PSOpolicy.MinPasswordLength $PSOpolicy.PasswordHistoryCount
    }            
}    

# scan the AD Domain for all users, choosing only users who have a valid mail property and whose passwords are set to expire
foreach ($user in (Get-ADUser -SearchBase $DN -Filter * -properties mail, PasswordNeverExpires | where { $_.passwordNeverExpires -ne "true" } | where {$_.enabled -eq "true"}))            
{   
    $samaccountname = $user.samaccountname  # store user account name
    $PSO= Get-ADUserResultantPasswordPolicy -Identity $samaccountname  # store ad user password policy
    # if resulting password policy is anything but null
    if ($PSO -ne $null)
    {                         
        $PSOpolicy = Get-ADUserResultantPasswordPolicy -Identity $samaccountname  # store ad user password policy
        $PSOMaxPasswordAge = $PSOpolicy.MaxPasswordAge.days  # store password age
        $pwdlastset = [datetime]::FromFileTime((Get-ADUser -LDAPFilter "(&(samaccountname=$samaccountname))" -properties pwdLastSet).pwdLastSet) # get password last set time
        $expirydate = ($pwdlastset).AddDays($PSOMaxPasswordAge) # get expiry date     
        $delta = ($expirydate - (Get-Date)).Days  # store the delta between today and the expiry date to find how many days are remaining
        LogWrite "$($time) : User: $($user.samaccountname) will expire in $($delta) days." 
        $comparionresults = (($expirydate - (Get-Date)).Days -le $notificationstartday) -AND ($delta -ge 1)  # store comparison results
        if ($comparionresults)  # if the results are valid            
        {            
            # CREATE EMAIL NOTIFICATION
            $mailBody = "Dear " + $user.GivenName + ",`r`n`r`n" # LINE ONE
            $mailBody += "Your password will expire after " + $delta + " days. You will need to change your password to continue using your account.`r`n`r`n"  # LINE TWO
            $mailBody += "Please ensure that your new password meets our complexity requirements.  You must use at least 8 characters, and you must include at least one capital letter, one lowercase letter, and one special character.`r`n`r`n"            
            $mailBody += "To change your password, Windows users can hit 'Ctrl + Alt + Del' and select the 'Change a password' option.`r`n`r`n" 
            $mailBody += "Mac OS X users can change their password by going to 'System Preferences -> Users & Groups', then selecting their account and hitting the 'Change Password' button.`r`n`r`n" 
            # if verbose was flagged, prepare password policy for insertion into body
            if ($verbose)            
            {            
                $mailBody += PreparePasswordPolicyMail $PSOpolicy.ComplexityEnabled $PSOpolicy.MaxPasswordAge.Days $PSOpolicy.MinPasswordAge.Days $PSOpolicy.MinPasswordLength $PSOpolicy.PasswordHistoryCount            
            }            
            $mailBody += "`r`n`r`nSoverance Studios IT Department"            
            $usermailaddress = $user.mail            
            SendMail $SMTPserver $sendermailaddress $usermailaddress $mailBody         
        }            
    }        
    # if the password policy was not defined, use the default policy    
    else            
    {
        if($passwordexpirydefaultdomainpolicy)            
        {            
            $pwdlastset = [datetime]::FromFileTime((Get-ADUser -LDAPFilter "(&(samaccountname=$samaccountname))" -properties pwdLastSet).pwdLastSet)            
            $expirydate = ($pwdlastset).AddDays($defaultdomainpolicyMaxPasswordAge)            
            $delta = ($expirydate - (Get-Date)).Days  
            LogWrite "$($time) : User: $($user.samaccountname) will expire in $($delta) days.  PASSWORD POLICY UNDEFINED!  Reverting to default domain policy."          
            $comparionresults = (($expirydate - (Get-Date)).Days -le $notificationstartday) -AND ($delta -ge 1)            
            if ($comparionresults)            
            {            
                $mailBody = "Dear " + $user.GivenName + ",`r`n`r`n"            
                $delta = ($expirydate - (Get-Date)).Days            
                $mailBody += "Your password will expire after " + $delta + " days. You will need to change your password to continue using your account.`r`n`r`n"  
                $mailBody += "Please ensure that your new password meets our complexity requirements.  You must use at least 8 characters, and you must include at least one capital letter, one lowercase letter, and one special character.`r`n`r`n"            
                $mailBody += "To change your password, Windows users can hit 'Ctrl + Alt + Del' and select the 'Change a password' option.`r`n`r`n" 
                $mailBody += "Mac OS X users can change their password by going to 'System Preferences -> Users & Groups', then selecting their account and hitting the 'Change Password' button.`r`n`r`n" 
                if ($verbose)            
                {            
                    $mailBody += $defaultdomainpolicyverbosemailBody            
                }            
                $mailBody += "`r`n`r`nSoverance Studios IT Department"            
                $usermailaddress = $user.mail            
                SendMail $SMTPserver $sendermailaddress $usermailaddress $mailBody           
            }              
        }            
    }            
}