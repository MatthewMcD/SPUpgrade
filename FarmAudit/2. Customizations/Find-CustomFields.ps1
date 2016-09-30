$verbose = $false
$verboseLogs = $false
Add-PSSnapin -Name Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue
cls
#$ErrorActionPreference = "Continue"
#FileName
$outfile = "column"
$fileName = ".\logs\$outfile-" + $(Get-Date -Format "yyyyMMddHHmmss") + ".csv"

#Field Exclude List
$fieldExcludeList = "WSEventSourceGUID", "WSPublishState", "WSGUID", "WebId", "UnreadMentions", "ItemId", "Subtype", "ItemUniqueId", "ListId", "SiteId", "OEAppInstanceID", "AppProductID", "AppRequestSeats", "AppSubtypeID", "OEDefaultHeight", "OEProductID", "OEDefaultWidth"
#Set up formatting
# Create custom table formatting
$sc = @{Expression={$_.Id};Label="Id";width=36}, 
      @{Expression={$_.InternalName};Label="InternalName";width=35},
      @{Expression={$_.Title};Label="Title";width=35},
      @{Expression={$_.FieldValueType};Label="FieldValueType";width=35},
      @{Expression={$_.FieldTypeDefinition.FieldTypeClass};Label="FieldTypeDefinition.FieldTypeClass";width=50},
      @{Expression={$_.TypeDisplayName};Label="TypeDisplayName";width=35},
      @{Expression={$_.Type};Label="Type";width=35}

#Output Array
[PSObject[]]$resultsarray = @()

