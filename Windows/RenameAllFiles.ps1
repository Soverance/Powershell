# © 2017 Soverance Studios
# Scott McCutchen
# soverance.com
# scott.mccutchen@soverance.com
#
# Rename all files incrementally in a specified directory.

# Run the script with the following options to rename all files in directory
# The -recurse parameter is optional, and if specified, will iterate and rename through all sub-folders
# The -recurse parameter DOES NOT WORK and will need some more effort before being fully functional
# The -prefix parameter is optional, and if specified, will prefix the new file name with the specified text, followed by an underscore (i.e., "screenshot_1.png")
# example:  ./RenameAllFiles.ps1 -folder \\SOV-CLOUD\Repository\Projects\Ethereal\Images -recurse -prefix screenshot
param (
	[string]$folder = $(throw "- A valid directory must be specified."),
    [switch]$recurse,
    [string]$prefix
)

# File Rename
function RenameFiles ()
{
    # Declare Basic Variables
    [int]$RenameIndex = 1
    [string]$FullPrefix = $null

    # Move to specified folder
    cd $folder

    # Get files in directory
    $files = Get-ChildItem

    # Get files recursively if specified
	if ($recurse)
	{
        # This option doesn't really work as intended DO NOT USE
		$files = Get-ChildItem -Recurse
	}
    
    # Build prefix string
    if ($prefix)
    {
        # If a prefix was specified, use it, appended with an underscore
        $FullPrefix = $prefix + "_"
    }
    else
    {
        # If no prefix was specified, empty it.
        $FullPrefix = ""
    }
    
    foreach($file in $files)
	{
        # Prepare complete file name
        $FullName = $FullPrefix + $RenameIndex.ToString() + $file.extension
        # Replace old file name with new file name, and keep the file type
        Rename-Item $file -NewName $FullName -Verbose
        # Increment RenameIndex
        $RenameIndex++
	}
}

# Call Rename Files
RenameFiles

# Return to this script's root working directory
Set-Location $PSScriptRoot