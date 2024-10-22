# Define the variables
$siteUrl = "https://conartia.sharepoint.com/sites/opap-whats-new"
$outputFile = "C:\temp\WebPartsAudit.csv"
 
# Import the PnP PowerShell module
Import-Module PnP.PowerShell
 
# Connect to the SharePoint site
Connect-PnPOnline -Url $siteUrl -Interactive -ClientId 5e31f47c-0069-48f6-bfb1-cbe7066529c1
 
# Function to get all pages in the site
function Get-AllPages {
    $pages = Get-PnPListItem -List "Site Pages"
    return $pages
}
 
# Function to get web parts on a page
function Get-WebPartsOnPage($pageName) {
    $page = Get-PnPClientSidePage -Identity $pageName
    $webParts = $page.Controls
    return $webParts
}
 
# Prepare an array to hold the audit results
$auditResults = @()
 
# Get all pages
$pages = Get-AllPages
 
# Iterate through each page and get web parts
foreach ($page in $pages) {
    $pageUrl = $page.FieldValues.FileRef
    $pageName = $page.FieldValues.FileLeafRef
    $webParts = Get-WebPartsOnPage -pageName $pageName
 
    foreach ($webPart in $webParts) {
        $auditResult = [PSCustomObject]@{
            PageUrl = $pageUrl
            WebPartId = $webPart.InstanceId
            WebPartTitle = $webPart.Title
            WebPartType = $webPart.Type
        }
        $auditResults += $auditResult
    }
}
 
# Export the results to a CSV file
$auditResults | Export-Csv -Path $outputFile -NoTypeInformation
 
# Disconnect from the SharePoint site
Disconnect-PnPOnline
 
Write-Output "Web parts audit completed and exported to $outputFile"