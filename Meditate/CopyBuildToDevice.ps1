<#
Copy Meditate.prg to:
Dieser PC\<device>\Internal Storage\GARMIN\Apps\Meditate.prg

USAGE:
  # default (searches for *fenix*)
  powershell -NoProfile -ExecutionPolicy Bypass -File .\CopyBuildToDevice.ps1

  # override device name (wildcards ok; * added automatically if none present)
  powershell -NoProfile -ExecutionPolicy Bypass -File .\CopyBuildToDevice.ps1 "fenix 8 - 47mm"
  # or
  powershell -NoProfile -ExecutionPolicy Bypass -File .\CopyBuildToDevice.ps1 fenix
#>

[CmdletBinding()]
param(
    [Parameter(Position=0)]
    [string]$DeviceName = 'fenix'
)

$ErrorActionPreference = 'Stop'

# --- Settings ---------------------------------------------------------------
$sourceFile = Join-Path $PSScriptRoot 'bin\Meditate.prg'
$appUuid    = '3A747E00-970F-4D64-A8D8-D02486B1D856'   # from manifest.xml
$backupRoot = Join-Path $PSScriptRoot 'backup'
# ----------------------------------------------------------------------------

if (-not (Test-Path $sourceFile)) {
    throw "Source file not found: $sourceFile"
}

# Create Shell COM (needed for MTP paths like 'Dieser PC\…')
$shell      = New-Object -ComObject Shell.Application
$myComputer = $shell.Namespace(0x11)  # 'This PC' / 'Dieser PC' (CSIDL_DRIVES)

# Helper: get first child folder whose name matches any of the given patterns
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

# Build a wildcard pattern: if user didn't include * themselves, wrap with *...*
$devicePattern = if ($DeviceName -match '\*') { $DeviceName } else { "*$DeviceName*" }

# Find the device (under 'Dieser PC')
$deviceItem = $myComputer.Items() |
    Where-Object { $_.IsFolder -and $_.Name -like $devicePattern } |
    Select-Object -First 1

if (-not $deviceItem) {
    throw "Device matching '$devicePattern' not found under 'Dieser PC'. Connect/unlock the watch and try again."
}

$deviceFolder = $deviceItem.GetFolder()

# Navigate to Internal Storage (allow German/English wording)
$internalFolder = Get-ChildFolder -ParentFolder $deviceFolder -NamePatterns @(
    'Internal Storage','Interner Speicher','*Internal*','*Interner*', 'Primary', '*Primary*'
)
if (-not $internalFolder) {
    throw "Couldn't find 'Internal Storage' on the device."
}

# Ensure GARMIN and Apps exist (create if missing)
$garminFolder = Get-ChildFolder -ParentFolder $internalFolder -NamePatterns @('GARMIN')
if (-not $garminFolder) {
    $internalFolder.NewFolder('GARMIN') | Out-Null
    Start-Sleep -Milliseconds 300
    $garminFolder = Get-ChildFolder -ParentFolder $internalFolder -NamePatterns @('GARMIN')
}
if (-not $garminFolder) { throw "Couldn't create/find GARMIN folder." }

# ── Backup app settings / data from watch ──────────────────────────────────
# Garmin stores per-app data in:
#   GARMIN/Apps/Data/<UUID>/   (Object Store & files)
#   GARMIN/Apps/SETTINGS/<UUID>.SET  (property/settings blob)
# We copy anything that matches the app UUID into a timestamped backup folder.

function Copy-MtpItemToLocal {
    <#
    .SYNOPSIS  Copy a single MTP (Shell) item to a local directory,
               preserving the relative sub-path.
    #>
    param(
        [Parameter(Mandatory)][__ComObject]$ShellItem,
        [Parameter(Mandatory)][string]$DestDir
    )
    if (-not (Test-Path $DestDir)) { New-Item -ItemType Directory -Path $DestDir -Force | Out-Null }
    $tempShell = New-Object -ComObject Shell.Application
    $destFolder = $tempShell.Namespace($DestDir)
    $destFolder.CopyHere($ShellItem, 0x4 -bor 0x10 -bor 0x200 -bor 0x400)
}

