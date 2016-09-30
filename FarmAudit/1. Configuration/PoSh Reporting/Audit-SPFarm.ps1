#Audit Farm

Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue
#Audit Farm
Clear-Host
$outfile = ".\Logs\Audit-Farm.csv"
$minBuild = "15.0.4481.1005"

#Write the CSV header
"Config DB `tBuild Version `tServers `tOutbound Email `tAuthentication Realm" > $outfile

$farm = Get-SPFarm
$authRealm = Get-SPAuthenticationRealm

$farm.Name + "`t" + $farm.BuildVersion + "`t" + $farm.Servers.Count + "`t" + $((Get-SPWebapplication)[0] | %{$_.outboundmailserviceinstance.server.Address}) + "`t" + $authRealm >> $outfile


$outfile = ".\logs\Audit-FarmServers.csv"
"Server `tRole `tStatus" > $outfile
#Web Application
foreach ($server in $farm.Servers)
{
    #WebApp URL, Content DB, Content DB Size, Site Collection Count, Site Limit
    $server.Name + "`t" + $server.Role +"`t" + $server.Status >> $outfile
}

