using Toybox.Sensor;
using Toybox.ActivityRecording;
using Toybox.Activity;
using Toybox.Timer;
using Toybox.System;
using Toybox.Time;
using Toybox.Application as App;
using Toybox.WatchUi as Ui;

// RESTART-CYCLE test. Does an actual app process restart unstick the beat-to-beat feed, or is it
// just elapsed time?
//
// Each launch is one short cycle: create session + register (exactly what MeditateApp does), watch
// for RunSeconds, then EXIT BY ITSELF. Relaunch immediately and it does another cycle. The stored
// history accumulates across launches, so one log pull shows cycle 1, 2, 3 ... with the gap between
// them and whether RR appeared.
//
// Why this is the experiment that matters. In all four stuck runs so far RR NEVER appeared during
// the run - not with a session held 180s, not with session.start(), not with setEnabledSensors, not
// with two in-process teardown+restart cycles. Every time, it appeared within 1-2s of the NEXT app
// launch. That was read as "elapsed time reached ~5 min", but restart and elapsed time were
// perfectly confounded: every relaunch happened only after a long run. We never restarted EARLY on
// a cold sensor, which is exactly what a user does in real life.
//
// Note the in-process teardown+restart that failed had only 5s between teardown and restart, while
// the real relaunches had 7-33s of the app being fully gone. And a real relaunch terminates the CIQ
// process, so the system reclaims the sensor resource - something unregisterSensorDataListener()
// evidently does not do.
//
// Reading it: RR on cycle 2 or 3 (~1-2 min total) => the RESTART is the lever, elapsed time is dead,
// and the fix/UX is "restart" not "wait". RR only after ~5 min worth of cycles => elapsed time, and
// restarting is irrelevant. No RR across many cycles => neither.
class HrvProbe {
	const RunSeconds = 40;
	const EndAfterRrSeconds = 10;

	private const LastRunKey = "probe_lastRunEpoch";
	private const HistoryKey = "probe_history";
	private const CycleKey = "probe_cycle";
	private const HistoryMax = 12;

	var elapsed;
	var cycle;
	var firstRr;
	var firstHr;
	var callbacks;
	var dataCallbacks;
	var lastCount;
	var hr;
	var done;
	var history;

	private var mTimer;
	private var mSession;
	private var mRegistered;
	private var mGapSeconds;
	private var mEndAt;

	function initialize() {
		me.history = App.Storage.getValue(HistoryKey);
		if (!(me.history instanceof Toybox.Lang.Array)) {
			me.history = [];
		}
		var c = App.Storage.getValue(CycleKey);
		me.cycle = c instanceof Toybox.Lang.Number ? c + 1 : 1;
		App.Storage.setValue(CycleKey, me.cycle);

		me.mTimer = null;
		me.mSession = null;
		me.mRegistered = false;
		me.mGapSeconds = null;
		me.mEndAt = RunSeconds;
		me.resetRun();
	}

	private function resetRun() {
		me.elapsed = 0;
		me.firstRr = null;
		me.firstHr = null;
		me.callbacks = 0;
		me.dataCallbacks = 0;
		me.lastCount = 0;
		me.hr = null;
		me.done = false;
		me.mEndAt = RunSeconds;
	}

	function start() {
		me.logHeader();
		// exactly what getInitialView -> startup() does
		me.createSession();
		me.register();
		if (me.mTimer == null) {
			me.mTimer = new Timer.Timer();
		}
		me.mTimer.start(method(:onTick), 1000, true);
	}

	// safe to call twice; mirrors MeditateApp.onStop
	function shutdown() {
		if (me.mTimer != null) {
			me.mTimer.stop();
		}
		me.unregister();
		me.discardSession();
		Sensor.setEnabledSensors([]);
		Sensor.enableSensorEvents(null);
	}

	function onTick() {
		me.elapsed += 1;

		var info = Activity.getActivityInfo();
		me.hr = info != null && info has :currentHeartRate ? info.currentHeartRate : null;
		if (me.hr != null && me.firstHr == null) {
			me.firstHr = me.elapsed;
			me.log("FIRST HR t=" + me.elapsed);
		}

		me.log("t=" + me.elapsed + " n=" + me.lastCount + " hr=" + me.hrText());

		if (me.elapsed >= me.mEndAt && !me.done) {
			me.finish();
			return;
		}
		Ui.requestUpdate();
	}

