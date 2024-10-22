Get-Module SharePointPnPPowerShell* -ListAvailable | Select-Object Name,Version | Sort-Object Version -Descending

Uninstall-Module -Name "SharePointPnPPowerShellOnline"

Install-Module -Name SharePointPnPPowerShellOnline -RequiredVersion 3.28.2012.0

Install-Module -Name SharePointPnPPowerShellOnline -RequiredVersion 3.19.2003.0