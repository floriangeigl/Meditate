using Toybox.Sensor;
using Toybox.Lang;
using Toybox.Timer;

module HrvAlgorithms {
	class HeartbeatIntervalsSensor {
		private var SessionSamplePeriodSeconds = 1;
		private var buffer;
		private var timer;
		private var bufferWriteIndex;
		private var mSensorListener;
		private var numFails;

		function initialize() {
			me.buffer = new [10];
			me.timer = new Timer.Timer();
			me.bufferWriteIndex = 0;
			me.numFails = 10;
			me.enableHrSensor();
		}

		function enableHrSensor() {
			Sensor.setEnabledSensors([Sensor.SENSOR_HEARTRATE]);
		}

		function disableHrSensor() {
			Sensor.setEnabledSensors([]);
		}

		function start() {
			Sensor.unregisterSensorDataListener();
			Sensor.registerSensorDataListener(method(:addToBuffer), {
				:period => SessionSamplePeriodSeconds,
				:heartBeatIntervals => {
					:enabled => true,
				},
			});
			me.timer.start(method(:update), 1000, true);
		}

		function stop() {
			me.timer.stop();
			me.bufferWriteIndex = 0;
			Sensor.unregisterSensorDataListener();
		}

		function addToBuffer(sensorData) {
			if (!(sensorData has :heartRateData) || mSensorListener == null) {
				return;
			}

			if (me.bufferWriteIndex >= me.buffer.size()) {
				me.bufferWriteIndex = 0;
			}

			if (sensorData.heartRateData != null) {
				me.buffer[me.bufferWriteIndex] = sensorData.heartRateData.heartBeatIntervals;
				me.bufferWriteIndex++;
			}
		}

		function setOneSecBeatToBeatIntervalsSensorListener(listener) {
			me.mSensorListener = listener;
		}

		function getStatus() {
			if (me.mSensorListener != null) {
				if (me.numFails < 2) {
					return HeartbeatIntervalsSensorStatus.Good;
				} else if (me.numFails < 5) {
					return HeartbeatIntervalsSensorStatus.Weak;
				} else {
					return HeartbeatIntervalsSensorStatus.Error;
				}
			}
		}

		function ensureSensorHealth() {
			if (me.numFails >= 30 && me.numFails % 30 == 0) {
				System.println("Restart HR sensor");
				var tmpListener = me.mSensorListener;
				me.stop();
				me.setOneSecBeatToBeatIntervalsSensorListener(null);
				me.start();
				me.setOneSecBeatToBeatIntervalsSensorListener(tmpListener);
			}
		}

		function update() {
			if (me.mSensorListener != null) {
				var data = [null];
				if (me.bufferWriteIndex > 0) {
					for (var i = 0; i < me.bufferWriteIndex; i++) {
						data = me.buffer[i];
						me.mSensorListener.invoke(data);
						if (data == null) {
							me.numFails++;
						} else {
							me.numFails = 0;
						}
					}
				} else {
					me.mSensorListener.invoke(data);
					me.numFails++;
				}
				me.bufferWriteIndex = 0;
				me.ensureSensorHealth();
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
