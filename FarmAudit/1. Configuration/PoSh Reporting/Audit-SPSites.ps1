#Add the SharePoint PowerShell Snap-In
Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue

#Audit Sites
Clear-Host
$outfile = ".\logs\Audit-SiteCollections.csv"
#Write the CSV header
"Site Collection `tSite Title `tOwner Email `tRoot Template `tCompatibility Level `tContent DB `tHNSC `tWeb Count `tSite Size (MB) `tSite Quota (MB)" > $outfile

#Web Application
foreach ($webapplication in $(Get-SPWebApplication))
{
    foreach ($spsite in $webapplication.Sites)
    {
        $hnsc = "{0}" -f $(if ($spsite.HostHeaderIsSiteName){"1"}else{"0"})
        #Site URL, RootWeb.Title, Site.AllWebs.Count, Site.Usage.Storage (MB)
        $spsite.Url + "`t" + $spsite.RootWeb.Title + "`t" + $spsite.Owner.Email + "`t" + $spsite.RootWeb.WebTemplate + "`t" + $spsite.CompatibilityLevel + "`t" + $spsite.ContentDatabase.Name + "`t" + $hnsc + "`t" + $spsite.AllWebs.Count + "`t" + $([Math]::Round($($spsite.Usage.Storage/1MB),2)) + "`t" + $([Math]::Round($($spsite.Quota.StorageMaximumLevel/1MB),2)) >> $outfile

    }    
}





#if enumsubwebs
#SubSite Title
#SubSite WebTemplate
#SubSite Size
#List Count
#Largest List
#List with Versions

