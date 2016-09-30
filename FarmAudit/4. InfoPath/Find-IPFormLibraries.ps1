Add-PSSnapin Microsoft.SharePoint.PowerShell
 
#Get the web application
#Write-Host "Enter the Web Application URL:"
$WebAppURL= "http://intranet.doghousetoys.com"
$SiteColletion = Get-SPSite($WebAppURL)
$WebApp = $SiteColletion.WebApplication

Clear-Host
$outfile = ".\logs\InfoPath-Libraries.csv"

#Write the CSV header
"Site Collection `t Site `t List Name `t List Url `t Docs Count `t Last Modified `t WF Count `t Live WF `t Live WF Names `t Form Template" > $outfile
 
#Loop through all site collections of the web app
foreach ($site in $WebApp.Sites)
{
    #Skip deep sites    if ($site.AllWebs.Count -gt 100){Write-Host "Skipping $($site.RootWeb.Title)" -ForegroundColor Magenta; Continue}
    # get the collection of webs
    foreach($web in $site.AllWebs)
    {
        write-host "Scaning Site" $web.title "@" $web.URL
        foreach($list in $web.lists)
        {
            if( $list.BaseType -eq "DocumentLibrary" -and $list.BaseTemplate -eq "XMLForm")
            {
                $listModDate = $list.LastItemModifiedDate.ToShortDateString()
                $listTemplate = $list.ServerRelativeDocumentTemplateUrl
                $listWorkflowCount = $list.WorkflowAssociations.Count
                $listLiveWorkflowCount = 0
                $listLiveWorkflows = ""
        
                foreach ($wf in $list.WorkflowAssociations)
                {
                    if ($wf.Enabled)
                    {
                        $listLiveWorkflowCount++
                        if ($listLiveWorkflows.Length -gt 0)
                        {
                            $listLiveWorkflows = "$listLiveWorkflows, $($wf.Name)"
                        }
                        else
                        {
                            $listLiveWorkflows = $wf.Name
                        }
                    }
                }
                #Write data to CSV File
                $site.RootWeb.Title +"`t" + $web.Title +"`t" + $list.title +"`t" + $Web.Url + "/" + $List.RootFolder.Url  +"`t" + $list.ItemCount +"`t" + $listModDate +"`t" + $listWorkflowCount +"`t" + $listLiveWorkflowCount +"`t" + $listLiveWorkflows +"`t" + $listTemplate >> $outfile
            }
        }
    }
}
 
#Dispose of the site object
$siteColletion.Dispose()
Write-host  "Report Generated at $($outfile)" -foregroundcolor green


#Read more: http://www.sharepointdiary.com/2012/09/find-all-infopath-form-libraries.html#ixzz430097SdY