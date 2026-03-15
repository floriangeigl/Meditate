<#
Restore a previously backed-up Meditate settings/data snapshot to the watch.

The script scans the backup/ folder, groups backups by date, and walks you
through a two-step selection: first pick a date, then pick a specific backup
from that date (sorted oldest-first).

USAGE:
  # default (searches for *fenix*)
  powershell -NoProfile -ExecutionPolicy Bypass -File .\RestoreSettingsToDevice.ps1

  # override device name
  powershell -NoProfile -ExecutionPolicy Bypass -File .\RestoreSettingsToDevice.ps1 "fenix 8 - 47mm"
#>

[CmdletBinding()]
param(
    [Parameter(Position=0)]
    [string]$DeviceName = 'fenix'
)

$ErrorActionPreference = 'Stop'

# --- Settings ---------------------------------------------------------------
$backupRoot = Join-Path $PSScriptRoot 'backup'
# ----------------------------------------------------------------------------

# -- List available backups and let the user pick ---------------------------
if (-not (Test-Path $backupRoot)) {
    throw "No backup folder found at: $backupRoot"
}

# All backup folders, sorted oldest-first (name starts with yyyy-MM-dd_HHmmss)
$allBackups = @(Get-ChildItem -Path $backupRoot -Directory | Sort-Object Name)

if ($allBackups.Count -eq 0) {
    throw "No backups found in: $backupRoot"
}

# Extract the date part (yyyy-MM-dd) from each folder name and group
$dateGroups = [ordered]@{}
foreach ($b in $allBackups) {
    if ($b.Name -match '^\d{4}-\d{2}-\d{2}') {
        $dateKey = $Matches[0]
    } else {
        $dateKey = 'unknown'
    }
    if (-not $dateGroups.Contains($dateKey)) {
        $dateGroups[$dateKey] = [System.Collections.Generic.List[System.IO.DirectoryInfo]]::new()
    }
    $dateGroups[$dateKey].Add($b)
}

# -- Step 1: pick a date ---------------------------------------------------
$dateKeys = @($dateGroups.Keys)

Write-Host ""
Write-Host "Available backup dates:"
Write-Host "--------------------------------------------------"
for ($i = 0; $i -lt $dateKeys.Count; $i++) {
    $dk = $dateKeys[$i]
    # Show as dd.MM.yyyy for readability, plus backup count
    $displayDate = if ($dk -match '(\d{4})-(\d{2})-(\d{2})') { "$($Matches[3]).$($Matches[2]).$($Matches[1])" } else { $dk }
    $count = $dateGroups[$dk].Count
    Write-Host ("  [{0}]  {1}  ({2} backup{3})" -f ($i + 1), $displayDate, $count, $(if ($count -ne 1) { 's' } else { '' }))
}
Write-Host "--------------------------------------------------"
Write-Host ""

do {
    $dateInput = Read-Host "Select date (1-$($dateKeys.Count)), or 'q' to quit"
    if ($dateInput -eq 'q') { Write-Host "Aborted."; exit 0 }
    $dateChoice = $dateInput -as [int]
} while (-not $dateChoice -or $dateChoice -lt 1 -or $dateChoice -gt $dateKeys.Count)

$selectedDate = $dateKeys[$dateChoice - 1]
$dayBackups = @($dateGroups[$selectedDate])   # already sorted oldest-first

# -- Step 2: pick a backup from that date ----------------------------------
if ($dayBackups.Count -eq 1) {
    $selectedBackup = $dayBackups[0]
    Write-Host ""
    Write-Host "Only one backup on this date - auto-selected: $($selectedBackup.Name)"
    Write-Host ""
} else {
    $displaySelectedDate = if ($selectedDate -match '(\d{4})-(\d{2})-(\d{2})') { "$($Matches[3]).$($Matches[2]).$($Matches[1])" } else { $selectedDate }
    Write-Host ""
    Write-Host "Backups on $displaySelectedDate (oldest first):"
    Write-Host "--------------------------------------------------"
    for ($i = 0; $i -lt $dayBackups.Count; $i++) {
        $b = $dayBackups[$i]
        $hasData     = Test-Path (Join-Path $b.FullName 'Apps_DATA')
        $hasSettings = Test-Path (Join-Path $b.FullName 'Apps_SETTINGS')
        $contents = @()
        if ($hasData)     { $contents += 'Data' }
        if ($hasSettings) { $contents += 'Settings' }
        $summary = if ($contents.Count -gt 0) { $contents -join ' + ' } else { '(empty?)' }

        # Show just the time portion for readability
        $timeDisplay = if ($b.Name -match '^\d{4}-\d{2}-\d{2}_(\d{2})(\d{2})(\d{2})') { "$($Matches[1]):$($Matches[2]):$($Matches[3])" } else { $b.Name }
        Write-Host ("  [{0}]  {1}  ({2})" -f ($i + 1), $timeDisplay, $summary)
    }
    Write-Host "--------------------------------------------------"
    Write-Host ""

    do {
        $backupInput = Read-Host "Select backup (1-$($dayBackups.Count)), or 'q' to quit"
        if ($backupInput -eq 'q') { Write-Host "Aborted."; exit 0 }
        $backupChoice = $backupInput -as [int]
    } while (-not $backupChoice -or $backupChoice -lt 1 -or $backupChoice -gt $dayBackups.Count)

    $selectedBackup = $dayBackups[$backupChoice - 1]
    Write-Host ""
    Write-Host "Selected: $($selectedBackup.Name)"
    Write-Host ""
}

