#Test All Content Databases

Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue
#
Clear-Host
$outfile = ".\logs\Test-SPContentDBs.csv"
$orphancheck = $true
$dbskip = "SharePoint_Content_Intranet_02" #, "SharePoint_2013_Content_Intranet"
#Write the CSV header
"Web Application `tContent Database `tContent DB Size (MB) `tSite Count `tSite Limit `tCategory `tError `tUpgrade Blocking `tMessage `tRemedy `tLocations `tOrphans" > $outfile

#Web Application
foreach ($webapplication in $(Get-SPWebApplication))
{
    foreach ($contentdb in $webapplication.ContentDatabases)
    {
        if ($dbskip -contains $contentdb.Name){Continue}
        Write-Host "Testing $($contentdb.Name)..." -ForegroundColor Yellow
        $results = Test-SPContentDatabase -Name $contentdb.Name -WebApplication $webapplication -ShowLocation:$true  
        if ($orphancheck){
            #https://msdn.microsoft.com/en-us/library/office/microsoft.sharepoint.administration.spcontentdatabase.repair.aspx
            Write-Host "orphan check..." -ForegroundColor Yellow
            [xml]$orphans = $contentdb.Repair($false)
            #$orphans.DocumentElement.OuterXml | Out-File "C:\Users\ruby\Desktop\orphans.xml"
        }
        Write-Host "`rTesting $($contentdb.Name) complete: " -ForegroundColor Yellow
        #"Web Application `tContent Database `tContent DB Size (MB) `tSite Count `tSite Limit `tCategory `tError `tUpgradeBlocking `tMessage `tRemedy `tLocations"        
        if (($results.Count -eq 0) -and ($orphancheck) -and ($orphans.OrphanedObjects.Count -eq 0))
        {
            Write-Host "   No errors found" -ForegroundColor Green
            $webapplication.Url + "`t" + $contentdb.Name +"`t" + $([Math]::Round($($contentdb.DiskSizeRequired/1MB),2)) + "`t" + $($contentdb.CurrentSiteCount) + "`t" + $($contentdb.MaximumSiteCount) + "`t" + "" + "`t" + "None" >> $outfile        
        }
        else
        {
            if (($orphancheck) -and ($orphans.OrphanedObjects.Count -gt 0))
            {
                Write-Host "   found $($orphans.OrphanedObjects.Count) orphans" -ForegroundColor Red
                $webapplication.Url + "`t" + $contentdb.Name +"`t" + $([Math]::Round($($contentdb.DiskSizeRequired/1MB),2)) + "`t" + $($contentdb.CurrentSiteCount) + "`t" + $($contentdb.MaximumSiteCount) + "`t" + "Corruption" + "`t" + "Orphaned Objects" + "`t" + "" + "`t" + "" + "`t" + "" + "`t" + "" + "`t" + $orphans.OrphanedObjects.Count >> $outfile        
            }
            if ($results.Count -gt 0)
            {
                Write-Host "   found $($results.Count) errors " -ForegroundColor Red
                foreach ($result in $results)
                {
                    $webapplication.Url + "`t" + $contentdb.Name +"`t" + $([Math]::Round($($contentdb.DiskSizeRequired/1MB),2)) + "`t" + $($contentdb.CurrentSiteCount) + "`t" + $($contentdb.MaximumSiteCount) + "`t" + $result.Category + "`t" + $result.Error + "`t" + $result.UpgradeBlocking + "`t" + $result.Message + "`t" + $result.Remedy + "`t" + $result.Locations >> $outfile        
                }
            }
        }
        Write-Host "" 
    }    
}

