using Toybox.WatchUi as Ui;

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
	private var mFitKind;
	private var mSummary;

	function initialize(meditateModel, beatIntervalFeed, meditateDelegate) {
		var selectedActivityType = Utils.getEffectiveActivityType(meditateModel.getActivityType());
		// current hypothesis: mediation/yoga/breathwork only supported with api >= 3.3.6
		// device to version: https://github.com/flocsy/garmin-dev-tools/blob/main/csv/device2all-versions.csv
		me.mFitKind = MeditateActivity.fitKindFor(selectedActivityType, Utils.MonkeyVersionAtLeast([3, 3, 6]));
		var name = FitSessionName.format(
			FitSessionName.resolve(meditateModel.getName(), selectedActivityType),
			meditateModel.getSessionTime()
		);
		var fitSessionSpec = FitSessionSpec.create(me.mFitKind, name);
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
		me.mAutoStopEnabled = GlobalSettings.load(GlobalSettings.AutoStopKey);
		me.mAutoStopRoundsTriggered = 0;
	}

	// the one place deciding what is recorded; hr first, the rest in metrics page order
	static function createMetrics(meditateModel, fitFields) {
		var metrics = [new HrMetric()];
		var hrvTracking = meditateModel.getHrvTracking();
		if (hrvTracking != HrvTracking.Off) {
			metrics.add(
				new HrvMetric(fitFields, hrvTracking == HrvTracking.OnDetailed, GlobalSettings.load(GlobalSettings.HrvWindowTimeKey))
			);
		}
		if (StressMetric.isSupported()) {
			metrics.add(new StressMetric());
		}
		if (RrMetric.isSupported() && GlobalSettings.load(GlobalSettings.RespirationRateKey) == RespirationRate.On) {
			metrics.add(new RrMetric());
		}
		return metrics;
	}

	// the fit sport of a session: generic, or any type below api 3.3.6, records as training
	static function fitKindFor(activityType, supportsActivityTypes) {
		if (!supportsActivityTypes || activityType == ActivityType.Generic) {
			return FitSessionKind.Training;
		}
		if (activityType == ActivityType.Yoga) {
			return FitSessionKind.Yoga;
		}
		if (activityType == ActivityType.Breathing) {
			return FitSessionKind.Breathing;
		}
		return FitSessionKind.Meditation;
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
		if (me.mFitKind != null) {
			WakeupSessionStorage.saveActivityType(me.mFitKind);
		}
	}
}
