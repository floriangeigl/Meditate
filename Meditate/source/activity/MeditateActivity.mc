using Toybox.WatchUi as Ui;
using Toybox.Timer;
using Toybox.FitContributor;
using Toybox.Timer;
using Toybox.Math;
using Toybox.Sensor;
using HrvAlgorithms.HrvTracking;

class MediteActivity extends HrvAlgorithms.HrvActivity {
	private var mMeditateModel;
	private var mVibeAlertsExecutor;
	private var mMeditateDelegate;
	private var mAutoStopEnabled;

	function initialize(meditateModel, heartbeatIntervalsSensor, meditateDelegate) {
		var fitSessionSpec;
		var sessionTime = meditateModel.getSessionTime();

		// Retrieve activity name property from Garmin Express/Connect IQ
		var activityName = null;

		if (meditateModel.getActivityType() == ActivityType.Yoga) {
			activityName = Ui.loadResource(Rez.Strings.sessionTitleYoga);
			fitSessionSpec = HrvAlgorithms.FitSessionSpec.createYoga(createSessionName(sessionTime, activityName));
		} else if (meditateModel.getActivityType() == ActivityType.Breathing) {
			activityName = Ui.loadResource(Rez.Strings.sessionTitleBreathing);
			fitSessionSpec = HrvAlgorithms.FitSessionSpec.createBreathing(createSessionName(sessionTime, activityName));
		} else {
			activityName = Ui.loadResource(Rez.Strings.sessionTitleMeditate);
			fitSessionSpec = HrvAlgorithms.FitSessionSpec.createMeditation(
				createSessionName(sessionTime, activityName)
			);
		}

		me.mMeditateModel = meditateModel;
		me.mMeditateDelegate = meditateDelegate;
		HrvAlgorithms.HrvActivity.initialize(fitSessionSpec, meditateModel.getHrvTracking(), heartbeatIntervalsSensor);
	 	me.mAutoStopEnabled = GlobalSettings.loadAutoStop();
	}

	private function createSessionName(sessionTime, activityName) {
		// Calculate session minutes and hours
		var sessionTimeMinutes = Math.round(sessionTime / 60);
		var sessionTimeHours = Math.round(sessionTimeMinutes / 60);
		var sessionTimeString;

		// Create the Connect activity name showing the number of hours/minutes for the meditate session
		if (sessionTimeHours < 1) {
			sessionTimeString = Lang.format("$1$min", [sessionTimeMinutes]);
		} else {
			sessionTimeMinutes = sessionTimeMinutes % 60;
			if (sessionTimeMinutes == 0) {
				sessionTimeString = Lang.format("$1$h", [sessionTimeHours]);
			} else {
				sessionTimeString = Lang.format("$1$h $2$min", [sessionTimeHours, sessionTimeMinutes]);
			}
		}

		// Replace "[time]" string with the activity time
		activityName = stringReplace(activityName, "[time]", sessionTimeString);

		// If the generated name is too big, cut if off
		if (activityName.length() > 21) {
			activityName = activityName.substring(0, 21);
		}
		return activityName;
	}

	private function stringReplace(str, oldString, newString) {
		var result = str;

		while (true) {
			var index = result.find(oldString);
			if (index != null) {
				var index2 = index + oldString.length();
				result = result.substring(0, index) + newString + result.substring(index2, result.length());
			} else {
				return result;
			}
		}
		return null;
	}

	function start() {
		HrvAlgorithms.HrvActivity.start();
		me.mMeditateModel.isTimerRunning = true;
		me.mVibeAlertsExecutor = new VibeAlertsExecutor(me.mMeditateModel);
	}

	function refreshActivityStats() {
		HrvAlgorithms.HrvActivity.refreshActivityStats();
		if (me.activityInfo.elapsedTime != null) {
			me.mMeditateModel.elapsedTime = me.activityInfo.timerTime / 1000;
		}
		me.mMeditateModel.currentHr = me.getLastValue();
		if (me.mMeditateModel.currentHr == null) {
			// use live heart rate before the first tumbling window is done
			me.mMeditateModel.currentHr = me.activityInfo.currentHeartRate;
		}
		me.mMeditateModel.minHr = me.minHr;
		if (me.mVibeAlertsExecutor != null) {
			me.mVibeAlertsExecutor.firePendingAlerts();
		}
		me.mMeditateModel.hrvValue = me.getHrv();

		// Check if we need to stop activity automatically when time ended
		if (me.mAutoStopEnabled && me.mMeditateModel.elapsedTime >= me.mMeditateModel.getSessionTime()) {
			mMeditateDelegate.stopActivity();
			return;
		}
		Ui.requestUpdate();
	}

	function stop() {
		HrvAlgorithms.HrvActivity.stop();
		me.mVibeAlertsExecutor = null;
	}

	function calculateSummaryFields() {
		var activitySummary = HrvAlgorithms.HrvActivity.calculateSummaryFields();
		var summaryModel = new SummaryModel(
			activitySummary,
			me.mMeditateModel.getRespirationActivity(),
			me.mMeditateModel.getStressActivity(),
			me.mMeditateModel.getHrvTracking()
		);
		return summaryModel;
	}
}
