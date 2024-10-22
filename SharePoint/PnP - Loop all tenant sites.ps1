Try {
    #Get All Site collections 
    $SitesCollection = Get-PnPTenantSite -Filter "Url -like '*opap*'" # Filter by URL
    #$SitesCollection = Get-PnPTenantSite  -Template SITEPAGEPUBLISHING#0 # Only Communication Sites

    #Loop through each site collection
    ForEach($Site in $SitesCollection) 
    { 
        Write-host -F Green $Site.Url
    }
}
Catch {
    write-host -f Red "Error:" $_.Exception.Message
}


#Read more: https://www.sharepointdiary.com/2020/12/sharepoint-online-powershell-to-iterate-through-all-site-collections.html#ixzz8joUGsGCE