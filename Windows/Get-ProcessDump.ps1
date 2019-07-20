# © 2018 Soverance Studios
# Scott McCutchen
# scott.mccutchen@soverance.com
#
# This script dumps a list of running processes from the specified computer, complete with CPU and Memory usage output

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

Get-WmiObject -class Win32_PerfFormattedData_PerfProc_Process | 
    Select-Object $properties |
    Format-Table -AutoSize