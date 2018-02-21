########################################################
# Name: BackupScript.ps1                              
# Creator: Michael Seidl aka Techguy                    
# CreationDate: 21.01.2014                              
# LastModified: 09.03.2014                               
# Version: 1.1   
# Doc: http://www.techguy.at/tag/backupscript/
# PSVersion tested: 3 and 4
#
# Description: Copies the Bakupdirs to the Destination
# You can configure more than one Backupdirs, every Dir
# wil be copied to the Destination. A Progress Bar
# is showing the Status of copied MB to the total MB
# Only Change Variables in Variables Section
# Change LoggingLevel to 3 an get more output in Powershell Windows
# 
#
# Beschreibung: Kopiert die BackupDirs in den Destination
# Ordner. Es können mehr als nur ein Ordner angegeben
# werden. Der Prozess wid mit einem Statusbar angezeigt
# diese zeigt die kopieren MB im Vergleich zu den gesamten
# MB an.
# Nur die Werte unter Variables ändern
# Ändere den Logginglevel zu 3 und erhalte die gesamte Ausgabe im PS Fenster
#
# Version 1.2 - FIX: Delete last Backup dirs, changed to support older PS Version
#               FIX: Fixed the Count in the Statusbar
#               FIX: Fixed Location Count in Statusbar
#
# Version 1.1 - CHANGE: Enhanced the Logging to a Textfile and write output, copy Log file to Backupdir
#             - FIX: Renamed some Variables an have done some cosmetic changes
#             - CHANGE: Define the Log Name in Variables
#
# Version 1.0 - RTM
########################################################
#
# www.techguy.at                                        
# www.facebook.com/TechguyAT                            
# www.twitter.com/TechguyAT                             
# michael@techguy.at 
########################################################

#Variables, only Change here
$Destination="\\SOV-CLOUD\Repo\Backups" #Copy the Files to this Location
$Versions="5" #How many of the last Backups you want to keep
$BackupDirs="U:\UnrealEngine-4.12\Ethereal", "U:\UnrealEngine-4.12\Echosphere", "E:\Github" #What Folders you want to backup
$Log="Log.txt" #Log Name
$LoggingLevel="1" #LoggingLevel only for Output in Powershell Window, 1=smart, 3=Heavy




#STOP-no changes from here
#STOP-no changes from here
#Settings - do not change anything from here
$Backupdir=$Destination +"\Backup-"+ (Get-Date -format yyyy-MM-dd)+"-"+(Get-Random -Maximum 100000)+"\"
$Items=0
$Count=0
$ErrorCount=0
$StartDate=Get-Date #-format dd.MM.yyyy-HH:mm:ss

#FUNCTION
#Logging
Function Logging ($State, $Message) {
    $Datum=Get-Date -format dd.MM.yyyy-HH:mm:ss

    if (!(Test-Path -Path $Log)) {
        New-Item -Path $Log -ItemType File | Out-Null
    }
    $Text="$Datum - $State"+":"+" $Message"

    if ($LoggingLevel -eq "1" -and $Message -notmatch "was copied") {Write-Host $Text}
    elseif ($LoggingLevel -eq "3" -and $Message -match "was copied") {Write-Host $Text}
   
    add-Content -Path $Log -Value $Text
}
Logging "INFO" "----------------------"
Logging "INFO" "Start the Script"

#Create Backupdir
Function Create-Backupdir {
    Logging "INFO" "Create Backupdir $Backupdir"
    New-Item -Path $Backupdir -ItemType Directory | Out-Null

    Logging "INFO" "Move Log file to $Backupdir"
    Move-Item -Path $Log -Destination $Backupdir

    Set-Location $Backupdir
    Logging "INFO" "Continue with Log File at $Backupdir"
}

#Delete Backupdir
Function Delete-Backupdir {
    $Folder=Get-ChildItem $Destination | where {$_.Attributes -eq "Directory"} | Sort-Object -Property $_.LastWriteTime -Descending:$false | Select-Object -First 1

    Logging "INFO" "Remove Dir: $Folder"
    
    $Folder.FullName | Remove-Item -Recurse -Force 
}