function Copy-MtpFolderRecursive {
    <#
    .SYNOPSIS  Recursively copy every item from an MTP Shell folder
               into a local directory.
    #>
    param(
        [Parameter(Mandatory)][__ComObject]$ShellFolder,
        [Parameter(Mandatory)][string]$DestDir
    )
    foreach ($item in $ShellFolder.Items()) {
        if ($item.IsFolder) {
            $subDest = Join-Path $DestDir $item.Name
            Copy-MtpFolderRecursive -ShellFolder $item.GetFolder() -DestDir $subDest
        } else {
            Copy-MtpItemToLocal -ShellItem $item -DestDir $DestDir
        }
    }
}

$timestamp  = Get-Date -Format 'yyyy-MM-dd_HHmmss'
# Sanitise device name for use in a folder name (remove chars illegal in paths and spaces)
$safeDeviceName = ($deviceItem.Name -replace '[\\/:*?"<>|\s]', '_').Trim('_')
$backupDir  = Join-Path $backupRoot "${timestamp}_${safeDeviceName}"
$backedUp   = $false

# 1) GARMIN/Apps/Data/<UUID>
$dataFolder = Get-ChildFolder -ParentFolder $garminFolder -NamePatterns @('Apps','APPS')
if ($dataFolder) {
    $dataSubFolder = Get-ChildFolder -ParentFolder $dataFolder -NamePatterns @('Data','DATA')
    if ($dataSubFolder) {
        $uuidFolder = Get-ChildFolder -ParentFolder $dataSubFolder -NamePatterns @("*$appUuid*")
        if ($uuidFolder) {
            $dest = Join-Path $backupDir "Apps\Data\$appUuid"
            Write-Host "Backing up Apps\Data\$appUuid ..."
            Copy-MtpFolderRecursive -ShellFolder $uuidFolder -DestDir $dest
            $backedUp = $true
        }
    }
}

# 2) GARMIN/Apps/SETTINGS/<UUID>.SET (and any other UUID-named files)
if ($dataFolder) {
    $settingsFolder = Get-ChildFolder -ParentFolder $dataFolder -NamePatterns @('SETTINGS','Settings','settings')
    if ($settingsFolder) {
        foreach ($item in $settingsFolder.Items()) {
            if ($item.Name -like "*$appUuid*") {
                $dest = Join-Path $backupDir "Apps\SETTINGS"
                Write-Host "Backing up Apps\SETTINGS\$($item.Name) ..."
                Copy-MtpItemToLocal -ShellItem $item -DestDir $dest
                $backedUp = $true
            }
        }
    }
}

if ($backedUp) {
    Write-Host "[OK] Backup saved to: $backupDir"
} else {
    Write-Host "[INFO] No existing app data/settings found on watch for UUID $appUuid — skipping backup."
}
# ────────────────────────────────────────────────────────────────────────────

$appsFolder = Get-ChildFolder -ParentFolder $garminFolder -NamePatterns @('Apps','APPS')
if (-not $appsFolder) {
    $garminFolder.NewFolder('Apps') | Out-Null
    Start-Sleep -Milliseconds 300
    $appsFolder = Get-ChildFolder -ParentFolder $garminFolder -NamePatterns @('Apps','APPS')
}
if (-not $appsFolder) { throw "Couldn't create/find Apps folder." }

# Copy file (suppress UI)
# Flags: FOF_SILENT (0x4), FOF_NOCONFIRMATION (0x10), FOF_NOCONFIRMMKDIR (0x200), FOF_NOERRORUI (0x400)
$fof = 0x4 -bor 0x10 -bor 0x200 -bor 0x400
$appsFolder.CopyHere($sourceFile, $fof)

# Verify it arrived (poll briefly because MTP copies are async)
$destItem = $appsFolder.ParseName('Meditate.prg')
for ($i=0; $i -lt 40 -and -not $destItem; $i++) {
    Start-Sleep -Milliseconds 250
    $destItem = $appsFolder.ParseName('Meditate.prg')
}

if ($destItem) {
    Write-Host "[OK] Copied to: $($deviceItem.Name)\Internal Storage\GARMIN\Apps\Meditate.prg"
} else {
    throw "[ERROR] Copy did not verify. Open the Apps folder in Explorer to confirm."
}
