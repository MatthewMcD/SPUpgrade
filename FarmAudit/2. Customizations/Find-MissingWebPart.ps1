#http://get-spscripts.com/2011/08/diagnose-missingwebpart-and.html

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


$wpGUID = 'ecf532ee-6fc9-4098-b03c-c396721a3313'
#Missing Web Part
Run-SQLQuery -SqlServer "SHELTIE" -SqlDatabase "SharePoint_2013_Content_Intranet" -SqlQuery "SELECT * from AllDocs inner join AllWebParts on AllDocs.Id = AllWebParts.tp_PageUrlID where AllWebParts.tp_WebPartTypeID = '$($wpGUID)'" | select Id, SiteId, DirName, LeafName, WebId, ListId, tp_ZoneID, tp_DisplayName | Format-List

$site = Get-SPSite -Limit all | where {$_.Id -eq "337c5721-5050-46ce-b112-083ac52f7f26"}
$site.Url

#http://portal/news/pages/articlelist.aspx?contents=1
#End Missing Web Part

#Missing Assembly
#Often Caused by missing EventHandlers
Run-SQLQuery -SqlServer "SQLSERVER" -SqlDatabase "SP2010_Content" -SqlQuery "SELECT * from EventReceivers where Assembly = ‘PAC.SharePoint.Tagging, Version=1.0.0.0, Culture=neutral, PublicKeyToken=b504d4b6c1e1a6e5'" | select Id, Name, SiteId, WebId, HostId, HostType | Format-List

$site = Get-SPSite -Limit all | where {$_.Id -eq "337c5721-5050-46ce-b112-083ac52f7f26"}
$web = $site | Get-SPWeb -Limit all | where {$_.Id -eq "2ae0de59-a008-4244-aa66-d8f76c79f1ad"}
$web.Url

$list = $web.Lists | where {$_.Id -eq "09308020-45a8-41e4-bbc0-7c8d8cd54132"}

$er = $list.EventReceivers | where {$_.Id -eq "657a472f-e51d-428c-ab98-502358d87612"}
$er.Delete()

#End Missing Assembly