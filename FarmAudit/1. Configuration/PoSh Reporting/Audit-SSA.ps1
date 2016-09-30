#Search Service App

Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue

Clear-Host
$ssaoutfile = ".\logs\Audit-SearchService.csv"
$ssacsoutfile = ".\logs\Audit-SearchServiceContent.csv"

#Write the CSV header
"Name `tSearch Center URL `tDefault Content Access Account `tIndex Location" > $ssaoutfile

$ssa = Get-SPEnterpriseSearchServiceApplication
#Default Content Access Account
$dcaaccount = (New-Object Microsoft.Office.Server.Search.Administration.Content $ssa).DefaultGatheringAccount
#Index Location
$index = (Get-SPEnterpriseSearchComponent -SearchTopology $ssa.ActiveTopology | ? {($_.GetType().Name -eq "IndexComponent")}).RootDirectory
$ssa.Name + "`t" + $ssa.SearchCenterUrl + "`t" + $dcaaccount + "`t" + $index >> $ssaoutfile

#Get-SPEnterpriseSearchComponent -SearchTopology $ssa.ActiveTopology | ? {($_.GetType().Name -eq "IndexComponent")}


"Name `tType `tStart Address" > $ssacsoutfile
#Content Sources
$contentSources = Get-SPEnterpriseSearchCrawlContentSource -SearchApplication $ssa
foreach ($source in $contentSources) {
    foreach ($startaddress in $source.StartAddresses) { 
        $source.Name + "`t" + $source.Type + "`t" + $startaddress >> $ssacsoutfile
    }
}
