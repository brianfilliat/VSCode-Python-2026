$outputDir = "D:\DOCU-2026"
$date      = Get-Date -Format "yyyy-MM-dd"
$baseName  = "SAN_Centene_Breakdown"

$targets = @(
    "D:\DOCU-2026\_SAN",
    "D:\DOCU-2026\Centene_documents_2021"
)

# --- Resolve available XLSX path ---
function Get-AvailableXlsxPath {
    $path = Join-Path $outputDir "${baseName}.xlsx"
    if (Test-Path $path) {
        try {
            $s = [System.IO.File]::Open($path, 'Open', 'ReadWrite', 'None')
            $s.Close()
            return $path
        } catch {
            $v = 1
            do { $path = Join-Path $outputDir "${baseName}_${date}_v${v}.xlsx"; $v++ } while (Test-Path $path)
        }
    }
    return $path
}

if (-not (Get-Module -ListAvailable -Name ImportExcel)) {
    Write-Host "Installing ImportExcel..." -ForegroundColor Yellow
    Install-Module -Name ImportExcel -Scope CurrentUser -Force -ErrorAction Stop
}
Import-Module ImportExcel

$xlsxPath = Get-AvailableXlsxPath
Write-Host "Saving to: $xlsxPath" -ForegroundColor Cyan

foreach ($targetPath in $targets) {
    $parentName = Split-Path $targetPath -Leaf
    Write-Host "Scanning $parentName ..." -ForegroundColor Cyan

    $rows = @()

    # Top-level subfolders
    $subDirs = Get-ChildItem -Path $targetPath -Directory -Force -ErrorAction SilentlyContinue

    foreach ($dir in $subDirs) {
        $files   = Get-ChildItem -Path $dir.FullName -Recurse -Force -File -ErrorAction SilentlyContinue
        $bytes   = ($files | Measure-Object -Property Length -Sum).Sum
        $sizeGB  = if ($bytes) { [math]::Round($bytes / 1GB, 2) } else { 0 }
        $sizeMB  = if ($bytes) { [math]::Round($bytes / 1MB, 0) } else { 0 }
        $count   = if ($files) { $files.Count } else { 0 }

        $rows += [PSCustomObject]@{
            Level       = "Subfolder"
            Name        = $dir.Name
            "Size (GB)" = $sizeGB
            "Size (MB)" = $sizeMB
            FileCount   = $count
            FullPath    = $dir.FullName
        }
    }

    # Loose files directly in root of target
    $rootFiles = Get-ChildItem -Path $targetPath -Force -File -ErrorAction SilentlyContinue
    if ($rootFiles) {
        $rootBytes = ($rootFiles | Measure-Object -Property Length -Sum).Sum
        $rows += [PSCustomObject]@{
            Level       = "Root Files"
            Name        = "(files in root)"
            "Size (GB)" = [math]::Round($rootBytes / 1GB, 2)
            "Size (MB)" = [math]::Round($rootBytes / 1MB, 0)
            FileCount   = $rootFiles.Count
            FullPath    = $targetPath
        }
    }

    $rows = $rows | Sort-Object "Size (GB)" -Descending

    # Sheet name max 31 chars
    $sheetName = $parentName.Substring(0, [math]::Min($parentName.Length, 31))

    $rows | Export-Excel -Path $xlsxPath -WorksheetName $sheetName -AutoSize -FreezeTopRow -BoldTopRow -TableName ($sheetName -replace '\W','_') -Append
    Write-Host "  -> $($rows.Count) rows written to sheet '$sheetName'" -ForegroundColor Green
}

Write-Host "`nDone. Breakdown saved to: $xlsxPath" -ForegroundColor Green
