using Toybox.Timer;
using Toybox.FitContributor;
using Toybox.ActivityRecording;
using Toybox.Sensor;

module HrvAlgorithms {
	class HrActivity extends SensorActivityTumbling {
		protected var mFitSession;
		private const RefreshActivityInterval = 1000;
		private var mRefreshActivityTimer;
		private const MinHrFieldId = 0;
		private var mMinHrField;
		protected var activityInfo;
		protected var minHr;
		protected var currentHr;
		private static const windowSize = 10;
		var sessionSaved = false;

		function initialize(fitSessionSpec) {
			SensorActivityTumbling.initialize(new HrSummary(), null, HrActivity.windowSize);
			me.mFitSession = ActivityRecording.createSession(fitSessionSpec);
			me.createMinHrDataField();
		}

		function start() {
			me.mFitSession.start();
			me.mRefreshActivityTimer = new Timer.Timer();
			me.mRefreshActivityTimer.start(method(:refreshActivityStats), RefreshActivityInterval, true);
			me.minHr = null;
			me.activityInfo = null;
			me.currentHr = null;
		}

		function stop() {
			if (me.mFitSession.isRecording() == false) {
				return;
			}
			me.mFitSession.stop();
			me.mRefreshActivityTimer.stop();
			me.mRefreshActivityTimer = null;
		}

		// Pause/Resume session, returns true is session is now running
		function pauseResume() {
			// Check if session is running
			if (me.mFitSession.isRecording()) {
				// Stop the timer and refresh the screen
				// to show the pause text
				me.mFitSession.stop();
				me.mRefreshActivityTimer.stop();
				me.mRefreshActivityTimer = null;
				me.refreshActivityStats();
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
			me.activityInfo = Activity.getActivityInfo();
			if (me.activityInfo == null) {
				me.updateData(null);
			}

			if (me.mFitSession != null && me.mFitSession.isRecording()) {
				me.updateData(activityInfo.currentHeartRate);
				me.currentHr = me.getLastValue();
			} else {
				me.currentHr = null;
			}
			if (me.currentHr != null && (me.minHr == null || me.currentHr < me.minHr)) {
				me.minHr = me.currentHr;
			}
		}

		function getSummary() {
			var summary = SensorActivityTumbling.getSummary();
			var activityInfo = Activity.getActivityInfo();
			summary.elapsedTimeSeconds = activityInfo.timerTime / 1000;
			return summary;
		}

		function finish() {
			me.mFitSession.save();
			me.mFitSession = null;
			me.sessionSaved = true;
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

		static function getLoadTime() {
			return HrActivity.windowSize;
		}
	}
}
