using Toybox.WatchUi as Ui;
using Toybox.Lang;
using Toybox.Math;
using Toybox.Application as App;

// owns the recorder, the sensor feed wiring and everything that fires on the session tick
class MeditateActivity {
	private var mMeditateModel;
	private var mMeditateDelegate;
	private var mFeed;
	private var mRecorder;
	private var mHrv;
	private var mVibeAlertsExecutor;
	private var mBreathCuesExecutor;
	private var mAutoStopEnabled;
	private var mAutoStopRoundsTriggered;
	private var mEffectiveWakeupSessionType;
	private var mSummary;

	function initialize(meditateModel, beatIntervalFeed, meditateDelegate) {
		var fitSessionSpec;
		var sessionTime = meditateModel.getSessionTime();
		// current hypothesis: mediation/yoga/breathwork only supported with api >= 3.3.6
		// device to version: https://github.com/flocsy/garmin-dev-tools/blob/main/csv/device2all-versions.csv
		var supportsActivityTypes = Utils.MonkeyVersionAtLeast([3, 3, 6]);
		// System.println(version + " " + supportsActivityTypes);

		// Determine activity name: prefer using the session's custom name if the global setting enables it,
		// otherwise fall back to the Garmin Connect property or default titles.
		var activityName = "";
		if (
			GlobalSettings.loadUseSessionName() &&
			meditateModel.getName() != null &&
			meditateModel.getName().length() > 0
		) {
			activityName = meditateModel.getName().toString();
		} else {
			var storedActivityName = App.Properties.getValue("activityName");
			if (storedActivityName != null && storedActivityName.length() > 0) {
				activityName = storedActivityName.toString();
			} else {
				activityName = "";
			}
		}
		var selectedActivityType = Utils.getEffectiveActivityType(meditateModel.getActivityType());
		if (selectedActivityType == ActivityType.Yoga) {
			activityName = activityName.length() > 0 ? activityName : Ui.loadResource(Rez.Strings.sessionTitleYoga);
			fitSessionSpec = FitSessionSpec.createYoga(createSessionName(sessionTime, activityName));
			me.mEffectiveWakeupSessionType = WakeupSessionType.Yoga;
		} else if (selectedActivityType == ActivityType.Breathing) {
			activityName =
				activityName.length() > 0 ? activityName : Ui.loadResource(Rez.Strings.sessionTitleBreathing);
			fitSessionSpec = FitSessionSpec.createBreathing(createSessionName(sessionTime, activityName));
			me.mEffectiveWakeupSessionType = WakeupSessionType.Breathing;
		} else {
			activityName = activityName.length() > 0 ? activityName : Ui.loadResource(Rez.Strings.sessionTitleMeditate);
			fitSessionSpec = FitSessionSpec.createMeditation(createSessionName(sessionTime, activityName));
			me.mEffectiveWakeupSessionType = WakeupSessionType.Meditation;
		}
		if (!supportsActivityTypes || selectedActivityType == ActivityType.Generic) {
			fitSessionSpec = FitSessionSpec.createTraining(createSessionName(sessionTime, activityName));
			me.mEffectiveWakeupSessionType = WakeupSessionType.Training;
			// System.println("create generic activity as others are not supported");
		}
		me.mMeditateModel = meditateModel;
		me.mMeditateDelegate = meditateDelegate;
		me.mFeed = beatIntervalFeed;
		// at most one open fit session: the wakeup session goes right before ours is created
		me.mFeed.discardWakeupSession();
		me.mRecorder = new ActivityRecorder(fitSessionSpec, me);
		var metrics = MeditateActivity.createMetrics(meditateModel, me.mRecorder.fit);
		me.mRecorder.setMetrics(metrics);
		meditateModel.liveMetrics = metrics;
		me.mHrv = meditateModel.getMetric(:hrv);
		me.mSummary = null;
		me.mAutoStopEnabled = GlobalSettings.loadAutoStop();
		me.mAutoStopRoundsTriggered = 0;
	}

