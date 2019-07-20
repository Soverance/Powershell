# Scott McCutchen
# soverance.com
#
# A simple script to convert all .mkv files in a directory into .avi files

function Write-Log 
    { 
        param
        (
            [string]$strMessage
        )

            $LogDir = 'B:\venture7'
            $Logfile = "\Conversion-Log.txt"
            $Path = $logdir + $logfile
            [string]$strDate = get-date
            add-content -path $Path -value ($strDate + "`t:`t"+ $strMessage)
}


$SearchPath = "B:\venture7"

$oldVideos = Get-ChildItem -Include @("*.mkv") -Path $SearchPath -Recurse;

Set-Location -Path 'D:\Repository\Software\ffmpeg-3.4.1-win64-static\bin';

foreach ($OldVideo in $oldVideos) 
{
    $newVideo = [io.path]::ChangeExtension($OldVideo.FullName, '.avi')
    & "D:\Repository\Software\ffmpeg-3.4.1-win64-static\bin\ffmpeg.exe" -i $($OldVideo) -c:v copy -c:a copy $($NewVideo) -bsf:v h264_mp4toannexb
    $OriginalSize = (Get-Item $OldVideo).length 
    $ConvertedSize = (Get-Item $Newvideo).length 
    [long]$Lbound = [Math]::Ceiling($OriginalSize * .85);
    [long]$Ubound = [Math]::Ceiling($OriginalSize * 1.15);

    If($ConvertedSize -eq $OriginalSize -or ($ConvertedSize -ge $LBound -and $ConvertedSize -le $UBound))
    {
        Write-Log "$($NewVideo) has been successfully updated"
        Remove-Item $OldVideo
        If (Test-Path $OldVideo)
        {
            write-log "Unable to remove $($OldVideo)"
        }

        Else
        {
            write-log "Successfully removed $($OldVideo)"
        }
    }
    elseif($ConvertedSize -lt $Lbound)
    {
        Write-Log "$($NewVideo) Is too small. Size is $($ConvertedSize)"
    }
    elseif($ConvertedSize -gt $Ubound)
    {
        Write-Log "$($NewVideo) Is too big. Size is $($ConvertedSize)"
    }
}