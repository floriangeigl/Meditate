<#
Restore a previously backed-up Meditate settings/data snapshot to the watch.

The script scans the backup/ folder, lists available backups, and lets you
pick which one to push back to the device.

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
$appUuid    = '3A747E00-970F-4D64-A8D8-D02486B1D856'   # from manifest.xml
$backupRoot = Join-Path $PSScriptRoot 'backup'
# ----------------------------------------------------------------------------

# ── List available backups and let the user pick ───────────────────────────
if (-not (Test-Path $backupRoot)) {
    throw "No backup folder found at: $backupRoot"
}

$backups = Get-ChildItem -Path $backupRoot -Directory | Sort-Object Name -Descending

if ($backups.Count -eq 0) {
    throw "No backups found in: $backupRoot"
}

Write-Host ""
Write-Host "Available backups:"
Write-Host "──────────────────────────────────────────────────"
for ($i = 0; $i -lt $backups.Count; $i++) {
    $b = $backups[$i]
    # Show a quick summary of what's inside
    $hasData     = Test-Path (Join-Path $b.FullName "Apps\Data")
    $hasSettings = Test-Path (Join-Path $b.FullName "Apps\SETTINGS")
    $contents = @()
    if ($hasData)     { $contents += 'Data' }
    if ($hasSettings) { $contents += 'Settings' }
    $summary = if ($contents.Count -gt 0) { $contents -join ' + ' } else { '(empty?)' }

    Write-Host ("  [{0}]  {1}  ({2})" -f ($i + 1), $b.Name, $summary)
}
Write-Host "──────────────────────────────────────────────────"
Write-Host ""

do {
    $input = Read-Host "Enter the number of the backup to restore (1-$($backups.Count)), or 'q' to quit"
    if ($input -eq 'q') { Write-Host "Aborted."; exit 0 }
    $choice = $input -as [int]
} while (-not $choice -or $choice -lt 1 -or $choice -gt $backups.Count)

$selectedBackup = $backups[$choice - 1]
Write-Host ""
Write-Host "Selected: $($selectedBackup.Name)"
Write-Host ""

# ── Connect to the watch via MTP ───────────────────────────────────────────
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

# ── Restore Data ───────────────────────────────────────────────────────────
$localDataDir = Join-Path $selectedBackup.FullName "Apps\Data\$appUuid"
if (Test-Path $localDataDir) {
    # Ensure GARMIN/Apps/Data/<UUID> exists on the watch
    $dataFolder = Get-ChildFolder -ParentFolder $appsFolder -NamePatterns @('Data','DATA')
    if (-not $dataFolder) {
        $appsFolder.NewFolder('Data') | Out-Null
        Start-Sleep -Milliseconds 500
        $dataFolder = Get-ChildFolder -ParentFolder $appsFolder -NamePatterns @('Data','DATA')
    }
    if (-not $dataFolder) { throw "Couldn't create/find GARMIN/Apps/Data folder." }

    $uuidFolder = Get-ChildFolder -ParentFolder $dataFolder -NamePatterns @("*$appUuid*")
    if (-not $uuidFolder) {
        $dataFolder.NewFolder($appUuid) | Out-Null
        Start-Sleep -Milliseconds 500
        $uuidFolder = Get-ChildFolder -ParentFolder $dataFolder -NamePatterns @("*$appUuid*")
    }
    if (-not $uuidFolder) { throw "Couldn't create/find Data/$appUuid folder on device." }

    # Copy every file from the local backup into the UUID folder on the watch
    $filesToRestore = Get-ChildItem -Path $localDataDir -File -Recurse
    foreach ($f in $filesToRestore) {
        Write-Host "  Restoring Data: $($f.Name) ..."
        $uuidFolder.CopyHere($f.FullName, $fof)
        Start-Sleep -Milliseconds 300
    }
    Write-Host "[OK] App data restored."
} else {
    Write-Host "[INFO] No Data folder in this backup — skipping."
}

# ── Restore Settings ──────────────────────────────────────────────────────
$localSettingsDir = Join-Path $selectedBackup.FullName "Apps\SETTINGS"
if (Test-Path $localSettingsDir) {
    $settingsFolder = Get-ChildFolder -ParentFolder $appsFolder -NamePatterns @('SETTINGS','Settings','settings')
    if (-not $settingsFolder) {
        $appsFolder.NewFolder('SETTINGS') | Out-Null
        Start-Sleep -Milliseconds 500
        $settingsFolder = Get-ChildFolder -ParentFolder $appsFolder -NamePatterns @('SETTINGS','Settings','settings')
    }
    if (-not $settingsFolder) { throw "Couldn't create/find GARMIN/Apps/SETTINGS folder." }

    $filesToRestore = Get-ChildItem -Path $localSettingsDir -File
    foreach ($f in $filesToRestore) {
        Write-Host "  Restoring Settings: $($f.Name) ..."
        $settingsFolder.CopyHere($f.FullName, $fof)
        Start-Sleep -Milliseconds 300
    }
    Write-Host "[OK] App settings restored."
} else {
    Write-Host "[INFO] No SETTINGS folder in this backup — skipping."
}

Write-Host ""
Write-Host "[DONE] Restore complete from: $($selectedBackup.Name)"
Write-Host "       Device: $($deviceItem.Name)"
