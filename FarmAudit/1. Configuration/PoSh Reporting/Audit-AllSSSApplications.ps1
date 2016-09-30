Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue

Clear-Host
$outfile = ".\logs\Audit-SecureStore.csv"
#Write the CSV header
"Application Name `tDisplay Name `tApp Type `tCredential Type `tUser Name `tPassword" > $outfile


$context = Get-SPServiceContext -Site http://greyhound:2013

$provider = New-Object Microsoft.Office.SecureStoreService.Server.SecureStoreProvider
$provider.Context = $context

$marshal = [System.Runtime.InteropServices.Marshal]

try
{
    $apps = $provider.GetTargetApplications()
    foreach ($app in $apps)
    {
       Write-Output "`n$($app.Name) - $($app.FriendlyName) - $($app.Type)"
        Write-Output "$('-'*80)"
        try
        {
            $username = ""
            $pword = ""
            $credType = ""

            $creds = $provider.GetCredentials($app.Name)
            foreach ($cred in $creds)
            {
                $ptr = $marshal::SecureStringToBSTR($cred.Credential)
                $str = $marshal::PtrToStringBSTR($ptr)

                #Write-Output "$($cred.CredentialType): $($str)"               
                if ($cred.CredentialType -eq "WindowsUserName"){
                    $username = $str
                    $credType = $cred.CredentialType
                }else{
                    $pword = $str
                }

            }

            $app.Name + "`t" + $app.FriendlyName +"`t" + $app.Type +"`t" + $credType +"`t" + $username +"`t" + $pword >> $outfile
        }
        catch
        {
            Write-Output "Error getting credentials! (Did you set the credentials?)"
        }
        Write-Output "$('-'*80)"
    }
}
catch
{
    Write-Output "Error getting Target Applications."
}

$marshal::ZeroFreeBSTR($ptr)