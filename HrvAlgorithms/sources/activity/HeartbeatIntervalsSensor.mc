using Toybox.Sensor;
using Toybox.Lang;
using Toybox.Timer;

module HrvAlgorithms {
	class HeartbeatIntervalsSensor {
		private const SessionSamplePeriodSeconds = 1;
		private var buffer;
		private const bufferMaxSize = 3;
		private var timer;
		private var bufferWriteIndex;
		private var mSensorListener;
		private var numFails;
		private var enabledHrSensors;
		private var totalTime;
		private var totalIntervals;
		private var sensorRestarts;

		function initialize() {
			// System.println("HR sensor: Init");
			me.buffer = new [me.bufferMaxSize];
			me.timer = null;
			me.bufferWriteIndex = 0;
			me.numFails = 10;
			me.enabledHrSensors = [];
			me.totalTime = 0;
			me.totalIntervals = 0.0;
			me.sensorRestarts = 0;
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
			if (me.timer == null) {
				// System.println("HR sensor: Start");
				me.enableHrSensor();
				me.totalTime = 0;
				me.totalIntervals = 0.0;
				Sensor.registerSensorDataListener(method(:addToBuffer), {
					:period => SessionSamplePeriodSeconds,
					:heartBeatIntervals => {
						:enabled => true,
					},
				});
				me.timer = new Timer.Timer();
				me.timer.start(method(:update), 1000, true);
			} else {
				// System.println("HR sensor: Can't start - already running");
			}
		}

		function stop() {
			if (me.timer != null) {
				// System.println("HR sensor: Stop");
				me.timer.stop();
				me.timer = null;
				me.bufferWriteIndex = 0;
				Sensor.unregisterSensorDataListener();
				me.disableHrSensor();
			} else {
				// System.println("HR sensor: Can't stop - already stopped");
			}
		}

		function addToBuffer(sensorData) {
			me.bufferWriteIndex = me.bufferWriteIndex < me.bufferMaxSize ? me.bufferWriteIndex : 0;
			me.buffer[me.bufferWriteIndex] =
				sensorData has :heartRateData &&
				sensorData.heartRateData != null &&
				sensorData.heartRateData has :heartBeatIntervals &&
				sensorData.heartRateData.heartBeatIntervals != null
					? sensorData.heartRateData.heartBeatIntervals
					: [];
			// System.println("HR sensor: buffer add [" + me.bufferWriteIndex + "]: " + me.buffer[me.bufferWriteIndex]);
			me.bufferWriteIndex = mSensorListener != null ? me.bufferWriteIndex + 1 : me.bufferWriteIndex;
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

		function update() {
			if (me.mSensorListener != null) {
				me.totalTime += 1;
				var data = [null];
				if (me.bufferWriteIndex > 0) {
					for (var i = 0; i < me.bufferWriteIndex; i++) {
						data = me.buffer[i];
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
					}
				} else {
					// System.println("HR sensor: No data in buffer, invoking with: " + data);
					me.mSensorListener.invoke(data);
					me.numFails++;
				}
				me.bufferWriteIndex = 0;
				if (me.totalTime > 60) {
					// System.println(
					// 	"HR sensor: Quality: " + me.totalIntervals / me.totalTime + " | restarts: " + me.sensorRestarts
					// );
				}
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
