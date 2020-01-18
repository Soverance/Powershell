# © 2020 Soverance Studios, LLC
# Scott McCutchen
# DevOps Engineer
# scott.mccutchen@soverance.com
#
# This script will split a CSV file of email addresses into two files:  one with gmail addresses, one with everything else
# it then splits the master gmail file into sub-files of 600 records each

# this regex value basically verifies whether the contained string is a valid gmail.com email address
$GmailRegex = "[a-zA-Z0-9]{0,}([.]?[a-zA-Z0-9]{1,})[@](gmail.com)"

# Define file paths
$WorkingFolder = "C:\Users\scottm\Documents\Powershell\Applications\GoogleApps"
$OriginalList = $WorkingFolder + "emails.csv"
$GmailMaster = $WorkingFolder + "gmail-addresses-master.csv"
$OtherMaster = $WorkingFolder + "other-addresses-master.csv"

# this is the absolute file path to your original CSV email file
$EmailList = Import-CSV $OriginalList

# empty array declarations, which we'll use later
$GmailArray = @()
$OtherArray = @()

# for each email in your CSV....
foreach ($Email in $EmailList)
{
  # verify if it matches a gmail address
  $DidItMatch = $Email -match $GmailRegex

  if ($DidItMatch)
  {
    $GmailArray += $Email  # add to the gmail array
  }
  else
  {
    $OtherArray += $Email  # add to the other array
  }
}

# export both arrays as CSV files
$GmailArray | Export-Csv $GmailMaster -NoClobber -NoTypeInformation
$OtherArray | Export-Csv $OtherMaster -NoClobber -NoTypeInformation

$startrow = 0  # row counter to start the split at
$counter = 1  # incremental counter used for file names

while ($startrow -lt $GmailArray.Count)
{
  Import-CSV $GmailMaster | Select-Object -skip $startrow -first 600 | Export-CSV "$($WorkingFolder)gmail-$($counter).csv" -NoClobber -NoTypeInformation
  $startrow += 600
  $counter++
}