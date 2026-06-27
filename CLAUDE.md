# CLAUDE.md — Meditate (Garmin Connect IQ)

## Overview

Garmin Connect IQ meditation watch-app tracking HR, HRV, stress, and respiration rate. Written in **Monkey C** using the **Toybox API**. Targets 90+ Garmin watches (Connect IQ ≥ 3.0). Licensed under MIT.

## Project Structure

Multi-folder VS Code workspace (`Meditate.code-workspace`) with four sub-projects:

```
Meditate/               Main watch-app (entry: source/MeditateApp.mc)
HrvAlgorithms/          Barrel — HRV/HR/stress sensor algorithms
ScreenPicker/           Barrel — carousel UI components (depends on StatusIconFonts)
StatusIconFonts/        Barrel — Font Awesome icon fonts
```

**Dependency graph:** `Meditate` → `HrvAlgorithms`, `ScreenPicker` → `StatusIconFonts`, `StatusIconFonts`

Barrels are Connect IQ reusable libraries, declared in `barrels.jungle` and compiled into the main app.

## Build & Run

### Prerequisites

- **Connect IQ SDK** ≤ v4.1.5 (if using v4.1.6+, [disable Monkey C type checker](https://forums.garmin.com/developer/connect-iq/f/discussion/314861/sdk-4-1-6-generating-new-errors-and-warnings#pifragment-1298=1))
- **VS Code** with [Monkey C extension](https://marketplace.visualstudio.com/items?itemName=garmin.monkey-c) and [Prettier Monkey C](https://marketplace.visualstudio.com/items?itemName=markw65.prettier-extension-monkeyc)

### Open Workspace

`File → Open Workspace from File… → Meditate.code-workspace`

### Build

Use Monkey C extension: `Ctrl+Shift+P → Monkey C: Build`. Output: `Meditate/bin/Meditate.prg`.

Build config in each `monkey.jungle`:

```jungle
project.typecheck = 0       # Type checking disabled
project.optimization = 3pz  # Maximum optimization
```

### Deploy to Device

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\CopyBuildToDevice.ps1            # default: *fenix*
powershell -NoProfile -ExecutionPolicy Bypass -File .\CopyBuildToDevice.ps1 "fenix 8"  # specific device
```

Copies `bin/Meditate.prg` to `<Device>\GARMIN\Apps\` via MTP.

### Release

**Always release via `makeRelease.sh`** — never hand-roll the version bump / commit / tag steps.

The script (run from repo root) does the full flow in order:

1. Prints the current `manifest.xml` version, then **prompts** `Make release for version:` (read from stdin).
2. Seds the entered version into every `about_AppVersion">vX.X.X<` string (all locale `strings.xml`) and into `Meditate/manifest.xml`'s `<iq:application version="...">`.
3. `git add .` → `git commit -am "bump version to vX.X.X"` → `git tag vX.X.X` → `git push origin tag vX.X.X` → `git push`.

It is interactive, so feed the version on stdin via the Bash tool:

```bash
echo "10.7.7" | ./makeRelease.sh   # non-interactive: pipes the version into the prompt
```

Notes:
- The version sed is idempotent — safe to re-run.
- Stage any other intended changes (e.g. doc edits) **before** running; step 3's `git add .` sweeps the whole tree into the bump commit.
- The final `git push` uses SSH (`git@github.com:...`). If the agent has no loaded key / a passphrase-protected key, push fails *after* the local commit+tag succeed — finish with a manual `git push origin dev && git push origin tag vX.X.X`.

## Supported Devices

Each of the **4 `manifest.xml` files** lists supported watches as `<iq:product id="<deviceId>"/>` entries inside `<iq:products>`. The `<deviceId>` matches the folder name under the SDK's device-definition directory.

- **SDK device definitions (source of truth for available watches):**
  - Windows: `%APPDATA%\Garmin\ConnectIQ\Devices\` (= `C:\Users\<user>\AppData\Roaming\Garmin\ConnectIQ\Devices\`)
  - macOS/Linux: `~/.Garmin/ConnectIQ/Devices/`
  - One folder per device (`fenix8`, `vivoactive6`, …), each with `<deviceId>.bin`, `simulator.json`, `compiler.json`. The folder name **is** the manifest product id.
- The 4 manifests are not identical: `Meditate/manifest.xml` is the actual app device list; the barrels (`HrvAlgorithms`, `ScreenPicker`, `StatusIconFonts`) typically list a superset. The app-facing list is `Meditate/manifest.xml`.

### Minimum memory requirement: 512 KB watch-app RAM

This app needs at least **512 KB of `watchApp` memory** to fit. Every currently-supported device meets this; nothing below it is supported (smallest supported = `fr255s` at 512 KB). Devices below the floor are excluded, e.g. `instinct3solar45mm` (128 KB) and the whole Instinct 2 family (96 KB).

The budget is in each device's **`compiler.json`** under `appTypes` → `watchApp` → `memoryLimit` (bytes). Check any device:

```powershell
$id = 'instinct3solar45mm'   # device id to check
$j = Get-Content "$env:APPDATA\Garmin\ConnectIQ\Devices\$id\compiler.json" -Raw | ConvertFrom-Json
$wa = ($j.appTypes | Where-Object { $_.type -eq 'watchApp' }).memoryLimit
if ($null -eq $wa) { "$id: no watchApp app type — cannot run this app" }
elseif ($wa -lt 524288) { "$id: $([int]($wa/1024)) KB — BELOW 512 KB floor, do NOT add" }
else { "$id: $([int]($wa/1024)) KB — meets 512 KB minimum" }
```

**Memory is necessary but not sufficient.** A device can have ≥512 KB and still be excluded. Known reasons (from git history), so they aren't re-evaluated blindly:

- **CIQ API below 3.0** — `epix` gen 1 is CIQ 1.2.1, below the app's floor. Gate new devices on `connectIQVersion` too (in `compiler.json`), not just memory.
- **App broke on the device** — `vivoactive4`/`vivoactive4s` (1024 KB) were removed in v8.5: commit `30af8d0` *"Removed support for Vivoactive 4(s) - app no longer working in these devices"*. Needs a code fix, not just a manifest line.
- **Parked, revisit later** — `vivoactive3m`/`vivoactive3mlte`, `marqexpedition` were temporarily removed (commit `46c1938` *"tmp rm devices again; try to support later"*); still in the barrel manifests.

So a new device passing the memory check still warrants a judgment call (CIQ version, form factor, and a sim build) before adding.

### Flow: check for new devices to support

**Goal: surface only genuinely new watch releases.** A raw SDK-vs-manifest diff returns ~76 entries that are *not* new — they're non-wrist hardware and old watches already intentionally dropped. Folder timestamps can't distinguish new from old (they all reset to the SDK install date). So the diff is filtered against a curated baseline of known exclusions; anything left over is a genuinely new device to evaluate.

Trigger whenever Garmin releases new watches (or after an SDK update):

1. List device ids in the SDK `Devices/` folder (folder names).
2. Diff against `<iq:product id=...>` ids in `Meditate/manifest.xml`.
3. Filter out non-wrist hardware, the dropped-watch baseline, and anything below the **512 KB** floor (see above). Whatever remains is **new and viable** — report it with its memory.
4. For each candidate, propose adding `<iq:product id="<deviceId>"/>` to all 4 manifests (keep barrels a superset of `Meditate`). If a candidate is non-wrist or otherwise unwanted, add its id to `$excludeExact`.
5. Rebuild in the simulator against one new device to confirm it compiles.

The memory gate auto-drops sub-512 KB devices (e.g. `instinct3solar45mm`), so the name baseline only needs non-wrist prefixes plus capable-but-unwanted old watches.

```powershell
# Non-wrist hardware — never a target for a meditation app (note: d2* are wrist aviation watches, NOT excluded)
$excludePrefixes = 'approach','edge','gpsmap','oregon','montana','rino','etrex','descent'
# Capable (>=512 KB, CIQ >= 3.0) but intentionally excluded — see "Minimum memory requirement" above
$excludeExact = @(
  'vivoactive3m','vivoactive3mlte',      # array-out-of-bounds crash on session finish (240x240 layout); kept in barrels only
  'system8preview'                       # SDK System-8 preview pseudo-device, not a real watch
)
# NOTE: vivoactive4/4s and marqexpedition were sim-verified OK and re-added to all 4 manifests after the
#       Apr-2025 bulk purge (46c1938 "tmp rm devices again"). vivoactive3m/3mlte still crash on finish.
# NOTE: fr70 / fr170 / fr170m were added to all 4 manifests (CIQ 6.0, 768 KB); flow now skips them via $man.
$man = Select-String -Path .\Meditate\manifest.xml -Pattern 'iq:product id="([^"]+)"' -AllMatches |
  ForEach-Object { $_.Matches } | ForEach-Object { $_.Groups[1].Value }
Get-ChildItem "$env:APPDATA\Garmin\ConnectIQ\Devices" -Directory | ForEach-Object {
  $id = $_.Name
  if ($id -in $man -or $id -in $excludeExact -or ($excludePrefixes | Where-Object { $id -like "$_*" })) { return }
  $j   = Get-Content "$($_.FullName)\compiler.json" -Raw | ConvertFrom-Json
  $wa  = ($j.appTypes | Where-Object { $_.type -eq 'watchApp' }).memoryLimit
  $ciq = ($j.partNumbers.connectIQVersion | ForEach-Object { [version]$_ } | Sort-Object | Select-Object -First 1)  # min across SKUs
  if ($wa -ge 524288 -and $ciq -ge [version]'3.0.0') {   # 512 KB floor AND CIQ >= 3.0
    [pscustomobject]@{ id=$id; KB=[int]($wa/1024); CIQ=$ciq }
  }
} | Sort-Object id | Format-Table -AutoSize   # empty = nothing new; drops epix (CIQ 1.2.1) by rule
```

## Testing

Unit tests exist in `HrvAlgorithms/sources/activity/hrv/tests/` but are **commented out** to reduce PRG binary size. They use Connect IQ's `(:test)` annotation framework and return `true`/`false`. To run: uncomment test files, then use the Monkey C extension test runner or Connect IQ simulator.

No CI pipeline builds or tests Monkey C code. GitHub Actions handle only image compression, content translation, and user guide publishing.

## Code Style & Conventions

### Naming

| Element           | Convention            | Example                           |
| ----------------- | --------------------- | --------------------------------- |
| Classes / Modules | PascalCase            | `MeditateActivity`, `VibePattern` |
| Methods           | camelCase             | `loadHrvTracking()`               |
| Private fields    | `m` prefix            | `mSessionStorage`, `mHrvTracking` |
| Public fields     | camelCase (no prefix) | `elapsedTime`, `currentHr`        |
| Enum values       | PascalCase            | `NoNotification = 0`              |
| Storage keys      | snake_case strings    | `"globalSettings_hrvTracking"`    |

### Patterns

- **MVC-like**: Model (data) → View (render) → Delegate (input). Example: `MeditateModel` / `MeditateView` / `MeditateDelegate`.
- **`me.` prefix** used consistently for instance member access.
- **Inheritance chain**: `MeditateActivity → HrvActivity → HrActivity → SensorActivity`.
- **Dictionary serialization**: Models use `fromDictionary()` / `toDictionary()` for `App.Storage` persistence.
- **Static load/save**: `GlobalSettings` uses static methods per setting key.
- **Barrel modules**: Each barrel wraps code in a module (e.g., `module HrvAlgorithms { ... }`).

### Formatting

- Tab indentation, LF line endings
- Format-on-save enabled via Prettier Monkey C
- Braces on same line: `function initialize() {`
- Comments: concise, lowercase, no full sentences — just the point (e.g. `// clear stale paused; else multi-session drops HRV after session 1`)

### Commit Messages

- **Always super concise.** Lead with the behavior change (what the user notices); add technical detail only if it's needed to understand the change.
- Start with **user-facing release notes** (what changed for the user)
- Follow with **technical details** below (implementation specifics, files changed, reasoning) — only when they add necessary context
- **No special characters** that shells may misinterpret: avoid parentheses, colons, slashes, quotes, brackets, backticks, and dollar signs in the message text
- When providing via terminal, use the temp-file approach: write to a file with `Set-Content`, then `git commit -a -F <file>`, then delete the file

### Release Notes

- **Always customer-facing, value-focused, super concise.** Describe what the user gets, not how it was built.
- No internal/technical detail (file names, refactors, SDK plumbing) — that belongs in commit messages only.

## Architecture

### App Flow

```
MeditateApp.getInitialView()
  → HeartbeatIntervalsSensor.startup()
  → SessionStorage (load sessions / presets)
  → SessionPickerDelegate (carousel)
    → [Start] → Preparation → MeditateActivity → Finalization → Save/Discard → Summary screens
    → [Multi-session: intermediate menu → next session or rollup exit]
```

### Key Source Directories

- `Meditate/source/activity/` — Core meditation activity, views, vibration alerts
- `Meditate/source/sessionSettings/` — Session config, color/custom pickers, interval alerts
- `Meditate/source/summaryScreen/` — Post-session summary with HR/HRV/stress/respiration graphs
- `Meditate/source/globalSettings/` — App-wide settings (static load/save)
- `Meditate/source/storage/` — Session CRUD, presets
- `Meditate/source/com/` — GA4 analytics, donation prompts
- `HrvAlgorithms/sources/activity/hrv/` — HRV algorithm implementations (RMSSD, SDRR, pNNx)

### Storage

- **`App.Storage`** — Key-value persistence for sessions, settings, analytics queue.
  - Session keys: `"sesssion_<key>"` (historical triple-s typo — **do not fix**)
  - Settings keys: `"globalSettings_<name>"`
- **`App.Properties`** — Device-configurable properties (activity name, GA4 credentials)

### Timers (`Timer.Timer` concurrency limit)

Connect IQ caps the number of **concurrently active `Timer.Timer` objects per app**. The limit is **device-dependent with a default of 3** (and a default minimum interval of 50 ms); both "depend on the host system" per the API docs. Starting one more than the device allows throws the runtime **"Too Many Timers Error"**. A `Timer.Timer` is a native resource — its slot is held until you call `.stop()` (or, unreliably, until the object is garbage-collected). **Always `.stop()` a timer before dropping its reference; do not rely on GC, especially on slower watches.** `Sensor.registerSensorDataListener` (used by `HeartbeatIntervalsSensor`) is **not** a `Timer` and does not count toward this limit.

**Timers in this app** (keep this list current when adding/removing timers):

| Timer | Where | Repeating | Released by |
| --- | --- | --- | --- |
| `mRefreshActivityTimer` | `HrActivity` (1 s session refresh) | yes | `stop()` / `pauseResume()` |
| `mviewDrawnTimer` | `MeditatePrepareView` (prepare/finalize countdown) | yes | `onHide()` → `stop()` |
| `viewDrawnTimer` | `DelayedFinishingView` (1 s finish delay) | no (one-shot) | `onHide()` → `stop()` |
| `mTimer` | `IdleReminderTimer` (10 min idle vibe) | yes | `stop()` |
| `notifyChangeTimer` | `AddEditIntervalAlertMenuDelegate` (500 ms debounce, settings only) | no (one-shot) | fires then nulls |

Steady state holds ≤2 of these at once (session refresh + an idle-reminder while a menu is up), well under the 3-timer floor. The finish flow is the tight spot: it chains two `DelayedFinishingView` instances and then starts the `IdleReminderTimer`, so any leaked finishing-view timer slot can tip a 3-timer device over. This is exactly the historical **"Too Many Timers Error"** (backtrace `IdleReminderTimer.start` ← `showSummaryView` ← `DelayedFinishingView.onViewDrawn`): fixed by having `DelayedFinishingView.onHide()` call `.stop()` instead of only nulling the reference, matching `MeditatePrepareView`.

## Secrets

`Meditate/resources/secrets.xml` is **gitignored**. Copy `secrets_template.xml` → `secrets.xml` and fill in GA4 credentials to enable usage analytics.

## .gitignore

```
bin
.metadata
export
Meditate/resources/secrets.xml
Meditate/backup
Meditate/debug-pulls
```

## Device Scripts (Meditate/)

Two PowerShell 5.1 scripts for deploying and debugging on a physical Garmin watch via MTP (USB). Both scripts accept an optional device name parameter (default: `fenix`).

### CopyBuildToDevice.ps1

Deploys `bin/Meditate.prg` to the watch:

1. Shows device and source path, asks for confirmation before deploying
2. Copies `Meditate.prg` to `GARMIN/Apps/` and verifies it arrived
3. Creates an empty `MEDITATE.TXT` in `GARMIN/Apps/LOGS/` to enable `System.println()` logging

### PullDebugInfoFromDevice.ps1

Pulls all debug-relevant files from the watch into a timestamped `debug-pulls/` subfolder:

- `GARMIN/Apps/LOGS/` -- println output (`MEDITATE.TXT`) and crash logs (`CIQ_LOG.YAML`)
- `GARMIN/CIQLOG/` -- Connect IQ system logs
- `GARMIN/ERR_LOG.txt` -- device/firmware crash logs

### Key Learnings (scripting for Garmin devices)

- **Connect IQ on-device logging**: `System.println()` writes to `GARMIN/Apps/LOGS/<APPNAME>.TXT`, but the file must **already exist** (empty) on the device. The filename matches the PRG name in uppercase (e.g., `Meditate.prg` -> `MEDITATE.TXT`).
- **`CIQ_LOG.YAML`** is auto-created by the runtime on **app crashes only** -- not a trigger file for logging.
- **Garmin app storage locations**: `GARMIN/Apps/DATA/` for Object Store data, `GARMIN/Apps/SETTINGS/` for phone-configured settings. **Older devices** use UUID-named subfolders (e.g., `DATA/3A747E00-.../`). **Newer devices** (fenix 8+) use short encoded filenames (e.g., `G1HF1837.DAT`, `G1HF1837.SET`) with no UUID in the name.
- **CIQ data files are encrypted per-build**: `.DAT` (Application.Storage) and `.IDX` (index) files are encrypted with a build-specific key. Same-build backups produce byte-identical DATs, but cross-build DATs are entirely different. Restoring a DAT from a different build causes the app to crash on first launch; the CIQ runtime then resets the corrupt store. `.SET` (Application.Properties) files contain plaintext key-value pairs but property ordering and offset tables change between builds -- they can usually be restored across builds. `.IMT` (install metadata) contains build-specific hashes and varies in size per build. **Only same-build restores of DAT/IDX are reliable. Cross-build restores should only include SET files.**
- **`GarminDevice.xml`** in the `GARMIN/` root contains an `<IQAppExt>` section that maps each installed CIQ app to its short filename. Each `<App>` entry has `<AppName>`, `<StoreId>`, `<AppId>` (= manifest UUID), and `<FileName>` (e.g., `G1HF1837.PRG`). The base name (without extension) is the short ID used across DATA, SETTINGS, and LOGS folders. Scripts parse this file to back up only the target app's files.
- **MTP access in PowerShell**: Use `Shell.Application` COM object. MTP paths (e.g., `Dieser PC\fenix\Internal Storage`) are not regular filesystem paths -- you must navigate via Shell folder objects. `CopyHere` always preserves the original filename -- to copy to a predictable path, use a unique temp subdirectory rather than renaming the destination.
- **PowerShell 5.1 encoding**: Files without a UTF-8 BOM are read as ANSI (Windows-1252). Non-ASCII characters (em dashes, box-drawing chars) in strings will cause parse errors. **Always use ASCII-only content or save with UTF-8 BOM.**

## Cloud Backup & Restore (Dev Feature)

In-app developer tool accessible via **long-press on the About screen** → "Dev Tools" menu. Backed by Firebase Realtime Database (`meditate-garmin` project).

### Sync Rule

**Whenever an `Application.Storage` key is added, renamed, or removed**, update both:

1. `Meditate/source/devTools/CloudBackup.mc` — `GLOBAL_SETTINGS_KEYS` constant array (for serialization)
2. `Meditate/source/devTools/CloudRestore.mc` — `onRestoreResponse()` method (for deserialization)

### Keys Currently Backed Up

- `globalSettings_*` (12 keys) — app-wide settings
- `sessionsKeys` — list of session IDs
- `selectedSessionIndex` — active session index
- `sesssion_<key>` (per entry in `sessionsKeys`) — individual session data (note: triple-s typo is intentional)
- `wakeupSession_activityType`
- `usageStats_monthly` — current month meditation time (via `monthlyStats` section)
- `usageStats_tipPending` — pending tip flag (via `monthlyStats` section)

**Not backed up:** `usageStats_queue_v2` (too large, auto-rebuilds).

### Architecture Notes

- Firebase auth via legacy database secret appended as `?auth=<SECRET>` query param
- Firebase credentials are in `secrets.xml` (gitignored) via `App.Properties` — they do NOT appear in Garmin Connect Mobile because they are not listed in `settings.xml`
- `restoreDeviceId` property IS listed in `settings.xml` → configurable in GCM to restore another device's backups
- All HTTP callbacks use an `mActive` boolean guard to prevent zombie callbacks from touching the view stack after navigation
- Use `Ui.switchToView` (not `pushView`+`popView`) from HTTP callbacks — `popView` from a callback corrupts the view stack
- Backup list is trimmed to the 10 most recent entries in code (after sort); old entries remain in Firebase but are never shown

### Key Learnings (App.Properties / secrets)

- **`properties.xml` is only needed for properties referenced by `settings.xml`** (via `@Properties.<id>`). Secrets used only in code (e.g. Firebase URL/secret, GA4 credentials) need only a `secrets.xml` entry — `properties.xml` is not required for them and should be omitted to avoid redundancy.
- **Firebase RTDB has no native TTL** — that feature exists only in Firestore (via Cloud Functions). For a dev tool, trimming the displayed list to the N most recent entries after sorting is sufficient; no Firebase config or cleanup code needed.

### Key Learnings (Monkey C compiler)

- **`settings.xml` string IDs must be defined in ALL locale resource folders.** Any string referenced via `@Strings.<id>` in `settings.xml` (e.g. as a `title=`) must exist in every `resources-<lang>/strings/strings.xml`, not just the base `resources/` folder. A missing locale string produces a `WARNING: String id '...' undefined for language '...'` and triggers the generic "A critical error has occurred" compiler crash.
- **Static methods cannot access `private` instance members or call `private` instance methods**, even on a freshly created instance of their own class. Doing so causes the assembler error `Trying to add undefined symbol: <memberName>` during release builds. The fix is to move all initialization that touches private members into `initialize()`, so the `static run()` factory simply calls `new MyClass()`.
- **"A critical error has occurred" is a compiler crash masking real errors.** Re-run with `--debug-log-level 2 --debug-log-output <file>.zip` to get `error.txt` inside the zip, which lists the actual `CompilerException` messages (e.g., assembler symbol errors, missing strings).
