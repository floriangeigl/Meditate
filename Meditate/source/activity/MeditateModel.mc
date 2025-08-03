using Toybox.Application as App;
using HrvAlgorithms.HrvTracking;

class MeditateModel extends ScreenPicker.DetailsModel {
	function initialize(sessionModel) {
		ScreenPicker.DetailsModel.initialize();
		me.mSession = sessionModel;
		me.titleColor = me.mSession.color;
		me.elapsedTime = 0;
		me.minHr = null;
		me.currentHr = null;
		me.hrvValue = null;
		me.respirationRate = null;
		me.isTimerRunning = false;
		me.rrActivity = new HrvAlgorithms.RrActivity();
		me.stressActivity = new HrvAlgorithms.StressActivity();
		me.mHrvTracking = me.mSession.getHrvTracking();
		me.mIsHrvOn = me.mHrvTracking != HrvTracking.Off;
		me.mRespirationRateSetting = GlobalSettings.loadRespirationRate();
	}

	private var mSession;
	private var rrActivity;
	private var stressActivity;
	private var mIsHrvOn, mHrvTracking;
	private var mRespirationRateSetting;

	var currentHr;
	var minHr;
	var elapsedTime;
	var hrvValue;
	var respirationRate;
	var isTimerRunning;

	function isHrvOn() {
		return me.mIsHrvOn;
	}

	function getHrvTracking() {
		return me.mHrvTracking;
	}

	function getSessionTime() {
		return me.mSession.time;
	}

	function hasIntervalAlerts() {
		return me.mSession.getIntervalAlerts().size() > 0;
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

	function isRespirationRateOn() {
		// Check if watch supports respiration rate & Check if global option is enabled
		if (me.rrActivity != null && me.rrActivity.isSupported() && me.mRespirationRateSetting == RespirationRate.On) {
			return true;
		} else {
			return false;
		}
	}

	function getRespirationRate() {
		if (isTimerRunning) {
			return rrActivity.getCurrentValue();
		} else {
			return null;
		}
	}

	function isStressSupported() {
		if (me.stressActivity != null) {
			return stressActivity.isSupported();
		} else {
			return null;
		}
	}

	function getStress() {
		if (me.isTimerRunning) {
			return me.stressActivity.getCurrentValue();
		} else {
			return null;
		}
	}

	function getRespirationActivity() {
		return rrActivity;
	}
	function getStressActivity() {
		return stressActivity;
	}
}
