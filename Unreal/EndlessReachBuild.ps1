# © 2017 Soverance Studios
# Scott McCutchen
# soverance.com
#
# Automate the build packaging of Endless Reach HD.
#
# Builds for the following platforms:
#
# Steam (Windows 64 bit only)

# Run the script with the following options to build for a specific platform
# This game does not currently support other platforms... but this is fine.
# example:  ./EndlessReachBuild.ps1 -platform Steam
param (
	[string]$platform = $(throw "-platform is required. Only Steam is supported.")
)

# Build Functions

# Windows 64-bit OnlineSubsystem = Steam
function BuildSteam ()
{
	# Navigate to the local path where the Unreal automation tool is located
	cd U:/UnrealEngine/Engine/Build/BatchFiles

	# Once there, run the cook and compile the build for Win64
	./RunUAT BuildCookRun -project="U:/UnrealEngine/EndlessReachHD/EndlessReachHD.uproject" -noP4 -platform=Win64 -clientconfig=Shipping -serverconfig=Shipping -cook -maps=Map1 -build -stage -pak -package -distribution -archive -archivedirectory="B:/EndlessReachBuilds/PC"

	if($?)
	{
		Write-Host "EndlessReachHD Steam Build Successful." -foregroundcolor black -backgroundcolor cyan
	}
	else
	{
		Write-Host "EndlessReachHD Steam Build Failed. Check log files for more information." -foregroundcolor white -backgroundcolor red
	}
}

# MAIN BUILD FUNCTION
function BuildEndlessReachHD ()
{
	# START!
	Write-Host "Starting EndlessReachHD Nightly Build... " -foregroundcolor black -backgroundcolor cyan
	
	# Define maps to package
	$Map1 = "01-LumoriaNebula"

	Write-Host "Set to cook ${Map1}." -foregroundcolor black -backgroundcolor cyan
	
	# Handle Steam Platform Build
	if ($platform -eq "Steam")
	{
		# Build Win64 for Steam Platform
		BuildSteam
	}
}

# MAIN OPERATION :
# Run the EndlessReachHD Build
BuildEndlessReachHD
