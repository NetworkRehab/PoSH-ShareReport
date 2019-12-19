$CurrentDateFormat1 = Get-Date -Format "yyyyMMdd"
$CSVExportPath = "StorageReport-Exported_" + $CurrentDateFormat1 + ".temp"
$CorrectedCSVExportPath = "StorageReport-Exported_" + $CurrentDateFormat1 + ".csv"
$ListofServers = "ListofServers.txt"
$FullListofShares = "ListofShares.txt"

If(Test-Path $FullListofShares){Clear-Content $FullListofShares}
If(Test-Path $ListofServers){
Get-Content $ListofServers | ForEach-Object {
$Serverpath = "\\" + $_
$shares = net view $Serverpath /all | select -Skip 7 | ?{$_ -match 'disk*'} | %{$_ -match '^(.+?)\s+Disk*'|out-null;$matches[1]}
#Write-Output $shares
$ServerOutput = "ListofShares-" + $_ + ".txt"
$shares | Out-File -FilePath $ServerOutput -Encoding ASCII -Append
    Get-Content $ServerOutput | ForEach-Object {
        $Servershares = $Serverpath + "\" + $_
        IF(!($Servershares.Contains("$"))){
            $Servershares | Out-File -FilePath $FullListofShares -Encoding ASCII -Append
        }
    }
    #Remove-Item $ServerOutput
}


Get-Content $FullListofShares | ForEach-Object {
    New-PSDrive -Name I -PSProvider FileSystem -Root $_ -Persist
    #Write-Output ('Free (GB): {0:N2} GB' -f ((Get-PSDrive -Name I).Free / 1GB))
    Remove-PSDrive -Name I -Force

} | Select-Object -Property DisplayRoot, Used, Free | Export-Csv $CSVExportPath -NoTypeInformation


Get-Content $CSVExportPath | ? {$_.trim() -ne ",," } | set-content $CorrectedCSVExportPath
Remove-Item $CSVExportPath

}
