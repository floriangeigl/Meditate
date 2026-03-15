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
$backupRoot = Join-Path $PSScriptRoot 'backup'
# ----------------------------------------------------------------------------

if (-not (Test-Path $sourceFile)) {
    throw "Source file not found: $sourceFile"
}

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

# -- Backup app settings / data from watch ----------------------------------
# Garmin stores CIQ app data in GARMIN/Apps/DATA/ and GARMIN/Apps/SETTINGS/.
# Newer devices (fenix 8+) use short encoded filenames (e.g. G1HF1837.DAT)
# rather than UUID-named subfolders. GarminDevice.xml maps app names to these
# short IDs, so we parse it to back up only Meditate-specific files.

# Discover the short filename base for Meditate from GarminDevice.xml
function Get-AppShortId {
    param(
        [Parameter(Mandatory)][__ComObject]$GarminShellFolder,
        [Parameter(Mandatory)][string]$AppName
    )
    $xmlItem = $GarminShellFolder.ParseName('GarminDevice.xml')
    if (-not $xmlItem) {
        Write-Host "[WARN] GarminDevice.xml not found on device - cannot identify app-specific files."
        return $null
    }
    # Copy into a unique temp subdirectory (MTP CopyHere keeps the original filename)
    $tempDir = Join-Path $env:TEMP "GarminDeviceXml_$([guid]::NewGuid().ToString('N').Substring(0,8))"
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
    $tempCopy = Join-Path $tempDir 'GarminDevice.xml'
    try {
        $tempFolder = (New-Object -ComObject Shell.Application).Namespace($tempDir)
        $tempFolder.CopyHere($xmlItem, 0x4 -bor 0x10 -bor 0x200 -bor 0x400)
        # Wait for the MTP copy to arrive
        for ($w = 0; $w -lt 20 -and -not (Test-Path $tempCopy); $w++) { Start-Sleep -Milliseconds 250 }
        if (-not (Test-Path $tempCopy)) {
            Write-Host "[WARN] Failed to copy GarminDevice.xml to temp - cannot identify app-specific files."
            return $null
        }
        $xmlContent = [IO.File]::ReadAllText($tempCopy)
        # Match: <AppName>Meditate</AppName>...<FileName>G1HF1837.PRG</FileName>
        $pattern = "<AppName>$([regex]::Escape($AppName))</AppName>.*?<FileName>([^<]+)\.PRG</FileName>"
        if ($xmlContent -match $pattern) {
            return $Matches[1]
        }
        Write-Host "[WARN] App '$AppName' not found in GarminDevice.xml."
        return $null
    } finally {
        if (Test-Path $tempDir) { Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue }
    }
}

function Copy-MtpItemToLocal {
    <#
    .SYNOPSIS  Copy a single MTP (Shell) item to a local directory.
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

$timestamp  = Get-Date -Format 'yyyy-MM-dd_HHmmss'
# Sanitise device name for use in a folder name (remove chars illegal in paths and spaces)
$safeDeviceName = ($deviceItem.Name -replace '[\\/:*?"<>|\s]', '_').Trim('_')
$backupDir  = Join-Path $backupRoot "${timestamp}_${safeDeviceName}"

# -- Check for existing backups - protect the original ----------------------
$skipBackup = $false
if (Test-Path $backupRoot) {
    $existingBackups = @(Get-ChildItem -Path $backupRoot -Directory | Sort-Object Name)
    if ($existingBackups.Count -gt 0) {
        $originalBackup = $existingBackups[0]
        Write-Host ""
        Write-Host "[INFO] Original backup is preserved at:"
        Write-Host "       $($originalBackup.Name)"
        Write-Host ""
        $skipAnswer = Read-Host "Create additional backup before deploying? [y/N]"
        if ($skipAnswer -notin @('y','Y','yes','Yes')) {
            Write-Host "Skipping backup (original is safe)."
            Write-Host ""
            $skipBackup = $true
        }
    }
}

$backedUp = $false

if (-not $skipBackup) {
    # Discover which short filename belongs to Meditate
    $appShortId = Get-AppShortId -GarminShellFolder $garminFolder -AppName 'Meditate'
    if (-not $appShortId) {
        throw "Could not determine Meditate's short ID from GarminDevice.xml - aborting backup."
    }
    Write-Host "[INFO] Meditate device short ID: $appShortId"

    $appsFolder = Get-ChildFolder -ParentFolder $garminFolder -NamePatterns @('Apps','APPS')
    if ($appsFolder) {
        # 1) GARMIN/Apps/DATA/ - back up only Meditate files (G1HF1837.*)
        $backupDataFolder = Get-ChildFolder -ParentFolder $appsFolder -NamePatterns @('Data','DATA')
        if ($backupDataFolder) {
            $dest = Join-Path $backupDir 'Apps_DATA'
            foreach ($item in $backupDataFolder.Items()) {
                if ($item.Name -notlike "$appShortId.*") { continue }
                Write-Host "  Backing up DATA: $($item.Name) ..."
                Copy-MtpItemToLocal -ShellItem $item -DestDir $dest
                $backedUp = $true
            }
        }

        # 2) GARMIN/Apps/SETTINGS/ - back up only Meditate files (G1HF1837.SET)
        $settingsFolder = Get-ChildFolder -ParentFolder $appsFolder -NamePatterns @('SETTINGS','Settings','settings')
        if ($settingsFolder) {
            $dest = Join-Path $backupDir 'Apps_SETTINGS'
            foreach ($item in $settingsFolder.Items()) {
                if ($item.Name -notlike "$appShortId.*") { continue }
                Write-Host "  Backing up SETTINGS: $($item.Name) ..."
                Copy-MtpItemToLocal -ShellItem $item -DestDir $dest
                $backedUp = $true
            }
        }
    }

    if ($backedUp) {
        # Verify the backup directory actually contains files
        $backupFiles = @(Get-ChildItem -Path $backupDir -Recurse -File)
        if ($backupFiles.Count -eq 0) {
            throw "Backup directory was created but contains no files - aborting deploy to protect your data."
        }
        $backupStatus = "Backup OK - $($backupFiles.Count) file(s) saved to $($backupDir | Split-Path -Leaf)"
    } else {
        $backupStatus = "No app data/settings found on watch - nothing was backed up"
    }
}  # end if (-not $skipBackup)

# -- Confirm before deploying -----------------------------------------------
Write-Host ""
Write-Host "--------------------------------------------------"
if ($skipBackup) {
    Write-Host "  Backup status: Skipped (existing backups preserved)"
} else {
    Write-Host "  Backup status: $backupStatus"
}
Write-Host "--------------------------------------------------"
Write-Host ""
$proceed = Read-Host "Proceed with deploying Meditate.prg to the watch? [Y/n]"
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
