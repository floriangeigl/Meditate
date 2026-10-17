using Toybox.Test;
using Toybox.Application as App;
using Toybox.Time;
using Toybox.Time.Gregorian;

// the monthly minutes moved out of UsageStats; same stored format [month, seconds]
(:test)
class MonthlyStatsTests {
	(:test)
	static function minutesAddUpAndANewMonthLeavesATip(logger) {
		var savedMonthly = App.Storage.getValue(MonthlyStats.MonthlyKey);
		var savedPending = App.Storage.getValue(MonthlyStats.TipPendingKey);
		try {
			var month = Gregorian.info(Time.now(), Time.FORMAT_SHORT).month;
			var otherMonth = month % 12 + 1;

			// same month: seconds add up, no tip
			App.Storage.setValue(MonthlyStats.MonthlyKey, [month, 600]);
			App.Storage.deleteValue(MonthlyStats.TipPendingKey);
			MonthlyStats.add(300);
			var sameMonth =
				StorageSnapshot.deepEquals(App.Storage.getValue(MonthlyStats.MonthlyKey), [month, 900]) &&
				App.Storage.getValue(MonthlyStats.TipPendingKey) == null;

			// a new month after 15 minutes starts over and leaves the tip for this month
			App.Storage.setValue(MonthlyStats.MonthlyKey, [otherMonth, 900]);
			MonthlyStats.add(60);
			var newMonth =
				StorageSnapshot.deepEquals(App.Storage.getValue(MonthlyStats.MonthlyKey), [month, 60]) &&
				StorageSnapshot.deepEquals(App.Storage.getValue(MonthlyStats.TipPendingKey), [month, 900]);

			// a second short of 15 minutes leaves no tip
			App.Storage.setValue(MonthlyStats.MonthlyKey, [otherMonth, 899]);
			App.Storage.deleteValue(MonthlyStats.TipPendingKey);
			MonthlyStats.add(60);
			var belowThreshold = App.Storage.getValue(MonthlyStats.TipPendingKey) == null;

			// no session time changes nothing
			MonthlyStats.add(null);
			var unchanged = StorageSnapshot.deepEquals(App.Storage.getValue(MonthlyStats.MonthlyKey), [month, 60]);

			StorageSnapshot.put(MonthlyStats.MonthlyKey, savedMonthly);
			StorageSnapshot.put(MonthlyStats.TipPendingKey, savedPending);
			return sameMonth && newMonth && belowThreshold && unchanged;
		} catch (ex) {
			StorageSnapshot.put(MonthlyStats.MonthlyKey, savedMonthly);
			StorageSnapshot.put(MonthlyStats.TipPendingKey, savedPending);
			throw ex;
		}
	}
}
