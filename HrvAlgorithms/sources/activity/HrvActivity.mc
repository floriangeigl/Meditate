module HrvAlgorithms {
	class HrvActivity extends HrActivity {
		function initialize(fitSession, hrvTracking, heartbeatIntervalsSensor) {
			me.mHrvTracking = hrvTracking;
			me.mHeartbeatIntervalsSensor = heartbeatIntervalsSensor;
			HrActivity.initialize(fitSession);
		}

		private var mHrvTracking;
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
				if (me.isHrvDetailOn()) {
					me.mHrvMonitor = new HrvMonitorDetailed(me.mFitSession);
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

		private var mHrvValue;

		function refreshActivityStats() {
			HrActivity.refreshActivityStats();
			if (me.isHrvOn()) {
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
