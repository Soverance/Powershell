# Dell EMC Fan Speed Controller
# Scott McCutchen
# DevOps Engineer
# scott.mccutchen@soverance.com

# This script is dependent on the Dell EMC OpenManage BMC Utility, v9.1.0 or later
# Download here:  https://www.dell.com/support/home/us/en/04/drivers/driversdetails?driverid=9ngfj&lwp=rt

# Fans on these boards are controlled in two zones:
# CPU or System fans, labelled with a number (e.g., FAN1, FAN2, etc.) - zone 0
# Peripheral zone fans, labelled with a letter (e.g., FANA, FANB, etc.) - zone 1

# On these boards there are 4 levels of speed control:
# Standard: BMC control of both fan zones, with CPU zone based on CPU temp (target speed 50%) and Peripheral zone based on PCH temp (target speed 50%)
# Optimal: BMC control of the CPU zone (target speed 30%), with Peripheral zone fixed at low speed (fixed ~30%)
# Full: all fans running at 100%
# Heavy IO: BMC control of CPU zone (target speed 50%), Peripheral zone fixed at 75%

# You can read the fan speed mode using the command:

# Code:
# ipmitool raw 0x30 0x45 0x00

# The values are:
# Standard: 0
# Full: 1
# Optimal: 2
# Heavy IO: 4
# I have no idea why they skipped "3"...

# You can also set the PWM duty cycle for each of the fan zones. PWM values are set 64 steps using hex values from 00-FF (ox00 to 0x64). 0x00 is minimum speed, 0x64 is full speed, and 0x32 is 50%, etc. Each "zone" is set seperately using the following command:

# ipmitool raw 0x30 0x70 0x66 0x01 0x<z> 0x<n>
# - where "z" is the zone (0 0r 1)
# - where "n" is the duty cycle (0x00..0x64)

# Example: Set CPU zone (0) to 50%:
# Code:
# ipmitool raw 0x30 0x70 0x66 0x01 0x00 0x32
# Example: Set Perpipheral zone (1) to 25%:
# Code:
# ipmitool raw 0x30 0x70 0x66 0x01 0x01 0x16

# estimated optimal temperature conditions for the average CPU are as follows:
# CPU Idle - under 35ºC ideal, 35-45ºC good enough, 45-50ºC No good, more than 50ºC disaster
# CPU 50%  - under 50ºC ideal, 50-65ºC good enough, 65-75ºC No good, more than 75ºC disaster
# CPU 100%  - under 60ºC ideal, 60-80ºC good enough, 80-85ºC No good, more than 85ºC disaster

param 
(
    [Parameter(Mandatory=$True)]
    [string]$iDRACAddress,

    [Parameter(Mandatory=$True)]
    [string]$iDRACadmin,

    [Parameter(Mandatory=$True)]
    [string]$iDRACadminPass,

    [Parameter(Mandatory=$True)]
    [string]$AverageTempThreshold,

    [Parameter(Mandatory=$True)]
    [string]$CriticalTempThreshold
)

try
{
    $InletSensorName ="04h"
    $CpuSensorName ="0Eh"
    $ipmiExe = "C:\Program Files (x86)\Dell\SysMgt\bmc\ipmitool.exe"
    $ipmiParams = @("-I", "lanplus", "-H", $iDRACAddress, "-U", $iDRACadmin, "-P", $iDRACadminPass)

    $ipmiGet = @("sdr", "type", "temperature")

    $ipmiSet = @("raw", "0x30", "0x30")
    $ipmiSetManual = @("0x01", "0x00")
    $ipmiSet20 = @("0x02", "0xff", "0x14");  # 20% seems to maintain about 12 CFM @ 3700 RPM through my Dell R230, and seems to hold idle CPU temp around 44ºC (fan noise at this level is nearly unnoticeable, quite comfortable for working in the same room)
    $ipmiSet25 = @("0x02", "0xff", "0x19");  # 25% seems to maintain about 14 CFM through my Dell R230, and seems to hold idle CPU temp around 41ºC (when stored with ambient intake temperature of about 23ºC / 72ºF)
    $ipmiSet30 = @("0x02", "0xff", "0x1e"); # 30%
    $ipmiSet35 = @("0x02", "0xff", "0x23"); # 35%
    $ipmiSet38 = @("0x02", "0xff", "0x26"); # 38%
    $ipmiSetMid = @("0x02", "0xff", "0x32"); # 50% seems to maintain about 25 CFM @ 9600 RPM through my Dell R230, and seems to hold idle CPU temp around 36ºC (fan noise at this level is loud enough to be distracting)
    $ipmiSetMax = @("0x02", "0xff", "0x64"); # 100%

    Write-Output "Average Temperature threshold set to $($AverageTempThreshold) degrees."
    Write-Output "Critical Temperature threshold set to $($CriticalTempThreshold) degrees."
    Write-Output "Checking server temperature..."

    # get the current server temperature, as reported by the iDRAC sensors
    $val = & $ipmiExe $ipmiParams $ipmiGet
    # I'll have to look at this more, but for now we can just split up the returned output based on which line has the relevant sensor
    # CPU Sensor
    $cpuval =  $val | Select-String $CpuSensorName
    $cpuval = "" + $cpuval #tostring
    $cpuval = $cpuval.Split('|')[4]
    $cpuval = $cpuval.Trim().Split(' ')[0]
    # Inlet Sensor
    $inletval =  $val | Select-String $InletSensorName
    $inletval = "" + $inletval #tostring
    $inletval = $inletval.Split('|')[4]
    $inletval = $inletval.Trim().Split(' ')[0]
    Write-Output "Inlet Sensor current temp: $($inletval)ºC"
    Write-Output "CPU Sensor current temp: $($cpuval)ºC"

    # activate manual fan control
    & $ipmiExe $ipmiParams $ipmiSet $ipmiSetManual

    # evaluate current temperature and adjust accordingly
    if ($cpuval -ge $CriticalTempThreshold)
    {
        "Temperature critical -> increasing RPM setting to MAX @ 100%";
        & $ipmiExe $ipmiParams $ipmiSet $ipmiSetMax
    }    
    if ($cpuval -gt $AverageTempThreshold -and $cpuval -lt $CriticalTempThreshold)
    {
        "Temperature too high -> increasing RPM setting to MID @ 50%";
        & $ipmiExe $ipmiParams $ipmiSet $ipmiSetMid
    }
    if ($cpuval -le $AverageTempThreshold)
    {
        "Temperature OK -> using LOW RPM setting @ 20%"
        & $ipmiExe $ipmiParams $ipmiSet $ipmiSet20
    }
}
catch
{
    Write-Output "ERROR in $($MyInvocation.MyCommand) on line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)"
    exit 1
}
