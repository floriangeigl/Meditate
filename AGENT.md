# AGENT.md — Meditate (Garmin Connect IQ)

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

```bash
./makeRelease.sh   # prompts for version, updates manifest + about strings, commits, tags, pushes
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

## Secrets

`Meditate/resources/secrets.xml` is **gitignored**. Copy `secrets_template.xml` → `secrets.xml` and fill in GA4 credentials to enable usage analytics.

## .gitignore

```
bin
.metadata
export
Meditate/resources/secrets.xml
```
