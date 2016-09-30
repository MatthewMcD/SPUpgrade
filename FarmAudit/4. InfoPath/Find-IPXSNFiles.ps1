if ((Get-PSSnapin "Microsoft.SharePoint.PowerShell" -ErrorAction SilentlyContinue) -eq $null) 
{
    Add-PSSnapin "Microsoft.SharePoint.PowerShell"
}

[PSObject[]]$global:resultsArray = @()

$outputPath = "c:\users\ruby\desktop\logs\InfoPathDiscovery\output"
$tempPath = "c:\users\ruby\desktop\logs\InfoPathDiscovery\temp"

New-Item "$outputPath" -type directory -force | Out-Null
New-Item "$tempPath" -type directory -force | Out-Null

#output file name
$fileName = "$outputPath\dht-ipforms-" + $(Get-Date -Format "yyyyMMddHHmmss") + ".csv"

$webApplications = Get-SPWebApplication

function Get-Datasources ($path)
{
	
	$templateUrl = $web.Url + $path
	
	#Write-Host $templateUrl
	
	## get the file 
	$file = $web.GetFile($path)
	
	#Write-Host $file
	
	## download the form template 
	$filename = $file.Name 
	$fileID = $file.UniqueId.Tostring() 
	$localFile = $fileID + "\" + $filename 
	
	Write-Host "	Downloading - " -foreground gray -nonewline; Write-Host $path 
	Write-Host "	To - " -foreground gray -nonewline; Write-Host $localFile 
	
	$file = $web.GetFile($path) 
	$bytes = $file.OpenBinary(); 
	
	## Download the file to the path 
	$localFile = "$tempPath\$localFile" 
	
	## Create Directories
	New-Item "$tempPath\$fileID" -type directory -force | Out-Null 
	New-Item "$tempPath\$fileID\Extracted" -type directory -force | Out-Null
	
	## Write File
	[System.IO.FileStream] $fs = new-object System.IO.FileStream($localFile, "OpenOrCreate") 
	$fs.Write($bytes, 0 , $bytes.Length) 
	$fs.Close()

	## crack open the form template 
	Write-Host "	Extracting - " -foreground gray -nonewline; Write-Host $filename 
	Write-Host "	To " -foreground gray -nonewline; Write-Host "$fileID\Extracted"
	$localExtractedPath = "$tempPath\$fileID\Extracted"
	#Write-Host $localExtractedPath
	EXPAND "$localfile" -F:* "$localExtractedPath" | Out-Null 
	
	Write-Host "	Reading Manifest" -foreground gray
	
	try
	{
		$xml = New-Object xml
		$xml.Load("$localExtractedPath\manifest.xsf")
		$webServiceNames = ""
		foreach ($dataObjectElement in $xml.xDocumentClass.dataObjects.dataObject)
		{
			foreach ($webServiceAdapter in $dataObjectElement.query.webServiceAdapter)
			{
				try
				{
					$wsdlUrl = $webServiceAdapter.getAttribute("wsdlUrl")
					if ($webServiceNames.Length -gt 0)
					{
						$webServiceNames = $webServiceNames + "," + $webServiceAdapter.getAttribute("wsdlUrl")
					}
					else
					{
						$webServiceNames = $wsdlUrl
					}
				}
				catch
				{
					#SKIP
				}
			}
		}
	}
	catch
	{
		#SKIP
	}
	
	Write-Host "	Completed" -foreground green
	
	return $webServiceNames
}

