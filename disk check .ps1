
# =================================================
# SQL Server Disk Space Monitoring Script (DBA)
# =================================================

# 1?? SQL Servers (COMPUTER NAMES ONLY)
$Servers = @(
    "WIN-37S6JPOV8CK",
    "WIN-LKM0VU6OV40"
)

# 2?? Thresholds (Industry Standard)
$WarningThreshold  = 20   # %
$CriticalThreshold = 10   # %

# 3?? Report Path
$ReportPath = "C:\DBA\DiskSpaceReport.csv"

# 4?? Collect Disk Space Information
$DiskReport = foreach ($Server in $Servers) {

    Write-Host "Checking disk space on $Server" -ForegroundColor Cyan

    Invoke-Command -ComputerName $Server -ScriptBlock {

        Get-PSDrive -PSProvider FileSystem | ForEach-Object {

            $TotalGB = ($_.Free + $_.Used) / 1GB
            $FreeGB  = $_.Free / 1GB
            $FreePct = ($_.Free / ($_.Free + $_.Used)) * 100

            [PSCustomObject]@{
                ServerName  = $env:COMPUTERNAME
                Drive       = $_.Name
                TotalGB     = [math]::Round($TotalGB,2)
                FreeGB      = [math]::Round($FreeGB,2)
                FreePercent = [math]::Round($FreePct,2)
                Status      = if ($FreePct -lt $using:CriticalThreshold) {
                                  "CRITICAL"
                              }
                              elseif ($FreePct -lt $using:WarningThreshold) {
                                  "WARNING"
                              }
                              else {
                                  "OK"
                              }
            }
        }
    }
}

# 5?? Filter SQL-Relevant Drives (Adjust as Needed)
$SQLDrives = $DiskReport | Where-Object {
    $_.Drive -match "^[CDEFZ]$"
}

# 6?? Export CSV Report
$SQLDrives |
Select-Object ServerName, Drive, TotalGB, FreeGB, FreePercent, Status |
Export-Csv $ReportPath -NoTypeInformation

# 7?? Display Non-OK Disks
$SQLDrives |
Where-Object { $_.Status -ne "OK" } |
Sort-Object FreePercent |
Format-Table ServerName, Drive, FreeGB, FreePercent, Status -AutoSize

Write-Host "Disk space monitoring completed." -ForegroundColor Green
Write-Host "Report saved to: $ReportPath" -ForegroundColor Green
