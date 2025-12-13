using Toybox.Sensor;
using Toybox.Lang;
using Toybox.Timer;
using Toybox.ActivityRecording;
using Toybox.Attention;

module HrvAlgorithms {
	class HeartbeatIntervalsSensor {
		private const SessionSamplePeriodSeconds = 1;
		private const resetSeconds = 30;
		private const maxReadyFails = 4;
		private const maxWeakFails = 8;
		private const minWeakFails = maxReadyFails + 1;

		private var mSensorListener;
		private var numFails;
		private var totalTime;
		private var totalIntervals;
		private var sensorRestarts;
		private var running;
		private var lastUpdateFailed;
		private var statusErrors;
		private var paused;
		var sensorWakeupSession;

		function initialize() {
			// System.println("HR sensor: Init");
			me.resetSensorQuality();
			me.running = false;
			me.lastUpdateFailed = false;
			me.paused = false;
			me.sensorWakeupSession = null;
		}

		function startup() {
			me.numFails = maxWeakFails + 1;
			me.resetSensorQuality();
			me.start();
			me.createWakeupSession();
		}

		function createWakeupSession() {
			me.discardWakeupeSession();
			me.sensorWakeupSession = ActivityRecording.createSession(FitSessionSpec.createTraining("tmp"));
		}

		function discardWakeupeSession() {
			if (me.sensorWakeupSession != null) {
				me.sensorWakeupSession.discard();
				me.sensorWakeupSession = null;
			}
		}

		function shutdown() {
			me.stop();
			me.discardWakeupeSession();
		}

		function start() {
			if (!me.running) {
				me.registerListener();
				me.running = true;
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
					:period => SessionSamplePeriodSeconds,
					:heartBeatIntervals => {
						:enabled => true,
					},
				});
			} catch (e instanceof Sensor.TooManySensorDataListenersException) {
				Sensor.unregisterSensorDataListener();
				me.registerListener();
			}
		}

		function setOneSecBeatToBeatIntervalsSensorListener(listener) {
			me.mSensorListener = listener;
		}

		function getStatus() {
			var status =
				me.numFails <= maxReadyFails
					? HeartbeatIntervalsSensorStatus.Good
					: me.numFails <= maxWeakFails
					? HeartbeatIntervalsSensorStatus.Weak
					: HeartbeatIntervalsSensorStatus.Error;
			if (status == HeartbeatIntervalsSensorStatus.Good && me.statusErrors > 0) {
				me.statusErrors = 0;
				Vibe.vibrate(VibePattern.Blip);
			} else if (status == HeartbeatIntervalsSensorStatus.Error) {
				me.statusErrors += 1;
				if (me.statusErrors % 5 == 0) {
					if (Attention has :backlight) {
						try {
							Attention.backlight(true);
						} catch (e instanceof Attention.BacklightOnTooLongException) {
							// burn in protection kicked in; backlight disabled; ignore
						}
					}
				}
				if (me.statusErrors > 20) {
					me.discardWakeupeSession();
					me.stop();
					me.start();
					me.createWakeupSession();
					me.statusErrors = 1;
				}
			}
			return status;
		}

		function resetSensorQuality() {
			me.totalTime = 0;
			me.totalIntervals = 0.0;
			me.sensorRestarts = 0;
			me.numFails = maxWeakFails + 1;
			me.statusErrors = 0;
		}

		function update(sensorData) {
			if (me.paused) {
				return;
			}
			me.totalTime += 1;
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
						me.totalIntervals = me.totalIntervals + val / 1000.0;
					}
				}
				data = cleanData;
			}

			// System.println("HR sensor: Invoke index " + i + " with data: " + data);
			if (me.mSensorListener != null) {
				me.mSensorListener.invoke(data);
			}

			//if (me.totalTime > 60) {
			// System.println(
			// 	"HR sensor: Quality: " + me.totalIntervals / me.totalTime + " | restarts: " + me.sensorRestarts
			// );
			//}
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
