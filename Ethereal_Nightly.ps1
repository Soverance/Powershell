# Scott McCutchen
# soverance.com
#
# Automate the nightly packaging of Ethereal Legends.
# This script should be run as a scheduled task each night.

# Set Default Definitions
function SetDefaults ()
{
	# Define supported platforms
	$Platform1 = "Win64"
	$Platform2 = "XboxOne"

	# Define maps to package
	$Map1 = "MainMenu"
	$Map2 = "Arcadia_Main"
	$Map3 = "ShiitakeTemple_Main"
	$Map4 = "VulcanShrine_Main"
	$Map5 = "BorealCore_Main"
	$Map6 = "Yggdrasil_Main"
	$Map7 = "EmpyreanGardens_Main"
	$Map8 = "CelestialNexus_Main"

	Write-Host "Set to cook ${Map1}." -foregroundcolor black -backgroundcolor cyan
	Write-Host "Set to cook ${Map2}." -foregroundcolor black -backgroundcolor cyan
	Write-Host "Set to cook ${Map3}." -foregroundcolor black -backgroundcolor cyan
	Write-Host "Set to cook ${Map4}." -foregroundcolor black -backgroundcolor cyan
	Write-Host "Set to cook ${Map5}." -foregroundcolor black -backgroundcolor cyan
	Write-Host "Set to cook ${Map6}." -foregroundcolor black -backgroundcolor cyan
	Write-Host "Set to cook ${Map7}." -foregroundcolor black -backgroundcolor cyan
	Write-Host "Set to cook ${Map8}." -foregroundcolor black -backgroundcolor cyan
	
	# Define trueSKY local source paths
	$trueSKYsourceSimul = "U:/UnrealEngine-4.12/Engine/Binaries/ThirdParty/Simul/*"
	$trueSKYsourceResources = "U:/UnrealEngine-4.12/Engine/Plugins/TrueSkyPlugin/Resources/*"
	$trueSKYsourceContent = "U:/UnrealEngine-4.12/Engine/Plugins/TrueSkyPlugin/Content/*"
	$trueSKYsourceShaderbin = "U:/UnrealEngine-4.12/Engine/Plugins/TrueSkyPlugin/shaderbin/*"

	# Define trueSKY local destination paths
	$trueSKYdestinationSimul = "G:/EtherealBuilds/PC/WindowsNoEditor/Engine/Binaries/ThirdParty/Simul/"
	$trueSKYdestinationResources = "G:/EtherealBuilds/PC/WindowsNoEditor/Engine/Plugins/TrueSkyPlugin/Resources/"
	$trueSKYdestinationContent = "G:/EtherealBuilds/PC/WindowsNoEditor/Engine/Plugins/TrueSkyPlugin/Content/"
	$trueSKYdestinationShaderbin = "G:/EtherealBuilds/PC/WindowsNoEditor/Engine/Plugins/TrueSkyPlugin/shaderbin/"
}

SetDefaults

# Build Functions
function BuildWindows ()
{
	# Navigate to the local path where the Unreal automation tool is located
	cd U:/UnrealEngine-4.12/Engine/Build/BatchFiles
	Write-Host "Starting Ethereal Nightly Build... " -foregroundcolor black -backgroundcolor cyan

	# Once there, run the cook and compile the build for Win64
	./RunUAT BuildCookRun -project="U:/UnrealEngine-4.12/Ethereal/Ethereal.uproject" -noP4 -platform=Win64 -clientconfig=Development -serverconfig=Development -cook -maps=Map1+Map2+Map3+Map4+Map5+Map6+Map7+Map8 -build -stage -pak -archive -archivedirectory="G:/EtherealBuilds/PC"

	if($?)
	{
		Write-Host "Ethereal Win64 Nightly Build Successful." -foregroundcolor black -backgroundcolor cyan
	}
	else
	{
		Write-Host "Ethereal Win64 Nightly Build Failed." -foregroundcolor white -backgroundcolor red
	}
}

BuildWindows


# Handle copying Simul trueSKY files into the archive.
# trueSKY local file paths are defined in the SetDefaults() function.

# Create a reusable copy function
function CopyItem ($source, $destination)
{
	Copy-Item $source -Destination $destination -Recurse -Force -ErrorVariable capturedErrors -ErrorAction SilentlyContinue
	$capturedErrors | foreach-object { if ($_ -notmatch "already exists") { write-error $_ } }
}

function TrueSKYCheckAndCopy ()
{
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

function CopyTrueSKY ()
{
	TrueSKYCheckAndCopy
	
	if($?)
	{
		Write-Host "Simul trueSKY files successfully copied." -foregroundcolor black -backgroundcolor cyan
	}
	else
	{
		Write-Host "Simul trueSKY copy failed." -foregroundcolor white -backgroundcolor red
	}
}

CopyTrueSKY




