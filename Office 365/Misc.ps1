#Install the module to interact with Office 365
#Filter with "AzureAD" to see the comdlets
#Install-Module -Name AzureAD

#Connect to the tenant
#$credential = Get-Credential
#Connect-AzureAD -Credential $credential

#Delete a group without waiting 30 days
#Get-AzureADMSDeletedGroup
#Remove-AzureADMSDeletedDirectoryObject -Id a5bb6d53-6106-4ca5-bb7e-48ae04714d2e


#List of users, groups etc.
#Get-AzureADUser -All $True
Get-AzureADGroup