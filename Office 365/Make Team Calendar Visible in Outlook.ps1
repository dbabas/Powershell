#https://techcommunity.microsoft.com/t5/microsoft-teams-ama/why-the-teams-calendar-not-visible-in-outlook/m-p/300155
$UserCredential = Get-Credential
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $UserCredential -Authentication Basic -AllowRedirection
Import-PSSession $Session
set-UnifiedGroup -identity "TeamNameHere" -HiddenFromExchangeClientsEnabled:$false