# © 2018 Soverance Studios
# Scott McCutchen
# scott.mccutchen@soverance.com

# perform a non-authoritative restore of the sysvol directory on a particular DC
# use this procedure whenever a DC becomes out of date with the PDC Emulator operation master role
# You wil know when this occurs because group policy will not update on the affected DC, 
# and there will be missing group policy folders in the "\\dc\SYSVOL\domain\Policies\" directory when compared to the PDC

# I THOUGHT THIS WAS GOING TO BE SCRIPTED, BUT TURNS OUT THAT'S UNNECESSARY, and seems easier to do with the GUI
# so I'm reproducing the steps here in this file for future reference.

# STEP 1 - Open Active Directory Users and Computers snap-in

# STEP 2 - Go to View menu, and then select the option "Users, Contacts, Groups, and Computers as containers"

# STEP 3 - In the tree view, go the Domain Controllers OU and unroll the problematic DC

# STEP 4 - Click "DFSR-LocalSettings"

# STEP 5 - Click "Domain System Volume"

# STEP 6 - Right-click the "SYSVOL Subscription" item in the details pane and select "Properties"

# STEP 7 - Click "Attribute Editor"

# STEP 8 - Click "msDFSR-Options"

# STEP 9 - Click "Edit"  (you can also double-click the "msDFSR-Options" object to edit)

# STEP 10 - Set "1" as the value

# STEP 11 - Apply the changes

# STEP 12 - Close the attribute editor and ADUC windows.

# STEP 13 - Restart the DFS Replication service

# you must restart the service (or wait for the next replication cycle) for the machine to restore the sysvol directory from the PDC.
# The "msDFSR-Options" attribute will return to a value of 0 when the restore is complete