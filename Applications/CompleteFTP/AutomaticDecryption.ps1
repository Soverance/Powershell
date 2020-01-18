# © 2020 Soverance Studios, LLC
# Scott McCutchen
# DevOps Engineer
# scott.mccutchen@soverance.com

# This script will decrypt the files uploaded to a specific vendor directory
# modify the file paths as necessary to support other clients/vendors

# This script is intended to run as part of a "Process Trigger" event within CompleteFTP

# add the custom module path in order to access the custom PS modules
$env:PSModulePath = $env:PSModulePath + ";C:\Scripts\PowerShell\Modules"
Import-Module SoverancePgp
Import-Module SoveranceMail

try
{
    $EmailAddress = "dataservices@soverance.com"
    $VendorDir = "L:\data\Lendly\Vendors\Predictive Analytics Group\"
    $OutboundWorking = "L:\data\Lendly\Automation\"
    $OutboundArchive = "L:\data\Lendly\Automation\Archive\"
    $Outbound = "\\AzureDataServer\Data\Global\External\PAG\Processing\"

    # create the outbound dir, if it doesn't already exist
    if (!(Test-Path $Outbound))
    {
        New-Item -Force -Path $Outbound -ItemType "directory"
    }

    $inboundFiles = Get-ChildItem -Path $VendorDir
    $inboundFileCount = ($inboundFiles | Measure-Object).Count

    if ($inboundFileCount -gt 0)
    {
        # copy all files from Inbound directory to OutboundWorking directory
        foreach ($file in $inboundFiles)
        {
            $OutboundDestination = $OutboundWorking + $file.Name
            Copy-Item -Path $file.FullName -Destination $OutboundDestination -Force
        }
    }

    # we wait a few seconds here to make sure the copy process has finalized
    Start-Sleep -s 15

    $username = "someuser"
    $password = "somepassword"
    $securePassword = ConvertTo-SecureString $password -AsPlainText -Force
    $credential = New-Object System.Management.Automation.PSCredential $username, $securePassword

    # Because this script is called by CompleteFTP, it is therefore run as the built-in SYSTEM account
    # the built-in SYSTEM account has no access to the PGP keyring, which is always specific to an actual user account 
    # therefore we must run the decryption process within the scope of an actual user account... and we do so by creating a new PS Session on the FTP server
    $s = New-PSSession -ComputerName "SOV-FTP" -Credential $credential
    
    Invoke-Command -Session $s -ScriptBlock {$env:PSModulePath = $env:PSModulePath + ";C:\Scripts\PowerShell\Modules"
        Import-Module DrumPgp
        Remove-ClientEncryption -FolderPath $OutboundWorking # NOTE:  you must specify this -FolderPath as an actual string... don't specify it as a variable, since the Remove-ClientEncryption function won't validate variables.
    }   

    # wait a few seconds for encryption process to finalize.  
    Start-Sleep -s 15

    # close the session to free up system resources
    Remove-PSSession -Session $s

    # removes/deletes all the encrypted files from the vendor's inbound directory
    Get-ChildItem -Path $VendorDir -Include ("*.pgp", "*.gpg") -Recurse | foreach {Remove-Item -Path $_.FullName}
    # copy the decrypted items from the working directory and into their final destination directory
    Get-ChildItem -Path $OutboundWorking -Exclude ("*.pgp", "*.gpg", "Archive") -Recurse | foreach {Copy-Item -Path $_.FullName -Destination $($Outbound + $_.Name)}
    # Finally, move the encrypted items into the automation archive, in case they're ever needed again
    Get-ChildItem -Path $OutboundWorking -Include ("*.pgp", "*.gpg") -Exclude ("Archive") -Recurse | foreach {Move-Item -Path $_.FullName -Destination $($OutboundArchive + $_.Name)}
    # finally, delete all the decrypted items from working directory
    Get-ChildItem -Path $OutboundWorking -Exclude ("README.txt", "*.pgp", "*.gpg", "Archive") -Recurse | foreach {Remove-Item -Path $_.FullName}
    
    # Send an email notification about the process
    $mailBody = "A new file was uploaded to Soverance Secure FTP Service<br><br>"
    $mailBody += "Decrypted files can be retrieved at $($Outbound)"
    SendMail -Recipient $EmailAddress -Subject "Soverance Data Event: A decryption process has succeeded" -MailBody $mailBody -IsHtml

}
catch
{
    $mailBody = "Error: $($_.Exception)<br><br>"  
    $mailBody += "Line Number: $($_.Exception.InvocationInfo.ScriptLineNumber)<br><br>"  
    $mailBody += "Message: $($_.Exception.Message)<br>"    
    SendMail -Recipient $EmailAddress -Subject "Soverance Data Event: An error occured with the Lendly Decryption automation process" -MailBody $mailBody -IsHtml
    exit 1
}
