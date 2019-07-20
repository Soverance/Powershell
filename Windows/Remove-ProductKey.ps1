# © 2018 Soverance Studios
# Scott McCutchen
# scott.mccutchen@soverance.com

# Remove the product key from a Windows installation, and prepare it for a new user.
# Use this only if you want to completely remove the activation key!

# uninstall the current product key and move Windows into "Unlicensed Mode"
slmgr /upk

# remove the product key from the registry, so that it cannot be stolen later
slmgr /cpky

# reset the Windows Activation timers so that the new owners will be prompted to activate Windows.
slmgr /rearm

# you must reboot the computer for these changes to take effect.
Restart-Computer