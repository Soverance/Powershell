# Scott McCutchen
# soverance.com
#
# A simple script to convert all files in a directory to UTF-8 encoding
# This is necessary for building Unreal Engine on certain platforms, specifically PlayStation 4

Param (
    [string]$path = $(throw "YOU MUST ENTER A VALID PATH.")
)

# Recursively collect all files within directory
# Include other file extensions as necessary
$files = Get-ChildItem $path -Recurse -Include *.h,*.cpp | ? {Test-Path $_.FullName -PathType Leaf}

foreach($file in $files)
{
	# Get all of the file's content
    $content = Get-Content $file.FullName
	# Write all content back into the file
	# The WriteAllLines function by default converts to UTF-8
	[IO.File]::WriteAllLines($file, $content)
	# Acknowledgement
	Write-Host "${file} was successfully encoded with UTF-8." -foregroundcolor black -backgroundcolor cyan
}