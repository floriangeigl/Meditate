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
		private var enabledHrSensors;
		private var totalTime;
		private var totalIntervals;
		var externalSensorConnected;

		function initialize() {
			System.println("HR sensor: Init");
			me.buffer = new [10];
			me.timer = null;
			me.bufferWriteIndex = 0;
			me.numFails = 10;
			me.enabledHrSensors = [];
			me.totalTime = 0;
			me.totalIntervals = 0.0;
		}

		private function enableHrSensor() {
			System.println("HR sensor: Enable");
			me.enabledHrSensors = Sensor.setEnabledSensors([Sensor.SENSOR_HEARTRATE]);
			me.externalSensorConnected = me.anyExternalHrSensorConnected();
		}

		private function disableHrSensor() {
			System.println("HR sensor: Disable");
			me.enabledHrSensors = Sensor.setEnabledSensors([]);
			me.externalSensorConnected = me.anyExternalHrSensorConnected();
		}

		function start() {
			if (me.timer == null) {
				System.println("HR sensor: Start");
				me.enableHrSensor();
				me.totalTime = 0;
				me.totalIntervals = 0.0;
				Sensor.unregisterSensorDataListener();
				Sensor.registerSensorDataListener(method(:addToBuffer), {
					:period => SessionSamplePeriodSeconds,
					:heartBeatIntervals => {
						:enabled => true,
					},
				});
				me.timer = new Timer.Timer();
				me.timer.start(method(:update), 1000, true);
				me.externalSensorConnected = me.anyExternalHrSensorConnected();
			} else {
				System.println("HR sensor: Can't start - already running");
			}
		}

		function stop() {
			if (me.timer != null) {
				System.println("HR sensor: Stop");
				me.timer.stop();
				me.timer = null;
				me.bufferWriteIndex = 0;
				Sensor.unregisterSensorDataListener();
				me.disableHrSensor();
				me.externalSensorConnected = me.anyExternalHrSensorConnected();
			} else {
				System.println("HR sensor: Can't stop - already stopped");
			}
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
				System.println("HR sensor: added data to buffer: " + me.buffer[me.bufferWriteIndex]);
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

		private function anyExternalHrSensorConnected() {
			for (var i = 0; i < me.enabledHrSensors.size(); i++) {
				System.println("Sensor: " + me.enabledHrSensors[i]);
				if (me.enabledHrSensors[i] == Sensor.SENSOR_HEARTRATE) {
					if (
						Sensor has :SENSOR_ONBOARD_HEARTRATE &&
						me.enabledHrSensors[i] != Sensor.SENSOR_ONBOARD_HEARTRATE
					) {
						return true;
					}
					return true;
				}
			}
			return false;
		}

		function ensureSensorHealth() {
			if (me.numFails >= 30 && me.numFails % 30 == 0) {
				System.println("HR sensor: Restart");
				var tmpListener = me.mSensorListener;
				me.stop();
				me.setOneSecBeatToBeatIntervalsSensorListener(null);
				me.start();
				me.setOneSecBeatToBeatIntervalsSensorListener(tmpListener);
			}
		}

		function update() {
			if (me.mSensorListener != null) {
				me.totalTime += 1;
				var data = [null];
				if (me.bufferWriteIndex > 0) {
					for (var i = 0; i < me.bufferWriteIndex; i++) {
						data = me.buffer[i];
						System.println("HR sensor: Invoke index " + i + " with data: " + data);
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
					me.mSensorListener.invoke(data);
					me.numFails++;
				}
				me.bufferWriteIndex = 0;
				if (me.totalTime > 60) {
					System.println("HR sensor: 60sec quality: " + me.totalIntervals / me.totalTime);
					me.totalTime = 0;
					me.totalIntervals = 0.0;
				}
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