# -- Connect to the watch via MTP -------------------------------------------
$shell      = New-Object -ComObject Shell.Application
$myComputer = $shell.Namespace(0x11)

function Get-ChildFolder {
    param(
        [Parameter(Mandatory)][__ComObject]$ParentFolder,
        [Parameter(Mandatory)][string[]]$NamePatterns
    )
    foreach ($item in $ParentFolder.Items()) {
        if (-not $item.IsFolder) { continue }
        foreach ($pat in $NamePatterns) {
            if ($item.Name -like $pat) { return $item.GetFolder() }
        }
    }
    return $null
}

$devicePattern = if ($DeviceName -match '\*') { $DeviceName } else { "*$DeviceName*" }

$deviceItem = $myComputer.Items() |
    Where-Object { $_.IsFolder -and $_.Name -like $devicePattern } |
    Select-Object -First 1

if (-not $deviceItem) {
    throw "Device matching '$devicePattern' not found under 'Dieser PC'. Connect/unlock the watch and try again."
}

$deviceFolder   = $deviceItem.GetFolder()
$internalFolder = Get-ChildFolder -ParentFolder $deviceFolder -NamePatterns @(
    'Internal Storage','Interner Speicher','*Internal*','*Interner*', 'Primary', '*Primary*'
)
if (-not $internalFolder) { throw "Couldn't find 'Internal Storage' on the device." }

$garminFolder = Get-ChildFolder -ParentFolder $internalFolder -NamePatterns @('GARMIN')
if (-not $garminFolder) { throw "Couldn't find GARMIN folder on the device." }

$appsFolder = Get-ChildFolder -ParentFolder $garminFolder -NamePatterns @('Apps','APPS')
if (-not $appsFolder) { throw "Couldn't find GARMIN/Apps folder on the device." }

# MTP copy flags: FOF_SILENT | FOF_NOCONFIRMATION | FOF_NOCONFIRMMKDIR
# Note: FOF_NOERRORUI (0x400) intentionally omitted so copy errors surface
$fof = 0x4 -bor 0x10 -bor 0x200

# Discover the short filename base for Meditate from GarminDevice.xml on the device.
# Identical to the function in CopyBuildToDevice.ps1.
function Get-AppShortId {
    param(
        [Parameter(Mandatory)][__ComObject]$GarminShellFolder,
        [Parameter(Mandatory)][string]$AppName
    )
    $xmlItem = $GarminShellFolder.ParseName('GarminDevice.xml')
    if (-not $xmlItem) { return $null }
    $tempDir  = Join-Path $env:TEMP "GarminDeviceXml_$([guid]::NewGuid().ToString('N').Substring(0,8))"
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
    $tempCopy = Join-Path $tempDir 'GarminDevice.xml'
    try {
        $tempFolder = (New-Object -ComObject Shell.Application).Namespace($tempDir)
        $tempFolder.CopyHere($xmlItem, 0x4 -bor 0x10 -bor 0x200 -bor 0x400)
        for ($w = 0; $w -lt 20 -and -not (Test-Path $tempCopy); $w++) { Start-Sleep -Milliseconds 250 }
        if (-not (Test-Path $tempCopy)) { return $null }
        $xmlContent = [IO.File]::ReadAllText($tempCopy)
        $pattern = "<AppName>$([regex]::Escape($AppName))</AppName>.*?<FileName>([^<]+)\.PRG</FileName>"
        if ($xmlContent -match $pattern) { return $Matches[1] }
        return $null
    } finally {
        if (Test-Path $tempDir) { Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue }
    }
}

# Infer the short ID that was current when the backup was taken, from the
# filenames of the backed-up files (e.g. G1HF1837.DAT -> G1HF1837).
function Get-BackupShortId {
    param([string]$BackupDir)
    $f = Get-ChildItem (Join-Path $BackupDir 'Apps_DATA') -Filter '*.DAT' -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $f) {
        $f = Get-ChildItem (Join-Path $BackupDir 'Apps_SETTINGS') -Filter '*.SET' -ErrorAction SilentlyContinue | Select-Object -First 1
    }
    if ($f) { return [IO.Path]::GetFileNameWithoutExtension($f.Name) }
    return $null
}

