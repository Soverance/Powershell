# Scott McCutchen
# scott.mccutchen@soverance.com

function Install-Azure-VPN-CLIENT-Certificate()
{
    $CertificateRemotePath = "\\some.network.address\Deployed Software\Deployed Software\Soverance-VPN-CLIENT.pfx"  # get the certificate
    # Import the VPN client certificate
    # this password was defined when the client certificate was exported from the server UA-PDC
    # The NoRoot option must be specified to suppress user interaction
    # If all our machines were on Windows 10, we'd use the Import-PfxCertificate cmdlet instead of certutil
    certutil -f -user -p "SomePassword" -importpfx $CertificateRemotePath NoRoot
}

function Install-Azure-VPN-CLIENT()
{
    $InstallerRemotePath = "\\some.network.address\Deployed Software\Deployed Software\Soverance-VPN-CLIENT.exe" # get remote application
    $InstallerLocalPath = "C:\AzureVPN\Soverance-VPN-CLIENT.exe"  # define local path
    # /Q - install in quiet mode to suppress user interaction
    # /T - specify a directory for temp files
    # /C - force extraction to temp dir
    $Switches = "/Q /T:C:\AzureVPN\ /C"  # define switches
    New-Item "C:\AzureVPN\" -Type Directory -Force  # force creation of this directory if it does not yet exist
    Copy-Item $InstallerRemotePath -Destination "C:\AzureVPN\" -Force  # copy the Azure VPN executable from the remote server to the local machine
    # this install unfortunately doesn't seem to work silently with the above params... it does extract the required files to the specified temp dir, but never sets up the connection
    # if the user could be prompted, we could simply remove the switch arguments and this would successfully complete the connection installation
    $Installer = Start-Process -FilePath $InstallerLocalPath -ArgumentList $Switches -Wait -PassThru  # install the Azure VPN Client software
}

function Create-Azure-VPN-Connection()
{
    ##############################
    # THIS FUNCTION IS INCOMPLETE, AND THEREFORE IS INOPERABLE ON OPERATING SYSTEMS OLDER THAN WINDOWS 10
    # DO NOT CALL!
    #############################

    # store the ID of your azure vpn gateway
    $AzureGateway = "azuregateway-755d8db8-0000-0000-0000-6be59c0533ee-179c72f598c2.cloudapp.net"

    # GOD DAMMIT!  BOTH New-EapConfiguration AND Add-VPNConnection are specific to Powershell v4.0 or later... which isn't on Win7 by default.  FUCK!

    # additonal params specify that the eap configuration:
    # - uses EAP-TLS security
    # - verifies the identity of the server to which the client connects is validated
    # - ensures EAP-TLS authentication method uses a user certificate
    $EapConfig = New-EapConfiguration -Tls -VerifyServerIdentity -UserCertificate

    # configure vpn connection with eap auth method.
    # additional params specify that the connection:
    # - Uses split tunneling (-SplitTunneling, ensures only corporate traffic returns over this connection)
    # - Is stored in the global phone book (-AllUserConnection, allows all users to access this connection)
    # - Caches the credentials used for the first successful connection (-RememberCredential)
    Add-VpnConnection -Name "Soverance VPN" -ServerAddress $AzureGateway -TunnelType L2tp -EncryptionLevel Required `
    -AuthenticationMethod Eap -SplitTunneling -AllUserConnection -RememberCredential -EapConfigXmlStream $EapConfig.EapConfigXmlStream -PassThru
}

Install-Azure-VPN-CLIENT-Certificate
Install-Azure-VPN-CLIENT
Create-Azure-VPN-Connection
