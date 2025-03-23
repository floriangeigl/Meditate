using Toybox.Application as App;
using HrvAlgorithms.HrvTracking;

class MeditateModel extends ScreenPicker.DetailsModel{
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
	}
	
	private var mSession;
	private var rrActivity;
	private var stressActivity;
	private var mIsHrvOn, mHrvTracking;
	private static const mRespirationRateSetting = GlobalSettings.loadRespirationRate();

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
	
	function getOneOffIntervalAlerts() {
		return me.getIntervalAlerts(IntervalAlertType.OneOff);
	}	
	
	function hasIntervalAlerts() {
		return me.mSession.intervalAlerts.count() > 0;
	}
	
	private function getIntervalAlerts(alertType) {
		var result = {};
		for (var i = 0; i < me.mSession.intervalAlerts.count(); i++) {
			var alert = me.mSession.intervalAlerts.get(i);
			if (alert.type == alertType) {
				result.put(result.size(), alert);
			}
		}
		return result;
	}
	
	function getRepeatIntervalAlerts() {		
		return me.getIntervalAlerts(IntervalAlertType.Repeat);
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

	static function isRespirationRateOn() {
		// Check if watch supports respiration rate & Check if global option is enabled
		if (HrvAlgorithms.RrActivity.isSensorSupported() && mRespirationRateSetting == RespirationRate.On) {
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

	function getStress() {
		if (isTimerRunning) {
			return stressActivity.getCurrentValue();
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