# Get all webpart instances from all sites in the tenant (this is for Valo Tabs)
Submit-PnPSearchQuery -Query "FileExtension:aspx SPFxExtensionJson:5d521df6-c396-48ac-9c4b-f76d6a5954de" -All -RelevantResults | select OriginalPath