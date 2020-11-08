#Install the module to interact with Office 365
#Filter with "AzureAD" to see the comdlets
Install-Module -Name AzureAD

Install-Module MSOnline

#Connect to the tenant
$credential = Get-Credential
Connect-AzureAD -Credential $credential
Install-Module ExchangeOnlineManagement
Connect-ExchangeOnline -Credential $UserCredential -ShowProgress $true




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


#Enable Dkim
#https://docs.microsoft.com/en-us/microsoft-365/security/office-365-security/use-dkim-to-validate-outbound-email?view=o365-worldwide
Install-Module ExchangeOnlineManagement
Connect-ExchangeOnline -Credential $UserCredential -ShowProgress $true
New-DkimSigningConfig -DomainName metalogistics.gr -Enabled $false
Get-DkimSigningConfig -Identity metalogistics.gr | Format-List Selector1CNAME, Selector2CNAME
#Add two CNAME records with the values created with the above commands and then run the following:
Set-DkimSigningConfig -Identity metalogistics.gr -Enabled $true