# Descriptions shown per file during restore confirmation
$fileDescriptions = @{
    '.SET' = 'app settings (values configured via Garmin Connect / Garmin Express)'
    '.DAT' = 'app storage data (saved sessions, state, analytics queue)'
    '.IDX' = 'data store index (paired with .DAT - needed for data integrity)'
    '.IMT' = 'install metadata (CIQ runtime app version info)'
}

# Copy a local file to an MTP destination folder, navigating fresh each time
# to avoid stale Shell.Application COM object references (same technique used
# in Copy-MtpItemToLocal for the backup direction).
function Copy-LocalFileToMtpFolder {
    param(
        [Parameter(Mandatory)][string]$LocalFilePath,
        [Parameter(Mandatory)][string[]]$MtpSubfolderPath   # e.g. @('GARMIN','Apps','DATA')
    )
    $fileName = [IO.Path]::GetFileName($LocalFilePath)
    # Fresh Shell instance - avoids stale folder reference after prior operations
    $sh = New-Object -ComObject Shell.Application
    $device = $sh.Namespace(0x11).Items() |
        Where-Object { $_.IsFolder -and $_.Name -like $devicePattern } |
        Select-Object -First 1
    if (-not $device) { throw "Device not found during restore copy." }
    $folder = $device.GetFolder()
    # Navigate to Internal Storage
    $internal = $null
    foreach ($item in $folder.Items()) {
        if ($item.IsFolder -and $item.Name -match 'Internal|Interner|Primary') {
            $internal = $item.GetFolder()
            break
        }
    }
    if (-not $internal) { throw "Internal Storage not found during restore copy." }
    $folder = $internal
    # Navigate the sub-path segments
    foreach ($seg in $MtpSubfolderPath) {
        $next = $folder.ParseName($seg)
        if (-not $next) { throw "MTP folder '$seg' not found during restore." }
        $folder = $next.GetFolder()
    }
    Write-Host "  Source : $LocalFilePath"
    Write-Host "  Target : Device\...\$($MtpSubfolderPath -join '\')\ "
    $folder.CopyHere($LocalFilePath, $fof)
    # Poll for arrival (CopyHere is async); re-query the folder each iteration
    for ($w = 0; $w -lt 30; $w++) {
        Start-Sleep -Milliseconds 500
        if ($folder.ParseName($fileName)) { return $true }
    }
    return $false
}

function Confirm-AndRestoreFile {
    param(
        [Parameter(Mandatory)][System.IO.FileInfo]$LocalFile,
        [Parameter(Mandatory)][string[]]$MtpSubfolderPath,
        [string]$TargetFileName = ''
    )
    if (-not $TargetFileName) { $TargetFileName = $LocalFile.Name }
    $ext  = [IO.Path]::GetExtension($TargetFileName).ToUpper()
    $desc = if ($fileDescriptions.ContainsKey($ext)) { $fileDescriptions[$ext] } else { 'unknown file type' }
    $nameDisplay = if ($TargetFileName -ne $LocalFile.Name) {
        "$($LocalFile.Name)  ->  $TargetFileName  (short ID renamed)"
    } else {
        $LocalFile.Name
    }
    Write-Host ""
    Write-Host "  $nameDisplay"
    Write-Host "  $desc"
    $ans = Read-Host "  Restore? [Y/n]"
    if ($ans -in @('n','N','no','No')) {
        Write-Host "  Skipped."
        return $false
    }
    # If a rename is required, create a temp copy with the target filename so
    # that CopyHere lands the file on the device under the correct name.
    $srcPath = $LocalFile.FullName
    $tempDir = $null
    if ($TargetFileName -ne $LocalFile.Name) {
        $tempDir = "$env:TEMP\MedRestore_$([guid]::NewGuid().ToString('N').Substring(0,8))"
        New-Item -ItemType Directory $tempDir -Force | Out-Null
        $srcPath = Join-Path $tempDir $TargetFileName
        Copy-Item -LiteralPath $LocalFile.FullName -Destination $srcPath
    }
    try {
        $ok = Copy-LocalFileToMtpFolder -LocalFilePath $srcPath -MtpSubfolderPath $MtpSubfolderPath
    } finally {
        if ($tempDir) { Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue }
    }
    if ($ok) {
        Write-Host "  [OK] Verified on device."
    } else {
        Write-Host "  [WARN] Copy sent but could not verify file arrived on device."
    }
    return $ok
}

