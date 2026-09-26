# CLAUDE.md — Meditate (Garmin Connect IQ)

## Agent Notes Policy

**Never use Claude's persistent cross-session memory for this project.** All notes, hints, learnings, and project knowledge go directly into this file instead — it's checked into the repo, version-controlled, and visible to every contributor and every future session. If you learn something worth remembering, add it here in the relevant section.

## Overview

Garmin Connect IQ meditation watch-app tracking HR, HRV, stress, and respiration rate. Written in **Monkey C** using the **Toybox API**. Targets 100+ Garmin watches (Connect IQ ≥ 3.0). Licensed under MIT.

## Project Structure

Multi-folder VS Code workspace (`Meditate.code-workspace`): the repo root plus two projects.

```
./                      README, UserGuide.md, store texts (ConnectIQStore/), translations (generated/), makeRelease.sh, .github/
Meditate/               Main watch-app (entry: source/MeditateApp.mc); sensor/recording engine in source/recording/
HrvProbe/               Standalone diagnostic app, not shipped — see "HRV cold start"
```

The app uses no barrels. The three it once had were merged in as plain top-level classes, because
none was a real boundary: `HrvAlgorithms` → `source/recording/` (it called the app's `Vibe`),
`ScreenPicker` and `StatusIconFonts` → `source/screenPicker/` (app-specific icons, the app's
settings, two extra 158-device manifests to keep in sync).

**Icon glyphs look empty but aren't.** `resources/strings/iconGlyphs.xml` holds Font Awesome code
points from the private use area (e.g. `IconStress` is U+E0B7), which terminals and most editors
render as blank. Move or edit that file only byte-safely, never retype a glyph, and keep
`translatable="false"` on every entry. `IconGlyphTests` fails if a used glyph stops being exactly
one private-use character.

## Build & Run

### Prerequisites

- **Connect IQ SDK**, currently 9.2.0. Type checking stays off (`project.typecheck = 0`, and `monkeyC.typeCheckLevel: Off` in VS Code): SDKs since 4.1.6 [report new errors on this code base](https://forums.garmin.com/developer/connect-iq/f/discussion/314861/sdk-4-1-6-generating-new-errors-and-warnings#pifragment-1298=1) otherwise.
- **VS Code** with [Monkey C extension](https://marketplace.visualstudio.com/items?itemName=garmin.monkey-c) and [Prettier Monkey C](https://marketplace.visualstudio.com/items?itemName=markw65.prettier-extension-monkeyc)

### Open Workspace

`File → Open Workspace from File… → Meditate.code-workspace`

### Build

Use Monkey C extension: `Ctrl+Shift+P → Monkey C: Build`. Output: `Meditate/bin/Meditate.prg`.

Build config in `Meditate/monkey.jungle`:

```jungle
project.typecheck = 0       # Type checking disabled
project.optimization = 3pz  # Maximum optimization
```

**Judge PRG size from a release build (`-r`), never a debug one** — they differ by ~2.5x. Same
tree on `fr255s` (2026-09-25): debug 366,380 B vs release 148,556 B. A debug PRG looks alarmingly
close to a 512 KB device budget while the shipped artifact uses under a third of it. Release
history on `fr255s`: 145 KB before breathwork, 172 KB with it, 167 KB after the data acquisition
rework, 149 KB after the 2026-09 settings/menu cleanup. **Compare sizes in bytes** (`stat -c %s`,
or `(Get-Item).Length`) against a baseline build of the same tree — 166 860 B reads as "163 KB" in
KiB and "167 KB" in kB, which once turned a +48 B change into an imaginary 4 KB saving.

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
echo "X.Y.Z" | ./makeRelease.sh   # non-interactive: pipes the version into the prompt
```

Notes:
- Run it on the branch that goes to `main` by PR. `main` is branch-protected, so the bump commit
  and the tag ride on that branch and land with the merge.
- The version sed is idempotent — safe to re-run.
- **Announcing a release on the watch is opt-in per release.** Most releases ship silently. When
  one is worth a word, bump `WhatsNewDelegate.NewsId` and rewrite the `whatsNew_*` strings in
  **all** locales *before* running `makeRelease.sh`. Existing users then see one screen on their
  next launch, dismissed with back/select/tap; new installs are marked caught-up so they never
  see it. The rows are drawn unwrapped, so keep each line About-screen short.
- **Before every release, check whether any of the changes since the last release require an update to `UserGuide.md`** (e.g. renamed/added/removed settings, menus, or features the guide documents). Update it and stage the edit *before* running `makeRelease.sh` so it lands in the bump commit.
- **Before every release, check whether the `codex-action@v1.11` pin can be lifted** — see "GitHub Actions" below.
- Stage any other intended changes (e.g. doc edits) **before** running; step 3's `git add .` sweeps the whole tree into the bump commit, untracked files included — check `git status` first.
- The final `git push` uses SSH (`git@github.com:...`). If the agent has no loaded key / a passphrase-protected key, push fails *after* the local commit+tag succeed — finish with a manual `git push origin HEAD && git push origin tag vX.X.X`.

## Supported Devices

`Meditate/manifest.xml` lists supported watches as `<iq:product id="<deviceId>"/>` entries inside `<iq:products>`. The `<deviceId>` matches the folder name under the SDK's device-definition directory.

- **SDK device definitions (source of truth for available watches):**
  - Windows: `%APPDATA%\Garmin\ConnectIQ\Devices\` (= `C:\Users\<user>\AppData\Roaming\Garmin\ConnectIQ\Devices\`)
  - macOS/Linux: `~/.Garmin/ConnectIQ/Devices/`
  - One folder per device (`fenix8`, `vivoactive6`, …), each with `<deviceId>.bin`, `simulator.json`, `compiler.json`. The folder name **is** the manifest product id.

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
- **Broke on the device, fixed later** — `vivoactive4`/`vivoactive4s` (1024 KB) were removed in v8.5 (`30af8d0` *"app no longer working in these devices"*), then re-added after a sim check; they still need the `SPORT_MEDITATION` remap below. A device that crashes needs a code fix, not just a manifest line.
- **Parked** — `vivoactive3m`/`vivoactive3mlte` crash on session finish (240x240 layout) and are in no manifest (see `$excludeExact` below). `marqexpedition`, parked in the same purge (`46c1938`), is back.

So a new device passing the memory check still warrants a judgment call (CIQ version, form factor, and a sim build) before adding.

### Device quirk: vívoactive4/4s reject SPORT_MEDITATION

vívoactive4/4s report Connect IQ API >= 3.3.6 (the `Utils.MonkeyVersionAtLeast([3,3,6])` gate in `MeditateActivity.mc` that's meant to guard Meditation/Yoga/Breathing FIT sport support), but `ActivityRecording.createSession` still throws **"Invalid Value"** for `SPORT_MEDITATION` (67) on this hardware — first seen as a production crash (backtrace `HrActivity.initialize` ← `HrvActivity.initialize` ← `MeditateActivity.initialize` — pre-rework names, today `ActivityRecorder.initialize` ← `MeditateActivity.initialize`; vívoactive4S firmware 8.30, app v10.7.8, 2026-07-03). Garmin's manuals confirm this device ships native Yoga and Breathwork activities but never got a native Meditation profile, so the API-level heuristic is a false positive specifically for this device family.

Fixed via `Utils.activityTypeOverridesByPartNumber` (keyed by `System.getDeviceSettings().partNumber` — `006-B3225-00`/`006-B3388-00` = vivoactive4, `006-B3224-00`/`006-B3387-00` = vivoactive4s, `006-B3226-00`/`006-B3389-00` = venu, `006-B3740-00`/`006-B3737-00` = venud Mercedes-Benz Collection) and `Utils.getEffectiveActivityType()`, applied once where `MeditateActivity.mc` resolves `selectedActivityType` — remaps `ActivityType.Meditating` to `ActivityType.Breathing` on these devices. That single remap point also fixes wakeup-resume: `MeditateActivity.fitKindFor` turns the effective type into a `FitSessionKind`, which `WakeupSessionStorage` stores and `BeatIntervalFeed` hands to the same `FitSessionSpec.create` for the next wakeup session. Add new devices/overrides to that table rather than writing new one-off boolean checks.

Note: `ActivityRecording.createSession` does **not** throw a catchable exception for this failure — a try/catch-and-retry safety net was considered and rejected because it wouldn't actually intercept it. Don't propose try/catch around a Toybox call without first confirming (via the API docs or existing repo precedent) that it's documented to throw.

### Device quirk: multitasking devices suspend sensors off-screen

On multitasking devices the app **keeps running when it leaves the screen** — no `onStop()`, just `AppBase.onInactive()`. While inactive the system suspends the app's sensors (`Toybox.Sensor` docs: *"Sensor states can not be changed while in inacitve mode and sensor enabled during active mode will be disabled when app becomes inactive"*), so the `heartBeatIntervals` callback keeps firing with **empty data** — indistinguishable from a dead HR sensor.

The authoritative device list is the **`onActive`/`onInactive` supported-devices list in the SDK docs** (`doc/Toybox/Application/AppBase.html`), API 4.2.3+: Approach S50, D2 Mach 2/Pro, Enduro 3, fēnix 8 (43/47/51/Pro/Solar), tactix 8, quatix 8, fēnix E, Venu 3/3S, Venu 4 41/45mm, D2 Air X15, Venu X1, vívoactive 5/6. Use that list, not "AMOLED" or "released after 2023" — fēnix 8 Solar 51mm is MIP and *is* multitasking.

Caveat: the doc list lags the device definitions. SDK 9.2.0 ships fēnix 9 device defs but its docs never mention fēnix 9 (0 hits, vs 321 for fēnix 8 Pro), so the list neither confirms nor rules out fēnix 9 multitasking. Assume it is, and re-check the list after an SDK doc refresh. Either way the code is safe: `foreground` defaults `true`, and `onActive`/`onInactive` are simply never called on a non-multitasking device.

This caused a production crash (24 reports, v10.7.10, backtrace `HeartbeatIntervalsSensor.createWakeupSession` ← `getStatus` ← `SessionPickerDelegate.updateHrvStatus` ← `update` — the class is `BeatIntervalFeed` and the method `pollStatus()` today): after ~40 s backgrounded on the session picker, the status poll's >20-error recovery path fired and called `ActivityRecording.createSession`, which is not permitted in that state. **Every crashing device was on the multitasking list; none of the other 81 supported devices appeared** — that 100% correlation is what identified the root cause, so check the device list against it before assuming a sport/spec problem.

Fixed with a `foreground` flag on `BeatIntervalFeed` (`setForeground()`, driven by `MeditateApp.onActive`/`onInactive`):

- The gate lives in **`pollStatus()`, not `update()`** — `pollStatus()`'s only caller is the session picker, so gating there cannot touch in-session HRV capture. Early-returning in `update()` would suppress `mListener.invoke(data)`, i.e. the HRV feed of a session recording in the background.
- `setForeground(true)` calls `resetSensorQuality()` on the false→true edge only — the counters are meaningless after a suspended gap, and this gives the re-enabled sensor its full ~21 s grace instead of firing recovery on the first tick back.
- `foreground` defaults `true` and the callbacks only exist on multitasking devices, so the other 81 devices are unchanged. Defining `onActive`/`onInactive` compiles fine down to CIQ 3.0.3 (verified on `d2deltapx`) — on older devices they're just methods that are never called.
- Going inactive deliberately does **nothing** beyond setting the flag: sensor state must not be changed there.

Known related exposure, unverified and not fixed: `MeditatePrepareView`'s countdown `Timer.Timer` calls `startMeditationSession()` → `createSession`. If a view's timer survives backgrounding (i.e. `onHide()` does *not* fire when a multitasking app loses the screen), backgrounding during a prepare countdown hits the same illegal call with a different backtrace.

### HRV cold start: two-phase status text, restarting is the only real fix

On a cold optical sensor `heartBeatIntervals` stays empty while `currentHeartRate` streams normally. The 1 Hz callback keeps firing with empty data, so the picker's hourglass animates forever. **Nothing done *within* a running app reliably unsticks it** — held session (180–320 s), `session.start()`, `setEnabledSensors`, `enableSensorType`, `enableSensorEvents`, and in-process `onStop`-style teardown+restart, all measured on a 10–12 h cold sensor, all nothing. It reproduces in ~100 lines that only register a listener, so it is not a Meditate bug, and the simulator cannot reproduce it at all.

**Restarting the app does fix it, fast.** Two cold sensors (11.4 h, 13.1 h gap) that failed on first launch got RR within 2–3 s of a genuine relaunch — total time under 1.5 min, against 180–320 s of continuous holding producing nothing on comparably cold sensors. One confound is still open — restarting requires handling the watch, and motion is known to affect the optical sensor, so "the restart" vs "the motion of restarting" isn't separated by any test run — but it doesn't change the recommendation.

**Fix shipped: two-phase status text, no new UI.** The status poll must not call `System.exit()` itself — unsafe mid-session or mid-menu — and users already know how to restart the app, so the fix is wording only. The feed knows nothing about UI: `BeatIntervalFeed.pollStatus()` returns the status and counts error seconds, `errorSeconds()` exposes the counter, and `SessionPickerDelegate.updateHrvStatus()` turns that into the text via `Utils.getHrvStatusText(status, errorSeconds)`, the recovery blip (`Good` while the counter drops from > 0 to 0) and the backlight pulse (every fifth counted error second):

- First ~18 s of Error status (`errorSeconds <= Utils.HrvRestartHintAfterErrorSeconds`): alternates every 2 s between `HRVstarting` ("HRV starting") and `HRVstartingAlt` ("Please wait") — `((errorSeconds - 1) / 2) % 2 == 1`, free-riding on the counter that already ticks once per second, no new timer. 18 is a multiple of the 2 s block size, so the handoff to `HRVrestart` lands right after a complete block, not mid-block — keep the threshold a multiple of the block size if either changes (both constants live in `Utils`). Most successful runs resolve in 1–3 s, so this covers the common case without alarming anyone.
- Beyond that: `HRVrestart` — "Restart the app". Justified by the data: RR never once recovered mid-run past this point in any measured run (up to 320 s), only on the next launch — so there is no case where waiting past ~18 s helps and telling the user to restart does not.
- The old `HRVwaiting` id and its "the app already ships a :sensorRestart setting" framing are superseded — the setting still exists but is no longer the documented answer; the status text itself now says what to do.
- Non-English translations for `HRVstarting`/`HRVrestart` are best-effort, not native-reviewed — worth a spot-check per locale before release.
- **The hint stays up until the sensor really delivers.** `errorSeconds()` is only reset on recovery
  (`Good` after errors → "Ready" + blip) or by `resetSensorQuality()`. It used to be set back to
  1 by `ensureWakeupSession()` once the counter passed 60, which flipped the text back to "HRV
  starting / Please wait" for 18 s every minute; `ensureWakeupSession()` now only recreates a
  missing wakeup session and touches nothing else.


**Do not re-propose `setEnabledSensors`/`enableSensorType`/ordering changes, and do not add more in-app retry logic** — all tested and rejected, several repeatedly across four years of git history.

Useful facts: HR availability is **not** a proxy for RR availability; warm latency is ~2 s; spin-down is >45 s.

Full investigation, all measurements, the six rejected hypotheses and the method mistakes that produced three wrong conclusions: **[`HrvProbe/FINDINGS.md`](HrvProbe/FINDINGS.md)**. The diagnostic app itself: [`HrvProbe/README.md`](HrvProbe/README.md) — use it before theorising about this again.

### Invariant: at most one open `ActivityRecording` session

`ActivityRecording.createSession` **returns the existing Session object** if one is open rather than creating a new one (documented, not an error). So any code path that leaves a stopped session unsaved/undiscarded silently corrupts the *next* session: `ActivityRecorder.initialize` gets handed the old object, `FitFields.create` re-adds `min_hr` to it, and the next meditation records into the previous session's file under its sport and name.

The invariant is two adjacent lines in `MeditateActivity.initialize`: `mFeed.discardWakeupSession()` immediately followed by `new ActivityRecorder(spec, me)`. Keep them adjacent.

`SaveDiscardMenuDelegate.onBack()` used to pop without saving or discarding, leaking exactly that. It now invokes the save callback — **back on the save/discard prompt saves**. `ActivityRecorder.finish()`/`discard()` both null-check `mFitSession`, so a later close can't double-fire.

A `discardDanglingActivity()` was once written for this but never wired up (`SummaryViewDelegate` stored the callback and never invoked it); both were deleted rather than left as dead code. Don't reintroduce a defensive discard before creating the recorder — that hides a leak instead of closing it. Close the session where it's created.

The unit tests hit this too: the test runner boots the app, whose `getInitialView()` opens the sensor wakeup session, so a test that creates a session gets *that* one. `RecordingFlowTests.closeAppWakeupSession()` discards it first; without that, `MeditateApp.onStop()` dies on an invalid session after the tests.

### Flow: check for new devices to support

**Goal: surface only genuinely new watch releases.** A raw SDK-vs-manifest diff returns ~76 entries that are *not* new — they're non-wrist hardware and old watches already intentionally dropped. Folder timestamps can't distinguish new from old (they all reset to the SDK install date). So the diff is filtered against a curated baseline of known exclusions; anything left over is a genuinely new device to evaluate.

Trigger whenever Garmin releases new watches (or after an SDK update):

1. List device ids in the SDK `Devices/` folder (folder names).
2. Diff against `<iq:product id=...>` ids in `Meditate/manifest.xml`.
3. Filter out non-wrist hardware, the dropped-watch baseline, and anything below the **512 KB** floor (see above). Whatever remains is **new and viable** — report it with its memory.
4. For each candidate, propose adding `<iq:product id="<deviceId>"/>` to `Meditate/manifest.xml`. If a candidate is non-wrist or otherwise unwanted, add its id to `$excludeExact`.
5. Rebuild in the simulator against one new device to confirm it compiles.

The memory gate auto-drops sub-512 KB devices (e.g. `instinct3solar45mm`), so the name baseline only needs non-wrist prefixes plus capable-but-unwanted old watches.

```powershell
# Non-wrist hardware — never a target for a meditation app (note: d2* are wrist aviation watches, NOT excluded)
$excludePrefixes = 'approach','edge','gpsmap','oregon','montana','rino','etrex','descent'
# Capable (>=512 KB, CIQ >= 3.0) but intentionally excluded — see "Minimum memory requirement" above
$excludeExact = @(
  'vivoactive3m','vivoactive3mlte',      # array-out-of-bounds crash on session finish (240x240 layout); in no manifest
  'system8preview'                       # SDK System-8 preview pseudo-device, not a real watch
)
# Recent additions, skipped via $man: vivoactive4/4s and marqexpedition (back after the Apr-2025 purge),
# fr70/fr170/fr170m (CIQ 6.0, 768 KB), the 7 fenix 9 variants (CIQ 6.0.3, 768 KB, fenix 8 resolutions).
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

Unit tests live next to the code they cover. They use Connect IQ's `(:test)` framework and
return `true`/`false`; a full run takes ~30 s. Run them after any change, and before a release also
on `d2deltapx` (CIQ 3.0.3, the app's API floor), where a call newer than the floor fails.

- `recording/tests/MetricTests` — the window engine against a scripted `read()` (flush on the
  completing tick, skipFirst, range, 90 % rule, keepHistory off, stats over window values).
- `recording/tests/BeatIntervalFeedTests` — the sensor listener fed fake `SensorData`: cleaning,
  pause, the Weak/Good/Error thresholds, error seconds on screen only, no reset past 60.
- `recording/tests/RecordingFlowTests` — `ActivityRecorder` and `MeditateActivity` start → tick →
  pause/resume → stop → summary → every summary page, against a real simulator FIT session.
- `recording/hrv/tests/HrvMetricTests` — RMSSD 38.37 / pNN20 33.33 / pNN50 16.67 / SDRR 26.95 on
  the six fixture intervals, rolling value per window, differences across windows, sticky `On`,
  SDRR first = ticks 1-300 and last = the final 300 ticks (identical below 300).
- `recording/hrv/tests/HrvSdrrTests` — the original SDRR expectations (`HrvAlgorithmsSampleOutput.xlsx`)
  ported to the ring of seconds: several beats in one second, empty seconds that push beats out.
- `activity/tests/MetricLineTests` — the metrics page row states.
- `activity/tests/FitSessionTests` — `FitSessionKind` numbers (stored), the kind per activity type
  with and without API 3.3.6, sport and sub-sport per kind as FIT profile numbers (a missing stored
  kind records as training), the `[time]` formatting and 21-character cut, and which name wins
  (session name, the phone's `activityName`, the type's title).
- `summaryScreen/tests/SummaryPagesTests` — the page set per HRV mode.
- `sessionSettings/tests/SessionPickerHrvStatusTests` — the picker's HRV line through the real
  delegate: starting texts, restart hint that stays past 60 s, weak, ready.
- `sessionSettings/tests/SessionEditorTests` — the session editor through the real settings menu:
  an edit changes only that field, a null activity type / HRV stays null (never filled with the
  global default), picking one stores it, an emptied program is stored as null, and opening the
  editor writes nothing.
- `storage/tests/SessionHistoryTests` — the session suggestion lookup as pure functions (newest
  within the hour, nearest routine re-centred, 3 h reach, midnight, first starts vs followers,
  followers by time, drop, append cap) and through real storage: launch moves only a picker the
  user left alone, a delete is not a user move, a deleted key is forgotten, Off forgets.
- `storage/tests/SessionStorageTests` — the stored session format round-trips unchanged, the enum
  numbers inside stored sessions, fresh-store presets, the one-time breathwork preset migration,
  index wrapping, delete-all restoring presets, new keys never reusing a used one, and the selection
  after a delete (through the real settings menu, with a `PickerSpy` for the picker).
- `globalSettings/tests/GlobalSettingsTests` — every setting key and default typed out as the
  released app stores them (missing → default, stored value → back unchanged, same type), the
  numbers of every setting enum, and the session/wakeup/usage-stats key strings.
- `globalSettings/tests/GlobalSettingsMenuTests` — the settings table matches the old hand-built
  menus row by row (order, stored key, option values, hint positions), and the subtitles show the
  stored value (`00:45`, `05:00`, labels) through the real `updateMenuItems()`.
- `tests/OptionMenuTests` — the shared option lists keep the old menus' values and order (vibe
  patterns for sessions and alerts, activity type, HRV tracking with its Default hint), a null vibe
  pattern reads as no notification, `indexOf` matches by value.
- `com/tests/MonthlyStatsTests` — the monthly minutes add up within a month, a new month after
  30 minutes starts over and leaves the tip prompt pending, no session time changes nothing.
- `screenPicker/tests/IconGlyphTests` — the icon font loads and every glyph the code uses is one
  private-use character (catches a blanked or retyped glyph).

**Tests run against the developer's own simulator data**, so a test that writes `App.Storage` or
`App.Properties` restores it. `StorageSnapshot` does this for sessions and the session history (its key strings are
literals on purpose: they are the stored format); the settings tests save and restore their keys.
A test that writes a session list must also write a dict for every key in it, or
`loadSelectedSession()` takes its destructive recovery path.

**Annotate the whole test and fixture classes `(:test)`, not just the functions** — a bare fixture
class costs ~400 B in the release PRG, a `(:test)` class costs 0 B (measured on `fr255s`).

**Check once that a new test can fail**: run it against the broken code (the fix reverted, a value
swapped). A test that cannot fail proves nothing.

Run from the CLI (the simulator is started if it isn't running; VS Code's "Run Tests" does the same):

```bash
SDK="$APPDATA/Garmin/ConnectIQ/Sdks/<current sdk>"
cd Meditate && "$SDK/bin/monkeyc.bat" -o /tmp/test.prg -f monkey.jungle -d fr255s -y <developer_key> -t -w
"$SDK/bin/simulator.exe" &   # once
MSYS_NO_PATHCONV=1 "$(cygpath -w "$SDK/bin/monkeydo.bat")" "$(cygpath -w /tmp/test.prg)" fr255s /t
# a single test: ... fr255s /t SessionStorageTests.newSessionNeverReusesAKey
```

- **In Git Bash, `/t` gets rewritten into a file path** and monkeydo only prints its usage text;
  hence `MSYS_NO_PATHCONV=1`, which in turn means every path must already be a Windows path.
- `monkeydo` blocks until the simulator answers, so wrap it in a timeout (`timeout 300` in Git
  Bash, or a PowerShell job with `Wait-Job -Timeout`). **A run that prints nothing until its
  timeout usually means the simulator has exited** — check for `simulator.exe` and restart it.
  Run one device per command so progress stays visible.
- **Upgrade tests in the simulator:** it keeps the app's data in
  `%TEMP%\com.garmin.connectiq\GARMIN\APPS\DATA\MEDITATE.DAT` (named after the app, not the build),
  so running an older build and then a newer one over the same data is a real upgrade. Copy
  `MEDITATE.DAT`/`.IDX` aside first and put them back afterwards.

## GitHub Actions

No CI pipeline builds or tests Monkey C code. GitHub Actions handle only image compression, content
translation, and user guide publishing.

### codex-action is pinned to v1.11 — check upstream before every release

`.github/workflows/translate-content.yml` runs `openai/codex-action@v1.11`, deliberately **not**
the floating `@v1`. Since v1.12 (2026-08-21) the default `safety-strategy: drop-sudo` chmods the
runner's D-Bus socket, `systemd-resolved` crash-loops, DNS on the VM dies, Codex hangs unable to
reach the API and GitHub kills the job ~60 min later with *"The hosted runner lost communication
with the server"* — the only annotation on the job, no step error. Runs 47–49 (Sep 2026) all died
that way; the last green run took 2 min. Upstream: [openai/codex-action#160](https://github.com/openai/codex-action/issues/160).
`main` is branch-protected — workflow fixes go through a PR, and merging one retriggers the
translation run because the workflow file is in its own `paths` filter, so the merge is the test.

**Before every release**, and whenever this workflow fails again, check whether a better
mitigation exists (`curl -s https://api.github.com/repos/openai/codex-action/tags | grep name`,
plus the issue above):

- Issue closed / a release newer than v1.12 fixes `drop-sudo` → move back to `@v1` (or the fixed
  tag), merge, and confirm the Codex step finishes in minutes, not an hour.
- v1.11 stops working (API change, model no longer accepted, CLI too old) → next best is
  `@v1` with `safety-strategy: unsafe` (the bwrap `workspace-write` sandbox still applies). Not
  `read-only` — it cannot write `generated/`.
- Diagnosis without a token: job annotations are public,
  `curl -s https://api.github.com/repos/floriangeigl/Meditate/check-runs/<jobId>/annotations`
  (the job id from the Actions URL is the check-run id); the `/logs` endpoint needs auth.

## Code Style & Conventions

### Naming

| Element           | Convention            | Example                           |
| ----------------- | --------------------- | --------------------------------- |
| Classes / Modules | PascalCase            | `MeditateActivity`, `VibePattern` |
| Methods           | camelCase             | `loadSelectedSession()`           |
| Private fields    | `m` prefix            | `mSessionStorage`, `mHrvTracking` |
| Public fields     | camelCase (no prefix) | `elapsedTime`, `currentHr`        |
| Enum values       | PascalCase            | `NoNotification = 0`              |
| Storage keys      | `XxxKey` constant     | `"globalSettings_hrvTracking"`    |

### Patterns

- **MVC-like**: Model (data) → View (render) → Delegate (input). Example: `MeditateModel` / `MeditateView` / `MeditateDelegate`.
- **`me.` prefix** used consistently for instance member access.
- **Composition over inheritance**: `MeditateActivity` owns an `ActivityRecorder`, which owns the `Metric` list — there is no activity class chain any more.
- **Dictionary serialization**: Models use `fromDictionary()` / `toDictionary()` for `App.Storage` persistence.
- **Settings**: `GlobalSettings.load(key)` / `save(key, value)` with `XxxKey` constants; the defaults are an if-chain (`defaultFor`) and `keys()` lists the same keys. No cached table, by decision (see runtime memory learnings). Key strings and defaults are stored data; `GlobalSettingsTests` types them all out, so a rename or a changed default fails a test instead of silently changing every user's app.
- **Top-level classes, no modules**: the one exception is `module StatusIconFonts`, which only holds the icon font loaded at startup.

### Formatting

- Tab indentation, LF line endings
- Format-on-save enabled via Prettier Monkey C
- Braces on same line: `function initialize() {`
- Comments: concise, lowercase, no full sentences — just the point (e.g. `// clear stale paused; else multi-session drops HRV after session 1`). One line, not a paragraph — this applies to agent-written comments too, don't explain background/history/rationale inline, that belongs in the commit message

### Commit Messages

- **Always super concise.** Lead with the behavior change (what the user notices); add technical detail only if it's needed to understand the change.
- Start with **user-facing release notes** (what changed for the user)
- Follow with **technical details** below (implementation specifics, files changed, reasoning) — only when they add necessary context
- **No special characters** that shells may misinterpret: avoid parentheses, colons, slashes, quotes (apostrophes too), brackets, backticks, and dollar signs in the message text. The `Co-Authored-By:` trailer is the one exception.
- When providing via terminal, use the temp-file approach: write the message to a file, stage explicit paths (`git add <paths>`), `git commit -F <file>`, then delete the file. Avoid `git commit -a`: it sweeps in every modified tracked file, including someone else's work in progress in the same tree.
- **After creating a commit, read the commit message back verbatim** in the reply — do not just assert that it follows the convention

### Release Notes

- **Always customer-facing, value-focused, super concise.** Describe what the user gets, not how it was built.
- No internal/technical detail (file names, refactors, SDK plumbing) — that belongs in commit messages only.
- **Always hand them over as a fenced ```markdown code block, ready to paste** into the store listing or GitHub release — never as rendered prose in the reply.

## Architecture

### App Flow

```
MeditateApp.getInitialView()
  → BeatIntervalFeed.startup()
  → SessionStorage (load sessions / presets)
  → SessionPickerDelegate (carousel)
    → [Start] → Preparation → MeditateActivity → Finalization → Save/Discard → Summary screens
    → [Multi-session: intermediate menu → next session or rollup exit]
```

### Recording: one engine, composition, one summary map

`Meditate/source/recording/` never references `GlobalSettings`, `Rez`, `Vibe` or `Ui` — everything
comes in through constructor arguments. Keep it that way; it is what makes the tests possible.

- **`Metric`** is the sampling engine for every live value: a fixed tick `window`, optional `lo`/`hi`
  range, `skipFirst`, `liveBeforeWindow` (HR shows the raw sample until the first window closes),
  `keepHistory`. `sample(info)` → `accept(read(info))` → window closes **on the tick that completes
  it**; `flush()` at the end keeps a partial window only if ≥ 90 % filled or the history is empty.
  `min`/`max`/`first`/`last`/`getAvg()` are **over the window values**, the same numbers the graphs
  draw — the details pages can no longer disagree with the graph. `flush()` runs once and makes the
  metric inert: a tick that lands after the summary can neither change the rollup nor touch a FIT
  field. `FitFields.set` converts to the field type (UINT16 → rounded Number, else Float) because
  `Field.setData` throws on a type mismatch; `create` skips unknown and repeated ids.
  **Configs shipped:** `HrMetric` {10 s, live before window}, `StressMetric` {30 s, 0..100, live
  before window}, `RrMetric` {30 s, 1..99, live before window}, `HrvMetric` below. So only the HRV
  row counts down; HR, stress and respiration show the watch's own value from the first tick and
  switch to the window mean once the first window closes (`RecordingFlowTests.onlyHrvCountsDown`
  pins this). `skipFirst` is engine-only since 2026-09: respiration used to skip its first tick
  because the 2025 `RrActivity` noted *"device returns 15 or 14 incorrectly as first mesure"*; if
  that placeholder shows up again on a device, `me.skipFirst = true` in `RrMetric` is the fix and
  `getLoadTime()` already accounts for it.
- **HRV is a metric too, sampled on the tick.** `BeatIntervalFeed` has one listener slot; during a
  session it is `HrvMetric.onIntervals`, which only *buffers* the second's cleaned intervals. The
  recorder tick then consumes the buffer like any other sample (`read()` returns and clears it),
  so every window, history and load time runs on recording seconds, frozen while paused. The
  buffer is bounded because the feed is paused whenever the timer is. One previous-interval
  tracker feeds everything: signed last difference (the `On` live value, FIT `hrv_successive`),
  Σd²/pairs (session RMSSD), |d| > 20/50 counters (pNN, denominator = beats incl. the first, per the
  1996 Task Force / Mietus 2002 definition — N−1 pairs is an alternative convention, deliberately
  not used; the (N−1)/N gap is invisible over a real session, don't re-propose it), and
  in `Detailed` the window Σd²/n (rolling RMSSD = live value + history + FIT `hrv_rmssd_rolling`),
  the per-beat FIT records and the `HrvSdrr` ring (population sd, ≥ 2 beats). **SDRR windows
  are 300 recording seconds, not 300 beats** — the old ring counted beats, so "5 min" was only
  true at 60 bpm. One ring holds the last 300 ticks, each slot the interval array `read()`
  handed over that tick (owned by the caller once `read()` swapped in a fresh buffer, so no
  copy); `sdrrFirst` is snapshotted on the tick the ring first fills, `sdrrLast` computed at
  `flush()`, and a session shorter than 300 ticks gets the same value for both. The tick is the
  clock (frozen while paused) — don't switch it to `info.timerTime`, and don't reintroduce a
  second `keepFirst` ring. Cost: 11.75 KB for a full ring (~360 beats) vs 3 KB for the old two
  float rings, released at flush; if that ever matters, the flat variant is a ring of intervals
  plus a ring of per-second counts (~4.6 KB) at the price of overflow bookkeeping when a second
  holds more beats than the free slots. Differences continue across window boundaries. `flush()` writes the
  FIT session fields and then drops the buffer, ring and `FitFields` reference — the rollup
  keeps only the light object with `rmssd`, `pnn20`, `pnn50`, `sdrrFirst`, `sdrrLast`,
  `history`, `detailed`.
- **`ActivityRecorder`** owns the FIT session, `FitFields`, the 1 s `Timer` and `elapsedTime`.
  `onTick()` samples every metric while recording, then calls `listener.onTick()`. `summary()`
  flushes each metric into `ActivitySummary.metrics[id]` and writes `min_hr` from the HR metric's
  window minimum — call it **before** `stop()` so session fields land in the file.
- **`MeditateActivity`** composes the recorder (no inheritance chain any more):
  `createMetrics(meditateModel, fitFields)` is the one place deciding what is recorded, in metrics
  page order; `start()`/`pauseResume()`/`stop()` wire the feed exactly as before (multi-session and
  picker invariants above). `stop()` caches the summary, `getSummary()` hands it to
  `MeditateDelegate`.
- **`MeditateModel.liveMetrics`** is the metrics page order (HR, HRV, stress, RR); the view reads
  `getMetric(id).getValue()` / `getLoadTime()` and never samples.
- **`ActivitySummary`** = `elapsedTime`, `sessionName`, `metrics {id → flushed Metric}`; ids `:hr`,
  `:hrv`, `:stress`, `:rr` are the join key for the live page, the summary pages and the rollup.
- **The metrics page is a loop, the summary is a table.** `MeditateView.onLayout` builds one
  `MetricLine` per entry of `liveMetrics` (icon from `MeditateView.createIcon(id)`, the only
  id → icon mapping, also used by the summary details page); `MetricLine.update(value, elapsed)`
  is the whole per-row state machine — hourglass + countdown until the first value, "--" once the
  load time has passed, the metric icon once loaded, grey after a loss or while paused.
  `SummaryViewDelegate.initialize` holds the page table `[id, kind, title, yMin, yMax]` in today's
  page order; presence by kind: `:graph`/`:details` need `metrics[id].hasData()` (the `:hr` graph
  is always there so the picker never has zero pages), `:hrvRmssd` needs `metrics[:hrv]`,
  `:hrvGraph`/`:hrvPnnx`/`:hrvSdrr` need `metrics[:hrv].detailed`. Build the table in
  `initialize()` — resource ids are not safe in static initialisers.
- **Adding a metric** = one `XxxMetric` class (~15 lines), one line in
  `MeditateActivity.createMetrics`, one case in `MeditateView.createIcon`, one row in the summary
  page table. `SummaryPagesTests` pins the page set per HRV mode; `MetricLineTests` the row states.

### Finish flow: `MeditateDelegate` outlives the session

`MeditateDelegate` is passed as the input delegate for the post-session `DelayedFinishingView`s ("calculating results"), not just for `MeditateView`. So its in-session gestures stay reachable **after** the activity has been stopped and its FIT session saved or discarded — at which point `ActivityRecorder.mFitSession` is `null` (nulled by `finish()`/`discard()`) and any `pauseResume()`/`stop()` on it throws **"Unexpected Type Error"**.

Guarded by `mActivityStopped`, set once in `stopActivity()` (the single choke point — only `stopFromPauseMenu()` and `onSessionAutoComplete()` reach it) and checked in `onBack()` and `onKey()`. A fresh `MeditateDelegate` is built per session in `SessionPickerDelegate.startMeditationSession()`, so the flag is never reset.

**Do not add in-session input handling to `MeditateDelegate` without checking that flag**, and do not add a null guard in `ActivityRecorder.pauseResume()` instead — that hides the stray pause menu rather than preventing it. Two production crashes came from this (v10.7.10): back on the post-save spinner → pause menu → back (`resumeFromPauseMenu`), and the same menu → "Stop" (`stopFromPauseMenu`). The stray menu also froze the flow, since `pushView` triggers `DelayedFinishingView.onHide()` which stops its 1 s timer.

Related: `MeditatePrepareView` (prepare/finalize countdowns) uses `MeditatePrepareDelegate`, which swallows keys and maps back to "skip countdown" — that path is unaffected.

**Auto save & exit relies on `System.exit()` letting the current function finish.** The first
`DelayedFinishingView` already carries the exit flag, and its `onViewDrawn` calls `System.exit()`
*before* `mOnShow.invoke()` → `onFinishActivity()` → `finish()` saves. The docs don't say whether code
after `exit()` runs; verified on hardware (fēnix, 2026-09-26) that it does and the activity is saved.
If a device ever loses Auto save & exit activities, pass `false` to the first finishing view so only
the second one, after `finish()`, exits.

**Storage next to the FIT save is proven safe.** The 2019 fix (`7bf00ca`) keeps next-session storage
work and the save apart by a 1 s finishing view, yet `MeditateActivity.finish()` has written the
wakeup type, monthly minutes and analytics queue in the same call as `save()` for years without a
corrupted activity. The comment in `onFinishActivity` still describes the 2019 order (settings first);
auto-save now saves first and builds the next view a second later.

### Per-second metrics are sampled on the activity tick, never in the view

`ActivityRecorder.onTick()` (the 1 s timer) is the single place that samples every metric
(`Metric.sample(info)`), then `MeditateActivity.onTick()` updates `elapsedTime` and the breath
runner and fires alerts/cues. `MeditateView.onUpdate()` only reads `getMetric(id).getValue()` — a
pure read of the last sampled state. Stress and respiration used to be sampled *inside* the view's
metrics draw (the old `getCurrentValue()` appended a sample as a side effect), so any session whose
view skipped that draw — the breathwork guidance page — recorded no stress/RR at all. Never give a
view anything that mutates a metric.

### Stress: live score on API ≥ 5, logged snapshot below

`ActivityMonitor.Info.stressScore` (API 5.0.0, "rolling average of the last 30 seconds") is an
**instance** attribute — read it from `ActivityMonitor.getInfo()`, never from the `Info` class
(`Toybox.ActivityMonitor.Info.stressScore` compiles and is always null; commit 44a4251 noted "seems
not providing data" and the app silently ran on the fallback for years). Below API 5 the fallback
is the newest non-null `SensorHistory.getStressHistory` sample, i.e. the watch's logged snapshot
that updates every few minutes; once the live read has delivered a value once the latch
(`StressMetric.mLiveSeen`) stops falling back. **Verified on hardware (2026-09-15): the watch keeps
computing `stressScore` while a CIQ activity records** — the live value moves during the session.
If a device ever leaves it null, the latch never sets and the snapshot fallback is what it keeps.
Because the score is already a 30 s rolling mean from the watch, the app's own 30 s window is a
second smoothing layer that exists for the graph buckets; the live row shows the raw score
(`liveBeforeWindow`) — there is nothing to wait for.

### Respiration rate: what Garmin actually provides

`ActivityMonitor.Info.respirationRate` (API 3.3.0) is "the current respiration rate for the user"
— the watch's *latest* estimate, not something computed for our session. Garmin/Firstbeat derive
it from the heartbeat rhythm: respiratory sinus arrhythmia (beat intervals shorten on inhale,
lengthen on exhale), extracted from the optical beat-interval signal. Update cadence and averaging
are undocumented; wrist accuracy is quoted at ~0.5–1.5 brpm at rest and degrades with motion — fit
and stillness are the dominant error sources.

Garmin documents that its **native** activity profiles record wrist-based respiration only for
Breathwork, Yoga and Health Snapshot (others need a chest strap). **That rule does not gate the
CIQ value: verified on hardware (2026-09-15), a session recorded under `SPORT_MEDITATION` shows
respiration values on the metrics page.** Don't tell users to switch to Yoga for respiration. The
README's 2025 "only works fine for Yoga … bug for Breathing activity" note concerns the Breathing
sub-sport specifically and is unverified today. The 2025 `RrActivity` observation of a first
reading of 14/15 brpm is why `skipFirst` existed; its cause is unknown.

Stress summary pages (graph + details) are shown whenever the stress history holds a non-null
window value (`metrics[:stress].hasData()`), independent of the HRV setting — stress is sampled
and shown live regardless of HRV, so hiding its summary with HRV Off was an accident.

### FIT fields: code and `hrvFitContributions.xml` must agree

Every field id created in code has a `<fitField id=…>` row in `Meditate/resources/hrvFitContributions.xml`
and label strings in `hrvFitContributionsStrings.xml` for **all 9 locales**, and nothing else:
ids 0, 6–13, 16. Ids 1, 15, 17 were declared for years with no code writing them and were
dropped. Check `bin/Meditate-fit_contributions.json` after a build — it lists exactly the
declared set. Field ids are FIT compatibility — never renumber.

### Key Source Directories

All under `Meditate/source/`:

- `activity/` — the running session: `MeditateActivity`, views, delegates, vibration alerts, breath cues, FIT naming
- `recording/` — sensor feed, FIT session, the `Metric` engine and HR/RR/stress metrics; `hrv/` — HRV (RMSSD, SDRR, pNNx)
- `summaryScreen/` — post-session summary pages and graphs
- `sessionSettings/` — session picker and editor, interval alerts, breath programs (`breathProgram/`), color and duration pickers (`colorPicker/`, `customPicker/`)
- `globalSettings/` — `GlobalSettings` (`load`/`save` by key) and the settings menu
- `storage/` — session CRUD, presets, the preset migration
- `screenPicker/` — page carousel delegate, details views, status icons, the icon font
- `OptionMenu.mc` — the shared choose-one menu and its option lists
- `com/` — GA4 analytics (`UsageStats`), monthly minutes and the tip prompt (`MonthlyStats`)
- `about/`, `help/` — About, What's New, the help pages; `devTools/` — the hidden cloud backup/restore

### Breath Programs (guided breathwork)

A session may carry an optional **breath program**: an ordered list of steps, each a fixed
4-slot pattern (`inhale / holdFull / exhale / holdEmpty`, seconds, `0` = skip) plus a repeat
rule (N rounds, or a duration). A pure breath-hold is just a step whose only non-zero slot is
a hold — there is no special case for it.

- **A rest step ("breathe freely") is `[0,0,0,0]` + Duration repeat** — no extra field or
  storage key; `BreathStep.isValid()` accepts exactly that zero-cycle shape and `isRest()`
  names it. Older app versions reject it in `fromDictionary` and just drop the step. The
  runner maps it to `BreathPhase.Rest` (value 4, runner-only — `PhaseCount` stays 4). The
  pattern editor deliberately cannot produce one (`applyPhase` reverts a zero cycle); rest
  steps get their own reduced menu (duration, move, delete) in `AddEditBreathStepMenuDelegate`.
- **The guidance-page phase word is capped by the text circle's chord at the word row**, not by
  a fraction of screen width (`BreathGuidanceRenderer.layout`, via `Utils.fitFont`). On
  `fr255s` that chord is ~129 px: "Breathe freely" fits at `FONT_SMALL` (121 px), while
  "Breathe normally" was 130 px even at `FONT_TINY` — which is why the rest word is "freely".
  Measure new phase strings on a 218 px dc before shipping them; long ones need shorter
  translations, not a wider cap.
- **Gate on `SessionModel.hasBreathProgram()`, never on `ActivityType.Breathing`.** The stored
  activity type and `Utils.getEffectiveActivityType()` diverge on the 8 vívoactive4/venu part
  numbers, so gating on activity type would show breathwork UI in *meditation* sessions there.
- **Degenerate programs count as absent.** `getActiveBreathProgram()` returns null for an empty
  program or one totalling 0s, and the session falls back to today's behaviour.
- **`SessionModel.time` stays the runtime source of truth.** The program editor recomputes
  `totalTime()` and writes it into `time` on every edit, so the session arc, auto-stop,
  interval-alert percentages and the picker card need no program awareness. Keep it that way.
- **`BreathProgramRunner` is a pure function of `elapsedTime`** (`activityInfo.timerTime / 1000`,
  which freezes while paused), so pause/resume needs no saved state. It precomputes only the
  per-step start offsets — never expand rounds into a flat timeline, that is thousands of
  entries for a long program.
- **Cues are edge-triggered on `phaseStart`**, not on `phaseElapsed == 0`, so a dropped timer
  tick fires late instead of not at all. Same reasoning as `VibeAlertsExecutor.pointCrossed`.
- **Interval alerts still work** and coexist with a program. Their tick ring is drawn on the
  metrics page; the guidance page draws step-boundary ticks on the same ring instead.
- `restorePresets()` runs only on a fresh store, after the last session is deleted, and in the
  corrupt-entry path of `loadSelectedSession()`. Existing users got the guided presets through
  `migratePresets()` (below), not through a restore.
- **`BreathTemplates.createProgram` is the single definition of each shipped program**;
  `SessionPresets` only wraps it in a session. There is no separate template-picker UI —
  `Add New` deliberately creates a plain empty session, exactly as it did before breathwork
  existed, and all four activity types stay reachable from the session's Activity Type row.

- **The breathing route (nose/mouth) is per step, not per program**, so a program can switch
  routes as it goes. `BreathStep.getRoute(phase)` / `setRoute(phase, route)` are the accessors;
  holds always return `Unset`.
- **Template routes are not arbitrary — they follow the source techniques.** Don't "tidy" them
  to be uniform: 4-7-8 exhales through the **mouth** (Weil's whoosh), coherent/resonant
  breathing is **nasal both ways**, box breathing is nasal in and tolerates either out, and
  power breathing (the `:breathHolds` template) is **nose in / mouth out** with the retention on
  empty lungs followed by a recovery breath held full.
- Avoid naming templates after living people; `:breathHolds` is deliberately generic.
- **Preset session keys are persistent ids and must never be renumbered.** Breathwork owns
  keys 7-12 (`SessionPresets.FirstBreathworkKey`); 7-9 shipped before guided programs existed,
  10-12 came with them. A stored session is matched back to its preset by key alone, so a new
  preset of any kind takes the next free key at the end. `SessionStorage.migratePresets()` runs
  once (gated by `globalSettings_presetsVersion`) and depends on this: it rewrites 7-9 in place
  when the stored name still matches the shipped one and there is no program yet, and adds
  10-12 when absent. Deleted presets stay deleted - 7-9 are never re-added, 10-12 never
  overwritten. The upgrade edits the *stored* session (program, time, cleared alerts) rather
  than replacing it, so colour, vibration and everything else the user chose survives.
- **Shipped programs repeat in rounds, never by duration**, so a session never cuts off
  mid-breath. That is why some totals are a few seconds off the nominal length (Box and 4-7-8
  are 5:04, not 5:00) — don't "round them back" to a duration repeat. Duration repeat stays
  available to users; it just isn't what the presets use.

**The breath step editor's two rules** (see the header comment in
`AddEditBreathStepMenuDelegate`): nothing mutates the step before a picker returns — a seed
value goes in and the accept callback writes type and value together, so backing out is a real
cancel; and no state is parked across a `pushView` — what is being edited rides on its own
callback, never on a field. Both existed as bugs first: a repeat-type switch that mutated up
front left a stale row and a stale session length when the picker was backed out.

**Known rough edges, reviewed and knowingly left as-is** (don't "discover" them again):

- **Session outliving the program**: with Auto Stop off, or after `Resume` on the completed
  pause menu, `elapsedTime` passes the program total. The runner clamps (`isDone` holds the
  final phase), so the word/countdown freeze at `1`, the phase ring stays full and cues stop,
  while the outer session ring wraps into a second lap. Not crashing, just confusing.
- **Two vibes at session start**: `MeditatePrepareView` fires its closing `Blip` and the first
  Inhale cue lands immediately after, from `BreathCuesExecutor`'s constructor.
- **Phase picker offers up to 59:59** but `applyPhase` silently clamps to `MaxPhaseTime`
  (9:59). Only the all-zero step gets a toast.
- **`isHoldOnly()` names a both-ends hold by the sum**: `[0,30,0,30]` renders as `Hold 1:00`.

Three gotchas that *were* fixed and must stay fixed: `ElapsedDurationRenderer`'s arc draws
nothing at exactly 100% (start == end degree), so `drawProgressPercentage` caps at 99.9;
`Ui.Confirmation` pops itself, so a confirmed delete needs exactly one `Ui.popView`; and an
empty `BreathProgram` must never reach storage — `SessionModel.toDictionary` writes `null` for
one, and `BreathProgramMenuDelegate.onBack` only notifies when something actually changed, so
opening the editor and leaving cannot attach an empty program.

Files: `Meditate/source/sessionSettings/breathProgram/` (model, templates, menus),
`Meditate/source/activity/BreathProgramRunner.mc`, `BreathCuesExecutor.mc`,
`BreathGuidanceRenderer.mc`.

### Session suggestion: the picker opens on the routine

`SessionHistory` (`storage/`) makes the picker open on the session usually started at this time
of day, and "Next session" in a multi-session on what usually follows. Setting "Learn routine"
(`GlobalSettings.LearnRoutineKey`, default on). User model: *opens where you left it; if you didn't
touch it, on the session you usually start now.* Principle: rarely worse than today (last selected),
never against the user's own choice.

- **Data:** `sessionHistory`, a flat array of the last 50 starts, 3 ints each:
  `[sessionKey, minuteOfDay, prevKey]`; `prevKey` is the session started before it in the same
  launch, null for a first start. Recorded in `startMeditationSession()` **before** the
  `MeditateDelegate` opens the FIT session (storage writes and FIT saves must not overlap).
- **One lookup** (`pick(log, prevKey, minute)`) for launch (prevKey null) and followers: newest
  start with that prevKey within ±60 min, else re-centre on the closest one within 180 min and take
  the newest there, else null (don't move). Last used wins by design (the user chose immediate
  adaptation); re-centring stops an abandoned session a minute closer from winning. Followers are
  matched by time too: one opener can lead to different sessions morning and evening.
- **"You moved it, it stays":** `sessionAutoKey` is the key the app last put the picker on (a
  start, an applied suggestion, the neighbour after a delete). `pickAtLaunch` only moves the picker
  when the selection still equals it. Scrolling is the signal, not editing: tweaking the session you
  just did must not pin it for the next morning. A delete re-marks the new selection as the app's.
- **Off forgets lazily:** `pickAtLaunch` clears both keys when the setting is off, so the generic
  settings menu needs no special case.
- **Multi-session:** `MeditateDelegate` looks up `nextSessionKey()` once, when it builds the
  post-session menu, and keeps it in `mNextSessionKey`. The "Next session" sublabel names it only
  when a follower is learned (Off and "nothing learned" look exactly like before), and the tap
  moves there via `moveTo()`, so the label and where the tap lands cannot disagree however long the
  menu stays open. Nothing moves before the tap, so "End multi-session" leaves selection and auto
  key consistent.
- **Storage writes:** `markAuto` writes only on a change (the picker marks on nearly every launch,
  same rule as `selectSession`); `append` trims to the cap, not by one.
- **Deleted keys are forgotten** (`forget`, entries with that key or that prevKey), because
  `generateSessionKey()` hands a freed key to the next new session.
- **Known and accepted:** recency-driven users (no fixed times) who switch their go-to session see
  the old one at some hours (the one regression vs today; Off restores today); weekday/weekend
  routines within an hour of each other miss twice a week (same as today; a weekday flag would fix
  it); two sessions in two separate launches are not learned as a sequence; a one-off at an unusual
  hour becomes that hour's pick. Rejected: a toast on jump (fires at nearly every launch for
  two-routine users), reordering the carousel (breaks spatial memory), a 15-min sticky timer (hid
  sessions prepared the evening before).

### Menus are built from one row list

`Ui.Menu2.updateItem(item, index)` replaces label, sublabel **and** id together, and
`Ui.Menu2.findItemById` is not safe at the app's CIQ 3.0 floor. So a menu that refreshes its
subtitles builds and refreshes from the **same** row list, and a row's index is simply its position
in that list; there are no hand-typed row numbers to drift.

- **Global settings** (`GlobalSettingsMenuDelegate.rows()`): one row per setting,
  `[id, row title, options title, setting key, values, labels, hints]`. `labels == null` marks a
  duration in seconds, shown as `mm:ss` both in the options and in the row subtitle.
  `GlobalSettingsMenuTests` pins the rows to the old hand-built menus.
- **Adding a global setting** touches:
  - an `XxxKey` constant;
  - an entry in `GlobalSettings.keys()`;
  - a branch in `defaultFor()`;
  - a row in `GlobalSettingsTests`' table;
  - a row in `rows()` and in `GlobalSettingsMenuTests`;
  - label strings in all 9 locales.

  The tests fail when `keys()`, their tables and `rows()` disagree. They cannot see a `defaultFor()`
  branch added alone: that setting would work but be missing from cloud backups.
- **Choose-one menus** go through `OptionMenu.push(title, values, labels, current, hints, onPicked,
  tag)`. The item id is the position in `values`, but `onPicked(tag, value)` always gets the
  **value**, so what is stored never depends on list order. The shared lists (vibe patterns for
  sessions and alerts, activity type, HRV tracking) live in `OptionMenu` too.
- **Duration pickers** go through `DurationPicker.pushHourMin` / `pushMinSec`, drawn `00:00` style
  (no h/m/s letters); the rounds picker (`12x`) is a count, not a duration, and stays separate.
- **Session editor** (`AddEditSessionMenuDelegate.rows()` / `createMenu()` / `updateMenuItems()`):
  same pattern, one `subtitleFor(id)`. Every edit changes the session in place and goes through
  one `publish()`: `onChangeSession` saves the **whole** session under its own key. Activity type
  and HRV tracking show the effective value (the global default when the field is null) but never
  write it; a null field means "follow the global default" and must stay null until the user picks
  a value. `SessionEditorTests` pins both.
- **Session settings root** (`SessionSettingsMenuDelegate.createMenu(storage)`) is built with its
  subtitles in one go; nothing refreshes it by index.
- The breath step editor keeps its own `Row*` constants next to its `createMenu()`.

### `ElapsedDurationRenderer` gotchas

- It **mutates its own radius/width on first draw** (`layoutDuration` subtracts
  `ceil(width/2)` from the radius and 1 from the width, guarded by `mX == null`). Construct
  instances in `onLayout`, never per frame, and pass radius `desired + ceil(width/2)`.
- `drawOverallElapsedTime` wraps via `elapsedTime % totalTime`, so a full ring reads as empty.
  Use `drawProgressPercentage` when you need an explicit 0-100% that can reach 100.

## Storage

**Everything in `App.Storage` is user data that must survive an update.** Each key string is a
public `XxxKey` constant on the class that owns it. The strings, their value formats and the enum
numbers stored in them never change; the storage and settings tests pin them. As long as that
holds an update needs no migration. The only one-time migration so far is
`SessionStorage.migratePresets()`.

- **`App.Storage`**:
  - `GlobalSettings.XxxKey` — `"globalSettings_<name>"`, one per setting (including the historical
    `prapareTime` typo)
  - `SessionStorage.SessionPrefixKey` — `"sesssion_<key>"` (historical triple-s typo — **do not
    fix**); `SessionKeysKey` = `"sessionsKeys"`, `SelectedIndexKey` = `"selectedSessionIndex"`
  - `WakeupSessionStorage.ActivityTypeKey` — `"wakeupSession_activityType"`, a `FitSessionKind` (0–3)
  - `MonthlyStats.MonthlyKey` / `TipPendingKey` — `"usageStats_monthly"` / `"usageStats_tipPending"`;
    `UsageStats` keeps its GA4 queue in `"usageStats_queue_v2"`
  - `selectedSessionIndex`: the picker reselects on every rebuild, so `selectSession()` writes only
    when the index actually changes. After a delete, storage keeps the position (the next session
    moves in, the last one falls back to the new last) and the picker takes that index as is. The
    `- 1` the menu used to add on top of storage's own decrement jumped two sessions back.
  - New session keys are the smallest unused number ≥ 100. The key list is in creation order, not
    sorted, so a single pass over it isn't enough: that once gave a new session an existing key and
    overwrote that session. A deleted session's key is reused, so anything keyed by session key must
    forget it on delete (as `SessionHistory.forget` does).
  - `SessionHistory.StorageKey` / `AutoKey` — `"sessionHistory"` (flat array, 3 ints per start) /
    `"sessionAutoKey"`; see "Session suggestion" under Architecture
- **`App.Properties`** — `activityName` and `restoreDeviceId` (Garmin Connect settings), plus the
  secrets from `secrets.xml`.

### Timers (`Timer.Timer` concurrency limit)

Connect IQ caps the number of **concurrently active `Timer.Timer` objects per app**. The limit is **device-dependent with a default of 3** (and a default minimum interval of 50 ms); both "depend on the host system" per the API docs. Starting one more than the device allows throws the runtime **"Too Many Timers Error"**. A `Timer.Timer` is a native resource — its slot is held until you call `.stop()` (or, unreliably, until the object is garbage-collected). **Always `.stop()` a timer before dropping its reference; do not rely on GC, especially on slower watches.** `Sensor.registerSensorDataListener` (used by `BeatIntervalFeed`) is **not** a `Timer` and does not count toward this limit.

**Timers in this app** (keep this list current when adding/removing timers):

| Timer | Where | Repeating | Released by |
| --- | --- | --- | --- |
| `mTimer` | `ActivityRecorder` (1 s recording tick) | yes | `stop()` / `pauseResume()` |
| `mviewDrawnTimer` | `MeditatePrepareView` (prepare/finalize countdown) | yes | `onHide()` → `stop()` |
| `viewDrawnTimer` | `DelayedFinishingView` (1 s finish delay) | no (one-shot) | `onHide()` → `stop()` |
| `mTimer` | `IdleReminderTimer` (10 min idle vibe) | yes | `stop()` |
| `notifyChangeTimer` | `AddEditIntervalAlertMenuDelegate` (500 ms debounce, settings only) | no (one-shot) | fires then nulls |

Steady state holds ≤2 of these at once (recording tick + an idle-reminder while a menu is up), well under the 3-timer floor. The finish flow is the tight spot: it chains two `DelayedFinishingView` instances and then starts the `IdleReminderTimer`, so any leaked finishing-view timer slot can tip a 3-timer device over. This is exactly the historical **"Too Many Timers Error"** (backtrace `IdleReminderTimer.start` ← `showSummaryView` ← `DelayedFinishingView.onViewDrawn`): fixed by having `DelayedFinishingView.onHide()` call `.stop()` instead of only nulling the reference, matching `MeditatePrepareView`.

## Secrets

`Meditate/resources/secrets.xml` is **gitignored**. Copy `secrets_template.xml` → `secrets.xml` and fill in the GA4 credentials (usage analytics) and the Firebase URL and secret (Dev Tools cloud backup).

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
2. Copies the PRG to `GARMIN/Apps/` and verifies it arrived
3. Creates an empty `<PRGNAME>.TXT` in `GARMIN/Apps/LOGS/` to enable `System.println()` logging

An optional **second** parameter deploys a different PRG (relative paths resolve against `Meditate/`), used for `HrvProbe`:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\CopyBuildToDevice.ps1 fenix ..\HrvProbe\bin\HrvProbe.prg
```

The LOGS trigger is named after the PRG, so a probe build automatically gets `HRVPROBE.TXT`. The source path is canonicalized with `Resolve-Path` before copying — **Shell COM `CopyHere` fails silently on paths containing `..`** while `Test-Path` accepts them, so an uncanonicalized path copies nothing and only trips the verify step.

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

In-app developer tool reached by **long-press or Menu on the About screen** → "Dev Tools" menu. Backed by Firebase Realtime Database (`meditate-garmin` project).

### Sync Rule

**A new global setting needs no backup change.** `CloudBackup` backs up every key of
`GlobalSettings.keys()` (see "Adding a global setting" under Menus). It used to read a hand-kept
`GLOBAL_SETTINGS_KEYS` array that silently dropped any key it lacked. Backup copies the *stored*
value only; a setting still at its default is not in the backup and falls back to the same
default after a restore.

**A new kind of stored data does need one**: a new top-level storage key outside
`GlobalSettings` belongs in a payload section here and in `CloudRestore`, or it is lost on a
restore.

`CloudRestore.onRestoreResponse()` needs **no change for new global settings** — it iterates
whatever keys came back (`gs.keys()`) and writes them straight to storage. It only needs
editing when a whole new *section* of the backup payload is added (alongside `globalSettings`,
`sessions`, `wakeup`, `monthlyStats`). Session dictionaries are likewise backed up opaquely, so
growing `SessionModel` needs no cloud-backup change at all — only watch the 32 KB
`maxLength` envelope on both sides.

### Keys Currently Backed Up

- every `GlobalSettings.keys()` entry — the settings, plus the two markers
  `globalSettings_presetsVersion` and `globalSettings_lastSeenNewsId`, which are not user settings
- `sessionsKeys`, `selectedSessionIndex`, and `sesssion_<key>` for each listed key
- `wakeupSession_activityType`
- `usageStats_monthly` and `usageStats_tipPending` (the `monthlyStats` section)

**Not backed up:** `usageStats_queue_v2` (too large, auto-rebuilds); `sessionHistory` and
`sessionAutoKey` (relearned from the next starts; `CloudRestore` clears them, since restored keys
may name other sessions).

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

### Key Learnings (Monkey C runtime memory)

- **Every object costs ~28 B on top of its content; array slots ~5 B.** Measured on `fr255s`:
  300 one- or two-element arrays = 11.75 KB, two flat `new [300]` of floats = 3 KB. Prefer one
  flat array over many small ones when the count is in the hundreds.
- **A string constant becomes a new String object whenever it's stored:** 48 B for a 26-character
  key on `fr255s`. Constants are not interned: `var x = GlobalSettings.HrvTrackingKey` allocates
  again even while an equal string is held elsewhere. So in a cached table of string keys the
  strings dominate. The 15 setting keys with their defaults cost 1,104 B as a Dictionary, 904 B as
  a flat `[key, value, …]` array and 1,432 B as 15 pairs. `key.equals(Constant)` only makes a
  temporary string that is freed at once.
- **What a session holds, for scale** (`fr255s`, HRV Detailed, stress and respiration, 60 bpm):
  - 4.1 KB once the metrics exist;
  - the HRV SDRR ring fills over the first 5 minutes, ~2.4 KB/min up to ~10 KB, released at
    `flush()`;
  - after that the histories grow ~55 B/min: 11 values a minute (6 HR, 2 stress, 2 respiration,
    1 HRV at the 60 s window), about 19 KB after an hour.

  Use this to size anything the app keeps for its whole lifetime.
- **Decision (2026-09-25): settings defaults are an if-chain, not a cached table.** A cached
  Dictionary held 1,104 B for the app's whole lifetime, about 20 minutes of recording history or
  6–7 % of a session's recording memory. `GlobalSettings.defaultFor` keeps nothing in memory and
  costs 176 B more code. Small either way; taken because it was nearly free. Don't reintroduce a
  cached key table for settings.
- **Measure, don't estimate:** a throwaway `(:test)` that diffs `System.getSystemStats().usedMemory`
  around the allocation and `logger.debug`s it takes two minutes and is exact; delete it afterwards.

### Key Learnings (Monkey C language and compiler)

- **A `switch` on `null` throws** `Unexpected Type Error` ("Failed invoking <symbol>") at runtime; a `default:` branch does not catch it. Any switch over a value that can be null (a session's `vibePattern`, a stored enum that may be missing) needs a null check first. `Utils.vibePatternLabel` keeps one; dropping it crashed the session picker for sessions without a stored pattern, caught by `SessionPickerHrvStatusTests`.
- **`settings.xml` string IDs must be defined in ALL locale resource folders.** Any string referenced via `@Strings.<id>` in `settings.xml` (e.g. as a `title=`) must exist in every `resources-<lang>/strings/strings.xml`, not just the base `resources/` folder. A missing locale string produces a `WARNING: String id '...' undefined for language '...'` and triggers the generic "A critical error has occurred" compiler crash.
- **Static methods cannot access `private` instance members or call `private` instance methods**, even on a freshly created instance of their own class. Doing so causes the assembler error `Trying to add undefined symbol: <memberName>` during release builds. The fix is to move all initialization that touches private members into `initialize()`, so the `static run()` factory simply calls `new MyClass()`.
- **"A critical error has occurred" is a compiler crash masking real errors.** Re-run with `--debug-log-level 2 --debug-log-output <file>.zip` to get `error.txt` inside the zip, which lists the actual `CompilerException` messages (e.g., assembler symbol errors, missing strings).
- **Runtime device identification**: Monkey C does not expose the SDK's device-id string (e.g. `"vivoactive4"`) at runtime. The closest proxy is `System.getDeviceSettings().partNumber`, a hardware SKU string (e.g. `"006-B3225-00"`) matching the `partNumbers[].number` entries in that device's `compiler.json`. Each device model can have multiple part numbers (one per regional/firmware SKU), so device-specific checks need the full list, not a single value — see the vívoactive4/4s quirk above for a working example.
- **Verify a Toybox API throws before wrapping it in try/catch.** `ActivityRecording.createSession` does not throw a catchable exception for an unsupported sport/subSport combo — confirmed via the vívoactive4/4s "Invalid Value" crash above. Check the API docs or existing repo precedent (e.g. `Sensor.TooManySensorDataListenersException`, `Attention.BacklightOnTooLongException`) before assuming a call is catchable.
- **Finish a CLI verification with a release build (`-r`), not just a debug one.** Debug builds happily compile code that the release assembler rejects — the private/static symbol error above is the known case, and adding private statics is exactly when this bites. A clean debug build is not evidence the change ships.
- **CLI builds outside the VS Code extension** need a private key (`-y`) even for unsigned debug builds — generate a throwaway one with `openssl genrsa` + `openssl pkcs8` if just verifying compilation. Jungle file paths in `-f` are resolved relative to the jungle file's own directory, not the invocation cwd — pass `Meditate/monkey.jungle` (the auto-generated `bin/combined.jungle` uses paths meant for the extension's own resolution and won't work standalone).
