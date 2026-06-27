class VibeAlertsExecutor {
	function initialize(meditateModel) {
		me.mMeditateModel = meditateModel;
		me.mIntervalAlerts = me.mMeditateModel.getIntervalAlerts();
		// start at 0 so the firing point at t=0 counts as already passed (no buzz at session start);
		// first interval fires at t=offset, or t=time when offset is 0
		me.mLastElapsedTime = 0;
	}

	private var mMeditateModel;
	private var mIntervalAlerts;
	private var mLastElapsedTime;

	function firePendingAlerts() {
		var elapsedTime = me.mMeditateModel.elapsedTime;
		me.fireIfRequiredIntervalAlerts(elapsedTime);
		me.fireIfRequiredFinalAlert(elapsedTime);
		me.mLastElapsedTime = elapsedTime;
	}

	// True if any multiple k*period (k >= 1) lies in (prev, cur].
	// Edge-triggered so a skipped/jittered timer tick can't miss the boundary.
	private function multipleCrossed(prev, cur, period) {
		if (period <= 0) {
			return false;
		}
		var p = prev < 0 ? 0 : prev;
		return cur / period > p / period;
	}

	// True if any firing point offset + k*period (k >= 0) lies in (prev, cur].
	private function pointCrossed(prev, cur, offset, period) {
		if (period <= 0) {
			return false;
		}
		var nCur = cur >= offset ? (cur - offset) / period + 1 : 0;
		var nPrev = prev >= offset ? (prev - offset) / period + 1 : 0;
		return nCur > nPrev;
	}

	private function fireIfRequiredFinalAlert(elapsedTime) {
		var sessionTime = me.mMeditateModel.getSessionTime();
		if (sessionTime > 0 && me.multipleCrossed(me.mLastElapsedTime, elapsedTime, sessionTime)) {
			Vibe.vibrate(me.mMeditateModel.getVibePattern());
		}
	}

	private function fireIfRequiredIntervalAlerts(elapsedTime) {
		var alert = null;
		var rm = [];
		for (var i = 0; i < me.mIntervalAlerts.size(); i++) {
			alert = me.mIntervalAlerts.get(i);
			if (alert.time > 0 && me.pointCrossed(me.mLastElapsedTime, elapsedTime, alert.offset, alert.time)) {
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
