using Toybox.Sensor;
using Toybox.Lang;
using Toybox.Timer;

module HrvAlgorithms {
	class HeartbeatIntervalsSensor {
		private const SessionSamplePeriodSeconds = 1;
		private const resetSeconds = 30;
		private const maxErrorFails = 11;

		private var mSensorListener;
		private var numFails;
		private var totalTime;
		private var totalIntervals;
		private var sensorRestarts;
		private var running;
		private var sensorTypes;

		function initialize(external_sensor) {
			// System.println("HR sensor: Init");
			me.numFails = 10;
			me.totalTime = 0;
			me.totalIntervals = 0.0;
			me.sensorRestarts = 0;
			me.running = false;
			me.sensorTypes = [];
			if (Sensor has :SENSOR_ONBOARD_HEARTRATE) {
				sensorTypes.add(Sensor.SENSOR_ONBOARD_HEARTRATE);
				if (external_sensor) {
					sensorTypes.add(Sensor.SENSOR_HEARTRATE);
				}
			} else {
				sensorTypes.add(Sensor.SENSOR_HEARTRATE);
			}
		}

		private function enableHrSensor() {
			// System.println("HR sensor: Enable");
			Sensor.setEnabledSensors(me.sensorTypes);

			if (Sensor has :enableSensorType) {
				for (var i = 0; i < me.sensorTypes.size(); i++) {
					Sensor.enableSensorType(me.sensorTypes[i]);
				}
			}
		}

		private function disableHrSensor() {
			// System.println("HR sensor: Disable");
			Sensor.setEnabledSensors([]);
		}

		function start() {
			me.enableHrSensor();
			me.registerListener();
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
			Sensor.unregisterSensorDataListener();
		}

		function setOneSecBeatToBeatIntervalsSensorListener(listener) {
			me.mSensorListener = listener;
		}

		function getStatus() {
			return me.numFails < 5
				? HeartbeatIntervalsSensorStatus.Good
				: me.numFails < maxErrorFails
				? HeartbeatIntervalsSensorStatus.Weak
				: HeartbeatIntervalsSensorStatus.Error;
		}

		function ensureSensorHealth() {
			if (me.numFails >= resetSeconds && me.numFails % resetSeconds == 0) {
				me.start();
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

			if (data == null || data.size() == 0) {
				me.numFails++;
			} else {
				me.numFails = me.numFails > maxErrorFails ? maxErrorFails : me.numFails;
				me.numFails--;
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
