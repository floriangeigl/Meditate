using Toybox.Application as App;
using Toybox.Math;
using Toybox.System;
using Toybox.Time;
using Toybox.Time.Gregorian;

// the minutes meditated this month and the tip prompt they can lead to; product behaviour, kept
// apart from the optional analytics in UsageStats. the key strings are stored data
class MonthlyStats {
	static const MonthlyKey = "usageStats_monthly";
	static const TipPendingKey = "usageStats_tipPending";

	// adds a finished session to this month; the first session of a new month leaves a pending tip
	// prompt behind when the month before reached 30 minutes
	static function add(sessionTime) {
		if (sessionTime == null) {
			return;
		}
		var monthlyStats = App.Storage.getValue(MonthlyKey);
		var current = 0;
		var month_today = Gregorian.info(Time.now(), Time.FORMAT_SHORT).month;
		if (monthlyStats != null) {
			var month_last_entry = monthlyStats[0];
			if (month_today != month_last_entry) {
				var lastMonthStats = monthlyStats[1];
				if (lastMonthStats / 60 >= 30) {
					var existingPending = App.Storage.getValue(TipPendingKey);
					if (existingPending == null || existingPending.size() < 1 || existingPending[0] != month_today) {
						App.Storage.setValue(TipPendingKey, [month_today, lastMonthStats]);
					}
				}
			} else {
				current = monthlyStats[1];
			}
		}
		current += sessionTime;
		App.Storage.setValue(MonthlyKey, [month_today, current]);
	}

	static function tryOpenPendingTip() {
		try {
			var pending = App.Storage.getValue(TipPendingKey);
			if (pending == null) {
				return;
			}
			// pending: [month_when_should_show, lastMonthStatsSeconds]
			if (pending.size() < 2 || pending[0] == null || pending[1] == null) {
				App.Storage.setValue(TipPendingKey, null);
				return;
			}
			var month_today = Gregorian.info(Time.now(), Time.FORMAT_SHORT).month;
			var pendingMonth = pending[0];
			if (month_today != pendingMonth) {
				// Next month started; drop the request so we don't show stale stats.
				App.Storage.setValue(TipPendingKey, null);
				return;
			}
			var devSettings = System.getDeviceSettings();
			if (devSettings != null && devSettings has :phoneConnected && !devSettings.phoneConnected) {
				// Phone not connected; keep pending and retry later.
				return;
			}
			var mins = Math.ceil(pending[1] / 60.0);
			TipMe.openTipMe(mins);
			App.Storage.setValue(TipPendingKey, null);
		} catch (ex) {
			// Never break the app due to optional tip prompt logic.
		}
	}
}
