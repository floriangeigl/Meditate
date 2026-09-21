using Toybox.Application as App;

// view model of a running session: elapsed time, the live metrics and the session facts
class MeditateModel extends ScreenPicker.DetailsModel {
	function initialize(sessionModel) {
		ScreenPicker.DetailsModel.initialize();
		me.mSession = sessionModel;
		me.titleColor = me.mSession.color;
		me.mDisplayName = null;
		me.elapsedTime = 0;
		me.isTimerRunning = false;
		me.liveMetrics = [];
		var breathProgram = me.mSession.getActiveBreathProgram();
		me.mBreathRunner = breathProgram == null ? null : new BreathProgramRunner(breathProgram);
	}

	private var mSession;
	private var mDisplayName;
	private var mBreathRunner;

	var elapsedTime;
	var isTimerRunning;
	// metrics page order; set by MeditateActivity before the view lays out
	var liveMetrics;

	function getMetric(id) {
		for (var i = 0; i < me.liveMetrics.size(); i++) {
			if (me.liveMetrics[i].id == id) {
				return me.liveMetrics[i];
			}
		}
		return null;
	}

	function getHrvTracking() {
		return me.mSession.getHrvTracking();
	}

	function getSessionTime() {
		return me.mSession.time;
	}

	function hasIntervalAlerts() {
		return me.mSession.getIntervalAlerts().size() > 0;
	}

	function getBreathRunner() {
		return me.mBreathRunner;
	}

	// single place the breath phase state advances; both the cues and the view read the result
	function updateBreathRunner() {
		if (me.mBreathRunner != null) {
			me.mBreathRunner.update(me.elapsedTime);
		}
	}

	function hasBreathProgram() {
		return me.mBreathRunner != null;
	}

	function getName() {
		if (me.mDisplayName != null) {
			return me.mDisplayName;
		}
		return me.mSession.getName();
	}

	function setDisplayName(name) {
		me.mDisplayName = name;
	}

	function getIntervalAlerts() {
		return me.mSession.getIntervalAlerts();
	}

	function getColor() {
		return me.mSession.color;
	}

	function getVibePattern() {
		return me.mSession.vibePattern;
	}

	function getActivityType() {
		return me.mSession.getActivityType();
	}
}
