#https://toddbaginski.com/blog/how-to-change-powerapps-owner/#:~:text=Change%20Owner%20of%20PowerApps%201%20Don%E2%80%99t%20actually%20change,a%20User.%20Previous%20Users%20remain%20Users.%20See%20More.


Install-Module -Name Microsoft.PowerApps.Administration.PowerShell
Install-Module -Name Microsoft.PowerApps.PowerShell -AllowClobber

Add-PowerAppsAccount #must be an environment admin

#EnvironmentName: you can get from powerapps url

Set-AdminPowerAppOwner -AppName 300fa6b4-ee0f-4d32-b3b3-90bc7ad8b821 -AppOwner $Global:currentSession.UserId -EnvironmentName Default-adeb4cab-9500-46b1-8d46-8ec19e24dcdd

