# © 2018 Soverance Studios
# Scott McCutchen
# scott.mccutchen@soverance.com

# This script will copy a file from one location to another, asynchronously.

param(
    [string]$source = $(throw "-source is required.  Enter a valid source file path."),
    [string]$target = $(throw "-target is required.  Enter a valid target file path.")
)

$scriptblock = {
    $BasePath = $args[0]
    $TargetPath = $args[1]
    $files = Get-ChildItem -File -Recurse -Path "$($BasePath)\$($Filename)" -ErrorAction SilentlyContinue

    foreach ($file in $files)
    {
        $subdirectorypath = split-path $file.FullName.Replace($BasePath, "").Trim("\")
        $targetdirectorypath = "$($TargetPath)\$($subdirectorypath)"
        if ((Test-Path $targetdirectorypath) -eq $false)
        {
            Write-Host "Creating directory: $targetdirectorypath"
            md $targetdirectorypath -Force
        }

        Write-Host "Copying file to: $($targetdirectorypath.TrimEnd('\'))\$($File.Name)"
        Move-Item $File.FullName "$($targetdirectorypath.TrimEnd('\'))\$($File.Name)" -Force
    }
}

$arguments = @($source,$target)
start-job -scriptblock $scriptblock -ArgumentList $arguments