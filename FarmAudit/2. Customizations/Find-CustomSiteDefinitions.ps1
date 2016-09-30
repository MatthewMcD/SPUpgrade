#Add the SharePoint PowerShell Snap-In
Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue 

function Get-InstalledSiteDefinitions {  
    param (
        [int] $lang = 1033
    )

    if ($lang -eq $NULL) { 
        $lang = 1033; 
    }

    $path = [Microsoft.SharePoint.Utilities.SPUtility]::GetGenericSetupPath("TEMPLATE\" + $lang + "\XML\WebTemp*.xml");
    if (Test-Path $path) {
        Get-ChildItem $path | foreach {
            [xml]$xml = Get-Content $_.FullName
            foreach ($template in $xml.SelectNodes('//Templates/Template'))
            {
                Write-Host "Found: $($template.Name) ($($template.ID))"    
            }
       }
    }
}

Get-InstalledSiteDefinitions 1033
