#Audit Web Apps

Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue
#Audit Sites
Clear-Host
$webappoutfile = ".\logs\Audit-WebApplications.csv"
"Web Application `tEmail Server `tManaged Paths `tContent DB Count `tApplication Pool `tClaims `tAAM Count" > $webappoutfile

$cdboutfile = ".\logs\Audit-ContentDatabases.csv"
#Write the CSV header
"Web Application `tContent Database `tContent DB Size (MB) `tSite Count `tSite Limit" > $cdboutfile

#Managed Path Value Formatting
$alias = @{Name="Alias";Expression={"{0}{1}" -f $(if (!$_.Name){"/"}else{$_.Name}), $(if($_.Type -eq "ExplicitInclusion"){"!"}else{"*"})}}

#Web Application
foreach ($webapplication in $(Get-SPWebApplication))
{
    $claims = 0
    if ($webapplication.UseClaimsAuthentication)
    {
        $claims = 1
    }

    #Get the Managed Paths as a delimited string
    $mps = Get-SPManagedPath -WebApplication $webapplication | Select $alias
    $managedpaths = ($mps | Select -ExpandProperty Alias) -Join ", "
        
    $webapplication.Url + "`t" + $webapplication.OutboundMailServiceInstance[0].Server.Address +"`t" + $managedpaths + "`t" + $webapplication.ContentDatabases.Count + "`t" + $webapplication.ApplicationPool.DisplayName + "`t" + $claims + "`t" + $webapplication.AlternateUrls.Count >> $webappoutfile

    foreach ($contentdb in $webapplication.ContentDatabases)
    {
        #WebApp URL, Content DB, Content DB Size, Site Collection Count, Site Limit
        $webapplication.Url + "`t" + $contentdb.Name +"`t" + $([Math]::Round($($contentdb.DiskSizeRequired/1MB),2)) + "`t" + $($contentdb.CurrentSiteCount) + "`t" + $($contentdb.MaximumSiteCount) >> $cdboutfile

    }    
}

