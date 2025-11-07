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
			me.minHr = null;
			me.currentHr = null;
			me.mFitSession = ActivityRecording.createSession(fitSessionSpec);
			me.createMinHrDataField();
			me.mRefreshActivityTimer = new Timer.Timer();
		}

		function start() {
			me.minHr = null;
			me.currentHr = null;
			me.mFitSession.start();
			me.mRefreshActivityTimer.start(method(:refreshActivityStats), RefreshActivityInterval, true);
			me.activityInfo = Activity.getActivityInfo();
		}

		function stop() {
			if (me.mFitSession.isRecording() == false) {
				return;
			}
			me.mFitSession.stop();
			me.mRefreshActivityTimer.stop();
		}

		// Pause/Resume session, returns true is session is now running
		function pauseResume() {
			// Check if session is running
			if (me.mFitSession.isRecording()) {
				me.mFitSession.stop();
				me.mRefreshActivityTimer.stop();
				return false;
			} else {
				me.mFitSession.start();
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
			if (me.mFitSession != null && me.mFitSession.isRecording()) {
				me.activityInfo = Activity.getActivityInfo();
				me.updateData(me.activityInfo.currentHeartRate);
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
			me.activityInfo = Activity.getActivityInfo();
			summary.elapsedTimeSeconds = me.activityInfo.timerTime / 1000;
			return summary;
		}

		function finish() {
			if (me.mFitSession != null) {
				me.mFitSession.save();
				me.sessionSaved = true;
			}
			me.mFitSession = null;
		}

		function discard() {
			if (me.mFitSession != null) {
				me.mFitSession.discard();
			}
			me.mFitSession = null;
		}

		function discardDanglingActivity() {
			if (me.mFitSession != null && !me.mFitSession.isRecording()) {
				me.discard();
			}
		}

		static function getLoadTime() {
			return HrActivity.windowSize;
		}
	}
}
