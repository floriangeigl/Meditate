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

# MTP copy flags: FOF_SILENT | FOF_NOCONFIRMATION | FOF_NOCONFIRMMKDIR | FOF_NOERRORUI
$fof = 0x4 -bor 0x10 -bor 0x200 -bor 0x400

# Descriptions shown per file during restore confirmation
$fileDescriptions = @{
    '.SET' = 'app settings (values configured via Garmin Connect / Garmin Express)'
    '.DAT' = 'app storage data (saved sessions, state, analytics queue)'
    '.IDX' = 'data store index (paired with .DAT - needed for data integrity)'
    '.IMT' = 'install metadata (CIQ runtime app version info)'
}

function Confirm-AndRestoreFile {
    param(
        [Parameter(Mandatory)][System.IO.FileInfo]$LocalFile,
        [Parameter(Mandatory)][__ComObject]$DestMtpFolder,
        [Parameter(Mandatory)][int]$Fof
    )
    $ext  = [IO.Path]::GetExtension($LocalFile.Name).ToUpper()
    $desc = if ($fileDescriptions.ContainsKey($ext)) { $fileDescriptions[$ext] } else { 'unknown file type' }
    Write-Host ""
    Write-Host "  $($LocalFile.Name)"
    Write-Host "  $desc"
    $ans = Read-Host "  Restore? [Y/n]"
    if ($ans -in @('n','N','no','No')) {
        Write-Host "  Skipped."
        return $false
    }
    $DestMtpFolder.CopyHere($LocalFile.FullName, $Fof)
    Start-Sleep -Milliseconds 300
    Write-Host "  Restored."
    return $true
}

# -- Restore Data -----------------------------------------------------------
$localDataDir = Join-Path $selectedBackup.FullName 'Apps_DATA'
if (Test-Path $localDataDir) {
    $dataFolder = Get-ChildFolder -ParentFolder $appsFolder -NamePatterns @('Data','DATA')
    if (-not $dataFolder) {
        $appsFolder.NewFolder('DATA') | Out-Null
        Start-Sleep -Milliseconds 500
        $dataFolder = Get-ChildFolder -ParentFolder $appsFolder -NamePatterns @('Data','DATA')
    }
    if (-not $dataFolder) { throw "Couldn't create/find GARMIN/Apps/DATA folder." }

    $restoredData = 0
    foreach ($item in (Get-ChildItem -Path $localDataDir -File)) {
        if (Confirm-AndRestoreFile -LocalFile $item -DestMtpFolder $dataFolder -Fof $fof) {
            $restoredData++
        }
    }
    Write-Host ""
    Write-Host "[OK] App data: $restoredData file(s) restored."
} else {
    Write-Host "[INFO] No Apps_DATA folder in this backup - skipping."
}

# -- Restore Settings ------------------------------------------------------
$localSettingsDir = Join-Path $selectedBackup.FullName 'Apps_SETTINGS'
if (Test-Path $localSettingsDir) {
    $settingsFolder = Get-ChildFolder -ParentFolder $appsFolder -NamePatterns @('SETTINGS','Settings','settings')
    if (-not $settingsFolder) {
        $appsFolder.NewFolder('SETTINGS') | Out-Null
        Start-Sleep -Milliseconds 500
        $settingsFolder = Get-ChildFolder -ParentFolder $appsFolder -NamePatterns @('SETTINGS','Settings','settings')
    }
    if (-not $settingsFolder) { throw "Couldn't create/find GARMIN/Apps/SETTINGS folder." }

    $restoredSettings = 0
    foreach ($item in (Get-ChildItem -Path $localSettingsDir -File)) {
        if (Confirm-AndRestoreFile -LocalFile $item -DestMtpFolder $settingsFolder -Fof $fof) {
            $restoredSettings++
        }
    }
    Write-Host ""
    Write-Host "[OK] App settings: $restoredSettings file(s) restored."
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
