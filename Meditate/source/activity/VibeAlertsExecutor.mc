class VibeAlertsExecutor {
	function initialize(meditateModel) {
		me.mMeditateModel = meditateModel;
		me.mIntervalAlerts = me.mMeditateModel.getIntervalAlerts();
	}

	private var mMeditateModel;
	private var mIntervalAlerts;

	function firePendingAlerts() {
		me.fireIfRequiredIntervalAlerts();
		me.fireIfRequiredFinalAlert();
	}

	private function fireIfRequiredFinalAlert() {
		var sessionTime = me.mMeditateModel.getSessionTime();
		if (sessionTime > 0 && me.mMeditateModel.elapsedTime > 0 && me.mMeditateModel.elapsedTime % sessionTime == 0) {
			Vibe.vibrate(me.mMeditateModel.getVibePattern());
		}
	}

	private function fireIfRequiredIntervalAlerts() {
		var alert = null;
		var rm = [];
		var elapsedTime = me.mMeditateModel.elapsedTime;
		for (var i = 0; i < me.mIntervalAlerts.size(); i++) {
			alert = me.mIntervalAlerts.get(i);
			if (alert.time > 0 && elapsedTime - alert.offset >= 0 && (elapsedTime - alert.offset) % alert.time == 0) {
				Vibe.vibrate(alert.vibePattern);
				if (alert.type == IntervalAlertType.OneOff) {
					rm.add(i);
				}
			}
		}
		// Delete one-off alerts in reverse index order to avoid shifting indices leading to out-of-bounds
		for (var i = rm.size() - 1; i >= 0; i--) {
			me.mIntervalAlerts.delete(rm[i]);
		}
	}
}
