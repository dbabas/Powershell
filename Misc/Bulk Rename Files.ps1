
$Path = 'C:\github\NAV'
$Name = '*.txt'
$NewName = '.cal'
$RegExpr = '\.txt$'

Set-Location $Path
Get-ChildItem $Name| Rename-Item -NewName { $_.Name -replace $RegExpr,$NewName }