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

		protected function onBeforeStart(fitSession) {
			HrActivity.onBeforeStart(fitSession);
			if (me.isHrvOn()) {
				me.mHeartbeatIntervalsSensor.setOneSecBeatToBeatIntervalsSensorListener(
					method(:onOneSecBeatToBeatIntervals)
				);
				if (me.isHrvDetailOn()) {
					me.mHrvMonitor = new HrvMonitorDetailed(fitSession, true);
				} else {
					me.mHrvMonitor = new HrvMonitorDefault(fitSession);
				}
			}
		}

		function onOneSecBeatToBeatIntervals(heartBeatIntervals) {
			if (me.isHrvOn()) {
				me.mHrvMonitor.addOneSecBeatToBeatIntervals(heartBeatIntervals);
			}
		}

		protected function onBeforeStop() {
			if (me.isHrvOn()) {
				me.mHeartbeatIntervalsSensor.setOneSecBeatToBeatIntervalsSensorListener(null);
			}
		}

		private var mHrvValue;

		protected function onRefreshHrActivityStats(activityInfo, minHr) {
			if (me.isHrvOn()) {
				if (me.isHrvDetailOn()) {
					me.mHrvValue = me.mHrvMonitor.getRmssdRolling();
				} else {
					me.mHrvValue = me.mHrvMonitor.calculateHrvSuccessive();
				}
			}
			me.onRefreshHrvActivityStats(activityInfo, minHr, me.mHrvValue);
		}

		protected function onRefreshHrvActivityStats(activityInfo, minHr, hrvValue) {}

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
