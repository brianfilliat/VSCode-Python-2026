$targetPath = "D:\DOCU-2026"
$outputDir  = "D:\DOCU-2026"
$baseName   = "FolderSizes"
$date       = Get-Date -Format "yyyy-MM-dd"
$threshold  = 1GB   # folders >= 1 GB are considered "large"

# --- Resolve available XLSX path (detect lock, version increment) ---
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

# --- Install ImportExcel module if missing ---
if (-not (Get-Module -ListAvailable -Name ImportExcel)) {
    Write-Host "Installing ImportExcel module..." -ForegroundColor Yellow
    Install-Module -Name ImportExcel -Scope CurrentUser -Force -ErrorAction Stop
}
Import-Module ImportExcel

$xlsxPath = Get-AvailableXlsxPath
Write-Host "Saving to: $xlsxPath" -ForegroundColor Cyan

# --- Sheet 1: Summary of ALL folders ---
Write-Host "Scanning folders..." -ForegroundColor Cyan
$summary = Get-ChildItem -Path $targetPath -Directory -Force | ForEach-Object {
    $files      = Get-ChildItem -Path $_.FullName -Recurse -Force -File -ErrorAction SilentlyContinue
    $totalBytes = ($files | Measure-Object -Property Length -Sum).Sum
    $sizeGB     = if ($totalBytes) { [math]::Round($totalBytes / 1GB, 2) } else { 0 }
    $fileCount  = if ($files) { $files.Count } else { 0 }
    [PSCustomObject]@{
        FolderName  = $_.Name
        "Size (GB)" = $sizeGB
        FileCount   = $fileCount
        FullPath    = $_.FullName
    }
} | Sort-Object "Size (GB)" -Descending

$summary | Export-Excel -Path $xlsxPath -WorksheetName "All Folders" -AutoSize -FreezeTopRow -BoldTopRow -TableName "AllFolders"

# --- Sheet 2: Large folders (>= 1GB) with subfolder breakdown ---
$largeRows = @()
$summary | Where-Object { $_."Size (GB)" -ge [math]::Round($threshold / 1GB, 2) } | ForEach-Object {
    $parentName = $_.FolderName
    $parentPath = $_.FullPath

    # Add parent row header
    $largeRows += [PSCustomObject]@{
        Type        = "PARENT"
        FolderName  = $parentName
        SubFolder   = ""
        "Size (GB)" = $_."Size (GB)"
        FileCount   = $_.FileCount
        FullPath    = $parentPath
    }

    # Add each immediate subfolder as breakdown
    Get-ChildItem -Path $parentPath -Directory -Force -ErrorAction SilentlyContinue | ForEach-Object {
        $subFiles = Get-ChildItem -Path $_.FullName -Recurse -Force -File -ErrorAction SilentlyContinue
        $subBytes = ($subFiles | Measure-Object -Property Length -Sum).Sum
        $subGB    = if ($subBytes) { [math]::Round($subBytes / 1GB, 2) } else { 0 }
        $largeRows += [PSCustomObject]@{
            Type        = "  subfolder"
            FolderName  = $parentName
            SubFolder   = $_.Name
            "Size (GB)" = $subGB
            FileCount   = if ($subFiles) { $subFiles.Count } else { 0 }
            FullPath    = $_.FullName
        }
    }
}

$largeRows | Export-Excel -Path $xlsxPath -WorksheetName "Large Folders Breakdown" -AutoSize -FreezeTopRow -BoldTopRow -TableName "LargeFolders" -Append

Write-Host "Done. Report saved to: $xlsxPath" -ForegroundColor Green