	// the one place deciding what is recorded; hr first, the rest in metrics page order
	static function createMetrics(meditateModel, fitFields) {
		var metrics = [new HrMetric()];
		var hrvTracking = meditateModel.getHrvTracking();
		if (hrvTracking != HrvTracking.Off) {
			metrics.add(
				new HrvMetric(fitFields, hrvTracking == HrvTracking.OnDetailed, GlobalSettings.loadHrvWindowTime())
			);
		}
		if (StressMetric.isSupported()) {
			metrics.add(new StressMetric());
		}
		if (RrMetric.isSupported() && GlobalSettings.loadRespirationRate() == RespirationRate.On) {
			metrics.add(new RrMetric());
		}
		return metrics;
	}

	private function createSessionName(sessionTime, activityName) {
		// Calculate session minutes and hours
		var sessionTimeMinutes = Math.round(sessionTime / 60.0).toNumber();
		var sessionTimeHours = sessionTimeMinutes / 60;
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
		if (me.mHrv != null) {
			me.mFeed.setListener(me.mHrv.method(:onIntervals));
			// clear stale paused from prior session; else multi-session drops HRV after session 1
			me.mFeed.resume();
			me.mFeed.resetSensorQuality();
		}
		me.mRecorder.start();
		me.mMeditateModel.isTimerRunning = true;
		me.mVibeAlertsExecutor = new VibeAlertsExecutor(me.mMeditateModel);
		if (me.mMeditateModel.hasBreathProgram()) {
			me.mBreathCuesExecutor = new BreathCuesExecutor(me.mMeditateModel);
		}
	}

	// recorder tick; the metrics are already sampled
	function onTick() {
		me.mMeditateModel.elapsedTime = me.mRecorder.elapsedTime;
		// advance the breath phase before anything reads it
		me.mMeditateModel.updateBreathRunner();
		if (me.mVibeAlertsExecutor != null) {
			me.mVibeAlertsExecutor.firePendingAlerts();
		}
		if (me.mBreathCuesExecutor != null) {
			me.mBreathCuesExecutor.firePendingCues();
		}

		// Check if we need to pause when a multiple of the planned session duration elapsed.
		// Edge-triggered on the round number so a skipped/jittered timer tick can't miss the boundary.
		var sessionTime = me.mMeditateModel.getSessionTime();
		if (me.mAutoStopEnabled && sessionTime > 0 && me.mMeditateModel.elapsedTime > 0) {
			var round = me.mMeditateModel.elapsedTime / sessionTime;
			if (round > me.mAutoStopRoundsTriggered) {
				me.mAutoStopRoundsTriggered = round;
				mMeditateDelegate.onSessionAutoComplete();
				return;
			}
		}
		Ui.requestUpdate();
	}

	// Pause/Resume session, returns true if session is now running
	function pauseResume() {
		var running = me.mRecorder.pauseResume();
		if (me.mHrv != null) {
			if (running) {
				me.mFeed.resume();
			} else {
				me.mFeed.pause();
			}
		}
		return running;
	}

	// the summary is taken before the recorder stops so session fields land in the fit file
	function stop() {
		me.mSummary = me.mRecorder.summary(me.mMeditateModel.getName());
		me.mRecorder.stop();
		if (me.mHrv != null) {
			me.mFeed.setListener(null);
			// clear paused so picker live HRV status keeps updating between sessions
			me.mFeed.resume();
		}
		me.mVibeAlertsExecutor = null;
		me.mBreathCuesExecutor = null;
	}

	function getSummary() {
		return me.mSummary;
	}

	function finish() {
		me.mRecorder.finish();
		me.persistWakeupSessionType();
		var usageStats = new UsageStats(me.mMeditateModel.elapsedTime);
		usageStats.sendCurrent();
		UsageStats.tryOpenPendingTip();
	}

	function discard() {
		me.mRecorder.discard();
		me.persistWakeupSessionType();
	}

	private function persistWakeupSessionType() {
		if (me.mEffectiveWakeupSessionType != null) {
			WakeupSessionStorage.saveActivityType(me.mEffectiveWakeupSessionType);
		}
	}
}
