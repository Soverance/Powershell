# © 2019 Soverance Studios
# Scott McCutchen
# scott.mccutchen@soverance.com
#
# This module allows for the sending of email notifications using a service account.

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

# Enter valid SMTP information in order to email the report
# PLEASE SEE THE ABOVE NOTICE ABOUT GMAIL SMTP AUTHENTICATION.
$sendermailaddress = "support@soverance.net"
$displayfromaddress = New-Object System.Net.Mail.MailAddress $sendermailaddress,'support@soverance.net'
$password = "xxxxxxxx"
$SMTPserver = "smtp.office365.com"
$smtpport = "587"

function SendMail ()
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string[]]$Recipient,

		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string]$Subject,

        [Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string]$MailBody
	)
	process {
		try {
            if ($Recipient)
			{
				# store credentials
				$pass = ConvertTo-SecureString -String $password -AsPlainText -Force
				$creds = New-Object -TypeName "System.Management.Automation.PSCredential" -ArgumentList $sendermailaddress, $pass

				# Create and send the email message with attachment
				Send-MailMessage `
					-To $Recipient `
					-Subject $Subject `
					-Body $MailBody   `
					-UseSsl `
					-Port $smtpport `
					-SmtpServer $SMTPserver `
					-From $displayfromaddress `
					-Credential $creds `
			}
		}
		catch {
			Write-Error $_.Exception.Message
		}
	}
}