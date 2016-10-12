# Scott McCutchen
# soverance.com
#
# Automate the nightly packaging of Ethereal Legends.
# This script should be run as a scheduled task each night.
#
# Builds for the following platforms:
#
# Windows PC 64-bit
# Xbox One
#
# Ethereal Legends uses the trueSKY middleware provided by Simul, 
# so this script will also migrate those files into the build directory as necessary.

# Set Default Definitions
function SetDefaults ()
{
	# Define supported platforms
	$Platform1 = "Win64"
	$Platform2 = "XboxOne"

	# Define maps to package
	$Map1 = "Ethereal"
	$Map2 = "Loading"
	$Map3 = "MainMenu"
	$Map4 = "Arcadia"
	$Map5 = "ShiitakeTemple"
	$Map6 = "VulcanShrine"
	$Map7 = "BorealCore"
	$Map8 = "Yggdrasil"
	$Map9 = "EmpyreanGardens"
	$Map10 = "CelestialNexus"
	$Map11 = "Arena"

	Write-Host "Set to cook ${Map1}." -foregroundcolor black -backgroundcolor cyan
	Write-Host "Set to cook ${Map2}." -foregroundcolor black -backgroundcolor cyan
	Write-Host "Set to cook ${Map3}." -foregroundcolor black -backgroundcolor cyan
	Write-Host "Set to cook ${Map4}." -foregroundcolor black -backgroundcolor cyan
	Write-Host "Set to cook ${Map5}." -foregroundcolor black -backgroundcolor cyan
	Write-Host "Set to cook ${Map6}." -foregroundcolor black -backgroundcolor cyan
	Write-Host "Set to cook ${Map7}." -foregroundcolor black -backgroundcolor cyan
	Write-Host "Set to cook ${Map8}." -foregroundcolor black -backgroundcolor cyan
	Write-Host "Set to cook ${Map9}." -foregroundcolor black -backgroundcolor cyan
	Write-Host "Set to cook ${Map10}." -foregroundcolor black -backgroundcolor cyan
	Write-Host "Set to cook ${Map11}." -foregroundcolor black -backgroundcolor cyan
}

# Build Functions

# Windows 64-bit OnlineSubsystem = Steam
function BuildSteam ()
{
	# Navigate to the local path where the Unreal automation tool is located
	cd U:/UnrealEngine/Engine/Build/BatchFiles

	# Once there, run the cook and compile the build for Win64
	./RunUAT BuildCookRun -project="U:/UnrealEngine/Ethereal/Ethereal.uproject" -noP4 -platform=Win64 -clientconfig=Debug -serverconfig=Debug -cook -maps=Map1+Map2+Map3+Map4+Map5+Map6+Map7+Map8+Map9+Map10+Map11 -build -stage -pak -archive -archivedirectory="B:/EtherealBuilds/PC"

	if($?)
	{
		Write-Host "Ethereal Steam Build Successful." -foregroundcolor black -backgroundcolor cyan
	}
	else
	{
		Write-Host "Ethereal Steam Build Failed. Check log files for more information." -foregroundcolor white -backgroundcolor red
	}
}

# Xbox One OnlineSubsystem = Xbox Live
function BuildXbox ()
{
	# Navigate to the local path where the Unreal automation tool is located
	cd U:/UnrealEngine/Engine/Build/BatchFiles

	# Once there, run the cook and compile the build for Win64
	./RunUAT BuildCookRun -project="U:/UnrealEngine/Ethereal/Ethereal.uproject" -noP4 -platform=XboxOne -clientconfig=Development -serverconfig=Development -cook -maps=Map1+Map2+Map3+Map4+Map5+Map6+Map7+Map8+Map9+Map10+Map11 -build -stage -pak -archive -archivedirectory="B:/EtherealBuilds/Xbox"

	if($?)
	{
		Write-Host "Ethereal Xbox One Build Successful." -foregroundcolor black -backgroundcolor cyan
	}
	else
	{
		Write-Host "Ethereal Xbox One Build Failed. Check log files for more information." -foregroundcolor white -backgroundcolor red
	}
}

# Handle copying Simul trueSKY files into the archive.
# trueSKY local file paths are defined in the SetDefaults() function.

# Create a reusable copy function
function CopyItem ($source, $destination)
{
	Copy-Item $source -Destination $destination -Recurse -Force -ErrorVariable capturedErrors -ErrorAction SilentlyContinue
	$capturedErrors | foreach-object { if ($_ -notmatch "already exists") { write-error $_ } }
}

