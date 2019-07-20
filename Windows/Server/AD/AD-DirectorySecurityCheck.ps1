# © 2018 Soverance Studios
# Scott McCutchen
# scott.mccutchen@soverance.com

# This script recursively pulls information on the NTFS security settings of a specified directory.

# Define all paths to scan
# These are specific to BKV's environment and must be replaced manually with new paths if/when necessary
$PathsToScan = "H:", "K:", "N:"

# Builds the complete path of the exported report using this script's current root.
$ExportPathWithFileName = $PSScriptRoot + "\BKV_Security_Report_" + (Get-Date -format yyyy-MM-dd) + ".xlsx"

# Get-ACE collects security information on a specified object (folder)
Function Get-ACE {
Param (
        [parameter(Mandatory=$true)]
        [string]
        [ValidateScript({Test-Path -Path $_})]
        $Path
)
    
    $ErrorLog = @()  # empty error log array declaration

    # Show Progress
    Write-Progress -Activity "Collecting folders" -Status $Path `
        -PercentComplete 0
    $folders = @() #empty folders array declaration
    # Collect all top level and sub folders
    $folders += Get-Item $Path | Select-Object -ExpandProperty FullName
	$subfolders = Get-Childitem $Path -Recurse -ErrorVariable +ErrorLog `
        -ErrorAction SilentlyContinue | 
        Where-Object {$_.PSIsContainer -eq $true} | 
        Select-Object -ExpandProperty FullName
    Write-Progress -Activity "Collecting folders" -Status $Path `
        -PercentComplete 100

    # We don't want to add a null object to the list if there are no subfolders
    If ($subfolders)
    {
        $folders += $subfolders # add valid subfolders to the main folder array
    }

    $i = 0 # initialize iterator
    $FolderCount = $folders.count  # get a complete count of all folders

    ForEach ($folder in $folders) 
    {
        # show scanning progress completion percentage based on iterator
        Write-Progress -Activity "Scanning folders" -CurrentOperation $folder `
            -Status $Path -PercentComplete ($i/$FolderCount*100)
        $i++ # increment iterator for next pass

        # Get-ACL cannot report some errors out to the ErrorVariable.
        # Therefore we have to capture this error using other means.
        Try {
            $acl = Get-ACL -LiteralPath $folder -ErrorAction Continue
        }
        Catch {
            $ErrorLog += New-Object PSObject `
                -Property @{CategoryInfo=$_.CategoryInfo;TargetObject=$folder}
        }

        $acl.access | 
            Where-Object {$_.IsInherited -eq $false} |
            Select-Object `
                @{name='Root';expression={$path}}, `
                @{name='Path';expression={$folder}}, `
                IdentityReference, FileSystemRights, IsInherited, `
                InheritanceFlags, PropagationFlags
    }
    
    $ErrorLog |
        Select-Object CategoryInfo, TargetObject |
        # Export Security Report
        Export-Excel -Path $ExportPathWithFileName -WorkSheetname Errors
}



# Call the Get-ACE function for each path in the text file
#Get-Content $PathsToScan | 
    ForEach ($path in $PathsToScan)
    {
        If (Test-Path -Path $path) # Check if path is valid
        {
            # Call Get-ACE for each path, and export results to CSV
            Get-ACE -Path $path |
            # Export Security Report
            Export-Excel -Path $ExportPathWithFileName -WorkSheetname Security
        } 
        Else 
        {
            # Error if path is not valid
            Write-Warning "Invalid path: $_"
        }
    }
