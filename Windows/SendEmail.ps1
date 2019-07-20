# © 2018 Soverance Studios
# Scott McCutchen
# soverance.com
# scott.mccutchen@soverance.com

# This script is a generic email test sent through Powershell

# Assuming the user was actually at the terminal, this script would be made better by simply calling Get-Credential
# Instead, converting to SecureString and creating a new PSCredential object allows us to modify this script to avoid the user credential prompt
# The params are really just here to make this script usable on it's own, but they are unnecessary if you modify the script to avoid a cred prompt

param(
    [string]$user = $(throw "-user is required. Please enter a valid email address."),
    [string]$password = $(throw "-password is required.")
)

#$user = 'info@soverance.com'
$pass = ConvertTo-SecureString -String $password -AsPlainText -Force

$creds = New-Object -TypeName "System.Management.Automation.PSCredential" -ArgumentList $user, $pass

Send-MailMessage `
    -To 'scott.mccutchen@soverance.com' `
    -Subject 'Powershell Email Test' `
    -Body 'On this page, you see a little girl giggling at a hippopotamus. I wonder why?' `
    -UseSsl `
    -Port 587 `
    -SmtpServer 'smtp.office365.com' `
    -From $user `
    -Credential $creds
    #-Attachments "Path To Attachment.xlsx"

if($?)
{
    Write-Host "SMTP Email sent successfully." -foregroundcolor black -backgroundcolor cyan
}
else
{
	Write-Host "SMTP Email failed!" -foregroundcolor white -backgroundcolor red
}