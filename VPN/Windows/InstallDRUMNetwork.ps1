# © 2018 Soverance Studios
# Scott McCutchen
# scott.mccutchen@soverance.com

# This script will silently install the Soverance VPN connection on Windows clients.
# It is run as a startup script applied via the "AutoVPN" group policy found in the UA domain.

# CMAK ROUTE TABLE INFO
# The METRIC option is *not* optional. Failure to include it will result in failed connections due to an 0x8007000B error (not documented).

# The basic approach that the routing table update facility uses assumes that
# the default gateway is set to the remote gateway. This allows the "default"
# keywords to have some usefulness. But, using the remote gateway as the
# default is often not desirable. So, REMOVE_GATEWAY allows the remote gateway
# to be reset to its local default once the routes have been established on the connection.

# change to the sysvol directory where this policy is stored
cd "\\contoso.com\SysVol\contoso.com\Policies\{19ADA050-46C6-4C41-BBC9-D334427D710A}\Machine\Scripts\Startup"

# See this TechNet article for more information about including Connection Manager in custom applications
# https://technet.microsoft.com/en-us/library/dd672647(v=ws.10).aspx

# silently install
./SoveranceVPN.exe /q:a /c:"cmstp.exe SOVERANCEVPN.inf /i"