foreach($webApp in $webApplications)
{
    Write-Host "Checking: $($webApp.DisplayName) $($webApp.Url)"
    foreach($site in $webApp.Sites)
    {
        #Skip deep sites        if ($site.AllWebs.Count -gt 100){Write-Host "Skipping $($site.RootWeb.Title)" -ForegroundColor Magenta; Continue}
        if ((Get-SPSite $site.url -ErrorAction SilentlyContinue) -ne $null) 
        {
            try
            {
                foreach($web in $site.AllWebs)
                {
                    if ((Get-SPWeb $web.url -ErrorAction SilentlyContinue) -ne $null) 
                    {
                        foreach ($list in $web.Lists)
                        {
							try
							{
								# is the default content type enabled as a form
								$contentTypeEnabled = $false
								# is the document library enabled as a form
								$documentLibraryEnabled = $false
								# does the list enabled as a form
								$listEnabled = $false
								
								if ($list.ContentTypesEnabled -and $list.ContentTypes[0].DocumentTemplate.ToLower().EndsWith("xsn"))
								{
									$contentTypeEnabled = $true
								}
								elseif ($list.BaseTemplate -eq "XMLForm" -and $list.ServerRelativeDocumentTemplateUrl.ToLower().EndsWith("xsn"))
								{
									$documentLibraryEnabled = $true;
								}
								elseif ($list.ContentTypes[0].ResourceFolder.Properties["_ipfs_infopathenabled"])
								{
									$listEnabled = $true
								}
							   
								if ($contentTypeEnabled -or $documentLibraryEnabled -or $listEnabled)
								{
									Write-Host "	Found a form on: $($webApp.DisplayName) - $($list.Title)"
									$outObject = new-object PSObject
									
									# Clear Variables
									$listLiveWorkflowCount = 0
									$listLiveWorkflows = ""
									$webServices = ""
									$path = ""
							
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
									
									try
									{
										if ($contentTypeEnabled)
										{
											$webServices = $web | Get-DataSources $list.ContentTypes[0].DocumentTemplate
										}
										elseif($documentLibraryEnabled)
										{
											$webServices = $web | Get-DataSources $list.ServerRelativeDocumentTemplateUrl
										}
										elseif($listEnabled)
										{
											$webServices = $web | Get-DataSources ($web.Url + "/" + $list.RootFolder.Url + "/item/" + $list.ContentTypes[0].ResourceFolder.Properties["_ipfs_solutionName"])
										}
									}
									catch
									{
										Write-Host "Caught an exception accessing XSN: $($site.RootWeb.Title) ($($list.Title))" -ForegroundColor Yellow
										Write-Host "Exception Message: $($_.Exception.Message)" -ForegroundColor Red
									}
									
									$outObject | add-member -membertype NoteProperty -name "BaseType" -Value $list.BaseType
									$outObject | add-member -membertype NoteProperty -name "SiteUrl" -Value $site.RootWeb.Url
									$outObject | add-member -membertype NoteProperty -name "SiteTitle" -Value $site.RootWeb.Title
									$outObject | add-member -membertype NoteProperty -name "WebURL" -Value $web.Url
									$outObject | add-member -membertype NoteProperty -name "WebTitle" -Value $web.Title
									$outObject | add-member -membertype NoteProperty -name "ListURL" -Value $list.RootFolder.Url
									$outObject | add-member -membertype NoteProperty -name "AllowContentTypes" -Value $list.AllowContentTypes
									$outObject | add-member -membertype NoteProperty -name "ContentTypeName" -Value $list.ContentTypes[0].Name
									$outObject | add-member -membertype NoteProperty -name "ContentTypeFormUrl" -Value $list.ContentTypes[0].DocumentTemplate
									$outObject | add-member -membertype NoteProperty -name "ListTemplate" -Value $list.ServerRelativeDocumentTemplateUrl
									$outObject | add-member -membertype NoteProperty -name "DefaultItemOpen" -Value $list.DefaultItemOpen
									$outObject | add-member -membertype NoteProperty -name "File" -Value $list.ContentTypes[0].ResourceFolder.Properties["_ipfs_solutionName"]
									$outObject | add-member -membertype NoteProperty -name "ListItemCount" -Value $list.ItemCount
									$outObject | add-member -membertype NoteProperty -name "ListLastModifiedDate" -Value $list.LastItemModifiedDate.ToShortDateString()
									$outObject | add-member -membertype NoteProperty -name "ListWorkflowCount" -Value $list.WorkflowAssociations.Count
									$outObject | add-member -membertype NoteProperty -name "ListLiveWorkflowCount" -Value $listLiveWorkflowCount
									$outObject | add-member -membertype NoteProperty -name "ListLiveWorkflows" -Value $listLiveWorkflows
									$outObject | add-member -membertype NoteProperty -name "WebServices" -Value $webServices
									
									$global:resultsArray += $outObject
								}
								
							}
							catch
							{
								Write-Host "Caught an exception accessing list: $($site.RootWeb.Title) ($($list.Title))" -ForegroundColor Yellow
								Write-Host "Exception Message: $($_.Exception.Message)" -ForegroundColor Red
							}
						}
					}
				}
			}
			catch
            {
                Write-Host "Caught an exception accessing site: $($site.RootWeb.Title) ($($site.Url))" -ForegroundColor Yellow
                Write-Host "Exception Message: $($_.Exception.Message)" -ForegroundColor Red
            }
		}
	}
}

$resultsArray | Export-csv $fileName -notypeinformation