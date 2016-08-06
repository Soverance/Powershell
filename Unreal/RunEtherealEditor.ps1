# Scott McCutchen
# soverance.com
#
# A simple script to open the Ethereal project editor.
# You can macro this somewhere for quick access.
# The Editor must be set to open the most recent project on startup,
# otherwise running this script will launch the UE4 Project Browser.

CD U:\UnrealEngine-4.12\Engine\Binaries\Win64\

./UE4Editor.exe -log -NoLoadStartupPackages "U:\UnrealEngine-4.12\Ethereal\Ethereal.uproject"