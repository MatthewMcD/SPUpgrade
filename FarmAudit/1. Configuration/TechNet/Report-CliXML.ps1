#Import and Report
$aams = Import-Clixml .\Get-SPAlternateURL.xml

$aams
$aams | Ft
$aams | %{$_.Collection.DisplayName}