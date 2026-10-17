using Toybox.Application as App;
using Toybox.Communications;
using Toybox.Math;
using Toybox.System;
using Toybox.Time;
using Toybox.Time.Gregorian;

// the minutes meditated this month and the tip prompt they can lead to; product behaviour, kept
// apart from the optional analytics in UsageStats. the key strings are stored data
class MonthlyStats {
	static const MonthlyKey = "usageStats_monthly";
	static const TipPendingKey = "usageStats_tipPending";
	// a month with at least this much meditation leads to the tip prompt
	static const TipMinSeconds = 900;

	// adds a finished session to this month; the first session of a new month leaves a pending tip
	// prompt behind when the month before reached TipMinSeconds
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
				if (lastMonthStats >= TipMinSeconds) {
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
			// [month to show it in, last month's seconds]
			if (pending.size() < 2 || pending[0] == null || pending[1] == null) {
				App.Storage.setValue(TipPendingKey, null);
				return;
			}
			var month_today = Gregorian.info(Time.now(), Time.FORMAT_SHORT).month;
			if (month_today != pending[0]) {
				// stale once the next month starts
				App.Storage.setValue(TipPendingKey, null);
				return;
			}
			if (!System.getDeviceSettings().phoneConnected) {
				// kept for a later launch
				return;
			}
			openTipPage(Math.ceil(pending[1] / 60.0).toNumber());
			App.Storage.setValue(TipPendingKey, null);
		} catch (ex) {
			// never break the app over the tip prompt
		}
	}

	private static function openTipPage(minutes) {
		Communications.openWebPage(
			"https://geigl.online/tipme/",
			{
				"meditate-minutes" => minutes.toString(),
				"utm_source" => "meditate_app",
				"utm_medium" => "garmin_watch",
				"utm_campaign" => "tip",
			},
			null
		);
	}
}