function TrueSKYCheckCopy ()
{
	# Define trueSKY local source paths
	$trueSKYsourceSimul = "U:/UnrealEngine/Engine/Binaries/ThirdParty/Simul/*"
	$trueSKYsourceContent = "U:/UnrealEngine/Engine/Plugins/TrueSkyPlugin/Content/*"
	$trueSKYsourceDeployContent = "U:/UnrealEngine/Engine/Plugins/TrueSkyPlugin/DeployToContent/*"
	$trueSKYsourceResources = "U:/UnrealEngine/Engine/Plugins/TrueSkyPlugin/Resources/*"	
	$trueSKYsourceShaderbin = "U:/UnrealEngine/Engine/Plugins/TrueSkyPlugin/shaderbin/*"

	# Define trueSKY local destination paths
	$trueSKYdestinationSimul = "B:/EtherealBuilds/PC/WindowsNoEditor/Engine/Binaries/ThirdParty/Simul/"
	$trueSKYdestinationContent = "B:/EtherealBuilds/PC/WindowsNoEditor/Engine/Plugins/TrueSkyPlugin/Content/"
	$trueSKYdestinationDeployContent = "B:/EtherealBuilds/PC/WindowsNoEditor/Engine/Plugins/TrueSkyPlugin/DeployToContent/"
	$trueSKYdestinationResources = "B:/EtherealBuilds/PC/WindowsNoEditor/Engine/Plugins/TrueSkyPlugin/Resources/"	
	$trueSKYdestinationShaderbin = "B:/EtherealBuilds/PC/WindowsNoEditor/Engine/Plugins/TrueSkyPlugin/shaderbin/"

	
	# Move Simul trueSKY files into the Build Archive
	# Test if the path exists, if not, create it, then copy the files.

	# Check /Simul/ destination
	if (test-path $trueSKYdestinationSimul)
	{
		CopyItem $trueSKYsourceSimul $trueSKYdestinationSimul
	}
	else
	{
		New-Item $trueSKYdestinationSimul -ItemType Directory -Force
		Write-Host "${trueSKYdestinationSimul} did not exist and was created."
		CopyItem $trueSKYsourceSimul $trueSKYdestinationSimul
	}
	# Check /DeployToContent/ destination
	if (test-path $trueSKYdestinationDeployContent)
	{
		CopyItem $trueSKYsourceDeployContent $trueSKYdestinationDeployContent
	}
	else
	{
		New-Item $trueSKYdestinationDeployContent -ItemType Directory -Force
		Write-Host "${trueSKYdestinationDeployContent} did not exist and was created."
		CopyItem $trueSKYsourceDeployContent $trueSKYdestinationDeployContent
	}	
	# Check /Resources/ destination
	if (test-path $trueSKYdestinationResources)
	{
		CopyItem $trueSKYsourceResources $trueSKYdestinationResources
	}
	else
	{
		New-Item $trueSKYdestinationResources -ItemType Directory -Force
		Write-Host "${trueSKYdestinationResources} did not exist and was created."
		CopyItem $trueSKYsourceResources $trueSKYdestinationResources
	}
	# Check /Content/ destination
	if (test-path $trueSKYdestinationContent)
	{
		CopyItem $trueSKYsourceContent $trueSKYdestinationContent
	}
	else
	{
		New-Item $trueSKYdestinationContent -ItemType Directory -Force
		Write-Host "${trueSKYdestinationContent} did not exist and was created."
		CopyItem $trueSKYsourceContent $trueSKYdestinationContent
	}
	# Check /shaderbin/ destination
	if (test-path $trueSKYdestinationShaderbin)
	{
		CopyItem $trueSKYsourceShaderbin $trueSKYdestinationShaderbin
	}
	else
	{
		New-Item $trueSKYdestinationShaderbin -ItemType Directory -Force
		Write-Host "${trueSKYdestinationShaderbin} did not exist and was created."
		CopyItem $trueSKYsourceShaderbin $trueSKYdestinationShaderbin
	}
}

# Actually run the trueSKY copy function, and ensure it ran successfully.
function TrueSKYcopy ()
{
	TrueSKYCheckCopy
	
	if($?)
	{
		Write-Host "Simul trueSKY files successfully copied." -foregroundcolor black -backgroundcolor cyan
	}
	else
	{
		Write-Host "Simul trueSKY copy failed." -foregroundcolor white -backgroundcolor red
	}
}

# MAIN THREAD

SetDefaults

Write-Host "Starting Ethereal Nightly Build... " -foregroundcolor black -backgroundcolor cyan

BuildSteam

TrueSKYcopy

#BuildXbox




