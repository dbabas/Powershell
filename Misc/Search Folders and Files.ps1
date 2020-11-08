
$Path = 'C:\Users\Dimitrios\Documents\GitHub\NAV'
$FilenameFilter = '*Password*'
$RegExpr = 'Created'

#Seartch text in files within a directory
Set-Location $Path
Get-ChildItem $FilenameFilter | Select-String -Pattern $RegExpr

#List files based on a filter
Set-Location $Path
Get-ChildItem $FilenameFilter

