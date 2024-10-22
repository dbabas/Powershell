#https://www.sharepointdiary.com/2019/02/sharepoint-online-disable-social-bar-on-modern-pages.html


#Set Parameters
$AdminCenterURL="https://conartia-admin.sharepoint.com"
$SiteURL = "https://conartia.sharepoint.com/sites/test-mytest"
 
#Connect to SharePoint Online
Connect-SPOService -Url $AdminCenterURL #-Credential (Get-Credential)
 
#Disable Social Bar on Site Pages
Set-SPOSite -Identity $SiteURL -SocialBarOnSitePagesDisabled $False


#Tenant level	
#Set-SPOTenant -SocialBarOnSitePagesDisabled $true 


#Read more: https://www.sharepointdiary.com/2019/02/sharepoint-online-disable-social-bar-on-modern-pages.html#ixzz7dKlqjJoe

