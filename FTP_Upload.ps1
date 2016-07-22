# Script will open an FTP request on a server using the supplied credentials,
# then UPLOAD and OVERWRITE the specified file.
# This script transmits credentials using insecure protocols.
# You should consider encrypting this script for a higher level of security.

# Create FTP Web Requests
$ftp = [System.Net.FtpWebRequest]::Create("ftp://server.address/folder/filename.txt")
$ftp = [System.Net.FtpWebRequest]$ftp

# configure FTP Requests
$ftp.Method = [System.Net.WebRequestMethods+Ftp]::UploadFile
$ftp.Credentials = new-object System.Net.NetworkCredential("username","password")
$ftp.UseBinary = $true
$ftp.UsePassive = $true

# read in the files to upload as a byte array
$content = [System.IO.File]::ReadAllBytes("C:/some/path/to/filename.txt")
$ftp.ContentLength = $content.Length

# get the request stream, and write the bytes into it
$rs = $ftp.GetRequestStream()
$rs.Write($content, 0, $content.Length)
# be sure to clean up after ourselves
$rs.Close()
$rs.Dispose()
Write-Host "Successfully Completed FTP File Upload" -foregroundcolor black -backgroundcolor cyan