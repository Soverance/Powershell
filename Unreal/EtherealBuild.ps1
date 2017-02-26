# © 2016 Soverance Studios
# Scott McCutchen
# soverance.com
#
# Automate the build packaging of Ethereal Legends.
#
# Builds for the following platforms:
#
# Steam (Windows 64 bit only)
# Xbox One
# PlayStation 4
#
# Ethereal Legends uses the trueSKY middleware provided by Simul, 
# so this script will also migrate those files into the build directory as necessary.

# Run the script with the following options to build for a specific platform
# example:  ./EtherealBuild.ps1 -platform Xbox
param (
	[string]$platform = $(throw "-platform is required. Only Steam, Xbox, and PS4 are supported.")
)

# Build Functions

# Windows 64-bit OnlineSubsystem = Steam
function BuildSteam ()
{
	# Navigate to the local path where the Unreal automation tool is located
	cd U:/UnrealEngine/Engine/Build/BatchFiles

	# Once there, run the cook and compile the build for Win64
	./RunUAT BuildCookRun -project="U:/UnrealEngine/Ethereal/Ethereal.uproject" -noP4 -platform=Win64 -clientconfig=Shipping -serverconfig=Shipping -cook -maps=Map1+Map2+Map3+Map4+Map5+Map6+Map7+Map8+Map9+Map10+Map11 -build -stage -pak -package -distribution -archive -archivedirectory="B:/EtherealBuilds/PC"

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

	# Once there, run the cook and compile the build for Xbox One
	./RunUAT BuildCookRun -project="U:/UnrealEngine/Ethereal/Ethereal.uproject" -noP4 -platform=XboxOne -clientconfig=Shipping -serverconfig=Shipping -cook -maps=Map1+Map2+Map3+Map4+Map5+Map6+Map7+Map8+Map9+Map10+Map11 -build -stage -pak -package -distribution -archive -archivedirectory="B:/EtherealBuilds/Xbox"

	if($?)
	{
		Write-Host "Ethereal Xbox One Build Successful." -foregroundcolor black -backgroundcolor cyan
	}
	else
	{
		Write-Host "Ethereal Xbox One Build Failed. Check log files for more information." -foregroundcolor white -backgroundcolor red
	}
}

# PlayStation 4 OnlineSubsystem = PSN
function BuildPS4 ()
{
	# Navigate to the local path where the Unreal automation tool is located
	cd U:/UnrealEngine/Engine/Build/BatchFiles

	# Once there, run the cook and compile the build for PlayStation 4
	./RunUAT BuildCookRun -project="U:/UnrealEngine/Ethereal/Ethereal.uproject" -noP4 -platform=PS4 -clientconfig=Development -serverconfig=Development -cook -maps=Map1+Map2+Map3+Map4+Map5+Map6+Map7+Map8+Map9+Map10+Map11 -build -stage -pak -archive -archivedirectory="B:/EtherealBuilds/PS4"

	if($?)
	{
		Write-Host "Ethereal PlayStation 4 Build Successful." -foregroundcolor black -backgroundcolor cyan
	}
	else
	{
		Write-Host "Ethereal PlayStation 4 Build Failed. Check log files for more information." -foregroundcolor white -backgroundcolor red
	}
}

# A reusable file copy function
function CopyItem ($source, $destination)
{
	Copy-Item $source -Destination $destination -Recurse -Force -ErrorVariable capturedErrors -ErrorAction SilentlyContinue
	$capturedErrors | foreach-object { if ($_ -notmatch "already exists") { write-error $_ } }
}

# Handle copying Simul trueSKY files into the archive.
# trueSKY paths in this script must be updated manually to account for configuration changes.
# Console builds are not required to copy trueSKY files in this manner. See trueSKY documentation for more details.
function TrueSKYPerformCopy ()
{
	# Define trueSKY local source paths
	$trueSKYsourceSimul = "U:/UnrealEngine/Engine/Binaries/ThirdParty/Simul/*"
	$trueSKYsourceContent = "U:/UnrealEngine/Engine/Plugins/TrueSkyPlugin/Content/*"
	$trueSKYsourceResources = "U:/UnrealEngine/Engine/Plugins/TrueSkyPlugin/Resources/*"	
	$trueSKYsourceShaderbin = "U:/UnrealEngine/Engine/Plugins/TrueSkyPlugin/shaderbin/*"

	# Define trueSKY local destination paths
	$trueSKYdestinationSimul = "B:/EtherealBuilds/PC/WindowsNoEditor/Engine/Binaries/ThirdParty/Simul/"
	$trueSKYdestinationContent = "B:/EtherealBuilds/PC/WindowsNoEditor/Engine/Plugins/TrueSkyPlugin/Content/"
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
	TrueSKYPerformCopy
	
	if($?)
	{
		Write-Host "Simul trueSKY files successfully copied." -foregroundcolor black -backgroundcolor cyan
	}
	else
	{
		Write-Host "Simul trueSKY copy failed." -foregroundcolor white -backgroundcolor red
	}
}

# MAIN BUILD FUNCTION
function BuildEthereal ()
{
	# START!
	Write-Host "Starting Ethereal Nightly Build... " -foregroundcolor black -backgroundcolor cyan
	
	# Define maps to package
	$Map1 = "Ethereal"
	$Map2 = "Loading"
	$Map3 = "MainMenu"
	$Map4 = "NewArcadia"
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
	
	# Handle Steam Platform Build
	if ($platform -eq "Steam")
	{
		# Build Win64 for Steam Platform
		BuildSteam
		
		# if the BuildSteam function succeeds
		if ($?)
		{
			# Copy the trueSKY files to their appropriate locations
			TrueSKYcopy
		}
	}
		
	# Handle Xbox Platform Build
	if ($platform -eq "Xbox")
	{
		# Build For Xbox Platform
		BuildXbox
	}
		
	# Handle PS4 Platform Build
	if ($platform -eq "PS4")
	{
		# Build For PS4 Platform
		BuildPS4
	}
}

# MAIN OPERATION :
# Run the Ethereal Build
BuildEthereal




