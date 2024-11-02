$CurrentDateFormat1 = Get-Date -Format "yyyyMMdd"
$CSVExportPath = "StorageReport-Exported_" + $CurrentDateFormat1 + ".temp"
$CorrectedCSVExportPath = "StorageReport-Exported_" + $CurrentDateFormat1 + ".csv"
$ListofServers = "ListofServers.txt"
$FullListofShares = "ListofShares.txt"

# Clear the content of the full list of shares file if it exists
If (Test-Path $FullListofShares) {
    Clear-Content $FullListofShares
}

# Check if the list of servers file exists
If (Test-Path $ListofServers) {
    # Read the list of servers and process each one
    Get-Content $ListofServers | ForEach-Object {
        $Serverpath = "\\" + $_
        try {
            # Get the list of shares from the server
            $shares = net view $Serverpath /all | select -Skip 7 | ?{$_ -match 'disk*'} | %{$_ -match '^(.+?)\s+Disk*' | out-null; $matches[1]}
            $ServerOutput = "ListofShares-" + $_ + ".txt"
            $shares | Out-File -FilePath $ServerOutput -Encoding ASCII -Append

            # Process each share
            Get-Content $ServerOutput | ForEach-Object {
                $Servershares = $Serverpath + "\" + $_
                IF (!($Servershares.Contains("$"))) {
                    $Servershares | Out-File -FilePath $FullListofShares -Encoding ASCII -Append
                }
            }
        } catch {
            Write-Error "Failed to process server: $_. Error: $_"
        } finally {
            # Clean up temporary server output file
            Remove-Item $ServerOutput -ErrorAction SilentlyContinue
        }
    }

    # Process the full list of shares
    Get-Content $FullListofShares | ForEach-Object {
        try {
            New-PSDrive -Name I -PSProvider FileSystem -Root $_ -Persist
            # Write-Output ('Free (GB): {0:N2} GB' -f ((Get-PSDrive -Name I).Free / 1GB))
        } catch {
            Write-Error "Failed to create PSDrive for share: $_. Error: $_"
        } finally {
            Remove-PSDrive -Name I -Force -ErrorAction SilentlyContinue
        }
    } | Select-Object -Property DisplayRoot, Used, Free | Export-Csv $CSVExportPath -NoTypeInformation

    # Clean up the CSV file
    Get-Content $CSVExportPath | ? { $_.trim() -ne ",," } | Set-Content $CorrectedCSVExportPath
    Remove-Item $CSVExportPath
} else {
    Write-Error "List of servers file not found: $ListofServers"
}
