# © 2017-2019 Soverance Studios
# Scott McCutchen
# scott.mccutchen@soverance.com

# Script will open an FTP request on a server using the supplied credentials,
# then UPLOAD and OVERWRITE the specified file.

# Parameters
param (
    # define the custom vault profile name
	[string]$file = $(throw "- A valid file path must be specified."),
    # define the site you wish to connect to
    [string]$destination = $(throw "- A valid FTP domain, path, and file must be specified.  EX:  ftp://contoso.com/.well-known/acmechallenge/testfile.txt"),
     # define the FTP username
    [string]$user = $(throw "- A valid FTP username must be specified."),
    # define the FTP user password
    [string]$pass = $(throw "- A valid FTP user password must be specified."),
    # If the -TLS switch is used, then the FTP upload will occur via FTP with TLS security.  Otherwise, credentials are sent in plain text.
    [switch]$TLS
)

# trim the file from the path so it can be tested
$splitpath = Split-Path -Path $destination
# turn the slashes around so the path can actually be parsed correctly...
$splitpath = $splitpath -replace "\\", "/"

# test if the directory already exists on the FTP server
try
{
    $makedir = [System.Net.FtpWebRequest]::Create($splitpath)
    $makedir.Credentials = New-Object System.Net.NetworkCredential($user,$pass)
    $makedir.Method = [System.Net.WebRequestMethods+Ftp]::MakeDirectory
    $response = $makedir.GetResponse();

    # if this succeeds, we created the folder successfully.
    #otherwise... catch!
}catch [Net.WebException]
{
    try
    {
        # if an error was returned, check if the folder already exists on the server
        $checkdir = [System.Net.FtpWebRequest]::Create($splitpath)
        $checkdir.Credentials = New-Object System.Net.NetworkCredential($user,$pass)
        $checkdir.Method = [System.Net.WebRequestMethods+Ftp]::PrintWorkingDirectory
        $response = $checkdir.GetResponse();
        # if this succeeds, the folder already exists.
    }catch [Net.WebException]
    {
        # if the folder didn't exist and couldn't be created, there's some other issue
        # most likely incorrect credentials, incorrect server name, etc.
    }
}

# Create FTP Web Requests
$ftp = [System.Net.FtpWebRequest]::Create($destination)
$ftp = [System.Net.FtpWebRequest]$ftp

# configure FTP Requests
# NOTE:  As of 03/25/2019, Liquid Web apparently stopped allowing FTP over TLS, and thus we can no longer use this method for uploading to Liquid Web servers
# To circumvent this without rewriting this module to support SFTP via WinSCP, we're just going to be lazy and send the credentials in plain text.
# Go fuck yourself, Liquid Web.
$ftp.Method = [System.Net.WebRequestMethods+Ftp]::UploadFile
$ftp.Credentials = New-Object System.Net.NetworkCredential($user,$pass)
$ftp.UseBinary = $true
$ftp.UsePassive = $true

if ($TLS)
{
    $ftp.EnableSsl = $true
}
else
{
    $ftp.EnableSsl = $false
}

# read in the files to upload as a byte array
$content = [System.IO.File]::ReadAllBytes($file)
$ftp.ContentLength = $content.Length

# get the request stream, and write the bytes into it
$rs = $ftp.GetRequestStream()
$rs.Write($content, 0, $content.Length)
# be sure to clean up after ourselves
$rs.Close()
$rs.Dispose()
Write-Host "Successfully Completed FTP File Upload" -foregroundcolor black -backgroundcolor cyan