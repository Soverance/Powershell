# Create a backup schedule in RouterOS

/system scheduler 
add name="backup" on-event="system backup save name=routeros.soverance.net.backup" \
    start-date=jan/01/2018 start-time=00:00:00 interval=24h comment="Soverance RouterOS Backup Plan" \
    disabled=no

# Run the backup command manually
/system backup save name=routeros.soverance.net.backup