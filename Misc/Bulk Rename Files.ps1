
$Path = 'C:\Users\Dimitrios\Documents\GitHub\NAV'
$Name = '*.cal'
$NewName = '.txt'
$RegExpr = '\.cal$'

Set-Location $Path
Get-ChildItem $Name| Rename-Item -NewName { $_.Name -replace $RegExpr,$NewName }