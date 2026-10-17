using Toybox.Sensor;
using Toybox.Lang;
using Toybox.ActivityRecording;

// the beat interval sensor listener: cleaning, pause, foreground gate, wakeup session and the
// quality counters. no ui side effects; the picker turns pollStatus and errorSeconds into text
class BeatIntervalFeed {
	private const SamplePeriodSeconds = 1;
	private const maxReadyFails = 4;
	private const maxWeakFails = 8;
	private const minWeakFails = maxReadyFails + 1;
	private const ensureSessionAfterErrors = 60;

	private var mListener;
	private var numFails;
	private var running;
	private var lastUpdateFailed;
	private var statusErrors;
	private var paused;
	private var foreground;
	var sensorWakeupSession;

	function initialize() {
		me.resetSensorQuality();
		me.running = false;
		me.lastUpdateFailed = false;
		me.paused = false;
		me.foreground = true;
		me.sensorWakeupSession = null;
	}

	// multitasking devices suspend our sensors while the app is not on screen
	function setForeground(isForeground) {
		if (isForeground && !me.foreground) {
			// sensors were suspended; fail counters mean nothing after that gap
			me.resetSensorQuality();
		}
		me.foreground = isForeground;
	}

	function startup() {
		me.resetSensorQuality();
		// wake the sensor before registering; see CLAUDE.md hrv cold start
		me.createWakeupSession();
		me.start();
	}

	function createWakeupSession() {
		me.discardWakeupSession();
		var fitSessionSpec = FitSessionSpec.create(WakeupSessionStorage.loadActivityType(), "tmp");
		me.sensorWakeupSession = ActivityRecording.createSession(fitSessionSpec);
	}

	function discardWakeupSession() {
		if (me.sensorWakeupSession != null) {
			me.sensorWakeupSession.discard();
			me.sensorWakeupSession = null;
		}
	}

	function shutdown() {
		me.stop();
		me.discardWakeupSession();
	}

	// callers must have the sensor awake already; see createWakeupSession
	function start() {
		if (!me.running) {
			me.registerListener();
			me.running = true;
		}
	}

	// retrying cannot wake a cold sensor - see CLAUDE.md HRV cold start; all this does is
	// guarantee a wakeup session exists, which matters after a meditation session discarded it
	private function ensureWakeupSession() {
		if (me.sensorWakeupSession == null) {
			me.createWakeupSession();
		}
	}

	function stop() {
		if (me.running) {
			Sensor.unregisterSensorDataListener();
			me.running = false;
		}
	}

	function pause() {
		me.paused = true;
	}

	function resume() {
		me.paused = false;
	}

	function registerListener() {
		try {
			Sensor.registerSensorDataListener(method(:update), {
				:period => SamplePeriodSeconds,
				:heartBeatIntervals => {
					:enabled => true,
				},
			});
		} catch (e instanceof Sensor.TooManySensorDataListenersException) {
			Sensor.unregisterSensorDataListener();
			me.registerListener();
		}
	}

	// one slot: the picker status while browsing, HrvMetric.onIntervals during a session
	function setListener(listener) {
		me.mListener = listener;
	}

	// picker only; counts error seconds while on screen, never call it from a session
	function pollStatus() {
		var status =
			me.numFails <= maxReadyFails
				? HeartbeatIntervalsSensorStatus.Good
				: me.numFails <= maxWeakFails
				? HeartbeatIntervalsSensorStatus.Weak
				: HeartbeatIntervalsSensorStatus.Error;
		// missing data while backgrounded is not a sensor fault; recovery here would create a session illegally
		if (!me.foreground) {
			return status;
		}
		if (status == HeartbeatIntervalsSensorStatus.Good) {
			me.statusErrors = 0;
		} else if (status == HeartbeatIntervalsSensorStatus.Error) {
			me.statusErrors += 1;
			if (me.statusErrors > ensureSessionAfterErrors) {
				me.ensureWakeupSession();
			}
		}
		return status;
	}

	// consecutive polled seconds without beat intervals; reset only by recovery or resetSensorQuality
	function errorSeconds() {
		return me.statusErrors;
	}

	function resetSensorQuality() {
		me.numFails = maxWeakFails + 1;
		me.statusErrors = 0;
	}

	function update(sensorData) {
		if (me.paused) {
			return;
		}
		var data =
			sensorData has :heartRateData &&
			sensorData.heartRateData != null &&
			sensorData.heartRateData has :heartBeatIntervals &&
			sensorData.heartRateData.heartBeatIntervals != null
				? sensorData.heartRateData.heartBeatIntervals
				: [];

		if (data == null || data.size() == 0) {
			// only increase fail if two in a row fail;
			// hr below 60, means not every second
			if (me.lastUpdateFailed) {
				me.numFails++;
				me.lastUpdateFailed = false;
			} else {
				me.lastUpdateFailed = true;
			}
		} else {
			me.lastUpdateFailed = false;
			me.numFails--;
			me.numFails = me.numFails > minWeakFails ? minWeakFails : me.numFails;
			me.numFails = me.numFails < 0 ? 0 : me.numFails;
			var cleanData = [];
			var val = null;
			for (var j = 0; j < data.size(); j++) {
				val = data[j];
				if (val != null && val >= 250 && val <= 2000) {
					cleanData.add(val);
				}
			}
			data = cleanData;
		}

		if (me.mListener != null) {
			me.mListener.invoke(data);
		}
	}
}

module HeartbeatIntervalsSensorStatus {
	enum {
		Error = 0,
		Weak = 1,
		Good = 3,
	}
}