# -- Determine short IDs (backup vs. current device) ----------------------
# The CIQ runtime assigns each app a short filename base (e.g. G3F85625).
# This ID can change across PRG deployments. When it does, backup files
# must be renamed to match the current ID so the app finds them.
$deviceShortId = Get-AppShortId -GarminShellFolder $garminFolder -AppName 'Meditate'
if (-not $deviceShortId) {
    throw "Could not read Meditate's current short ID from device GarminDevice.xml."
}

$backupShortId = Get-BackupShortId -BackupDir $selectedBackup.FullName

if ($backupShortId -and $backupShortId -ne $deviceShortId) {
    Write-Host ""
    Write-Host "[NOTE] App short ID changed since this backup was taken."
    Write-Host "       Backup ID : $backupShortId"
    Write-Host "       Device ID : $deviceShortId"
    Write-Host "       Files will be renamed during restore: $backupShortId.* -> $deviceShortId.*"
    Write-Host ""
}

# Helper: given a backup filename, return the name to use on the device
# (replaces the backup short ID with the current device short ID if needed).
function Get-TargetName {
    param([string]$SourceName)
    if ($backupShortId -and $backupShortId -ne $deviceShortId) {
        return $SourceName -replace [regex]::Escape($backupShortId), $deviceShortId
    }
    return $SourceName
}

# -- Restore Data -----------------------------------------------------------
$localDataDir = Join-Path $selectedBackup.FullName 'Apps_DATA'
if (Test-Path $localDataDir) {
    $dataFiles = @(Get-ChildItem -Path $localDataDir -File)
    if ($dataFiles.Count -eq 0) {
        Write-Host "[INFO] Apps_DATA backup folder is empty - skipping."
    } else {
        Write-Host "Data files in backup ($($dataFiles.Count)):"
        $dataFiles | ForEach-Object { Write-Host "  $($_.Name)  ($([math]::Round($_.Length/1KB, 1)) KB)" }
        $restoredData = 0
        foreach ($item in $dataFiles) {
            $targetName = Get-TargetName -SourceName $item.Name
            if (Confirm-AndRestoreFile -LocalFile $item -MtpSubfolderPath @('GARMIN', 'Apps', 'DATA') -TargetFileName $targetName) {
                $restoredData++
            }
        }
        Write-Host ""
        Write-Host "[OK] App data: $restoredData of $($dataFiles.Count) file(s) restored."
    }
} else {
    Write-Host "[INFO] No Apps_DATA folder in this backup - skipping."
}

# -- Restore Settings ------------------------------------------------------
$localSettingsDir = Join-Path $selectedBackup.FullName 'Apps_SETTINGS'
if (Test-Path $localSettingsDir) {
    $settingsFiles = @(Get-ChildItem -Path $localSettingsDir -File)
    if ($settingsFiles.Count -eq 0) {
        Write-Host "[INFO] Apps_SETTINGS backup folder is empty - skipping."
    } else {
        Write-Host "Settings files in backup ($($settingsFiles.Count)):"
        $settingsFiles | ForEach-Object { Write-Host "  $($_.Name)  ($([math]::Round($_.Length/1KB, 1)) KB)" }
        $restoredSettings = 0
        foreach ($item in $settingsFiles) {
            $targetName = Get-TargetName -SourceName $item.Name
            if (Confirm-AndRestoreFile -LocalFile $item -MtpSubfolderPath @('GARMIN', 'Apps', 'SETTINGS') -TargetFileName $targetName) {
                $restoredSettings++
            }
        }
        Write-Host ""
        Write-Host "[OK] App settings: $restoredSettings of $($settingsFiles.Count) file(s) restored."
    }
} else {
    Write-Host "[INFO] No Apps_SETTINGS folder in this backup - skipping."
}

# -- Clean up debug log artifacts --------------------------------------
# Remove the MEDITATE.TXT trigger file and accumulated log output.
# Only delete files related to this app, not other apps' logs.
$logsFolder = Get-ChildFolder -ParentFolder $appsFolder -NamePatterns @('LOGS','Logs','logs')
if ($logsFolder) {
    $appLogNames = @('MEDITATE.TXT', 'MEDITATE.BAK')
    $deleted = 0
    foreach ($logItem in $logsFolder.Items()) {
        if ($logItem.Name -in $appLogNames) {
            Write-Host "  Removing LOGS/$($logItem.Name) ..."
            $logItem.InvokeVerb('delete')
            Start-Sleep -Milliseconds 200
            $deleted++
        }
    }
    if ($deleted -gt 0) {
        Write-Host "[OK] Removed $deleted Meditate log file(s)."
    }
}

Write-Host ""
Write-Host "[DONE] Restore complete from: $($selectedBackup.Name)"
Write-Host "       Device: $($deviceItem.Name)"
Write-Host ""
Write-Host "IMPORTANT: Disconnect the watch from USB now."
Write-Host "           The app will load the restored data when you open it on the watch."
