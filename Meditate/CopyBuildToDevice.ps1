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

  # deploy a different PRG (e.g. the HRV troubleshooting probe)
  powershell -NoProfile -ExecutionPolicy Bypass -File .\CopyBuildToDevice.ps1 fenix ..\HrvProbe\bin\HrvProbe.prg
#>

[CmdletBinding()]
param(
    [Parameter(Position=0)]
    [string]$DeviceName = 'fenix',

    # Optional: deploy a different PRG (e.g. ..\HrvProbe\bin\HrvProbe.prg).
    # The LOGS trigger file is named after the PRG, so println logging follows automatically.
    [Parameter(Position=1)]
    [string]$PrgPath
)

$ErrorActionPreference = 'Stop'

# --- Settings ---------------------------------------------------------------
if ($PrgPath) {
    $sourceFile = if ([System.IO.Path]::IsPathRooted($PrgPath)) { $PrgPath } else { Join-Path $PSScriptRoot $PrgPath }
} else {
    $sourceFile = Join-Path $PSScriptRoot 'bin\Meditate.prg'
}
# ----------------------------------------------------------------------------

if (-not (Test-Path $sourceFile)) {
    throw "Source file not found: $sourceFile"
}

# Shell COM CopyHere fails silently on paths containing '..' segments, so canonicalize.
$sourceFile  = (Resolve-Path -LiteralPath $sourceFile).ProviderPath
$prgFileName = [System.IO.Path]::GetFileName($sourceFile)

# Create Shell COM (needed for MTP paths like 'Dieser PC\...')
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

# -- Confirm before deploying -----------------------------------------------
Write-Host ""
Write-Host "--------------------------------------------------"
Write-Host "  Device : $($deviceItem.Name)"
Write-Host "  Source : $sourceFile"
Write-Host "--------------------------------------------------"
Write-Host ""
$proceed = Read-Host "Deploy $prgFileName to the watch? [Y/n]"
if ($proceed -in @('n','N','no','No')) {
    Write-Host "Aborted - no changes made to the watch."
    exit 0
}
Write-Host ""
# ----------------------------------------------------------------------------

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

# Verify it arrived (poll briefly because MTP copies are async).
# Re-acquire the Apps folder each round: the shell caches MTP listings and a stale
# handle can keep reporting the file as missing after it has actually landed.
$destItem = $appsFolder.ParseName($prgFileName)
for ($i=0; $i -lt 40 -and -not $destItem; $i++) {
    Start-Sleep -Milliseconds 250
    $appsFolder = Get-ChildFolder -ParentFolder $garminFolder -NamePatterns @('Apps','APPS')
    if ($appsFolder) { $destItem = $appsFolder.ParseName($prgFileName) }
}

if ($destItem) {
    Write-Host "[OK] Copied to: $($deviceItem.Name)\Internal Storage\GARMIN\Apps\$prgFileName"
} else {
    Write-Host "[WARN] Could not verify $prgFileName in the Apps folder. Current contents:"
    foreach ($item in $appsFolder.Items()) {
        if (-not $item.IsFolder) { Write-Host "    $($item.Name)" }
    }
    throw "[ERROR] Copy did not verify. Check the Apps folder in Explorer."
}

# -- Create empty MEDITATE.TXT to enable System.println() logging ---------
# Connect IQ writes println() output to GARMIN/Apps/LOGS/<APPNAME>.TXT,
# but only if the file already exists. We create it empty to enable logging.
$logsFolder = Get-ChildFolder -ParentFolder $appsFolder -NamePatterns @('LOGS','Logs','logs')
if (-not $logsFolder) {
    $appsFolder.NewFolder('LOGS') | Out-Null
    Start-Sleep -Milliseconds 500
    $logsFolder = Get-ChildFolder -ParentFolder $appsFolder -NamePatterns @('LOGS','Logs','logs')
}
if ($logsFolder) {
    $prgBaseName = [System.IO.Path]::GetFileNameWithoutExtension($sourceFile).ToUpper()
    $logFileName = "$prgBaseName.TXT"
    $logTrigger  = Join-Path $env:TEMP $logFileName
    if (-not (Test-Path $logTrigger)) {
        New-Item -ItemType File -Path $logTrigger -Force | Out-Null
    }
    $logsFolder.CopyHere($logTrigger, $fof)
    Start-Sleep -Milliseconds 300
    Write-Host "[OK] Created $logFileName in GARMIN/Apps/LOGS/ (println logging enabled)"
} else {
    Write-Host "[WARN] Could not create GARMIN/Apps/LOGS/ folder - println logging not enabled."
}
