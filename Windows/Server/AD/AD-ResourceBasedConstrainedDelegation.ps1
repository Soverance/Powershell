# © 2018 Soverance Studios
# Scott McCutchen
# scott.mccutchen@soverance.com

# This file is used for configuring Resource-based Constrained Delegation for Microsoft Project Honolulu

# A good primer on resource-based constrained delegation can be found here:
# https://blogs.technet.microsoft.com/ashleymcglone/2016/08/30/powershell-remoting-kerberos-double-hop-solved-securely/
# also here:
# http://www.itprotoday.com/security/how-windows-server-2012-eases-pain-kerberos-constrained-delegation-part-1

# This code must be run on a Server 2012 or higher domain controller

# specify gateway machine  where Project Honolulu is installed
$gateway = "SOV-ADConnect"

# specify the node you wish to authenticate against when accessing Project Honolulu - in most cases, it's the primary domain controller
$node = "SOV-PDC"

# Collect the gateway computer object
$gatewayObject = Get-ADComputer -Identity $gateway

# Collect the authentication node computer object
$nodeObject = Get-ADComputer -Identity $node

# Configure the authentication node to allow the gateway object to delegate authentication
Set-ADComputer -Identity $nodeObject -PrincipalsAllowedToDelegateToAccount $gatewayObject