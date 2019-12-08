# AutoCluster Deployment Tools
# Scott McCutchen
# DevOps Engineer
# scott.mccutchen@m3as.com

# This script will configure the WinRM HTTPS listener, using a specified certificate
# this certificate was manually generated and self-signed
# it is installed via Group Policy, in the same GPO that runs this script at startup

try {
    
    if (!(Get-EventLog -LogName Application -Source "WinRM GPO"))
    {
        New-EventLog -LogName Application -Source "WinRM GPO"
    }

    $duration = 5
    $dnsname = $env:COMPUTERNAME

    $cert = New-SelfSignedCertificate -Subject $dnsname -DnsName $dnsname -CertStoreLocation "cert:\LocalMachine\My" -KeyUsage KeyEncipherment,DataEncipherment,KeyAgreement -Type SSLServerAuthentication -KeyAlgorithm RSA -HashAlgorithm SHA256 -Provider "Microsoft Enhanced Cryptographic Provider v1.0" -KeyLength 2048 -KeyExportPolicy Exportable -NotAfter (Get-Date).AddYears($duration)

    New-Item WSMan:\localhost\listener -Transport HTTPS -Address * -CertificateThumbPrint $cert.Thumbprint -Force

    Write-EventLog -LogName Application -Source "WinRM GPO" -EntryType Information -EventID 0 -Message "WinRM HTTPS Listener now configured." 
}
catch {
    Write-EventLog -LogName Application -Source "WinRM GPO" -EntryType Information -EventID 1 -Message "ERROR in $($MyInvocation.MyCommand) on line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)"
}

