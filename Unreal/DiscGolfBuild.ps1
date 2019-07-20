# © 2018 Soverance Studios
# Scott McCutchen
# scott.mccutchen@soverance.com
#
# Automate the build packaging of Ethereal Legends.
#
# Builds for the following platforms:
#
# Steam (Windows 64 bit only)
#
# Disc Golf VR

# Run the script with the following options to build for a specific platform
# example:  ./DiscGolfBuild.ps1 -platform Steam
param (
	[string]$platform = $(throw "-platform is required. Only Rift is currently supported.")
)

# Build Functions

# Windows 64-bit OnlineSubsystem = Steam
function BuildRift ()
{
	# Navigate to the local path where the Unreal automation tool is located
	cd U:/UnrealEngine/Engine/Build/BatchFiles

	# Once there, run the cook and compile the build for Win64
	./RunUAT BuildCookRun -project="U:/UnrealEngine/DiscGolf/DiscGolf.uproject" -noP4 -platform=Win64 -clientconfig=Shipping -serverconfig=Shipping -cook -maps=Map1+Map2+Map3+Map4 -build -stage -pak -package -distribution -archive -archivedirectory="B:/DiscGolfBuilds/PC"

	if($?)
	{
		Write-Host "Disc Golf Oculus Rift Build Successful." -foregroundcolor black -backgroundcolor cyan
	}
	else
	{
		Write-Host "Disc Golf Oculus Rift Build Failed. Check log files for more information." -foregroundcolor white -backgroundcolor red
	}
}

# MAIN BUILD FUNCTION
function BuildDiscGolf ()
{
	# START!
	Write-Host "Starting Disc Golf Nightly Build... " -foregroundcolor black -backgroundcolor cyan
	
	# Define maps to package
	$Map1 = "DiscGolf"
	$Map2 = "Splash"
	$Map3 = "Zone1"
	$Map4 = "Zone2"

	Write-Host "Set to cook ${Map1}." -foregroundcolor black -backgroundcolor cyan
	Write-Host "Set to cook ${Map2}." -foregroundcolor black -backgroundcolor cyan
	Write-Host "Set to cook ${Map3}." -foregroundcolor black -backgroundcolor cyan
	Write-Host "Set to cook ${Map4}." -foregroundcolor black -backgroundcolor cyan
	
	# Handle Steam Platform Build
	if ($platform -eq "Rift")
	{
		# Build Win64 for the Oculus Rift Platform
		BuildRift		
	}
}

# MAIN OPERATION :
# Run the DiscGolf Build
BuildDiscGolf




