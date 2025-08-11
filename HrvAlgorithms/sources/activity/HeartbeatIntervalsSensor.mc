using Toybox.Sensor;
using Toybox.Lang;
using Toybox.Timer;

module HrvAlgorithms {
	class HeartbeatIntervalsSensor {
		private const SessionSamplePeriodSeconds = 1;
		private var mSensorListener;
		private var numFails;
		private var enabledHrSensors;
		private var totalTime;
		private var totalIntervals;
		private var sensorRestarts;
		private var running;

		function initialize() {
			// System.println("HR sensor: Init");

			me.numFails = 10;
			me.enabledHrSensors = [];
			me.totalTime = 0;
			me.totalIntervals = 0.0;
			me.sensorRestarts = 0;
			me.running = false;
		}

		private function enableHrSensor() {
			// System.println("HR sensor: Enable");
			me.enabledHrSensors = Sensor.setEnabledSensors([Sensor.SENSOR_HEARTRATE]);
		}

		private function disableHrSensor() {
			// System.println("HR sensor: Disable");
			me.enabledHrSensors = Sensor.setEnabledSensors([]);
		}

		function start() {
			if (!me.running) {
				// System.println("HR sensor: Start");
				me.enableHrSensor();
				me.totalTime = 0;
				me.totalIntervals = 0.0;
				Sensor.registerSensorDataListener(method(:update), {
					:period => SessionSamplePeriodSeconds,
					:heartBeatIntervals => {
						:enabled => true,
					},
				});
				me.running = true;
			} else {
				// System.println("HR sensor: Can't start - already running");
			}
		}

		function stop() {
			if (me.running) {
				// System.println("HR sensor: Stop");
				Sensor.unregisterSensorDataListener();
				me.disableHrSensor();
				me.running = false;
			} else {
				// System.println("HR sensor: Can't stop - already stopped");
			}
		}

		function setOneSecBeatToBeatIntervalsSensorListener(listener) {
			me.mSensorListener = listener;
		}

		function getStatus() {
			return me.numFails < 2
				? HeartbeatIntervalsSensorStatus.Good
				: me.numFails < 5
				? HeartbeatIntervalsSensorStatus.Weak
				: HeartbeatIntervalsSensorStatus.Error;
		}

		function ensureSensorHealth() {
			if (me.numFails >= 30 && me.numFails % 30 == 0) {
				// System.println("HR sensor: Restart");
				var tmpListener = me.mSensorListener;
				me.setOneSecBeatToBeatIntervalsSensorListener(null);
				me.stop();
				me.start();
				me.setOneSecBeatToBeatIntervalsSensorListener(tmpListener);
				me.sensorRestarts += 1;
			}
		}

		function resetSensorQuality() {
			me.totalTime = 0;
			me.totalIntervals = 0.0;
			me.sensorRestarts = 0;
		}

		function update(sensorData) {
			if (me.mSensorListener != null) {
				var data =
					sensorData has :heartRateData &&
					sensorData.heartRateData != null &&
					sensorData.heartRateData has :heartBeatIntervals &&
					sensorData.heartRateData.heartBeatIntervals != null
						? sensorData.heartRateData.heartBeatIntervals
						: [];
				// System.println("HR sensor: Invoke index " + i + " with data: " + data);
				me.mSensorListener.invoke(data);
				if (data == null || data.size() == 0) {
					me.numFails++;
				} else {
					me.numFails = me.numFails > 5 ? 5 : me.numFails;
					me.numFails--;
					me.numFails = me.numFails < 0 ? 0 : me.numFails;
					for (var j = 0; j < data.size(); j++) {
						me.totalIntervals = me.totalIntervals + data[j] / 1000.0;
					}
				}

				//if (me.totalTime > 60) {
				// System.println(
				// 	"HR sensor: Quality: " + me.totalIntervals / me.totalTime + " | restarts: " + me.sensorRestarts
				// );
				//}
				me.ensureSensorHealth();
			} else {
				// System.println("HR sensor: No listener set, skipping update");
			}
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
