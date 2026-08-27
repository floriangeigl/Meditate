# HRV cold start — investigation record

**Conclusion: nothing done *inside* a running app reliably unsticks a cold sensor, but restarting the
app does.** Held session, `session.start()`, `setEnabledSensors`, `enableSensorType`,
`enableSensorEvents` and in-process teardown+restart were all measured on a 10–12 h cold sensor and
all produced nothing across 180–320 s. A genuine app restart on a comparably cold sensor produced RR
within seconds, twice, for well under 1.5 minutes total — see
[Resolved — restart works](#resolved--restart-works-elapsed-time-alone-does-not).

One confound remains open: restarting requires physically handling the watch, and Garmin's optical
sensor is known to ramp up on motion, so "the restart" and "the motion of restarting" are not
separated by any test run so far. Doesn't change the recommendation — restarting is the actionable
fix either way — but avoid claiming the *mechanism* is the software restart specifically.

Investigation ran 2026-08-13 → 2026-08-19 on fēnix 8 47mm (`006-B4532-00`), firmware 22.41 → 22.43,
using `HrvProbe`.

---

## Symptom

On the session picker the HRV line sits on "HRV waiting" **with the hourglass still animating** — the
1 Hz sensor callback fires normally, but `heartBeatIntervals` is always empty. It never recovers.
Closing and reopening the app makes it ready in 2–5 s. Worst on the first open of the day.

Complaints go back to 2024 (`d91a642` "New attempt to fix HRV detection in app startup"), and the git
log shows roughly four years of attempted fixes.

## What the SDK says: nothing

Checked exhaustively: `doc/docs/Core_Topics/Sensors.html`, `bin/api.debug.xml`, `bin/api.mir`, and all
43 samples.

- Exactly **one** sample uses `registerSensorDataListener` (PitchCounter, accelerometer). **None**
  uses `heartBeatIntervals`.
- The Core Topics guide treats `:heartBeatIntervals` as just another option beside
  accelerometer/gyro/magnetometer. The only stated constraint is that a single sensor data request
  may be active at a time.
- It says *"Calling `Sensor.registerSensorDataListener()` will enable your application to receive
  data"* — implying registration alone enables the sensor. There is **no documented ordering
  contract** with `ActivityRecording`, no mention of power modes and no mention of warm-up.
- `simulator.exe` models sensors as acquirable resources (`OhrSensorResource`, `AccelSensorResource`,
  `GyroSensorResource`, `PulseOxSensorResource`) with **no optical power-state machine** — which is
  independently why **the simulator cannot reproduce this bug**.

The real gating lives in watch firmware, which is not shipped in the SDK. Decompiling further does
not help: `monkeybrains.jar` is the compiler and `simulator.exe` is a host emulator.

## The measurements

### Time to first RR, by how long the sensor had been idle

| idle gap | time to first RR |
| --- | --- |
| 53–346 s | 1–13 s |
| 518 s | 188 s |
| 1844 s | 204 s |
| 36844 s (10.2 h) | **286 s** |
| 43162 s (12 h) | **330 s** |

Roughly monotonic with idle length; the deep-cold floor of **~5 minutes** is solid across two
independent overnight runs on different days. One unexplained outlier: a 1418 s gap woke in 22 s, so
it is not a clean function of idle time.

### Overnight-cold run, 2026-08-14 06:07, gap 43162 s (12 h)

320 s, **zero** RR, HR present in all 320 samples (48–66 bpm):

| tried | duration | result |
| --- | --- | --- |
| registered, no session | 20 s | nothing |
| created Meditation session, **held untouched** | 180 s | nothing |
| `setEnabledSensors` + `enableSensorType` | 30 s | nothing |
| `enableSensorEvents` | 30 s | nothing |
| **`session.start()`** (actually recording) | 30 s | nothing |
| discard, create **and start** a Generic session | 30 s | nothing |

RR appeared ~330 s after the run began. The two follow-up runs got RR at t=2 and t=5 with no session
at all.

### Overnight-cold run, 2026-08-14 16:27, gap 36844 s (10.2 h) — the reset test

250 samples, **zero** RR, HR present in all 250:

| step | at | action | result |
| --- | --- | --- | --- |
| S0 | 0 s | session + register (Meditate startup replica) | nothing |
| S1 | 90 s | `setEnabledSensors([])` **only** | nothing |
| S2/S3 | 120/125 s | full `onStop` teardown + `getInitialView` startup | nothing (60 s observed) |
| S4/S5 | 185/190 s | same again | nothing (60 s observed) |

## Hypotheses tested and rejected

| # | Hypothesis | Verdict |
| --- | --- | --- |
| 1 | **Wake-before-register ordering** — the request binds to the sensor mode at registration and never re-binds, so the wakeup session must be created first | **Falsified.** On two cold runs a listener registered while the sensor slept later began delivering *on its own*, without re-registration. Survives the timing confound: whatever woke the sensor, the already-registered listener picked it up. |
| 2 | **Restart thrash** — `getStatus()`'s ~20 s teardown keeps aborting a slow acquisition | **Not the cause.** A session held untouched for 180 s on a cold sensor still produced nothing. Still worth removing as pointless churn. |
| 3 | **Sport type** — `SPORT_MEDITATION` doesn't wake the sensor the way `SPORT_GENERIC` does | **Falsified.** Meditation woke it (t=45→47) and Generic woke it (t=60→62); both also appeared in runs that produced nothing. |
| 4 | **Cold wake takes ~150 s, just hold the session** | **Falsified.** 180 s of holding, then `session.start()`, produced nothing on a 12 h-cold sensor. |
| 5 | **The sensor must be shut down properly before it can start** — only "on" had ever been tried | **Falsified.** Two full `onStop`+`getInitialView` cycles in-process did nothing. The apparent correlation (RR arriving 8–24 s after the probe's own teardown in three runs) was an artefact of where runs happened to end — S4's teardown was followed by 60 s of nothing. |
| 6 | **`setEnabledSensors` / `enableSensorType` / `enableSensorEvents`** | **No effect.** Tried in every combination 2024-04 → v10.6.39 and deleted; re-tested directly here on a cold sensor. Retroactively explains why those commits never fixed anything. |

## Resolved — restart works, elapsed time alone does not

**2026-08-19, restart-cycle probe, 6 cycles.** Each cycle: launch, create session + register, watch
40 s, auto-exit; relaunch for the next cycle.

| cycle | gap before it | what it was | RR |
| --- | --- | --- | --- |
| 1 | 269019 s (74.7 h) | full cold launch | **t=3** |
| 2 | 40987 s (11.4 h) | full cold launch | none (cut short at t=13) |
| 3 | 15 s | retry right after cycle 2 failed | **t=2** |
| 4 | 83001 s (23.1 h) | full cold launch | **t=2** |
| 5 | 46984 s (13.1 h) | full cold launch | none (ran the full 40 s) |
| 6 | 42 s | retry right after cycle 5 failed | **t=3** |

**The decisive comparison is against the earlier hold experiment, not within this run.** Two prior
runs held a session untouched for 180–320 s on a 10–12 h cold sensor and got **zero RR every time**.
Here, two *comparable* cold gaps (11.4 h, 13.1 h) also failed on the first launch — but restarting
immediately after produced RR within 2–3 s, for a **total elapsed time under 1.5 minutes**:

| | cold gap | total time trying | RR |
| --- | --- | --- | --- |
| Hold (no restart) | 10–12 h | 180–320 s continuous | **never** |
| Restart-cycle | 11.4 h / 13.1 h | ~30 s / ~85 s, **with one restart** | **yes, both times** |

If elapsed warm-up time were what mattered, the long continuous hold should have won and the short
restart-cycles should have lost. The opposite happened, twice. **Restarting the app is a real, fast,
repeatable fix** — this matches the user's own report almost exactly (stuck, restart, works within
about a minute) and settles the open question in that direction.

### Remaining confound — restart, or the motion of restarting?

Cycles 1 and 4 complicate a clean story: both had *longer* idle gaps than the cycles that failed
(74.7 h and 23.1 h vs. 11.4 h and 13.1 h), yet both got RR on the very first launch, no restart
needed. Cold-gap length alone does not predict failure. Firmware changed between cycle 3 and 4
(22.41 → 22.43) but cannot be the explanation, since cycle 1 succeeded immediately on the *old*
firmware too.

Most plausible account: `gapSinceLastRun` measures **app-idle** time, not **sensor-idle** time — it
says nothing about whether the watch had just been picked up, the wrist moved, or a button pressed in
the moment before launch. Garmin's optical sensors are known to run reduced duty cycle when
stationary and ramp up on motion. The physical act of restarting the app (pick up the watch, press a
button) *is* wrist motion, so **"restarting the app" and "recent physical interaction" are confounded
in every test run so far**, including this one — software alone cannot separate them.

This does not weaken the actionable conclusion. Whether the true mechanism is the process restart
itself or the motion required to trigger it, restarting remains a real, fast, repeatable fix — which
is what matters for UX. It only means "why restarting works" is not fully closed; "that restarting
works" is.

## Facts worth keeping

- **HR availability ≠ RR availability.** `currentHeartRate` streamed normally (48–92 bpm, never null)
  through *every* run, including those with zero RR for 5 minutes. Never use a HR reading as a proxy
  for beat-to-beat being available.
- **Warm latency is ~2 s.** When the sensor is already warm, RR appears ~2 s after a session is
  created (observed twice with identical latency). This is why a quick restart *appears* to fix it
  during the day — the sensor is only lightly cold.
- **Spin-down is >45 s.** Once RR is flowing it keeps flowing for at least 45 s after the session is
  discarded.
- **The failure reproduces in ~100 lines** that only register a listener — no wakeup session, no
  restart loop, no Meditate code. It is not a Meditate bug.

## Method notes — how this went wrong three times

Every wrong conclusion came from the same mistake: **measurement windows shorter than the effect, and
the session torn down mid-wait.**

1. A 15 s baseline "proved" the session woke the sensor — a cold sensor plausibly needs 15–25 s
   anyway, which looks identical.
2. 45 s stages "proved" the session was irrelevant — the two "failures" actually produced RR 143 s and
   159 s after their first session, landing in the *next* run's log, ~15–25 s after the window closed.
3. Run-boundary coincidences "proved" teardown was the lever — until a teardown mid-run was given
   60 s and did nothing.

Rules that follow, for any future variant of this experiment:

- Reconstruct the clock **across** runs, not just within one. RR onset repeatedly landed in the next
  run's log.
- Log `gapSinceLastRun`. A short gap is not a cold test and the run means nothing.
- Give any lever a window longer than the effect you are hunting — minutes, not 30 s.
- Include a do-nothing control arm.
- One cold run per morning is the real constraint; quitting a run early wastes the cold state that
  the next run needed.

## Implications for Meditate

- **Do not add more in-app levers.** Everything reachable from inside a running app has been tried on
  a cold sensor and failed. The `getStatus()` retry loop is futile at any cadence; it is now
  `ensureWakeupSession()`, which only guarantees a session exists after a meditation session
  discarded it — no retry, no restart attempt.
- **Do not have the app auto-restart itself.** `System.exit()` from inside `getStatus()`'s recovery
  path would be jarring and unsafe if the user is anywhere other than the picker (mid-session, in a
  menu, editing settings).
- **Shipped fix (2026-08-22): two-phase status text, no new UI.** Single static wording was rejected
  mid-review — showing "restart" from t=0 would create false urgency for the common case, since most
  successful runs resolve in 1–3 s. Implemented instead as a threshold on the sensor's own
  `statusErrors` counter (already tracked for the backlight-flash and `ensureWakeupSession` logic):

  - `HeartbeatIntervalsSensor.shouldSuggestRestart()` — `true` once `statusErrors` exceeds
    `restartHintAfterErrors` (18, i.e. ~18 s continuously stuck).
  - `Utils.getHrvStatusText(status, suggestRestart)` — for `Error` status, returns the `HRVstarting`
    resource ("HRV starting") below the threshold, `HRVrestart` ("Restart the app") above it.
  - `SessionPickerDelegate.updateHrvStatus()` passes `shouldSuggestRestart()` through on every call.

  The 18 s threshold is justified directly by the data: across every measured stuck run (up to 320 s)
  RR never once recovered mid-run — only warm/lucky runs succeeded, always within 1–3 s. There is no
  observed case where waiting past ~18 s helps, so there is no case where the switch fires too early.

  No new UI element, no tip, no one-tap action, no auto-restart — users already know how to restart
  the app; the `:sensorRestart` global setting still exists for the rare case they don't, it just
  isn't specifically pointed at anymore. Non-English translations for `HRVstarting`/`HRVrestart` are
  best-effort machine/AI translations reusing each locale's existing `sensorRestart` vocabulary for
  consistency — not native-reviewed, worth a spot-check before release.
- Do not claim the mechanism is "the software restart" specifically in any wording — the
  physical-motion confound above is still open — but recommending a restart is sound regardless of
  why it works.
