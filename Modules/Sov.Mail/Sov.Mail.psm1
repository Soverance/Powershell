# © 2019 Soverance Studios
# Scott McCutchen
# scott.mccutchen@soverance.com

# This module allows for the sending of email notifications using a remote SMTP server

##############################################
###
###  SMTP Configuration Notes
###
##############################################

######### Gmail

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

########## Office 365

## STANDARD AUTH METHOD
## this method is the typical smtp method, where a user logs into their own mailbox and sends mail
## it does not support MFA enabled accounts
#$SenderAddress = "support@soverance.net"
#$SMTPpassword = "xxxxxxxx"
#$SMTPserver = "smtp.office365.com"
#$SMTPport = "587"

# SMTP RELAY CONNECTOR METHOD
# this method is the better method, but has caveats
# It requires TLS communication, and therefore requires a valid SSL certificate with which to communicate with O365
# The certificate cannot be self-signed or signed by an internal CA; it must be signed by a public authority
# The $SmtpServer is whatever O365 added as your domain's MX record
# The Send As user account must exist, but does not require a dedicated mailbox
#$SmtpServer = "soverance-com.mail.protection.outlook.com"
#$SmtpPort = "25"

function Send-Mail ()
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory=$True)]
		[ValidateNotNullOrEmpty()]
		[string]$SmtpUser,  # the email address (user account) used for the SMTP server authentication

		# [Parameter(Mandatory=$False)]
		# [ValidateNotNullOrEmpty()]
		# [string]$DisplayAddress,  # the email address you'd rather show instead of the actual sender's address

		[Parameter(Mandatory=$True)]
		[ValidateNotNullOrEmpty()]
		[string]$SmtpServer,

		[Parameter(Mandatory=$False)]
		[ValidateNotNullOrEmpty()]
		[string]$SmtpPassword,

		[Parameter(Mandatory=$True)]
		[ValidateNotNullOrEmpty()]
		[string]$SmtpPort,

		[Parameter(Mandatory=$True)]
		[ValidateNotNullOrEmpty()]
		[string[]]$Recipient,  # an array of recipients, comma delimited

		[Parameter(Mandatory=$True)]
		[ValidateNotNullOrEmpty()]
		[string]$Subject,  # subject line of email

        [Parameter(Mandatory=$True)]
		[ValidateNotNullOrEmpty()]
		$Body,  # HTML email body - i don't know how to strongly type this var

		[Parameter(Mandatory=$False)]
		[switch]$Anonymous,  # whether or not the smtp connection should be established with anonymous authentication

        [Parameter(Mandatory=$False)]
		[switch]$UseSSL,  # whether or not the smtp connection should be established with ssl encryption

        [Parameter(Mandatory=$False)]
		[ValidateNotNullOrEmpty()]
		[string]$pfxFile,

        [Parameter(Mandatory=$False)]
		[string]$pfxPass
	)
	process 
	{
		try 
		{
			# ensure valid recipients (should always be true, as it's validated in the param)
            if ($Recipient)
			{
				if ($Anonymous)
				{
					$pass = ConvertTo-SecureString -String "anonymous" -AsPlainText -Force
					$creds = New-Object -TypeName "System.Management.Automation.PSCredential" -ArgumentList "anonymous", $pass
				}
				else
				{
					$pass = ConvertTo-SecureString -String $SmtpPassword -AsPlainText -Force
					$creds = New-Object -TypeName "System.Management.Automation.PSCredential" -ArgumentList $SmtpUser, $pass
				}

				# $displayfromaddress = ""

				# # configure the display address, if it was provided
				# if ($DisplayAddress)
				# {
				# 	$displayfromaddress = New-Object System.Net.Mail.MailAddress $SenderAddress,$DisplayAddress
				# }
				# else
				# {
				# 	$displayfromaddress = $SenderAddress
				# }

                # Create and send the email message with attachment
                if ($UseSSL)
                {
                    # force TLS communication
                    [System.Net.ServicePointManager]::SecurityProtocol = 'Tls,TLS11,TLS12'

                    # # specify internal SSL certificate (used for O365 smtp relays)
                    # $pfxBytes = Get-Content -Path $pfxFile -Encoding Byte -ErrorAction:SilentlyContinue
                    # $X509Cert = New-Object -TypeName System.Security.Cryptography.X509Certificates.X509Certificate2
                    # $X509Cert.Import([byte[]]$pfxBytes, $pfxPass, "Exportable,PersistKeySet")

                    # $smtp = New-Object Net.Mail.SmtpClient($SmtpServer,$SmtpPort)
                    # $smtp.ClientCertificates.Add($X509Cert)
                    # $smtp.EnableSsl = $UseSSL

                    # $emailMessage = New-Object System.Net.Mail.MailMessage
                    # $emailMessage.From = $SmtpUser
                    # $emailMessage.To.Add($Recipient)
                    # $emailMessage.Subject = $Subject
                    # $emailMessage.Body = $Body

                    # $smtp.Send($emailMessage)

                    Send-MailMessage `
					   -To $Recipient `
					   -Subject $Subject `
					   -BodyAsHtml `
					   -Body ($Body | Out-String)  `
					   -UseSsl `
					   -Port $SmtpPort `
					   -SmtpServer $SmtpServer `
					   -From $SmtpUser `
					   -Credential $creds `
                }
                else
                {
                    Send-MailMessage `
					    -To $Recipient `
					    -Subject $Subject `
					    -BodyAsHtml `
					    -Body ($Body | Out-String)  `
					    -Port $SmtpPort `
					    -SmtpServer $SmtpServer `
					    -From $SmtpUser `
					    -Credential $creds `
                }
			}
		}
		catch 
        {
			Write-Output "ERROR in $($MyInvocation.MyCommand) on line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)"
    		exit 1
		}
	}
}