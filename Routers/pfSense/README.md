# pfSense
Soverance Studios pfSense Firewall Configurations

All pfSense XML config files within this repo are automatically exported using the pfSenseBackup.ps1 script found in the root of this repo.  This script is designed to be run on a schedule, as a Windows scheduled task.

In the event of a firewall failure, these configuration files can be restored into a factory-configured pfSense device using the "*Diagnostics -> Backup & Restore*" feature found in the Webconfigurator.  These XML backup files can also be manually exported directly using the "*Diagnostics -> Backup & Restore*" feature found in the pfSense Webconfigurator.

Each file carries the following naming syntax:

*Example file name:*
"**config-pfSense.soverance.net-20170829090556.xml**"

* **config** = prefix specifies that this is a configuration file.
* **pfSense** = the firewall's complete hostname, as defined in the "*System -> General Setup*" section of the Webconfigurator.
* **soverance.net** = the firewall's complete domain name, as defined in the "*System -> General Setup*" section of the Webconfigurator.
* **20170829090556** = a timestamp - year (2017), month (08), day (29), and time (090556).  A greater time value indicates the backup was taken later in the day.
* **.xml** = file extension


