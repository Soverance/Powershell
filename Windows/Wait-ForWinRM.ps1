
function Wait-ForWinRM()
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$True)]
        [PSObject]$Node, 
        
        [Parameter(Mandatory=$True)]
        [Int]$Timeout
    )

    $mgmtResult = $False    
    $endResult = $False
    $checkDelay = 1

    $timer = [Diagnostics.Stopwatch]::StartNew()

    while($endResult -eq $False)
    {
        Write-Output "Waiting for WinRM on $($Node.Hostname) to become available..."

        if (Test-WSMan -ComputerName $Node.FQDN)
        {
            Write-Host "Successful WinRM connection to $($Node.Hostname)."
            $mgmtResult = $True
            $endResult = $True
            #break
        }
        if ($timer.Elapsed.TotalSeconds -ge $Timeout)
        {
            Write-Host "ERROR:  Connection timeout exceeded. Giving up waiting for WinRM."
            $endResult = $True
        }
        
        Start-Sleep -Seconds $checkDelay
    }

    $timer.Stop()
    
    if ($mgmtResult -eq $True)
    {
        return $True
    }
    else
    {
        return $False
    }
}



$ServerInfo = New-Object -TypeName PSObject
$ServerInfo | Add-Member -MemberType NoteProperty -Name Hostname -Value "metcubtwnsit002"
$ServerInfo | Add-Member -MemberType NoteProperty -Name IPAddress -Value "192.168.61.124"
$ServerInfo | Add-Member -MemberType NoteProperty -Name FQDN -Value "metcubtwnsit002.lab.local"

$DomainUser = "sisense.install"
$DomainPass = "Support1"
$Timeout = 600

$Result = Wait-ForWinRM -Node $ServerInfo -DomainUser $DomainUser -DomainPass $DomainPass -Timeout $Timeout

if ($Result -eq $True)
{
    Write-Output "Connection Successful!"
}
else {
    Write-Output "Connection FAILED!"
}

