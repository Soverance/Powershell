# © 2018 Soverance Studios
# Scott McCutchen
# scott.mccutchen@soverance.com

# This script starts the Unreal cook server for consoles, and allows it to accept connections for debugging console games via Visual Studio
# In Visual Studio, be sure to set up the project Properties correctly

# FOR XBOX ONE:
# Set the remote IP address or hostname under "Configuration -> Durango -> General"
# Set command line arguments under "Debugging" to [MapName] -filehostip=192.168.0.1  (or whatever your local IP address is, as seen from the Xbox)

# FOR PLAYSTATION 4:
# Set Executable Arguments under "Debugging" to the following:
# [RelativePathToProject.uproject] [MapName] -filehostip=192.168.0.1
# e.g. ../../../MyProject/MyProject.uproject -filehostip=192.168.0.1 (or whatever the IP address of your PC is, as seen from the PS4)

# Run the script with the following options to run the file server for a specific platform
# example:  ./EtherealBuild.ps1 -platform Xbox
param (
	[string]$platform = $(throw "-platform is required. Only Xbox and PS4 are supported.")
)

function StartXbox ()
{
    # Run the cook server and prepare it to accept connections on the local host
	./UE4Editor-cmd.exe Ethereal -run=cook -targetplatform=XboxOne -cookonthefly
}

function StartPS4 ()
{
    # Run the cook server and prepare it to accept connections on the local host
	./UE4Editor-cmd.exe U:\UnrealEngine\Ethereal\Ethereal.uproject Ethereal -run=cook -targetplatform=PS4 -cookonthefly
}

function StartServer ()
{
    # Navigate to the local path where the Unreal tools are located
	Set-Location U:/UnrealEngine/Engine/Binaries/Win64

    # Handle Xbox Platform Build
	if ($platform -eq "Xbox")
	{
		# Build For Xbox Platform
		StartXbox
	}
		
	# Handle PS4 Platform Build
	if ($platform -eq "PS4")
	{
		# Build For PS4 Platform
		StartPS4
	}	
}

StartServer