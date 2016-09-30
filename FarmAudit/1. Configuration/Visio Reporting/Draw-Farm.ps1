#Add the SharePoint PowerShell Snap-In
Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue 
#Add the Visio module from https://github.com/saveenr
Import-Module Visio -ErrorAction SilentlyContinue

$ErrorActionPreference = "Continue"

cls

function Draw-Webapps($webapp, $parent){    #$web = Get-SPWeb $url    Write-Host "Drawing Webapp..." -ForegroundColor Gray        Write-Host "Drawing Web Application at: $($webapp.Url)" -ForegroundColor Green

    #$masHome = Get-VisioMaster "Home" $web_shapes
    $webappparent = New-VisioShape $master 1,1 
    Set-VisioShapeText $webapp.Url
    New-VisioConnection -From $parent -To $webappparent | Out-Null
    #New-VisioHyperlink -Address $web.Url -Shapes $parent    foreach ($cdb in $webapp.ContentDatabases)
    { 
        #if ($depth -eq $maxdepth) {return}
        Write-Host "Drawing Content DB : $($cdb.Name)" -ForegroundColor Green
        #Shapes if isAppWeb
        
        
        $shpcdb = New-VisioShape -Masters $master -Points 4,4 -NoSelect
        Set-VisioShapeText $cdb.Name -Shapes @($shpcdb)
        
        New-VisioConnection -From $webappparent -To $shpcdb | Out-Null
        
        #Enumerate and Draw the Site Collectios for the Content DB
        Draw-SiteCollections $cdb $shpcdb

        
    }}function Draw-SiteCollections($contentdb, $parent){    Write-Host "SPSite"    foreach ($spsite in $contentdb.Sites)
    { 
        #The RootWeb has some of the properties we need
        $web = $spsite.RootWeb
        Write-Host "Drawing Site at: $($web.Url)" -ForegroundColor Green
        
        #Add a shape for the Site Collection
        $shpSite = New-VisioShape -Masters $master -Points 4,4 
        
        if (!$web.Title) {
            $title = $web.Url
        }else{
            $title = $web.Title
        }

        #Set the Shape Text
        Set-VisioShapeText $title -Shapes @($shpSite)
        #Get a few Custom Properties
        Set-VisioCustomProperty -Name "CompatibilityLevel" -Label "Compatibility Level" -Value $spsite.CompatibilityLevel
        Set-VisioCustomProperty -Name "Owner" -Label "Owner" -Value $spsite.Owner.DisplayName 
        Set-VisioCustomProperty -Name "OwnerEmail" -Label "Owner Email" -Value $spsite.Owner.Email 
        Set-VisioCustomProperty -Name "AllWebsCount" -Label "Subsites" -Value $spsite.AllWebs.Count 
        #Flag the Site Collection if it is not ready for upgrade
        if ($spsite.CompatibilityLevel -ne "15")
        {
            #Set the shape to red to flag issue with site
            Set-VisioShapeCell -Hashtable @{"Fillforegnd"="THEMEGUARD(RGB(255,0,0))"}
        }
        
        if ($spsite.AllWebs.Count -gt "50")
        {
            #Set the shape to red to flag issue with site
            Set-VisioShapeCell -Hashtable @{"FillPattern"="2";"Fillforegnd"="THEMEGUARD(THEMEVAL(`"AccentColor`"))";"Fillbkgnd"="THEMEGUARD(RGB(255,255,255))"}
        }

        #Create a Hypelink to the Site Collection
        New-VisioHyperlink -Address $web.Url -Shapes $shpSite
        #Connet the Shape to the Parent Content DB
        New-VisioConnection -From $parent -To $shpSite | Out-Null
        
    }}$spfarm = Get-SPFarmNew-VisioApplicationNew-VisioDocument | Out-Null$basic_u = Open-VisioDocument basic_u.vss$master = Get-VisioMaster "Rectangle" $basic_u#$masHome = Get-VisioMaster "Home" $web_shapes
$parent = New-VisioShape $master 1,1
Set-VisioShapeText "Farm"
        Write-Host "Enumerating Web Applications..."
$webapps = Get-SPWebApplication -IncludeCentralAdministration
if ($webapps)
{
    Write-Host "This script will enumerate $($webapps.Count) web applications. Press [Enter] to continue [X] to abort."    $continue = Read-Host    if ($continue -ne "x")
    {
        foreach ($webapp in $webapps)
        {
            Draw-webapps $webapp $parent    
        }
        
    }
}