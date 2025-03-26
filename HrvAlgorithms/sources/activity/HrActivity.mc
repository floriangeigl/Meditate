using Toybox.Timer;
using Toybox.FitContributor;
using Toybox.ActivityRecording;
using Toybox.Sensor;

module HrvAlgorithms {
	class HrActivity extends SensorActivityTumbling {
		private var mFitSession;
		private const RefreshActivityInterval = 1000;
		private var mRefreshActivityTimer;
		private const MinHrFieldId = 0;
		private var mMinHrField;
		var minHr;

		function initialize(fitSessionSpec) {
			SensorActivityTumbling.initialize(new HrSummary(), null, null);
			me.mFitSession = ActivityRecording.createSession(fitSessionSpec);
			me.createMinHrDataField();
			me.onBeforeStart(me.mFitSession);
			me.mFitSession.start();
			me.mRefreshActivityTimer = new Timer.Timer();
			me.mRefreshActivityTimer.start(method(:refreshActivityStats), RefreshActivityInterval, true);
			me.minHr = null;
		}

		protected function onBeforeStart(fitSession) {}

		function stop() {
			if (me.mFitSession.isRecording() == false) {
				return;
			}
			me.onBeforeStop();
			me.mFitSession.stop();
			me.mRefreshActivityTimer.stop();
			me.mRefreshActivityTimer = null;
		}

		protected function onBeforeStop() {}

		// Pause/Resume session, returns true is session is now running
		function pauseResume() {
			// Check if session is running
			if (me.mFitSession.isRecording()) {
				// Stop the timer and refresh the screen
				// to show the pause text
				me.mFitSession.stop();
				me.mRefreshActivityTimer.stop();
				me.mRefreshActivityTimer = null;
				refreshActivityStats();
				return false;
			} else {
				// Restart the timer for the session
				me.mFitSession.start();
				me.mRefreshActivityTimer = new Timer.Timer();
				me.mRefreshActivityTimer.start(method(:refreshActivityStats), RefreshActivityInterval, true);
				return true;
			}
		}

		function isTimerRunning() {
			return me.mFitSession.isRecording();
		}

		private function createMinHrDataField() {
			me.mMinHrField = me.mFitSession.createField("min_hr", me.MinHrFieldId, FitContributor.DATA_TYPE_UINT16, {
				:mesgType => FitContributor.MESG_TYPE_SESSION,
				:units => "bpm",
			});
		}

		function refreshActivityStats() {
			var activityInfo = Activity.getActivityInfo();
			if (activityInfo == null) {
				me.updateData(null);
			}

			var currentHr = null;
			if (me.mFitSession != null && me.mFitSession.isRecording()) {
				currentHr = activityInfo.currentHeartRate;
				me.updateData(currentHr);
			}
			if (currentHr != null && (me.minHr == null || currentHr < me.minHr)) {
				me.minHr = currentHr;
			}
			me.onRefreshHrActivityStats(activityInfo, me.minHr);
		}

		protected function onRefreshHrActivityStats(activityInfo, minHr) {}

		function getSummary() {
			var summary = SensorActivityTumbling.getSummary();
			var activityInfo = Activity.getActivityInfo();
			summary.elapsedTimeSeconds = activityInfo.timerTime / 1000;
			return summary;
		}

		function finish() {
			me.mFitSession.save();
			me.mFitSession = null;
		}

		function discard() {
			me.mFitSession.discard();
			me.mFitSession = null;
		}

		function discardDanglingActivity() {
			var isDangling = me.mFitSession != null && !me.mFitSession.isRecording();
			if (isDangling) {
				me.discard();
			}
		}
	}
}
