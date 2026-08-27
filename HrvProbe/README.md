# HRV Probe

Standalone throwaway watch-app that answers one question: **why does the beat-to-beat
(`heartBeatIntervals`) feed stay empty on the first app open, but work instantly after a restart?**

It is not part of the Meditate app and shares no code with it. Build and deploy it separately.

## Result: restarting works — investigation closed

**Answered 2026-08-19.** Two comparably cold sensors (11.4 h, 13.1 h gap) failed on the first launch,
then produced RR within 2–3 s of an immediate relaunch — total time under 1.5 min, against 180–320 s
of continuous holding producing nothing on comparably cold sensors in an earlier run. Restarting the
app is a real, fast, repeatable fix. One confound remains open (restarting requires physically
handling the watch, and motion is known to affect the optical sensor, so "the restart" vs "the motion
of restarting" is not separated by any test run) — it doesn't change the recommendation. Full
numbers and reasoning: [FINDINGS.md](FINDINGS.md#resolved--restart-works-elapsed-time-alone-does-not).

## Design — restart-cycle test (superseded, answered the question above)

Each launch is one short cycle — create session + register (exactly what `MeditateApp` does), watch
for 40 s, then **the app exits by itself**. Relaunch immediately for the next cycle. The stored
history accumulates across launches, so one log pull shows every cycle with its gap and result.

## Previous design (superseded) — reset test

Everything before this tried to **turn the sensor on** — hold a session, start a session,
`setEnabledSensors`, `enableSensorType`, `enableSensorEvents`. On an overnight-cold sensor all of it
failed for 320 s straight. This run tests the opposite: **turn it off properly first, then start it.**

| Step | at | Action |
| --- | --- | --- |
| S0 | 0 s | create session + register — replica of Meditate startup; expect stuck |
| S1 | 90 s | `setEnabledSensors([])` **only** — isolates the disable call |
| S2 | 120 s | **full teardown** — replica of `MeditateApp.onStop` |
| S3 | 125 s | **full startup** — replica of `getInitialView`; together S2+S3 == "close and reopen" |
| S4 | 185 s | full teardown again |
| S5 | 190 s | full startup again |
| — | 250 s | end |

**Why.** In all three stuck runs so far, RR appeared **8–24 s after the probe's own teardown**, not
after anything we deliberately tried. Time-since-teardown clusters tightly (8, ≤24, 9 s) while
time-since-session-created does not (143, 159, 330 s). And closing Meditate runs exactly this
teardown, which is why reopening it is ready in 2–5 s — far too fast for any warm-up explanation.

Note `HeartbeatIntervalsSensor.restartSensor()` does unregister → discard → create → register and
**never** calls `setEnabledSensors([])` or `enableSensorEvents(null)`. If S3 unsticks it and S1 does
not, the fix is to make the in-app recovery perform the full `onStop` teardown.

Reading it: RR right after **S3/S5** ⇒ the reset is the lever and Meditate can do it itself. RR after
**S1** ⇒ `setEnabledSensors([])` alone suffices, cheaper still. RR during **S0** ⇒ the sensor was
never stuck and the run says nothing. Nothing at all ⇒ reset is not the answer either.

## Previous design (superseded) — hold, then escalate

| Phase | Window | Action |
| --- | --- | --- |
| A | 0–20 s | register the listener, no session — is the sensor already warm? |
| B | 20–200 s | create **one** session and **hold it untouched** — the measurement |
| C | 200–230 s | escalate: `setEnabledSensors` + `enableSensorType` |
| D | 230–260 s | escalate: `enableSensorEvents` (the `Sensor.Info` stream) |
| E | 260–290 s | escalate: `session.start()` — beeps, records, discarded at the end |
| F | 290–320 s | escalate: discard, then create **and start** a Generic session |

C–F only happen if RR still has not appeared. If it does appear the run ends 30 s later, so the
**expected cold run is ~3.3 minutes**; the full 5.3 minutes only happens when everything fails.

Deliberately no longer tested, because earlier runs settled them: sport type (Meditation and Generic
each woke it once and timed out once), create-before-register ordering (falsified), spin-down
(measured >45 s), and unregister+re-register (same falsification as ordering). The 20 s baseline only
needs to be long enough for an already-warm sensor to give itself away — every warm onset observed
was t=1–8.

**Why the hold is the whole point.** Cold wake latency is ~150 s; warm is ~2 s. Two earlier designs
came to opposite conclusions ("the session wakes it" / "the session is irrelevant") and both were
artefacts of windows that were too short and sessions torn down mid-wait. Reconstructing the clock
showed RR arriving 143 s and 159 s after those runs' first session — landing in the *next* run's log.
**Never shorten the hold or add stage changes inside it**, or the probe just measures its own
interference.

## Previous design (superseded) — crossover

| Stage | Window | Action |
| --- | --- | --- |
| A | 0–60 s | register the listener, **no session** — long baseline |
| B | 60–120 s | create a session, sport #1 |
| C | 120–180 s | discard, create a session, sport #2 |

Read the result off the stage in which RR data first appears:

| First RR in | Conclusion |
| --- | --- |
| **A** | No session needed — it is plain sensor warm-up. Every session-based theory is wrong. |
| **B** | The first sport woke it. |
| **C** | The first sport did **not** wake it but the second did → **sport type is the cause**. |
| nowhere | Wake takes >180 s from cold, or the cause is elsewhere. |

### Two controls that make it trustworthy

**A 60 s baseline (stage A).** The first version of this probe used 15 s and concluded "the session
woke the sensor" because data arrived just after it was created. That was unsound: a cold optical
sensor plausibly needs 15–25 s on its own, which looks identical. Only if stage A stays empty for a
full minute, and RR then appears within seconds of a session being created, is the session causal.

**Randomised sport order.** Sport #1/#2 are MEDITATION and GENERIC in random order each run. Without
this, stage C would always benefit from stage B having already woken things up, and whichever sport
sat in C would look better for purely positional reasons. Randomising breaks that: if a sport only
ever delivers when it runs *second*, it is an order effect; if it delivers regardless of position,
it is a real sport effect. The chosen order is shown on screen and logged as `order=` per run.

**Residual limitation:** each sport only gets a 60 s window in a crossover run. If a sport needs
longer than that, it will look like a failure. If one sport does come out worse, confirm it with
dedicated single-sport runs before believing it.

## Logging

Everything goes to `GARMIN/Apps/LOGS/HRVPROBE.TXT` (pull with `Meditate/PullDebugInfoFromDevice.ps1`).
Each run logs:

- `clock=` wall time and `epoch=`
- **`gapSinceLastRun=`** — the key covariate. A short gap is not a cold test; a run 20 minutes after
  the last one proves nothing, and without this the log cannot be interpreted at all.
- `part=` / `fw=` device and firmware
- `order=` which sport ran first
- the **stored history of previous runs**, so one log pull gives every result even if the file was
  cleared in between
- a per-second trace `t= st= n= hr=` for the whole run, plus `FIRST HR`, `FIRST RR` (with the raw
  interval array) and stage transitions
- `=== run end ===` one-line summary and `verdict:`

`hr` is the cross-check: a HR number while RR stays empty means the optical sensor is running but
not producing beat-to-beat.

## Running it

**This must be a cold test.** Don't open Meditate or the probe for at least 30 minutes beforehand
(first thing in the morning is ideal). Wear the watch normally, launch, and leave it alone for
3 minutes. Check `gapSinceLastRun` in the log to confirm the run counted.

`SELECT` re-runs with a freshly randomised order, but warm — a wiring check, not a measurement.

Because of the noise already seen (one cold run produced no RR at all), treat any single run as
weak evidence. Several runs across different mornings are what make the picture trustworthy.

## Build and deploy

```powershell
# build (adjust device id; see Meditate/manifest.xml for valid ids)
& "$env:APPDATA\Garmin\ConnectIQ\Sdks\<sdk>\bin\monkeyc.bat" `
  -f HrvProbe\monkey.jungle -o HrvProbe\bin\HrvProbe.prg -y <key>.der -d fenix847mm

# deploy (CopyBuildToDevice.ps1 takes an optional PRG path as its 2nd argument)
cd Meditate
powershell -NoProfile -ExecutionPolicy Bypass -File .\CopyBuildToDevice.ps1 fenix ..\HrvProbe\bin\HrvProbe.prg
```

If your watch is not in `manifest.xml`, add its `<iq:product id="..."/>` — the id is the folder name
under `%APPDATA%\Garmin\ConnectIQ\Devices\`.

Note: one stage uses `SPORT_MEDITATION`, which throws "Invalid Value" on vívoactive 4/4s (see the
main `CLAUDE.md`). Those devices are not in this manifest; don't add them without handling that.
