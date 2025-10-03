using Toybox.Sensor;
using Toybox.Lang;
using Toybox.Timer;

module HrvAlgorithms {
	class HeartbeatIntervalsSensor {
		private const SessionSamplePeriodSeconds = 1;
		private var mSensorListener;
		private var numFails;
		private var totalTime;
		private var totalIntervals;
		private var sensorRestarts;
		private var running;
		private const softResetSeconds = 15;
		private const hardResetSeconds = 60;
		private var sensorTypes;

		function initialize() {
			// System.println("HR sensor: Init");
			me.numFails = 10;
			me.totalTime = 0;
			me.totalIntervals = 0.0;
			me.sensorRestarts = 0;
			me.running = false;
			me.sensorTypes = [Sensor.SENSOR_HEARTRATE];
			if (Sensor has :SENSOR_ONBOARD_HEARTRATE) {
				sensorTypes.add(Sensor.SENSOR_ONBOARD_HEARTRATE);
			}
		}

		private function enableHrSensor() {
			// System.println("HR sensor: Enable");
			Sensor.setEnabledSensors(me.sensorTypes);
		}

		private function disableHrSensor() {
			// System.println("HR sensor: Disable");
			Sensor.setEnabledSensors([]);
		}

		function start() {
			if (!me.running) {
				// System.println("HR sensor: Start");
				me.totalTime = 0;
				me.totalIntervals = 0.0;
				me.enableHrSensor();
				me.registerListener();
				me.running = true;
			} else {
				// System.println("HR sensor: Can't start - already running");
			}
		}

		function registerListener() {
			Sensor.unregisterSensorDataListener();
			Sensor.registerSensorDataListener(method(:update), {
				:period => SessionSamplePeriodSeconds,
				:heartBeatIntervals => {
					:enabled => true,
				},
			});
		}

		function stop() {
			if (me.running) {
				// System.println("HR sensor: Stop");
				Sensor.unregisterSensorDataListener();
				me.running = false;
			}
			me.disableHrSensor();
		}

		function setOneSecBeatToBeatIntervalsSensorListener(listener) {
			me.mSensorListener = listener;
		}

		function getStatus() {
			return me.numFails < 3
				? HeartbeatIntervalsSensorStatus.Good
				: me.numFails < 6
				? HeartbeatIntervalsSensorStatus.Weak
				: HeartbeatIntervalsSensorStatus.Error;
		}

		function ensureSensorHealth() {
			if (
				me.numFails >= softResetSeconds &&
				(me.numFails % softResetSeconds == 0 || me.numFails % hardResetSeconds == 0)
			) {
				me.registerListener();
				// System.println("HR sensor: Soft reset");
				if (me.numFails >= hardResetSeconds && me.numFails % hardResetSeconds == 0) {
					// System.println("HR sensor: Hard reset");
					me.stop();
					me.start();
				}

				me.sensorRestarts += 1;
			}
		}

		function resetSensorQuality() {
			me.totalTime = 0;
			me.totalIntervals = 0.0;
			me.sensorRestarts = 0;
		}

		function update(sensorData) {
			var data =
				sensorData has :heartRateData &&
				sensorData.heartRateData != null &&
				sensorData.heartRateData has :heartBeatIntervals &&
				sensorData.heartRateData.heartBeatIntervals != null
					? sensorData.heartRateData.heartBeatIntervals
					: [];
			// System.println("HR sensor: Invoke index " + i + " with data: " + data);
			if (me.mSensorListener != null) {
				//TODO: cleanup data? <250ms & >2000ms
				me.mSensorListener.invoke(data);
			}
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
