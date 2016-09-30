#Add the SharePoint PowerShell Snap-In
Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue 

#FileName
$outfile = "2013Workflows"
$fileName = ".\logs\$outfile-" + $(Get-Date -Format "yyyyMMddHHmmss") + ".csv"

#Output Array
[PSObject[]]$resultsarray = @()

Clear-Host

$WebApplications = Get-SPWebApplication
foreach($webApp in $WebApplications){    Write-Host "Checking: $($webApp.DisplayName) $($webApp.Url)"    foreach($site in $webApp.Sites)    {        if ((Get-SPSite $site.url -ErrorAction SilentlyContinue) -ne $null)         {            try            {                #Skip deep sites                if ($site.AllWebs.Count -gt 100){Write-Host "Skipping $($site.RootWeb.Title)" -ForegroundColor Magenta; Continue}                foreach($web in $site.AllWebs)                {                    if ((Get-SPWeb $web.url -ErrorAction SilentlyContinue) -ne $null)                     {                        #-- Getting a Workflow manager object to work with.
                        $wfm = New-object Microsoft.SharePoint.WorkflowServices.WorkflowServicesManager($web)
                        #-- Getting the subscriptions
                        $sub = $wfm.GetWorkflowSubscriptionService()
                        #Enum the web lists
                        foreach ($list in $web.Lists){
                            # Enum workflows
                            $workflows = $sub.EnumerateSubscriptionsByList($list.ID)
                            foreach ($workflow in $workflows){
                                Write-Host "Found 2013 Workflow: $($workflow.Name) on $($list.Title) in $($list.ParentWeb.Title)" -ForegroundColor Yellow
                                $outObject = new-object PSObject                                $outObject | add-member -membertype NoteProperty -name "Site" -Value $list.ParentWeb.Site.Url                                $outObject | add-member -membertype NoteProperty -name "Web" -Value $list.ParentWeb.Title                                $outObject | add-member -membertype NoteProperty -name "List" -Value $list.Title                                $outObject | add-member -membertype NoteProperty -name "Name" -Value $workflow.Name                                $outObject | add-member -membertype NoteProperty -name "Platform" -Value "2013"                                $outObject | add-member -membertype NoteProperty -name "Url" -Value $list.DefaultViewUrl
                                $global:resultsarray += $outObject

                            }
                        }
                    }
                }
            }
            catch            {                Write-Host "Caught an exception accessing site: $($site.RootWeb.Title) ($($site.Url))" -ForegroundColor Yellow
                #Write-Host "Exception Type: $($_.Exception.GetType().FullName)" -ForegroundColor Red
                Write-Host "Exception Message: $($_.Exception.Message)" -ForegroundColor Red            }
        }
    }
}

$resultsarray | Export-csv $fileName -notypeinformation