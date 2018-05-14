# Scott McCutchen
# soverance.com
#
# A simple script to convert all files in a directory to UTF-8 encoding

function Write-Log 
    { 
        param
        (
            [string]$strMessage
        )

            $LogDir = 'D:\Media\Music'
            $Logfile = "\Conversion-Log.txt"
            $Path = $logdir + $logfile
            [string]$strDate = get-date
            add-content -path $Path -value ($strDate + "`t:`t"+ $strMessage)
}


$SearchPath = "D:\Media\Music"
$rate = "192k"

$oldSongs = Get-ChildItem -Include @("*.wma") -Path $SearchPath -Recurse;

Set-Location -Path 'D:\Repository\Software\ffmpeg-3.4.1-win64-static\bin';

foreach ($OldSong in $oldSongs) 
{
    $NewSong = [io.path]::ChangeExtension($OldSong.FullName, '.mp3')
    & "D:\Repository\Software\ffmpeg-3.4.1-win64-static\bin\ffmpeg.exe" -i `"$OldSong`" -id3v2_version 3 -f mp3 -ab $rate -ar 44100 `"$NewSong`" -y


    # the following section does some "error checking" on the resulting size of the converted file
    # this is more or less arbitrary... 
    $OriginalSize = (Get-Item $OldSong).length 
    $ConvertedSize = (Get-Item $NewSong).length 
    [long]$Lbound = [Math]::Ceiling($OriginalSize * .5);
    [long]$Ubound = [Math]::Ceiling($OriginalSize * 2.0);

    #  if the new file is within the specified bounds...
    If($ConvertedSize -eq $OriginalSize -or ($ConvertedSize -ge $LBound -and $ConvertedSize -le $UBound))
    {
        Write-Log "$($NewSong) has been successfully updated"
        Remove-Item $OldSong
        If (Test-Path $OldSong)
        {
            write-log "Unable to remove $($OldSong)"
        }

        Else
        {
            write-log "Successfully removed $($OldSong)"
        }
    }
    #  if new file size is out of bounds...
    elseif($ConvertedSize -lt $Lbound)
    {
        Write-Log "$($NewSong) Is too small. Size is $($ConvertedSize)"
    }
    elseif($ConvertedSize -gt $Ubound)
    {
        Write-Log "$($NewSong) Is too big. Size is $($ConvertedSize)"
    }
}