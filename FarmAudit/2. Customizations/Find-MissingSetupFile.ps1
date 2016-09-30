#http://get-spscripts.com/2011/06/diagnosing-missingsetupfile-issues-from.html
function Run-SQLQuery ($SqlServer, $SqlDatabase, $SqlQuery)
{
    $SqlConnection = New-Object System.Data.SqlClient.SqlConnection
    $SqlConnection.ConnectionString = "Server =" + $SqlServer + "; Database =" + $SqlDatabase + "; Integrated Security = True"
    $SqlCmd = New-Object System.Data.SqlClient.SqlCommand
    $SqlCmd.CommandText = $SqlQuery
    $SqlCmd.Connection = $SqlConnection
    $SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
    $SqlAdapter.SelectCommand = $SqlCmd
    $DataSet = New-Object System.Data.DataSet
    $SqlAdapter.Fill($DataSet) | Out-Null
    $SqlConnection.Close()
    $DataSet.Tables[0]
}

$SetupPath=""
Run-SQLQuery -SqlServer "SHELTIE" -SqlDatabase "SharePoint_2013_Content_Intranet" -SqlQuery "SELECT * from AllDocs where SetupPath = '$($SetupPath)'" | select Id, SiteId, DirName, LeafName, WebId, ListId | Format-List

$site = Get-SPSite -Limit all | where { $_.Id -eq "7b4d043c-8bbe-4068-ad91-3c270dfae151" }
$web = $site | Get-SPWeb -Limit all | where { $_.Id -eq "1876be06-419f-46fb-a942-a15e510f1a70" }
$web.Url

$file = $web.GetFile([Guid]”f5fc66e7-920a-4b44-9e3d-3a5ab825093f”)
$file.ServerRelativeUrl
