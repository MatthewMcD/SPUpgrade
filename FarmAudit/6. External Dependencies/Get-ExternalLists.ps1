#Add the SharePoint PowerShell Snap-In
Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue 

#FileName
$outfile = "ExternalLists"
$fileName = ".\logs\$outfile-" + $(Get-Date -Format "yyyyMMddHHmmss") + ".csv"

#Output Array
[PSObject[]]$resultsarray = @()

foreach($webApp in $WebApplications){    Write-Host "Checking Web App: $($webApp.DisplayName) $($webApp.Url)"    foreach($spsite in $webApp.Sites)    {        if ($spsite.AllWebs.Count -gt 50){            Write-Host "Skipping $($spsite.Url)"            Continue        }        if ((Get-SPSite $spsite.url -ErrorAction SilentlyContinue) -ne $null)         {            try            {                foreach ($web in $spsite.AllWebs){
                    foreach ($list in $web.Lists){
                        if ($list.hasexternaldatasource){                            Write-Host "Found $($list.Title) in site $($web.Title)"                            $outObject = new-object PSObject                            $outObject | add-member -membertype NoteProperty -name "Site" -Value $list.ParentWeb.Site.Url                            $outObject | add-member -membertype NoteProperty -name "Web" -Value $list.ParentWeb.Title                            $outObject | add-member -membertype NoteProperty -name "List" -Value $list.Title                            $outObject | add-member -membertype NoteProperty -name "URL" -Value $list.DefaultViewUrl                            $outObject | add-member -membertype NoteProperty -name "ECT Name" -Value $list.DataSource.GetEntity().Name                            $outObject | add-member -membertype NoteProperty -name "Namespace" -Value $list.DataSource.GetEntity().Namespace                            $outObject | add-member -membertype NoteProperty -name "Version" -Value $list.DataSource.GetEntity().Version
                            $global:resultsarray += $outObject                        }                    }                }            }            catch            {                Write-Host "Caught an exception accessing site: $($spsite.RootWeb.Title) ($($spsite.Url))" -ForegroundColor Yellow
                #Write-Host "Exception Type: $($_.Exception.GetType().FullName)" -ForegroundColor Red
                Write-Host "Exception Message: $($_.Exception.Message)" -ForegroundColor Red            }        }    }}

$resultsarray | Export-csv $fileName -notypeinformation





#Get-SPWebApplication http://intranet.doghousetoys.com | Select –ExpandProperty Sites |
# Select -ExpandProperty AllWebs | Select -ExpandProperty Lists |
# where {$_.hasexternaldatasource -eq $true} | Format-Table $a -AutoSize


 