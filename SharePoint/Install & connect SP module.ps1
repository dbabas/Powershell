# Check if already installed
Get-Module -Name Microsoft.Online.SharePoint.PowerShell -ListAvailable | Select Name,Version

# Install the module with admin rights
Install-Module -Name Microsoft.Online.SharePoint.PowerShell

# Install the module with user rights (only for the current user)
Install-Module -Name Microsoft.Online.SharePoint.PowerShell -Scope CurrentUser

# Update the module
Update-Module -Name Microsoft.Online.SharePoint.PowerShell


# Connect to SharePoint Online (Username and Password)
Connect-SPOService -Url https://conartia-admin.sharepoint.com -Credential dimitrios.bampas@conartia.com

# Connect to SharePoint Online (MFA)
Connect-SPOService -Url https://conartia-admin.sharepoint.com