	private function register() {
		try {
			Sensor.registerSensorDataListener(method(:onData), {
				:period => 1,
				:heartBeatIntervals => {
					:enabled => true,
				},
			});
		} catch (e instanceof Sensor.TooManySensorDataListenersException) {
			Sensor.unregisterSensorDataListener();
			me.log("  too many listeners; retried");
			Sensor.registerSensorDataListener(method(:onData), {
				:period => 1,
				:heartBeatIntervals => {
					:enabled => true,
				},
			});
		}
		me.mRegistered = true;
	}

	private function unregister() {
		if (me.mRegistered) {
			Sensor.unregisterSensorDataListener();
			me.mRegistered = false;
		}
	}

	private function createSession() {
		me.discardSession();
		var spec = { :name => "probe", :sport => Activity has :SPORT_MEDITATION ? Activity.SPORT_MEDITATION : 67 };
		me.mSession = ActivityRecording.createSession(spec);
		me.log("  session created=" + (me.mSession != null));
	}

	private function discardSession() {
		if (me.mSession != null) {
			me.mSession.discard();
			me.mSession = null;
		}
	}

	function onData(sensorData) {
		me.callbacks += 1;
		var data =
			sensorData has :heartRateData &&
			sensorData.heartRateData != null &&
			sensorData.heartRateData has :heartBeatIntervals &&
			sensorData.heartRateData.heartBeatIntervals != null
				? sensorData.heartRateData.heartBeatIntervals
				: [];
		me.lastCount = data.size();
		if (me.lastCount > 0) {
			me.dataCallbacks += 1;
			if (me.firstRr == null) {
				me.firstRr = me.elapsed;
				me.log("FIRST RR t=" + me.elapsed + " n=" + me.lastCount + " rr=" + data);
				var stop = me.elapsed + EndAfterRrSeconds;
				me.mEndAt = stop < me.mEndAt ? stop : me.mEndAt;
			}
		}
	}

	// -- reporting -----------------------------------------------------------

	private function finish() {
		me.done = true;
		me.shutdown();

		var summary =
			"cycle" + me.cycle +
			" " + me.clockText() +
			" gap=" + (me.mGapSeconds == null ? "?" : me.mGapSeconds.toString()) + "s" +
			" ran=" + me.elapsed + "s" +
			" RR=" + (me.firstRr == null ? "none" : me.firstRr + "s") +
			" firstHR=" + (me.firstHr == null ? "none" : me.firstHr + "s");
		me.history.add(summary);
		while (me.history.size() > HistoryMax) {
			me.history = me.history.slice(1, me.history.size());
		}
		App.Storage.setValue(HistoryKey, me.history);

		me.log("=== cycle end === " + summary);
		if (me.firstRr == null) {
			me.log("no RR this cycle - RELAUNCH to run the next one");
		} else {
			me.log("RR on cycle " + me.cycle);
		}
		// exit by itself so every cycle is the same length and the next launch is a clean process restart
		System.exit();
	}

	private function logHeader() {
		var nowEpoch = Time.now().value();
		var last = App.Storage.getValue(LastRunKey);
		if (last instanceof Toybox.Lang.Number) {
			me.mGapSeconds = nowEpoch - last;
		}
		App.Storage.setValue(LastRunKey, nowEpoch);

		me.log("=== HRVPROBE cycle " + me.cycle + " ===");
		me.log("clock=" + me.clockText() + " epoch=" + nowEpoch);
		// gap since the PREVIOUS launch; small gaps are the whole point of this experiment
		me.log("gapSinceLastRun=" + (me.mGapSeconds == null ? "unknown" : me.mGapSeconds + "s"));
		var ds = System.getDeviceSettings();
		me.log(
			"part=" + (ds has :partNumber ? ds.partNumber : "?") + " fw=" + (ds has :firmwareVersion ? ds.firmwareVersion : "?")
		);
		me.log("-- history --");
		for (var i = 0; i < me.history.size(); i++) {
			me.log("  " + me.history[i]);
		}
		me.log("-- run --");
	}

	function hrText() {
		return me.hr == null ? "--" : me.hr.toString();
	}

	function clockText() {
		var c = System.getClockTime();
		return c.hour.format("%02d") + ":" + c.min.format("%02d") + ":" + c.sec.format("%02d");
	}

	function gapText() {
		if (me.mGapSeconds == null) {
			return "?";
		} else if (me.mGapSeconds > 3600) {
			return (me.mGapSeconds / 3600) + "h";
		}
		return (me.mGapSeconds / 60) + "m";
	}

	private function log(msg) {
		System.println(msg);
	}
}
