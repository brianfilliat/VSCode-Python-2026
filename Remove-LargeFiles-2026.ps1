$targetPath = "D:\DOCU-2026"
$thresholdGB = 2

Write-Host "Scanning for files larger than $thresholdGB GB in $targetPath..." -ForegroundColor Cyan

$largeFiles = Get-ChildItem -Path $targetPath -Recurse -Force -File -ErrorAction SilentlyContinue |
    Where-Object { $_.Length -gt ($thresholdGB * 1GB) }

if (-not $largeFiles) {
    Write-Host "No files larger than $thresholdGB GB found." -ForegroundColor Green
    exit
}

Write-Host "`nFiles to be deleted:" -ForegroundColor Yellow
$largeFiles | ForEach-Object {
    $sizeGB = [math]::Round($_.Length / 1GB, 2)
    Write-Host "  [$sizeGB GB] $($_.FullName)" -ForegroundColor Red
}

$totalSizeGB = [math]::Round(($largeFiles | Measure-Object -Property Length -Sum).Sum / 1GB, 2)
Write-Host "`nTotal: $($largeFiles.Count) file(s) | $totalSizeGB GB will be freed" -ForegroundColor Yellow

$confirm = Read-Host "`nProceed with deletion? (yes/no)"
if ($confirm -ne "yes") {
    Write-Host "Aborted." -ForegroundColor Cyan
    exit
}

$largeFiles | ForEach-Object {
    try {
        Remove-Item -Path $_.FullName -Force
        Write-Host "Deleted: $($_.FullName)" -ForegroundColor Green
    } catch {
        Write-Host "Failed: $($_.FullName) — $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`nDone. $totalSizeGB GB freed." -ForegroundColor Green
