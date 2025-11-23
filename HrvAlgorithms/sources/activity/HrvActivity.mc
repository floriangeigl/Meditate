module HrvAlgorithms {
	class HrvActivity extends HrActivity {
		function initialize(fitSession, hrvTracking, heartbeatIntervalsSensor, hrvWindowSize) {
			me.mHrvTracking = hrvTracking;
			me.mHrvWindowSize = hrvWindowSize;
			me.mHeartbeatIntervalsSensor = heartbeatIntervalsSensor;
			HrActivity.initialize(fitSession);
			me.mHeartbeatIntervalsSensor.sensorWakeupSession = null;
		}

		private var mHrvTracking;
		private var mHrvWindowSize;
		private var mHeartbeatIntervalsSensor;
		private var mHrvMonitor;

		private function isHrvOn() {
			return me.mHrvTracking != HrvTracking.Off;
		}

		private function isHrvDetailOn() {
			return me.mHrvTracking == HrvTracking.OnDetailed;
		}

		function start() {
			if (me.isHrvOn()) {
				me.mHeartbeatIntervalsSensor.setOneSecBeatToBeatIntervalsSensorListener(
					method(:onOneSecBeatToBeatIntervals)
				);
				me.mHeartbeatIntervalsSensor.resetSensorQuality();
				if (me.isHrvDetailOn()) {
					me.mHrvMonitor = new HrvMonitorDetailed(me.mFitSession, me.mHrvWindowSize);
				} else {
					me.mHrvMonitor = new HrvMonitorDefault(me.mFitSession);
				}
			}
			HrActivity.start();
		}

		function getHrv() {
			if (me.mHrvMonitor != null) {
				return me.mHrvMonitor.getHrv();
			} else {
				return null;
			}
		}

		function onOneSecBeatToBeatIntervals(heartBeatIntervals) {
			if (me.isHrvOn()) {
				me.mHrvMonitor.addOneSecBeatToBeatIntervals(heartBeatIntervals);
			}
		}

		function stop() {
			HrActivity.stop();
			if (me.isHrvOn()) {
				me.mHeartbeatIntervalsSensor.setOneSecBeatToBeatIntervalsSensorListener(null);
			}
		}

		// Override pause/resume to also pause heartbeat interval capturing
		function pauseResume() {
			var running = HrActivity.pauseResume();
			if (me.isHrvOn()) {
				if (running) {
					// Activity resumed -> resume sensor data capturing
					me.mHeartbeatIntervalsSensor.resume();
				} else {
					// Activity paused -> pause sensor data capturing
					me.mHeartbeatIntervalsSensor.pause();
				}
			}
			return running;
		}

		private var mHrvValue;

		function refreshActivityStats() {
			HrActivity.refreshActivityStats();
			if (me.isHrvOn() && me.mFitSession != null && me.mFitSession.isRecording()) {
				me.mHrvValue = me.mHrvMonitor.getHrv();
			}
		}

		function calculateSummaryFields() {
			var hrSummary = HrActivity.getSummary();
			var activitySummary = new ActivitySummary();
			activitySummary.hrSummary = hrSummary;
			if (me.isHrvOn()) {
				activitySummary.hrvSummary = me.mHrvMonitor.calculateHrvSummary();
			}
			return activitySummary;
		}
	}
}
