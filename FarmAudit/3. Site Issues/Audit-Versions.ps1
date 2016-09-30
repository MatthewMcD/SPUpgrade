#Adapted from : https://gallery.technet.microsoft.com/office/SharePoint-Document-e9701c96
#Add the SharePoint PowerShell Snap-In
Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue 

$url = "http://intranet.doghousetoys.com"
	
#Get the Web Application
$webapplication = Get-SPWebApplication $url

#Log when the versions are higher than n this value
$versionLimit = 20

#Perform a Library Version settings check, good for governance
$checkLibVersionSettings = $false
#Skip these libraries
#$excludeLibList = "Site Pages", "Style Library", "Pages"
$excludeLibList = "Site Pages", "Style Library", "Pages"

Clear-Host
$outfile = ".\logs\Library-Versions.csv"

#Write the CSV Header - Tab Separated
"Site Name`t Library `t File Name `t File URL `t File Type `t Last Modified `t No. of Versions `t Latest Version Size(MB) `t Versions Size(MB) `t Total File Size(MB)" | out-file $outfile

#Also detect libraies w/o version limits

#Loop through each site collection
foreach($site in $webapplication.Sites)
{
    #Loop through each site in the site collection
    Write-Host "Checking $($site.RootWeb.Title) ($($site.AllWebs.Count))"
    if ($site.AllWebs.Count -gt 200){continue}
    
    foreach($web in $site.AllWebs){
        #Loop through  each List
        foreach ($list in $web.Lists)
        {
            #Get only Document Libraries & Exclude Hidden System libraries
            if ( ($list.BaseType -eq "DocumentLibrary") -and ($list.Hidden -eq $false) )
            {
                #Flag list if Versioning true and no version limits
                if (($checkLibVersionSettings) -and ($list.Title -notin $excludeLibList)){
                    if (($list.EnableVersioning) -and (($list.MajorVersionLimit -lt 1) -or (($list.EnableMinorVersions) -and ($list.MajorWithMinorVersionsLimit -lt 1)))){
                        #Log the list with Versionsing and no limits
                        "$($siteName) `t $($list.Title) `t `t $($web.Url)/$($list.DefaultView.Url) `t `t No version limits on this library`t `t `t `t " | Out-File $outfile -Append
                    }
                }
                foreach ($listitem  in $list.Items)
                {
 				    #Throttle number of versions detected here
                    if ($listitem.Versions.Count -gt $versionLimit)
                    {
					    $versionSize=0

                        #Get the versioning details
                        foreach ($FileVersion in $listitem.File.Versions)
                        {
                            $versionSize = $versionSize + $FileVersion.Size;
                        }
					    #To Calculate Total Size(MB)
					    $TotalFileSize= [Math]::Round(((($listitem.File.Length + $versionSize)/1024)/1024),2)
							
                        #Convert Size to MB
                        $versionSize= [Math]::Round((($versionSize/1024)/1024),2)
							
					    #Get the Size of the current version
					    $CurrentVersionSize= [Math]::Round((($listitem.File.Length/1024)/1024),2)
							
                        #Get Site Name
                        if ($web.IsRootWeb -eq $true)
                        {
                            $siteName = $web.Title +" - Root";
                        }
                        else
                        {
                            $siteName= $site.RootWeb.Title + " - " + $web.Title;
                        }

                        #Log the data to a CSV file where versioning size > 0MB!
                        if ($versionSize -gt 0)
                        {
                            "$($siteName) `t $($list.Title) `t $($listitem.Name) `t $($web.Url)/$($listitem.Url) `t $($listitem['File Type'].ToString()) `t $($listitem['Modified'].ToString())`t $($listitem.Versions.Count) `t $CurrentVersionSize `t $($versionSize) `t $($TotalFileSize)" | Out-File $outfile -Append
                        }
                    }
                }
            }
        }
	    $web.Dispose()          
    }
    $site.Dispose()          
}
 

