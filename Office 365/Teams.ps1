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
    $credential = Get-Credential

    #Connect to Microsoft Teams
    Connect-MicrosoftTeams -Credential $credential

    #Connection to Skype for Business Online and import into Ps session
    $session = New-CsOnlineSession -Credential $credential
    Import-PsSession $session

