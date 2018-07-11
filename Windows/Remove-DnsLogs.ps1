# © 2018 Soverance Studios
# Scott McCutchen
# scott.mccutchen@soverance.com
#
# Removes all log files older than 90 days.
# We're using this as a scheduled task to keep disk space available on our DNS servers.

$Logfile = "C:\Scripts\DnsLogFileRemoval.log"

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
LogWrite "$($time) : =====  START DNS LOG REMOVAL  ====="

$path = "C:\Windows\System32\dns"

# collect all log files in the directory
$logfiles = Get-ChildItem -Path $path -Filter *.log -Recurse -File | Where-Object LastWriteTime -le (Get-Date).AddDays(-90)

# if there are no log files...
if ($logfiles.Length -le 0)
{
    LogWrite "$($time) : No DNS logs older than 90 days were found."
}

# if there is at least one log file...
if ($logfiles.Length -ge 1)
{
    foreach ($log in $logfiles)
    {
        LogWrite "$($time) : A DNS log file was deleted.  FILENAME:  $($log.Name)"  # log it
        Remove-Item -Path $log.FullName -Force  # delete it
    }
}

LogWrite "$($time) : =====  END DNS LOG REMOVAL  ====="
LogWrite ""
