#Connect to exchange on-line
#https://docs.microsoft.com/en-us/powershell/exchange/connect-to-exchange-online-powershell?view=exchange-ps
Connect-ExchangeOnline -UserPrincipalName <Username> -ShowProgress $true
#Make team's calendar available in Outlook.
set-UnifiedGroup -identity <Team name> -HiddenFromExchangeClientsEnabled:$false