function Get-CustomColumns($web)
{

    #Find custom columns
    Write-Host "Checking Site: $($web.Title)"
    try
    {
        #Check Site Columns
        #Specific Pattern
        #$siteColumns = $web.Fields | Where-Object{$_.FieldTypeDefinition.FieldTypeClass -like "*Dev4Side*"}
        #Default Pattern
        #$siteColumns = $web.Fields | Where-Object{$_.FieldTypeDefinition.FieldTypeClass -Notlike "Microsoft.SharePoint.*" -and ($_.FieldValueType -like "Microsoft.SharePoint.*" -or $_.FieldValueType -like "System.*" )}
        #Another Pattern
        $siteColumns = $web.Fields | Where-Object{($_.FieldTypeDefinition.FieldTypeClass -Notlike "Microsoft.SharePoint.*") -and ($_.SourceId -notlike "http://schemas.microsoft.com/sharepoint*") -and ($_.InternalName -notin $fieldExcludeList)}
        
        if ($siteColumns)
        {
            if ($verboseLogs)
            {
                $siteColumns | Select Id, InternalName, Title, FieldValueType, FieldTypeDefinition, TypeDisplayName, Type, SourceId | FT $sc | Out-String -Width 1024 > .\$($web.Title)-fields.txt
            }
            foreach ($field in $siteColumns)
            {
                Write-Host "Found Site Column: $($field.Title)" 
                    $outObject = new-object PSObject                    $outObject | add-member -membertype NoteProperty -name "ColumnType" -Value "Site Column"                    $outObject | add-member -membertype NoteProperty -name "FieldTypeClass" -Value $field.FieldTypeDefinition.FieldTypeClass                    $outObject | add-member -membertype NoteProperty -name "Site" -Value $list.ParentWeb.Site.Url                    $outObject | add-member -membertype NoteProperty -name "Web" -Value $list.ParentWeb.Title                    $outObject | add-member -membertype NoteProperty -name "List" -Value $list.Title                    $outObject | add-member -membertype NoteProperty -name "Column" -Value $field.Title                    $outObject | add-member -membertype NoteProperty -name "Url" -Value $list.DefaultViewUrl
                    $global:resultsarray += $outObject
                #Determine field in use
                foreach ($use in $field.ListsFieldUsedIn())
                {
                    $useweb = $web.Site.AllWebs[$use[0].WebID]
                    $uselist = $useweb.Lists[$use[0].ListID]

                    Write-Host "Found Site Column in list: $($uselist.Title)" 
                    $outObject = new-object PSObject                    $outObject | add-member -membertype NoteProperty -name "ColumnType" -Value "Site Column"                    $outObject | add-member -membertype NoteProperty -name "FieldTypeClass" -Value $field.FieldTypeDefinition.FieldTypeClass                    $outObject | add-member -membertype NoteProperty -name "Site" -Value $useweb.Site.Url                    $outObject | add-member -membertype NoteProperty -name "Web" -Value $useweb.Title                    $outObject | add-member -membertype NoteProperty -name "List" -Value $uselist.Title                    $outObject | add-member -membertype NoteProperty -name "Column" -Value $field.Title                    $outObject | add-member -membertype NoteProperty -name "Url" -Value $uselist.DefaultViewUrl
                    $global:resultsarray += $outObject
                }
            }
        }
        
        $lists = $web.Lists
        
        foreach ($list in $lists)
        {            
            try
            {
                if ($verbose){Write-Host -ForegroundColor Green "-> Checking List: $($list.Title)"}
            
                #All Fields
                #$list.Fields | Select Id, InternalName, Title, FieldValueType, FieldTypeDefinition, TypeDisplayName, Type | FT $sc | Out-String -Width 1024 > .\$($web.Title)-$($list.Title)-allfields.txt
                #Specific Template
                #$fields = $list.Fields | Where-Object{$_.FieldTypeDefinition.FieldTypeClass -ilike "*Dev4Side*"}
                #Default Template
                #$list.Fields | Where-Object{($_.FieldTypeDefinition.FieldTypeClass) -and ($_.FieldTypeDefinition.FieldTypeClass -Notlike "Microsoft.SharePoint.*") -and ($_.FieldValueType.ToString() -like "System.*")} | Select Id, InternalName, Title, FieldValueType, FieldTypeDefinition, TypeDisplayName, Type | FT $sc | Out-String -Width 1024
                $fields = $list.Fields | Where-Object{($_.FieldTypeDefinition.FieldTypeClass) -and ($_.FieldTypeDefinition.FieldTypeClass -Notlike "Microsoft.SharePoint.*") -and ($_.FieldValueType) -and ($_.FieldValueType.ToString() -like "System.*")}
            
                if ($fields)
                {
                    #If Logging Verbose
                    if ($verboseLogs)
                    {
                        $fields | Select Id, InternalName, Title, FieldValueType, FieldTypeDefinition, TypeDisplayName, Type, SourceId | FT $sc | Out-String -Width 1024 > .\$($web.Title)-$($list.Title)-fields.txt
                    }
                    #if $field.count < 1 it is a column from a Site Column
                    #TODO : Return to this in case it's an issue
                    foreach ($field in $fields)
                    {
                        Write-Host "Found: $($field.Title) in list $($list.Title)" 
                        $outObject = new-object PSObject                        $outObject | add-member -membertype NoteProperty -name "ColumnType" -Value "List Column"                        $outObject | add-member -membertype NoteProperty -name "FieldTypeClass" -Value $field.FieldTypeDefinition.FieldTypeClass                        $outObject | add-member -membertype NoteProperty -name "Site" -Value $list.ParentWeb.Site.Url                        $outObject | add-member -membertype NoteProperty -name "Web" -Value $list.ParentWeb.Title                        $outObject | add-member -membertype NoteProperty -name "List" -Value $list.Title                        $outObject | add-member -membertype NoteProperty -name "Column" -Value $field.Title                        $outObject | add-member -membertype NoteProperty -name "Url" -Value $list.DefaultViewUrl                                 $global:resultsarray += $outObject
                    }
                }
            }
            catch 
            {
                Write-Host "Caught an exception accessing list: $($list.Title) ($($web.Url))" -ForegroundColor Yellow
                Write-Host "Exception Type: $($_.Exception.GetType().FullName)" -ForegroundColor Red
                Write-Host "Exception Message: $($_.Exception.Message)" -ForegroundColor Red
                 
                $outObject = new-object PSObject                $outObject | add-member -membertype NoteProperty -name "ColumnType" -Value "ERROR"                $outObject | add-member -membertype NoteProperty -name "FieldTypeClass" -Value $_.Exception.Message                $outObject | add-member -membertype NoteProperty -name "Site" -Value $list.ParentWeb.Site.Url                $outObject | add-member -membertype NoteProperty -name "Web" -Value $list.ParentWeb.Title                $outObject | add-member -membertype NoteProperty -name "List" -Value $list.Title                $outObject | add-member -membertype NoteProperty -name "Column" -Value ""                $outObject | add-member -membertype NoteProperty -name "Url" -Value $list.DefaultViewUrl
                $global:resultsarray += $outObject
            }
        }
    }
    catch
    {
        Write-Host "Caught an exception accessing: $($web.Title) ($($web.Url))" -ForegroundColor Yellow
        Write-Host "Exception Type: $($_.Exception.GetType().FullName)" -ForegroundColor Red

        $outObject = new-object PSObject        $outObject | add-member -membertype NoteProperty -name "ColumnType" -Value "Error"        $outObject | add-member -membertype NoteProperty -name "FieldTypeClass" -Value ""        $outObject | add-member -membertype NoteProperty -name "Site" -Value $list.ParentWeb.Site.Url        $outObject | add-member -membertype NoteProperty -name "Web" -Value $list.ParentWeb.Title        $outObject | add-member -membertype NoteProperty -name "List" -Value $list.Title        $outObject | add-member -membertype NoteProperty -name "Column" -Value $field.Title        $outObject | add-member -membertype NoteProperty -name "Url" -Value $list.DefaultViewUrl
        $global:resultsarray += $outObject
    }

    # Use recursion to loop through all subwebs.    foreach ($subweb in $web.Webs)    {        Get-CustomColumns($subweb)    }

}

$WebApplications = Get-SPWebApplication #make an optional param
foreach($webApp in $WebApplications){    Write-Host "Checking Web App: $($webApp.DisplayName) $($webApp.Url)"    foreach($spsite in $webApp.Sites)    {        if ($spsite.AllWebs.Count -gt 50){            Write-Host "Skipping $($spsite.Url)"            Continue        }        if ($spsite.Url.Contains("SiteColumns")){            Write-Host "Checking $($spsite.Url)"                    }        if ((Get-SPSite $spsite.url -ErrorAction SilentlyContinue) -ne $null)         {            try            {                Get-CustomColumns($spsite.RootWeb)            }            catch            {                Write-Host "Caught an exception accessing site: $($spsite.RootWeb.Title) ($($spsite.Url))" -ForegroundColor Yellow
                #Write-Host "Exception Type: $($_.Exception.GetType().FullName)" -ForegroundColor Red
                Write-Host "Exception Message: $($_.Exception.Message)" -ForegroundColor Red            }        }    }}

$resultsarray | Export-csv $fileName -notypeinformation#New-Alias -Name Notepad -Value 'C:\Program Files (x86)\Notepad++\notepad++.exe' -ErrorAction SilentlyContinueNotepad $fileName


#<Field Name="FieldTypeClass">Dev4Side.SP2010.FilteredLookup.FilteredLookupField, Dev4Side.SP2010.FilteredLookup, Version=1.0.0.0, Culture=neutral, PublicKeyToken=af31a3eeecf7add1</Field>