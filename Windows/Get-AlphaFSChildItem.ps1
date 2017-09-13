function Get-AlphaFSChildItem {
	<#
	.SYNOPSIS
	 	Gets the files and folders in a file system drive and can handle Folder and File paths that are greater than 260 characters.
	.DESCRIPTION
		This command is similar to Get-ChildItem except it takes advantage of the AlphaFS(.NET) module in order to get around the 260 character path limit.
		***************************************************************
		The AlphaFS.dll must be downloaded: http://alphafs.alphaleonis.com/index.html 
		Then imported: PS C:\> Import-Module -Name "%FilePath%/AlphaFS.dll"
		   
		Information can be found: https://github.com/alphaleonis/AlphaFS/wiki/PowerShell
		***************************************************************
	.PARAMETER Path
	.EXAMPLE
		Get-AlphaFSChildItem
		
		Description

		-----------

		This command gets the files and subdirectories in the current directory. If the current directory does not have
		child items, the command does not return any results.
	.EXAMPLE
		Get-AlphaFSChildItem -path C:\ps-test
		
		Description

		-----------

		This command gets the child items in the C:\ps-test directory
	.EXAMPLE
		Get-AlphaFSChildItem -path C:\ps-test -recurse
		
		Description

		-----------

		This command gets the system files and folders in the specified directory and its subdirectories.
	.EXAMPLE
		Get-AlphaFSChildItem -path C:\ps-test -SearchPattern "*.txt"
				
		Description

		-----------

		This command gets the system files that end in	"*.txt"
		
		
	.LINK
		http://alphafs.alphaleonis.com/index.html
		http://alphafs.alphaleonis.com/doc/2.0/index.html
		https://github.com/alphaleonis/AlphaFS/wiki/PowerShell
	
	#>
	param(
		[Parameter(
			ValueFromPipeline=$True,
			ValueFromPipelineByPropertyName=$True
		)
		][string]$Path = (Get-Location).Path,
		[string]$SearchPattern = '*',
		[array]$Include,
		[array]$Exclude,
		[Switch]$Recurse
	)
	$Error.Clear()
	
	if(!(Get-Module -name AlphaFS -ErrorAction SilentlyContinue)){	
		Import-Module -name AlphaFS
	}
	if($Error){
		return
	}
	
	$items = @()
	$FileSystemEntryInfo = @()
	if($recurse){
		$SearchOption = 'AllDirectories'
	}
	else{
		$SearchOption = 'TopDirectoryOnly'
	}
#	Get all folders
	$array = @()
	Try {
	    $array = [Alphaleonis.Win32.Filesystem.Directory]::EnumerateDirectories($Path,$SearchPattern,[System.IO.SearchOption]::$SearchOption)
		Foreach ($file in $array) { $items += $file } 
	}
	Catch [System.UnauthorizedAccessException] {
	    # Report exception.
	}
#	Get all files
	Try {
	    $array = [Alphaleonis.Win32.Filesystem.Directory]::EnumerateFiles($Path,$SearchPattern,[System.IO.SearchOption]::$SearchOption)
		Foreach ($file in $array) { $items += $file } 
	}
	Catch [System.UnauthorizedAccessException] {
# 	Report exception.
	}
	foreach($item in $items){
		$FileSystemEntryInfo += [Alphaleonis.Win32.Filesystem.File]::GetFileSystemEntryInfo($item)
	}
	if($Include){
		$IncludedItems = @()
		foreach($inc in $Include){
			$IncludedItems += $FileSystemEntryInfo | Where-Object {$_.FullPath -like "$inc"}
		}
		$FileSystemEntryInfo = $IncludedItems
	}	
	if($Exclude){
		foreach($Exc in $Exclude){
			$FileSystemEntryInfo = $FileSystemEntryInfo | Where-Object {$_.FullPath -notlike "$Exc"}
		}
	}
	return $FileSystemEntryInfo | Select @{N='FullName'; E={$_.FullPath}},@{N='LongFullName'; E={$_.LongFullPath}},* 
}
