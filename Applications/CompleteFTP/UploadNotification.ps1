# © 2020 Soverance Studios, LLC
# Scott McCutchen
# DevOps Engineer
# scott.mccutchen@soverance.com

# This script will send an email notification to a user whenever someone uploads a file to the monitored directory

# This script is intended to run as part of a "Process Trigger" event within CompleteFTP
# The event uses the following configuration:

# Events:  Upload File
# Errors:  Trigger on success
# Folder Filter:  /Files/Folder*  (where "Folder" is the name of the client folder you wish to monitor)
# User Filter:  All Users
# Type:  Powershell Script

#########################################################################################################################
# You must copy and paste the script below this line into the "Script" section of the Process Trigger within CompleteFTP.
#########################################################################################################################

$user = "smtpuser@soverance.com"
$password = "somepassword"
$smtpserver = "smtp.gmail.com"
$smtpport = "587"
$displayfromaddress = New-Object System.Net.Mail.MailAddress $user,'dataservices@soverance.com'

$uncpath = "\\SOV-FTP%VirtualFolder%"
$uncpath = $uncpath -replace "/", "\"

$mailBody = "A new file was uploaded to Soverance Secure FTP Service<br><br>"
$mailBody += "<b>FOLDER:</b>  $uncpath<br>"
$mailBody += "<b>FILE:</b>  %FileName%<br>"
$mailBody += "<b>USER:</b>  %LoginUserName%<br>"
$mailBody += "<b>TIME:</b>  %Time%<br>"
#$mailBody += "<b>TYPE:</b>  %Type%<br>"
#$mailBody += "<b>STATUS:</b>  %TransferStatus%<br>"
$mailBody += "<b>IP ADDRESS:</b>  %ClientIP%<br><br>"
$mailBody += "For quick access to this file on your desktop, copy and paste the FOLDER path into the address bar of a new Windows Explorer session.<br>"

$recipient = "dataservices@soverance.com"

$pass = ConvertTo-SecureString -String $password -AsPlainText -Force

$creds = New-Object -TypeName "System.Management.Automation.PSCredential" -ArgumentList $user, $pass

Send-MailMessage `
        -To $recipient `
        -Subject 'Soverance FTP Notification Service' `
        -BodyAsHtml $mailBody `
        -UseSsl `
        -Port $smtpport `
        -SmtpServer $smtpserver `
        -From $displayfromaddress `
        -Credential $creds