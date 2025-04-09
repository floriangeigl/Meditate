class VibeAlertsExecutor {
	function initialize(meditateModel) {
		me.mMeditateModel = meditateModel;
		me.mIntervalAlerts = me.mMeditateModel.getIntervalAlerts();
		me.mIsFinalAlertPending = true;
	}

	private var mIsFinalAlertPending;
	private var mMeditateModel;
	private var mIntervalAlerts;

	function firePendingAlerts() {
		if (me.mIsFinalAlertPending == true) {
			me.fireIfRequiredIntervalAlerts();
			me.fireIfRequiredFinalAlert();
		}

		// Continue firing alert for repeated invervals even after regular session time is over
		if (me.mMeditateModel.elapsedTime >= me.mMeditateModel.getSessionTime() + 10) {
			me.fireIfRequiredIntervalAlerts();
		}
	}

	private function fireIfRequiredFinalAlert() {
		if (me.mMeditateModel.elapsedTime >= me.mMeditateModel.getSessionTime()) {
			Vibe.vibrate(me.mMeditateModel.getVibePattern());
			me.mIsFinalAlertPending = false;
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
					rm.add(alert);
				}
			}
		}
		for (var i = 0; i < rm.size(); i++) {
			me.mIntervalAlerts.remove(rm[i]);
		}
	}
}
