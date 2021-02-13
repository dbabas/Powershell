#https://docs.microsoft.com/en-us/microsoftteams/teams-powershell-overview
#Filter Modules with "MicrosoftTeams" to see teams commands only


#https://docs.microsoft.com/en-us/microsoftteams/teams-powershell-install
#Install General Availability release.
Install-Module MicrosoftTeams -Force -AllowClobber
#Update General Availability release.
Update-Module MicrosoftTeams
#Uninstall General Availability release.
Uninstall-Module MicrosoftTeams

#https://docs.microsoft.com/en-us/microsoftteams/teams-powershell-install
#Sign in
    #Connect to Microsoft Teams
    $credential = Get-Credential
    Connect-MicrosoftTeams -Credential $credential

    #Connect to Microsoft Teams with MFA
    Connect-MicrosoftTeams -AccountID dimitrios.bampas@conartia.onmicrosoft.com

    #Connection to Skype for Business Online and import into Ps session
    $session = New-CsOnlineSession -Credential $credential
    Import-PsSession $session


#Return all teams that a user belongs to
Get-Team -User dimitrios.bampas@conartia.com | Sort-Object -property Visibility | Format-Table -GroupBy Visibility -AutoSize # or -Wrap


Get-Team | Get-TeamChannel -GroupId -eq $_.GroupId