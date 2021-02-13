#Add a specific user to all Teams 
#needs TeamsFunctions from Powershell Gallery

$Admin = 'dimitrios.bampas@conartia.com'
$MFA = 'Yes' #Yes or No
$User = 'fokion.tzourdas@conartia.onmicrosoft.com'
$Role = 'Owner' #Owner or Member


if ($MFA -eq 'Yes')
    {
        Connect-Me -UserName $Admin -MicrosoftTeams -SkypeOnline #needs TeamsFunctions from Powershell Gallery
    }
else
    {
        $credential = Get-Credential
        Connect-MicrosoftTeams -Credential $credential
    
        #Connection to Skype for Business Online and import into Ps session
        $session = New-CsOnlineSession -Credential $credential
        Import-PsSession $session
        
    }

get-team | Add-TeamUser -Groupid {$_.Groupid} -User $User -Role $Role