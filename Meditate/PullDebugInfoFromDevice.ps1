<#
Pull all debug-relevant information from the watch for troubleshooting.

Copies files from these device locations into a local debug-pulls/ folder:
  GARMIN/Apps/LOGS/     - println() output (MEDITATE.TXT) and crash logs (CIQ_LOG.YAML)
  GARMIN/CIQLOG/        - Connect IQ system logs
  GARMIN/ERR_LOG.txt    - device crash log (firmware-level)

Each pull creates a timestamped subfolder so previous pulls are preserved.

USAGE:
  # default (searches for *fenix*)
  powershell -NoProfile -ExecutionPolicy Bypass -File .\PullDebugInfoFromDevice.ps1

  # override device name
  powershell -NoProfile -ExecutionPolicy Bypass -File .\PullDebugInfoFromDevice.ps1 "fenix 8 - 47mm"
#>

[CmdletBinding()]
param(
    [Parameter(Position=0)]
    [string]$DeviceName = 'fenix'
)

$ErrorActionPreference = 'Stop'

# --- Settings ---------------------------------------------------------------
$debugPullRoot = Join-Path $PSScriptRoot 'debug-pulls'
# ----------------------------------------------------------------------------

# Create Shell COM (needed for MTP paths)
$shell      = New-Object -ComObject Shell.Application
$myComputer = $shell.Namespace(0x11)  # 'This PC' / 'Dieser PC'

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

function Copy-MtpItemToLocal {
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

# -- Connect to the watch --------------------------------------------------
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

# -- Pull debug info ------------------------------------------------
$timestamp = Get-Date -Format 'yyyy-MM-dd_HHmmss'
$safeDeviceName = ($deviceItem.Name -replace '[\\/:*?"<>|\s]', '_').Trim('_')
$pullDir = Join-Path $debugPullRoot "${timestamp}_${safeDeviceName}"

$pulled = $false

# 1) GARMIN/Apps/LOGS/
$appsFolder = Get-ChildFolder -ParentFolder $garminFolder -NamePatterns @('Apps','APPS')
if ($appsFolder) {
    $appLogsFolder = Get-ChildFolder -ParentFolder $appsFolder -NamePatterns @('LOGS','Logs','logs')
    if ($appLogsFolder) {
        $dest = Join-Path $pullDir 'Apps_LOGS'
        Write-Host "Pulling GARMIN/Apps/LOGS/ ..."
        Copy-MtpFolderRecursive -ShellFolder $appLogsFolder -DestDir $dest
        $pulled = $true
    }
}

# 2) GARMIN/CIQLOG/
$ciqLogFolder = Get-ChildFolder -ParentFolder $garminFolder -NamePatterns @('CIQLOG','CIQLog','ciqlog')
if ($ciqLogFolder) {
    $dest = Join-Path $pullDir 'CIQLOG'
    Write-Host "Pulling GARMIN/CIQLOG/ ..."
    Copy-MtpFolderRecursive -ShellFolder $ciqLogFolder -DestDir $dest
    $pulled = $true
}

# 3) GARMIN/ERR_LOG.txt (device/firmware crash log)
foreach ($item in $garminFolder.Items()) {
    if (-not $item.IsFolder -and $item.Name -match '^ERR_LOG') {
        Write-Host "Pulling GARMIN/$($item.Name) ..."
        Copy-MtpItemToLocal -ShellItem $item -DestDir $pullDir
        $pulled = $true
    }
}

# -- Result -------------------------------------------------------------
if ($pulled) {
    $fileCount = @(Get-ChildItem -Path $pullDir -Recurse -File).Count
    Write-Host ""
    Write-Host "[OK] Pulled $fileCount file(s) to: $pullDir"
} else {
    Write-Host "[INFO] No debug info found on device."
}
