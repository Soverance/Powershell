# Soverance
# Scott McCutchen
# scott.mccutchen@soverance.com
#
# This module allows for automatic PGP encryption

# this function will encrypt all files in the specified folder
function Add-ClientEncryption {

	[CmdletBinding()]
	[OutputType([System.IO.FileInfo])]
	param
	(
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[ValidateScript({Test-Path -Path $_ -PathType Container})]
		[string]$FolderPath,

        [Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string]$Recipient,

		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[string]$GpgPath = 'C:\Program Files (x86)\GnuPG\bin\gpg.exe',

        [Parameter()]
		[ValidateNotNullOrEmpty()]
		[string]$PassphraseFile = 'C:\Scripts\Your-Passphrase-File.txt'

	)
	process {
		try {
            $fd = 0
			Get-ChildItem -Path $FolderPath | foreach {
				Write-Verbose -Message "Encrypting [$($_.FullName)]"
                Start-Process -FilePath $GpgPath -ArgumentList "--batch --yes --local-user support@soverance.net --encrypt --sign --symmetric --passphrase-fd $($fd) --recipient $($Recipient) $($_.FullName)" -RedirectStandardInput $PassphraseFile -Wait -NoNewWindow
                #Start-Process -FilePath $GpgPath -ArgumentList "--batch --yes --local-user support@soverance.net --encrypt --sign --symmetric --passphrase-file $($passphrase) --recipient $($Recipient) $($_.FullName)" -Wait -NoNewWindow
			}
			Get-ChildItem -Path $FolderPath -Filter '*.pgp'
		} catch {
			Write-Error $_.Exception.Message
		}
	}
}

# this function will decrypt all files in the specified directory
# this assumes the file was encrypted for a recipient to which you have the private key
function Remove-ClientEncryption {

	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[ValidateScript({ Test-Path -Path $_ -PathType Container })]
		[string]$FolderPath,

		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[string]$GpgPath = 'C:\Program Files (x86)\GnuPG\bin\gpg.exe'
	)
	process {
		try {
			Get-ChildItem -Path $FolderPath -Filter '*.pgp' | foreach {
				$decryptFilePath = $_.FullName.TrimEnd('.pgp')
				Write-Verbose -Message "Decrypting [$($_.FullName)] to [$($decryptFilePath)]"
                Start-Process -FilePath $GpgPath -ArgumentList "--batch --yes --output $($decryptFilePath) --decrypt $($_.FullName)" -Wait -NoNewWindow
			}
			Get-ChildItem -Path $FolderPath | where {$_.Extension -ne 'pgp'}
		} catch {
			Write-Error $_.Exception.Message
		}
	}
}