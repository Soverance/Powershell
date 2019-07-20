# © 2018 Soverance Studios
# Scott McCutchen
# scott.mccutchen@soverance.com
#
# This script dumps a list of running processes from the specified computer, complete with CPU and Memory usage output

#################################################################
## EDITABLE VARIABLES BELOW
##
## Only make changes to these values here!
#################################################################

# Enter valid SMTP information in order to email the report
# PLEASE SEE THE ABOVE NOTICE ABOUT GMAIL SMTP AUTHENTICATION.
# If you're unsure of the settings you should use here, DO NOT CHANGE THEM!
$sendermailaddress = "info@soverance.com"
$usermailaddress = "scott.mccutchen@soverance.com"
$displayfromaddress = New-Object System.Net.Mail.MailAddress $sendermailaddress,'alert@soverance.com'
$password = "somepassword"
$SMTPserver = "smtp.gmail.com"
$smtpport = "587"

#################################################################
##
## MAKE NO CHANGES BEYOND THIS POINT!
##
#################################################################

# collect the number of CPU cores on the local machine so that we can estimate processor usage
$CpuCores = (Get-WMIObject Win32_ComputerSystem).NumberOfLogicalProcessors

# collect the total amount of RAM available on this system
$RAM= Get-WMIObject Win32_PhysicalMemory | Measure -Property capacity -Sum | %{$_.sum/1Mb}

# collect the current total CPU load
$TotalCpuLoad = Get-WmiObject win32_processor | select LoadPercentage  |fl

# Get all running processes

#configure the table
$properties=@(
    @{Name="Process Name"; Expression = {$_.Name}},
    @{Name="CPU (%)"; Expression = {[Math]::Round(((Get-Counter "\Process($($_.Name))\% Processor Time").CounterSamples.CookedValue) / $CpuCores,2)}},    
    @{Name="Memory (MB)"; Expression = {[Math]::Round(($_.workingSetPrivate / 1mb),2)}}
)

$processes = Get-WmiObject -class Win32_PerfFormattedData_PerfProc_Process | 
                Select-Object $properties |
                Format-Table -AutoSize
                
function SendMail ($SMTPserver,$sendermailaddress,$usermailaddress,$mailBody)
{
    if ($usermailaddress)  # do not send mail if user is invalid or null
    {
        # This is an ugly hack to convert the password string into secure credentials
        $pass = ConvertTo-SecureString -String $password -AsPlainText -Force

        # Store the full SMTP credentials in a single variable
        $creds = New-Object -TypeName "System.Management.Automation.PSCredential" -ArgumentList $sendermailaddress, $pass

        $mailBody += "A Performance Alert has been generated for " + $env:COMPUTERNAME + ".`r`n`r`n"
        $mailBody += "Processor Time (CPU Usage) has gone above 90 %. `r`n`r`n"
        $mailBody += $env:COMPUTERNAME + " has a total CPU Load of " + $TotalCpuLoad + " at the time this alert was generated.`r`n`r`n"
        $mailBody += $env:COMPUTERNAME + " has " + $CpuCores + " CPU Cores and " + $RAM + " GB of total available RAM.`r`n`r`n"
        $mailBody += "The following processes and their resource usage as recorded at the time of this alert are listed below: `r`n`r`n"            
        $mailBody += "`r`n`r`n"
        $mailBody += $processes

        # Create and send the email message with attachment
        Send-MailMessage `
            -To $usermailaddress `
            -Subject 'PERFORMANCE ALERT - CPU USAGE on ' $($env:COMPUTERNAME) `
            -Body $mailBody   `
            -UseSsl `
            -Port $smtpport `
            -SmtpServer $SMTPserver `
            -From $displayfromaddress `
            -Credential $creds `
    }
}