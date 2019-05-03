#Install the module to interact with Office 365
#Filter with "AzureAD" to see the comdlets
#Install-Module -Name AzureAD

Install-Module MSOnline

#Connect to the tenant
$credential = Get-Credential
#Connect-AzureAD -Credential $credential


#Delete a group without waiting 30 days
#Get-AzureADMSDeletedGroup
#Remove-AzureADMSDeletedDirectoryObject -Id a5bb6d53-6106-4ca5-bb7e-48ae04714d2e


#List of users, groups etc.
#Get-AzureADUser -All $True
#Get-AzureADGroup

#Rename Group email
#$credential = Get-Credential
#Connect-AzureAD -Credential $credential
#$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $credential -Authentication Basic -AllowRedirection
#Import-PSSession $Session -DisableNameChecking
#Set-UnifiedGroup -Identity “HR” -PrimarySmtpAddress “hr@gerovassiliou.gr”
#Remove-PSSession $Session #Do not forget to close the session!!!!!!!!!!

#List of users with Last Password Change
Connect-MsolService -Credential $credential
Get-MsolUser -All | select DisplayName, LastPasswordChangeTimeStamp
Get-MsolUser -All | select DisplayName, LastPasswordChangeTimeStamp | Export-CSV LastPasswordChange.csv -NoTypeInformation
