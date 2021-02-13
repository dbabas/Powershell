## Created by SAMCOS @ MSFT, Collaboration with others!
## You must first connect to Microsoft Teams Powershell & Exchange Online Powershell for this to work.
## Links:
## Teams: https://www.powershellgallery.com/packages/MicrosoftTeams/0.9.5
## Exchange: https://docs.microsoft.com/en-us/powershell/exchange/exchange-online/connect-to-exchange-online-powershell/connect-to-exchange-online-powershell?view=exchange-ps
## Have fun! Let me know if you have any comments. 

$AllTeamsInOrg = (Get-Team).GroupID
$TeamList = @()

Write-Output "This may take a little bit of time... Please sit back, relax and enjoy some GIFs inside of Teams!"
Write-Host ""

Foreach ($Team in $AllTeamsInOrg)
{       
        $TeamGUID = $Team.ToString()
        $TeamGroup = Get-UnifiedGroup -identity $Team.ToString()
        $TeamName = (Get-Team | ?{$_.GroupID -eq $Team}).DisplayName
        $TeamOwner = (Get-TeamUser -GroupId $Team | ?{$_.Role -eq 'Owner'}).User
        $TeamUserCount = ((Get-TeamUser -GroupId $Team).UserID).Count
        $TeamGuest = (Get-UnifiedGroupLinks -LinkType Members -identity $Team | ?{$_.Name -match "#EXT#"}).Name
            if ($TeamGuest -eq $null)
            {
                $TeamGuest = "No Guests in Team"
            }
        $TeamList = $TeamList + [PSCustomObject]@{TeamName = $TeamName; TeamObjectID = $TeamGUID; TeamOwners = $TeamOwner -join ', '; TeamMemberCount = $TeamUserCount; TeamSite = $TeamGroup.SharePointSiteURL; AccessType = $TeamGroup.AccessType; TeamGuests = $TeamGuest -join ','}
}

#######

$TestPath = test-path -path 'c:\temp'
if ($TestPath -ne $true) {New-Item -ItemType directory -Path 'c:\temp' | Out-Null
    write-Host  'Creating directory to write file to c:\temp. Your file is uploaded as TeamsDatav2.csv'}
else {Write-Host "Your file has been uploaded to c:\temp as 'TeamsDatav2.csv'"}
$TeamList | export-csv c:\temp\TeamsDatav2.csv -NoTypeInformation