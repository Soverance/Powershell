# © 2018 Soverance Studios
# Scott McCutchen
# soverance.com
# scott.mccutchen@soverance.com

# Export the specified Event Viewer report to an Excel .xlsx file

#################################################################
## EDITABLE VARIABLES BELOW
##
## Only make changes to these values here!
#################################################################

$ComputerName = "host.contoso.com"  # server you wish to pull logs from
$LogName = "Application","Security","System"  # logs you wish to scan for specified events
$EventID = 4659  # comma delimited list of event IDs you wish to report

# Enter the file name prefix of the report you wish to create - use your company or AD forest name
$filenameprefix = "DRUM"

# Enter valid SMTP information in order to email the report
# PLEASE SEE THE ABOVE NOTICE ABOUT GMAIL SMTP AUTHENTICATION.
# If you're unsure of the settings you should use here, DO NOT CHANGE THEM!
$user = "someemailaccount@gmail.com"
$password = "somepassword"
$smtpserver = "smtp.gmail.com"
$smtpport = "587"

# Enter the "Send To" email address (who receives the report)
$recipient = "support@contoso.com"

#################################################################
##
## MAKE NO CHANGES BEYOND THIS POINT!
##
#################################################################

# Define the export path to place the .xlsx report
# We're using the current root directory of this script, for simplicity.
$exportpath = $PSScriptRoot

# Builds the complete path of the exported report, including file name.
$ExportPathWithFileName = $exportpath + "\" + $filenameprefix + "_File_Audit_Report_" + (Get-Date -format yyyy-MM-dd) + ".xlsx"

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
        -Subject 'File Audit Report' `
        -Body 'You will find the File Audit Report attached below.' `
        -UseSsl `
        -Port $smtpport `
        -SmtpServer $smtpserver `
        -From $user `
        -Credential $creds `
        -Attachments $ExportPathWithFileName
}

function ExportEvent
{
	process
	{
		#check whether path is correct
		try
		{
			$TempPath=Split-Path $ExportPathWithFileName
			if (-not (Test-Path $TempPath))
			{
				New-Item -ItemType directory -Path $TempPath -ErrorAction Stop  |Out-Null
			}
		}
		catch
		{
			Write-Error -Message "Could not create path '$ExportPathWithFileName'. Please make sure you have correct permissions and the file format is correct."
			return
		}
		#export a certain eventlog with specified log name and event ID for last 24 hours. 
        $events = Get-WinEvent -LogName $LogName -ComputerName $ComputerName -MaxEvents 1000 -EA SilentlyContinue | Where-Object {$_.id -in $EventID -and $_.Timecreated -gt (Get-date).AddHours(-24)} | Select-Object Message,Id,LogName,MachineName,UserId,TimeCreated,TaskDisplayName | Sort TimeCreated -Descending

        #$events.Message

        foreach ($event in $events)
        {
            Write-Host "This is a new event" -foregroundcolor black -backgroundcolor cyan
            $xmlitem = [xml]$event.ToXml()
            #Get EventID
            $xmlitem.Event.System.EventID
            #Get logging computer
            $xmlitem.Event.System.Computer
            #Get computer
            $xmlitem.Event.EventData.Data | where-object {$_.Name -eq "SubjectUserName"}
            #Get account
            $xmlitem.Event.EventData.Data | where-object {$_.Name -eq "TargetUserName"}
            #Get logon type
            $xmlitem.Event.EventData.Data | where-object {$_.Name -eq "LogonType"}
            #Get ip address
            $xmlitem.Event.EventData.Data | where-object {$_.Name -eq "IpAddress"}
            #Get all data
            $xmlitem.Event.EventData.Data
        }

        #| Export-Excel -Path $ExportPathWithFileName -WorkSheetname WinEvents
	} 
}

ExportEvent
#EmailReport