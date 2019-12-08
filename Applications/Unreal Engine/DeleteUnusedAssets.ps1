# © 2018 Soverance Studios
# Scott McCutchen
# scott.mccutchen@soverance.com

# This script will check your project's maps and remove any unused assets from the content browser.

# THIS IS AN UNDOCUMENTED FEATURE IN UNREAL ENGINE!
# USE THIS AT YOUR OWN RISK!
# See here for more info:  https://forums.unrealengine.com/unreal-engine/feedback-for-epic/103291-delete-all-unused-assets

# Below is the C++ code within Unreal Engine that makes up this function
# use it as a reference to build the command for your specific project

##########################################################################
##
#// overall commandlet control options
#bool bShouldRestoreFromPreviousRun = FParse::Param(*Params, TEXT("restore"));
#bool bShouldSavePackages = !FParse::Param(*Params, TEXT("nosave"));
#bool bShouldSaveUnreferencedContent = !FParse::Param(*Params, TEXT("nosaveunreferenced"));
#bool bShouldDumpUnreferencedContent = FParse::Param(*Params, TEXT("reportunreferenced"));
#bool bShouldCleanOldDirectories = !FParse::Param(*Params, TEXT("noclean"));
#bool bShouldSkipMissingClasses = FParse::Param(*Params, TEXT("skipMissingClasses"));

#// what per-object stripping to perform
#bool bShouldStripLargeEditorData = FParse::Param(*Params, TEXT("striplargeeditordata"));
#bool bShouldStripMips = FParse::Param(*Params, TEXT("stripmips"));

#// package loading options
#bool bShouldLoadAllMaps = FParse::Param(*Params, TEXT("allmaps"));

#// if no platforms specified, keep them all
#UE_LOG(LogContentCommandlet, Warning, TEXT("Keeping platform-specific data for ALL platforms"));

#FString SectionStr;
#FParse::Value( *Params, TEXT( "SECTION=" ), SectionStr );
##
##########################################################################
##
# EXAMPLE USAGE
# "C:\Program Files\Epic Games\UE_4.18\Engine\Binaries\Win64\UE4Editor-Cmd.exe" "D:\Perforce\Epic\depot\usr\Tom.Shannon\GameJamKit - Copy\GameJamKit.uproject" -run=WrangleContent -allmaps
#

Set-Location -Path "U:\UnrealEngine\Engine\Binaries\Win64"

./UE4Editor-CMD.exe "U:\UnrealEngine\Ethereal\Ethereal.uproject" -run=WrangleContent -allmaps
