' https://support.microsoft.com/en-us/help/937537/you-find-that-several-custom-attributes-are-missing-when-you-use-admt
' We make no exclusions during this migration, as we want all data to migrate if possible
' therefore this property is intentionally left blank

Set o = CreateObject("ADMT.Migration")
o.SystemPropertiesToExclude = ""