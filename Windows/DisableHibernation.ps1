# Scott McCutchen
# info@soverance.com

# this script disables the hibernation file on a windows system, and is intended to run via Group Policy as a Startup script

try 
{
    $source = "SovGPO"

    if (!(Get-EventLog -LogName Application -Source $source))
    {
        New-EventLog -LogName Application -Source $source
    }

    powercfg.exe /h off

    if ($?)
    {
        Write-EventLog -LogName Application -Source $source -EntryType Information -EventId 0 -Message "Hibernation disabled via Soverance Group Policy."
    }
}
catch
{
    Write-EventLog -LogName Application -Source $source -EntryType Error -EventId 1 -Message "Hibernation could not be disabled :  $($_.Exception.Message)"
}