#Check if Backupdirs and Destination is available
function Check-Dir {
    Logging "INFO" "Check if BackupDir and Destination exists"
    if (!(Test-Path $BackupDirs)) {
        return $false
        Logging "Error" "$BackupDirs does not exist"
    }
    if (!(Test-Path $Destination)) {
        return $false
        Logging "Error" "$Destination does not exist"
    }
}

#Save all the Files
Function Make-Backup {
    Logging "INFO" "Started the Backup"
    $Files=@()
    $SumMB=0
    $SumItems=0
    $SumCount=0
    $colItems=0
    Logging "INFO" "Count all files and create the Top Level Directories"

    foreach ($Backup in $BackupDirs) {
        $colItems = (Get-ChildItem $Backup -recurse | Where-Object {$_.mode -notmatch "h"} | Measure-Object -property length -sum) 
        $Items=0
        $FilesCount += Get-ChildItem $Backup -Recurse | Where-Object {$_.mode -notmatch "h"}  
        Copy-Item -Path $Backup -Destination $Backupdir -Force -ErrorAction SilentlyContinue
        $SumMB+=$colItems.Sum.ToString()
        $SumItems+=$colItems.Count
    }

    $TotalMB="{0:N2}" -f ($SumMB / 1MB) + " MB of Files"
    Logging "INFO" "There are $SumItems Files with  $TotalMB to copy"

    foreach ($Backup in $BackupDirs) {
        $Index=$Backup.LastIndexOf("\")
        $SplitBackup=$Backup.substring(0,$Index)
        $Files = Get-ChildItem $Backup -Recurse | Where-Object {$_.mode -notmatch "h"} 
        foreach ($File in $Files) {
            $restpath = $file.fullname.replace($SplitBackup,"")
            try {
                Copy-Item  $file.fullname $($Backupdir+$restpath) -Force -ErrorAction SilentlyContinue |Out-Null
                Logging "INFO" "$file was copied"
            }
            catch {
                $ErrorCount++
                Logging "ERROR" "$file returned an error an was not copied"
            }
            $Items += (Get-item $file.fullname).Length
            $status = "Copy file {0} of {1} and copied {3} MB of {4} MB: {2}" -f $count,$SumItems,$file.Name,("{0:N2}" -f ($Items / 1MB)).ToString(),("{0:N2}" -f ($SumMB / 1MB)).ToString()
            $Index=[array]::IndexOf($BackupDirs,$Backup)+1
            $Text="Copy data Location {0} of {1}" -f $Index ,$BackupDirs.Count
            Write-Progress -Activity $Text $status -PercentComplete ($Items / $SumMB*100)  
            if ($File.Attributes -ne "Directory") {$count++}
        }
    }
    $SumCount+=$Count
    $SumTotalMB="{0:N2}" -f ($Items / 1MB) + " MB of Files"
    Logging "INFO" "----------------------"
    Logging "INFO" "Copied $SumCount files with $SumTotalMB"
    Logging "INFO" "$ErrorCount Files could not be copied"
 }

#Check if Backupdir needs to be cleaned and create Backupdir
$Count=(Get-ChildItem $Destination | where {$_.Attributes -eq "Directory"}).count
Logging "INFO" "Check if there are more than $Versions Directories in the Backupdir"

if ($count -lt $Versions) {

    Create-Backupdir

} else {
    
    Delete-Backupdir

    Create-Backupdir
}

#Check if all Dir are existing and do the Backup
$CheckDir=Check-Dir

if ($CheckDir -eq $false) {
    Logging "ERROR" "One of the Directory are not available, Script has stopped"
} else {
    Make-Backup

    $Enddate=Get-Date #-format dd.MM.yyyy-HH:mm:ss
    $span = $EndDate - $StartDate
    $Minutes=$span.Minutes
    $Seconds=$Span.Seconds
    
    Logging "INFO" "Backupduration $Minutes Minutes and $Seconds Seconds"
    Logging "INFO" "----------------------"
    Logging "INFO" "----------------------" 
}

Write-Host "Press any key to close ..."
$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")