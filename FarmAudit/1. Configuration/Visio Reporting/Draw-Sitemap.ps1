#Add the SharePoint PowerShell Snap-In
Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue 
Import-Module Visio -ErrorAction SilentlyContinue

cls

#Templates: C:\Program Files (x86)\Microsoft Office\Office15\Visio Content\1033

function Draw-SubSites($web, $parent){    #$web = Get-SPWeb $url    Write-Host "Drawing Sites for $url" -ForegroundColor Gray    if (!$parent)
    {
        Write-Host "Drawing root site at: $($web.Url)" -ForegroundColor Green

        $masHome = Get-VisioMaster "Home" $web_shapes
        $parent = New-VisioShape $masHome 1,1
        Set-VisioShapeText $web.Title
        New-VisioHyperlink -Address $web.Url -Shapes $parent
        
    }        foreach ($subweb in $web.Webs)
    { 
        #if ($depth -eq $maxdepth) {return}
        Write-Host "Drawing Subsite at: $($subweb.Url)" -ForegroundColor Green
        #Shapes if isAppWeb
        #$ac = Start-SPAssignment
        
        $shpweb = New-VisioShape -Masters $masWeb -Points 4,4 -NoSelect
        Set-VisioShapeText $subweb.Title -Shapes @($shpweb)
        New-VisioHyperlink -Address $subweb.Url -Shapes $shpweb

        New-VisioConnection -From $parent -To $shpweb | Out-Null
        
        #Stop-SPAssignment $ac
        Draw-SubSites $subweb $shpweb
    }}$siteurl = "http://intranet.doghousetoys.com"New-VisioApplication#$web_shapes = $doc.Application.Documents.Add("WEBSIT_U.VSTX")New-VisioDocument$web_shapes = Open-VisioDocument WEBSIT_U.VSSX#$web_shapes = Open-VisioDocument "WEBSIT_U.VSTX"#$newdoc = Get-VisioDocument -ActiveDocument$masWeb = Get-VisioMaster "Web page" $web_shapes#$masWeb = Get-VisioMaster "Web page" $newdocWrite-Host "Creating Sites..."
$site = Get-SPSite $siteurl -ErrorAction SilentlyContinue
if ($site)
{
    Write-Host "This script will enumerate $($site.AllWebs.Count) subsites. Press [Enter] to continue [X] to abort."    $continue = Read-Host    if ($continue -ne "x")
    {
        Draw-SubSites $site.RootWeb $null
    }
}